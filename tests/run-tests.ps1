param([string]$Source,[switch]$Online)
$ErrorActionPreference='Stop'
if(!$Source){$Source=Join-Path (Split-Path $PSScriptRoot) 'src\mml.ps1'}
$text=Get-Content $Source -Raw
. "$PSScriptRoot/TestHelpers.ps1" -Source $Source
$start=$text.IndexOf('{')+1; $prefix=$text.Substring($start,$functions[0].Extent.StartOffset-$start)
. ([scriptblock]::Create($prefix)); 'PASS repeated initialization'
$root=[IO.Path]::GetFullPath((Join-Path $env:TEMP ('MML public tests '+[guid]::NewGuid().ToString('N'))))
$null=[IO.Directory]::CreateDirectory($root)
function Assert($ok,$description){if(!$ok){throw $description};"PASS $description"}
$cs=$text.Substring($text.IndexOf('using System;'));$cs=$cs.Substring(0,$cs.IndexOf("'@"))
$fixture=$cs.Replace('MMLCore025','MMLCore025Fixture').Replace('new HttpClientHandler { AllowAutoRedirect=false }','new FixtureHandler()').Replace('TimeSpan.FromSeconds(120)','TimeSpan.FromMilliseconds(500)')
$fixture=$fixture.Replace('public static bool Valid(string path,string hash) {','public static bool Valid(string path,string hash) { using(FixtureHandler.Check())')
Add-TestType ($fixture+([IO.File]::ReadAllText((Join-Path $PSScriptRoot 'fixtures\HttpStub.cs'))))
$file=Join-Path $root 'expected'; [IO.File]::WriteAllBytes($file,[FixtureHandler]::Data)
$sha1=(Get-FileHash $file -Algorithm SHA1).Hash; $sha256=(Get-FileHash $file -Algorithm SHA256).Hash
Assert ([MMLCore025]::Valid($file,$sha1)) 'SHA1';Assert ([MMLCore025]::Valid($file,$sha256)) 'SHA256'
foreach($hash in @('bad',('x'*40),('a'*39),('a'*65))){$bad=$false;try{[MMLCore025]::Valid($file,$hash)}catch{$bad=$true};Assert $bad 'Invalid checksum rejected'}
$jobs=New-Object 'Collections.Generic.List[MMLCore025Fixture+Job]'
foreach($i in 1..24){$jobs.Add([MMLCore025Fixture+Job]::new("https://libraries.minecraft.net/file-$i",(Join-Path $root "batch/$i"),$sha1))}
# Duplicate destinations must create neither duplicate verification work nor downloads.
$jobs.Add($jobs[0]); $oldLimit=[Net.ServicePointManager]::DefaultConnectionLimit
$context=[Threading.SynchronizationContext]::Current
try{[Threading.SynchronizationContext]::SetSynchronizationContext([RejectContext]::new());[MMLCore025Fixture]::Batch($root,$jobs)}
finally{[Threading.SynchronizationContext]::SetSynchronizationContext($context)}
Assert ([FixtureHandler]::Requests -eq 24 -and [FixtureHandler]::Peak -le 8 -and [FixtureHandler]::Peak -gt 1) "Deduplicated concurrent download requests=24 peak=$([FixtureHandler]::Peak)"
Assert ([FixtureHandler]::ActiveChecks -eq 0 -and [FixtureHandler]::PeakChecks -gt 1 -and [FixtureHandler]::PeakChecks -le 4) "Parallel checksum peak=$([FixtureHandler]::PeakChecks), limit=4"
Assert ([Net.ServicePointManager]::DefaultConnectionLimit -eq $oldLimit) 'Connection limit restored'
[MMLCore025Fixture]::Batch($root,$jobs);Assert ([FixtureHandler]::Requests -eq 24) 'Warm cache creates no requests'
foreach($j in $jobs){Assert ([MMLCore025]::Valid($j.Path,$j.Hash)) 'Streamed file checksum'}
foreach($case in @('retry','redirect','partial','locked','evil','loop','timeout','bad-hash')){
 $target=Join-Path $root $case;[IO.File]::WriteAllText($target,'preserve')
 $hash=if($case -eq 'bad-hash'){'0'*40}else{$sha256}
 $job=[MMLCore025Fixture+Job]::new("https://libraries.minecraft.net/$case",$target,$hash)
 if($case -eq 'locked'){[FixtureHandler]::LockPath=$target}
 $failed=$false; try{[MMLCore025Fixture]::Batch($root,@($job),1,1)}catch{$failed=$true}
 if($case -eq 'locked'){[FixtureHandler]::Hold.Dispose();[FixtureHandler]::Hold=$null}
 if($case -in @('retry','redirect','partial')){Assert (!$failed -and [MMLCore025]::Valid($target,$hash)) "$case succeeds"}
 else{Assert ($failed -and [IO.File]::ReadAllText($target) -eq 'preserve') "$case fails without replacing destination"}
 if($case -in @('retry','partial','locked','timeout','bad-hash','evil')){Assert ([FixtureHandler]::Count("/$case") -eq 3) "$case bounded to three attempts"}
 Assert ([FixtureHandler]::Active -eq 0) "$case waits for canceled requests"
}
Assert ([FixtureHandler]::Count('/loop') -eq 18) 'Redirect cap: six responses per attempt'
Assert ([FixtureHandler]::Count('/payload') -eq 0) 'Disallowed redirect never requested'
Assert (@(Get-ChildItem $root -Recurse -Filter '*.part').Count -eq 0) 'Temporary files cleaned'
$conflict=[MMLCore025Fixture+Job]::new($jobs[0].Url,$jobs[0].Path,('b'*40));$blocked=$false
try{[MMLCore025Fixture]::Batch($root,@($jobs[0],$conflict))}catch{$blocked=$true};Assert $blocked 'Conflicting destination rejected'
foreach($url in @('http://libraries.minecraft.net/a','https://evil.example/a','https://user@libraries.minecraft.net/a','https://libraries.minecraft.net:444/a','https://github.com/evil/download')){
 $blocked=$false;try{[MMLCore025]::Url($url)}catch{$blocked=$true};Assert $blocked "URL rejection $url"
}
. (Join-Path $PSScriptRoot 'safety-cases.ps1')
if($Online){
 $releases=@(Get-Releases)
 Assert ($releases.Count -gt 0 -and @($releases | Where-Object {$_.type -ne 'release'}).Count -eq 0) 'Official manifest release filtering'
 $record=$releases | Where-Object id -eq '1.20.1' | Select-Object -First 1
 Assert ([bool]$record) 'Supported minimum release present'
 $v=[IO.File]::ReadAllText((Get-Resource $record 'online/version.json')) | ConvertFrom-Json
 Assert ($v.id -eq '1.20.1' -and $v.javaVersion.majorVersion -eq 17) 'Actual version JSON and required Java'
 $index=[IO.File]::ReadAllText((Get-Resource $v.assetIndex 'online/assets.json')) | ConvertFrom-Json
 $objects=[ordered]@{}
 foreach($entry in ($index.objects.PSObject.Properties | Select-Object -First 4)){ $objects[$entry.Name]=$entry.Value }
 $objects['duplicate']=$objects.Values | Select-Object -First 1
 Download-Assets ([pscustomobject]@{objects=[pscustomobject]$objects})
 foreach($entry in $objects.Values){
  $h=$entry.hash; Assert ([MMLCore025]::Valid((Data-Path "assets/objects/$($h.Substring(0,2))/$h"),$h)) 'Official asset SHA1'
 }
 Download-Assets ([pscustomobject]@{objects=[pscustomobject]$objects})
 Assert ($releases[0].id -ne '') 'Latest official release identified (metadata only)'
}
"COMPLETE Runtime=$($PSVersionTable.PSVersion); no Minecraft launched; production data untouched"
