& {
  $ErrorActionPreference = 'Stop'
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $root = Join-Path $env:LOCALAPPDATA 'MML0.2'
  if (!('MMLCore025' -as [type])) {
    $compileOptions=@{}
    if ($PSVersionTable.PSEdition -eq 'Desktop') { $compileOptions.ReferencedAssemblies='System.Net.Http.dll' }
    else { $compileOptions.CompilerOptions='/nowarn:SYSLIB0014' }
    Add-Type @compileOptions -TypeDefinition @'
using System; using System.IO;
using System.Net; using System.Net.Http;
using System.Security.Cryptography;
using System.Collections.Generic; using System.Collections.Concurrent;
using System.Threading; using System.Threading.Tasks;
using System.Text.RegularExpressions;
public static class MMLCore025 {
  public struct Job {
    public readonly string Url, Path, Hash;
    public Job(string url,string path,string hash) { Url=url; Path=path; Hash=hash; }
  }
  static readonly HttpClient Http = new HttpClient(new HttpClientHandler { AllowAutoRedirect=false }) { Timeout=Timeout.InfiniteTimeSpan };
  static readonly HashSet<string> Hosts = new HashSet<string>((
    "piston-meta.mojang.com,piston-data.mojang.com,launchermeta.mojang.com,launcher.mojang.com,libraries.minecraft.net,"+
    "resources.download.minecraft.net,api.adoptium.net,github.com,objects.githubusercontent.com,release-assets.githubusercontent.com").Split(','));
  public static string PathIn(string root,string relative) {
    if(Path.IsPathRooted(relative)||relative.Contains(":")) throw new IOException("Unsafe relative path");
    string full=Path.GetFullPath(Path.Combine(root,relative));
    if(!full.StartsWith(Path.GetFullPath(root).TrimEnd('\\')+"\\",StringComparison.OrdinalIgnoreCase)) throw new IOException("Path escapes data directory");
    for(string p=full;p!=null;p=Path.GetDirectoryName(p))
      if((File.Exists(p)||Directory.Exists(p))&&(File.GetAttributes(p)&FileAttributes.ReparsePoint)!=0) throw new IOException("Reparse point refused: "+p);
    return full;
  }
  public static void Url(string value) {
    Uri u=new Uri(value);
    if(u.Scheme!="https"||!u.IsDefaultPort||u.UserInfo!=""||!Hosts.Contains(u.DnsSafeHost)) throw new IOException("Untrusted URL: "+value);
    if(u.DnsSafeHost=="github.com"&&!Regex.IsMatch(u.AbsolutePath,@"^/adoptium/temurin[^/]+-binaries/releases/download/")) throw new IOException("Untrusted Java release");
  }
  static HashAlgorithm Algorithm(string hash) {
    if(!Regex.IsMatch(hash??"",@"\A(?:[a-fA-F0-9]{40}|[a-fA-F0-9]{64})\z")) throw new IOException("Invalid checksum");
    return hash.Length==40?(HashAlgorithm)SHA1.Create():SHA256.Create();
  }
  static bool Equal(byte[] bytes,string hash) { return BitConverter.ToString(bytes).Replace("-","").Equals(hash,StringComparison.OrdinalIgnoreCase); }
  public static bool Valid(string path,string hash) {
    using(var h=Algorithm(hash)) { if(!File.Exists(path)) return false;
      using(var s=File.OpenRead(path)) return Equal(h.ComputeHash(s),hash); }
  }
  static async Task Fetch(string root,Job job) {
    for(int attempt=1;;attempt++) {
      string temp=job.Path+"."+Guid.NewGuid().ToString("N")+".part";
      try {
        Directory.CreateDirectory(Path.GetDirectoryName(job.Path));
        using(var cancel=new CancellationTokenSource(TimeSpan.FromSeconds(120))) {
          string location=job.Url;
          for(int redirects=0;;redirects++) {
            Url(location);
            using(var response=await Http.GetAsync(location,HttpCompletionOption.ResponseHeadersRead,cancel.Token)) {
              if((int)response.StatusCode/100==3) {
                if(redirects>=5||response.Headers.Location==null) throw new IOException("Redirect limit or missing Location");
                location=new Uri(new Uri(location),response.Headers.Location).AbsoluteUri; continue;
              }
              response.EnsureSuccessStatusCode();
              using(var input=await response.Content.ReadAsStreamAsync())
              using(var output=new FileStream(temp,FileMode.CreateNew,FileAccess.Write,FileShare.None,65536,true))
              using(var h=Algorithm(job.Hash)) {
                byte[] buffer=new byte[65536]; int n;
                while((n=await input.ReadAsync(buffer,0,buffer.Length,cancel.Token))!=0) {
                  h.TransformBlock(buffer,0,n,buffer,0);
                  await output.WriteAsync(buffer,0,n,cancel.Token);
                }
                h.TransformFinalBlock(buffer,0,0);
                if(!Equal(h.Hash,job.Hash)) throw new IOException("Checksum mismatch");
              }
              PathIn(root,job.Path.Substring(root.Length));
              if(File.Exists(job.Path)) File.Replace(temp,job.Path,null); else File.Move(temp,job.Path);
              return;
            }
          }
        }
      } catch { if(attempt==3) throw; }
      finally { if(File.Exists(temp)) File.Delete(temp); }
      await Task.Delay(attempt*1000);
    }
  }
  public static void Assets(string root,string[] hashes) {
    var jobs=new List<Job>();
    foreach(string hash in new HashSet<string>(hashes)) {
      if(!Regex.IsMatch(hash??"",@"\A[a-f0-9]{40}\z")) throw new IOException("Invalid asset hash");
      string relative=hash.Substring(0,2)+"/"+hash;
      jobs.Add(new Job("https://resources.download.minecraft.net/"+relative,Path.Combine(root,"assets/objects/"+relative),hash));
    }
    Console.WriteLine("Assets: {0} unique files",jobs.Count); Batch(root,jobs.ToArray());
  }
  public static void Batch(string root,Job[] jobs,int downloads=8,int checks=4) {
    if(downloads<1||checks<1) throw new ArgumentException("Invalid concurrency");
    root=Path.GetFullPath(root).TrimEnd('\\')+"\\";
    var unique=new Dictionary<string,Job>(StringComparer.OrdinalIgnoreCase);
    foreach(var job in jobs) {
      string path=Path.GetFullPath(job.Path); Url(job.Url);
      if(!path.StartsWith(root,StringComparison.OrdinalIgnoreCase)) throw new IOException("Download outside data directory");
      PathIn(root,path.Substring(root.Length));
      using(var h=Algorithm(job.Hash)) {}
      Job previous;
      if(unique.TryGetValue(path,out previous)&&previous.Hash!=job.Hash) throw new IOException("Conflicting destination");
      unique[path]=new Job(job.Url,path,job.Hash);
    }
    var missing=new ConcurrentQueue<Job>();
    Parallel.ForEach(unique.Values,new ParallelOptions{MaxDegreeOfParallelism=checks},j=>{if(!Valid(j.Path,j.Hash))missing.Enqueue(j);});
    var errors=new ConcurrentQueue<Exception>(); int total=missing.Count,done=0;
    var workers=new Task[Math.Min(downloads,total)];
    int old=ServicePointManager.DefaultConnectionLimit; ServicePointManager.DefaultConnectionLimit=Math.Max(old,downloads);
    try {
      for(int w=0;w<workers.Length;w++) workers[w]=Task.Run(async delegate {
        Job j; while(missing.TryDequeue(out j)) { try { await Fetch(root,j); Interlocked.Increment(ref done); } catch(Exception e) { errors.Enqueue(new IOException(j.Path+": "+e.Message,e)); } }
      });
      var all=Task.WhenAll(workers);
      while(!all.Wait(1000)) Console.Write("\rFiles: {0}/{1}  ",Volatile.Read(ref done),total);
      if(total>0) Console.WriteLine("\rFiles: {0} succeeded, {1} failed",done,errors.Count);
      if(!errors.IsEmpty) throw new AggregateException(errors);
    } finally { ServicePointManager.DefaultConnectionLimit=old; }
  }
}
'@
  }
  $core='MMLCore025' -as [type]
  function Data-Path([string]$relative) { $core::PathIn($root,$relative) }
  function Get-Json([string]$url) {
    $core::Url($url)
    for ($i = 1; $i -le 3; $i++) {
      try { return Invoke-RestMethod -Uri $url -TimeoutSec 60 -UseBasicParsing }
      catch { if ($i -eq 3) { throw }; Start-Sleep -Seconds $i }
    }
  }
  function Expand-Safe([string]$zip,[string]$destination,$exclude=@()) {
    $null=[IO.Directory]::CreateDirectory($destination)
    $archive=[IO.Compression.ZipFile]::OpenRead($zip)
    try { :entries foreach($entry in $archive.Entries) {
      $target=$core::PathIn($destination,$entry.FullName)
      if (!$entry.Name) { continue }
      foreach($x in $exclude) { if ($entry.FullName.StartsWith($x,[StringComparison]::OrdinalIgnoreCase)) { continue entries } }
      $null=[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
      [IO.Compression.ZipFileExtensions]::ExtractToFile($entry,$target,$true)
    } } finally { $archive.Dispose() }
  }
  function Download-Assets($assets) {
    [MMLCore025]::Assets($root,[string[]]@($assets.objects.PSObject.Properties | ForEach-Object {$_.Value.hash}))
  }
  function Test-Rules($rules) {
    if (!$rules) { return $true }
    $allow=$false; $win=[Environment]::OSVersion.Version
    foreach($r in $rules) {
      $os=$r.os
      if (($os.name -and $os.name -ne 'windows') -or
          ($os.arch -and $os.arch -notin @('x86_64','amd64','x64')) -or
          ($os.version -and $win.ToString() -notmatch $os.version) -or
          ($os.versionRange.min -and $win -lt [version]$os.versionRange.min) -or
          ($os.versionRange.max -and $win -ge [version]$os.versionRange.max) -or
          ($r.features -and @($r.features.PSObject.Properties.Where({[bool]$_.Value},'First')).Count)) { continue }
      $allow=$r.action -eq 'allow'
    }
    return $allow
  }
  function Offline-UUID([string]$name) {
    $md5 = [Security.Cryptography.MD5]::Create()
    try { $bytes = $md5.ComputeHash([Text.Encoding]::UTF8.GetBytes("OfflinePlayer:$name")) } finally { $md5.Dispose() }
    $bytes[6] = ($bytes[6] -band 15) -bor 48
    $bytes[8] = ($bytes[8] -band 63) -bor 128
    return ([BitConverter]::ToString($bytes)).Replace('-','').ToLowerInvariant()
  }
  function Quote-Argument([string]$s) {
    return '"' + [regex]::Replace([regex]::Replace($s, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
  }
  function Probe-Java([string]$path, [int]$major) {
    try {
      $psi = New-Object Diagnostics.ProcessStartInfo -Property @{
        FileName=$path; Arguments='-XshowSettings:properties -version'; UseShellExecute=$false
        CreateNoWindow=$true; RedirectStandardError=$true; RedirectStandardOutput=$true
      }
      $p = [Diagnostics.Process]::Start($psi)
      $stderr = $p.StandardError.ReadToEndAsync(); $stdout = $p.StandardOutput.ReadToEndAsync()
      if (!$p.WaitForExit(15000)) { $p.Kill(); return $false }
      $output = $stderr.Result + $stdout.Result
      return ($p.ExitCode -eq 0 -and $output -match "java\.version\s*=\s*$major(?:\.|\s|\+)" -and $output -match 'os\.arch\s*=\s*(amd64|x86_64)')
    } catch { return $false }
  }
  function Find-Java([int]$major,[switch]$Install) {
    $owned=Data-Path "java/$major"
    $dirs=@(
      $owned; $env:JAVA_HOME
      foreach ($base in @($env:ProgramFiles,${env:ProgramFiles(x86)},(Join-Path $env:LOCALAPPDATA 'Programs'))) {
        if (!$base) { continue }
        foreach ($vendor in @('Java','Eclipse Adoptium','Microsoft','BellSoft','Amazon Corretto','Zulu','GraalVM')) {
          $d=Join-Path $base $vendor
          if (Test-Path $d) { $d; @(Get-ChildItem $d -Directory -ea SilentlyContinue).FullName }
        }
      }
      foreach ($key in @('HKLM:\SOFTWARE\JavaSoft','HKLM:\SOFTWARE\WOW6432Node\JavaSoft','HKCU:\SOFTWARE\JavaSoft')) {
        if (!(Test-Path $key)) { continue }
        foreach ($k in @($key)+@(Get-ChildItem $key -Recurse -ea SilentlyContinue).PSPath) {
          if ($k) { (Get-ItemProperty $k -ea SilentlyContinue).JavaHome }
        }
      }
    )
    $candidates=@(
      foreach ($d in $dirs) {
        if (!$d -or !(Test-Path $d)) { continue }
        Join-Path $d 'bin/java.exe'
        if ($d -eq $owned) { @(Get-ChildItem $d -Filter java.exe -Recurse -ea SilentlyContinue).FullName }
      }
      @(Get-Command java.exe -All -ea SilentlyContinue).Source
    )
    foreach ($c in ($candidates | Select-Object -Unique)) { if ($c -and (Test-Path -LiteralPath $c) -and (Probe-Java $c $major)) { return $c } }
      if (!$Install) { return }
    foreach ($kind in @('jre','jdk')) {
      try { $releases = @(Get-Json "https://api.adoptium.net/v3/assets/latest/$major/hotspot?architecture=x64&image_type=$kind&os=windows&vendor=eclipse") } catch { if ($kind -eq 'jdk') { throw }; continue }
      $package = $releases.binary.package | Where-Object { $_.name -like '*.zip' } | Select-Object -First 1
      if ($package) { break }
    }
    if (!$package) { throw "No Windows x64 Java $major archive available" }
    $zip = Get-Resource $package "cache/java-$major.zip" -Runtime
    Expand-Safe $zip (Data-Path "java/$major")
    $java = Find-Java $major
    if (!$java) { throw "Downloaded Java $major failed executable validation" }
    return $java
  }
  function Get-Releases {
    $manifest = Get-Json 'https://piston-meta.mojang.com/mc/game/version_manifest_v2.json'
    $minimum = ($manifest.versions | Where-Object id -eq '1.20.1').releaseTime
    if (!$minimum) { throw 'Official manifest does not contain 1.20.1' }
    return @($manifest.versions | Where-Object { $_.type -eq 'release' -and [datetime]$_.releaseTime -ge [datetime]$minimum } | Sort-Object { [datetime]$_.releaseTime } -Descending)
  }
  function Choose-Version {
    $versions=@(@(foreach($d in Get-ChildItem (Data-Path 'versions') -Directory -ea SilentlyContinue) {
      try {
        $r=[IO.File]::ReadAllText((Join-Path $d.FullName 'installed.json')) | ConvertFrom-Json
        if ($r.id -eq $d.Name -and $r.sha1 -match '^[a-f0-9]{40}$') { $r }
      } catch {}
    }) | Sort-Object {[datetime]$_.releaseTime} -Descending)
    Write-Host 'Minimum Minecraft Launcher 0.2.5'
    while ($true) {
      $cached=[bool]$versions.Count
      if (!$cached) { $releases=@(Get-Releases); $versions=@($releases | Select-Object -First 12) }
      $count=$versions.Count
      Write-Host $(if($cached){'Installed versions (files will be verified):'}else{'Available releases:'})
      for($i=0;$i -lt $count;$i++) { Write-Host "[$($i+1)] $($versions[$i].id)" }
      Write-Host $(if($cached){"[$($count+1)] Install another release"}else{'[0] Enter a specific release (1.20.1 or newer)'})
      $choice=Read-Choice ($count+[int]$cached) -Zero:(!$cached)
      if ($choice -gt 0 -and $choice -le $count) { return $versions[$choice-1] }
      if ($cached) { $versions=@(); continue }
      do { $id=Read-Host 'Release ID'; $selected=$releases | Where-Object id -eq $id | Select-Object -First 1 } until ($selected)
      return $selected
    }
  }
  function Read-Choice([int]$max, [switch]$Zero) {
    do {
      $text = Read-Host 'Choose version [1]'; if (!$text) { return 1 }
      $n = 0
    } until ([int]::TryParse($text, [ref]$n) -and $n -le $max -and ($n -ge 1 -or ($Zero -and $n -eq 0)))
    return $n
  }
  function Get-Resource($entry,[string]$relative,[switch]$Runtime) {
    $path=Data-Path $relative
    $url=$entry.url; $hash=$entry.sha1
    if ($Runtime) { $url=$entry.link; $hash=$entry.checksum }
    if ($hash.Length -ne (40+24*[int][bool]$Runtime)) { throw "Invalid checksum: $path" }
    $core::Batch($root,@([MMLCore025+Job]::new($url,$path,$hash)),1,1)
    return $path
  }
  function Install-Minecraft($record, $v) {
    $id = $record.id
    $jobs=New-Object 'Collections.Generic.List[MMLCore025+Job]'
    $extract=New-Object Collections.ArrayList
    $client=Data-Path "versions/$id/$id.jar"
    $jobs.Add([MMLCore025+Job]::new($v.downloads.client.url,$client,$v.downloads.client.sha1))
    $natives = Data-Path "natives/$id"
    $null = [IO.Directory]::CreateDirectory($natives)
    $classpath=@(foreach ($lib in $v.libraries) {
      if (!(Test-Rules $lib.rules) -or $lib.name -match ':natives-windows-(arm64|aarch64|x86)$') { continue }
      $artifact = $lib.downloads.artifact
      if ($artifact) {
        $path = Data-Path ("libraries/" + $artifact.path); $jobs.Add([MMLCore025+Job]::new($artifact.url,$path,$artifact.sha1))
        $path
        if ($lib.name -match ':natives-windows$') { $null=$extract.Add(@($path,@('META-INF/'))) }
      }
      if ($lib.natives.windows) {
        $classifier = $lib.natives.windows.Replace('${arch}','64')
        $native = $lib.downloads.classifiers.$classifier
        if (!$native) { throw "Missing native classifier: $classifier" }
        $path = Data-Path ("libraries/" + $native.path); $jobs.Add([MMLCore025+Job]::new($native.url,$path,$native.sha1))
        $null=$extract.Add(@($path,@($lib.extract.exclude)))
      }
    }; $client)
    $core::Batch($root,$jobs.ToArray())
    foreach($item in $extract) { Expand-Safe $item[0] $natives $item[1] }
    $assets = [IO.File]::ReadAllText((Get-Resource $v.assetIndex "assets/indexes/$($v.assetIndex.id).json")) | ConvertFrom-Json
    if ($assets.virtual -or $assets.map_to_resources) { throw 'Legacy asset layout is unsupported' }
    Download-Assets $assets
    $logFile = if ($v.logging.client.file) {
      Get-Resource $v.logging.client.file "assets/log_configs/$($v.logging.client.file.id)"
    }
    $record | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath (Data-Path "versions/$id/installed.json") -Encoding UTF8
    return @{ Version=$v; Classpath=($classpath -join ';'); Natives=$natives; LogFile=$logFile }
  }
  function Build-Arguments($install, [string]$username) {
    $v = $install.Version
    $game = Data-Path "instances/$($v.id)"
    $null = [IO.Directory]::CreateDirectory($game)
    $values = @{
      auth_player_name=$username; auth_uuid=(Offline-UUID $username); auth_access_token='MML_OFFLINE'
      auth_xuid='0'; clientid=''; user_type='legacy'; user_properties='{}'; version_type='release'
      version_name=$v.id; game_directory=$game; assets_root=(Data-Path 'assets'); assets_index_name=$v.assetIndex.id
      natives_directory=$install.Natives; launcher_name='MML'; launcher_version='0.2.5'
      classpath=$install.Classpath; classpath_separator=';'; library_directory=(Data-Path 'libraries')
    }
    '-Xms512M'; '-Xmx2G'
    foreach ($token in @($v.arguments.jvm
      if ($install.LogFile) { $v.logging.client.argument.Replace('${path}',$install.LogFile) }
      $v.mainClass; $v.arguments.game)) {
      if ($token -is [string]) { $parts = @($token) }
      elseif (Test-Rules $token.rules) { $parts = @($token.value) } else { continue }
      foreach ($part in $parts) {
        $expanded = [string]$part
        foreach ($key in $values.Keys) { $expanded = $expanded.Replace(('${'+$key+'}'), [string]$values[$key]) }
        if ($expanded -match '\$\{[^}]+\}') { throw "Unknown argument placeholder: $expanded" }
        $expanded
      }
    }
  }
  try {
    if (![Environment]::Is64BitOperatingSystem -or ![Environment]::Is64BitProcess) { throw 'Please open 64-bit Windows PowerShell on Windows x64.' }
    $record = Choose-Version
    do { $username = Read-Host 'Game username [Steve]'; if (!$username) { $username = 'Steve' } } until ($username -cmatch '^[A-Za-z0-9_]{3,16}$')
    $id=$record.id
    $v = [IO.File]::ReadAllText((Get-Resource $record "versions/$id/$id.json")) | ConvertFrom-Json
    if ($v.id -ne $id -or !$v.javaVersion.majorVersion -or !$v.arguments) { throw 'Unsupported version metadata' }
    $major = [int]$v.javaVersion.majorVersion
    Write-Host "Checking Windows x64 Java $major..."
    $java = Find-Java $major -Install
    $install = Install-Minecraft $record $v
    $arguments = @(Build-Arguments $install $username)
    $log = Data-Path ('logs/game-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
    $null = [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($log))
    $command = ($arguments | ForEach-Object { Quote-Argument $_ }) -join ' '
    Write-Host "Starting Minecraft $($record.id), Java $major. Log: $log"
    $process = Start-Process -FilePath $java -ArgumentList $command -WorkingDirectory (Data-Path "instances/$($record.id)") -RedirectStandardOutput $log -RedirectStandardError "$log.err" -PassThru
    $process.WaitForExit()
    if ($process.ExitCode -ne 0) { throw "Game exited with code $($process.ExitCode). See $log and $log.err" }
  } catch { Write-Host ("MML failed: " + $_.Exception.Message) -ForegroundColor Red }
}
