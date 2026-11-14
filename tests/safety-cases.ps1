# Dot-sourced by run-tests.ps1 after loading production functions into an isolated data root.
Add-Type -AssemblyName System.IO.Compression
Assert ((Offline-UUID 'Steve') -ceq '5627dd98e6be3c21b8a8e92344183641') 'Offline UUID known vector'
foreach($pair in @(
    @('', '""'), @('hello world','"hello world"'),
    @('a"b','"a\"b"'), @('C:\space path\','"C:\space path\\"')
)) { Assert ((Quote-Argument $pair[0]) -ceq $pair[1]) 'Windows quote vector' }
$rules=@(
    @('[]',$true),
    @('[{"action":"allow","os":{"name":"linux"}}]',$false),
    @('[{"action":"allow","os":{"name":"windows","arch":"x86_64"}}]',$true),
    @('[{"action":"allow"},{"action":"disallow"}]',$false),
    @('[{"action":"disallow"},{"action":"allow"}]',$true),
    @('[{"action":"allow","features":{"is_demo_user":true}}]',$false),
    @('[{"action":"allow","features":{"is_demo_user":false}}]',$true),
    @('[{"action":"allow","os":{"versionRange":{"min":"999.0"}}}]',$false),
    @('[{"action":"allow","os":{"versionRange":{"max":"0.1"}}}]',$false),
    @('[{"action":"allow","os":{"version":"^does-not-match$"}}]',$false)
)
foreach($pair in $rules){ Assert ((Test-Rules (ConvertFrom-Json $pair[0])) -eq $pair[1]) 'Rule ordering, OS and features' }
$assignments=$ast.FindAll({param($n) $n -is [Management.Automation.Language.AssignmentStatementAst]},$true)
# $null assignments intentionally discard command output and are valid PowerShell.
$protected='HOME|Host|PID|Error|Matches|Input|PROFILE|PSVersionTable|PSHOME|PSScriptRoot|PSCommandPath|ExecutionContext|MyInvocation|PSCulture|PSUICulture|ShellId|IsWindows|IsLinux|IsMacOS|PSEdition|true|false'
$conflicts=@($assignments | Where-Object { $_.Left.Extent.Text -match ('^\$(?:(?:script|global|local|private):)?('+$protected+')\b') })
$declarations=$ast.FindAll({param($n) $n -is [Management.Automation.Language.ParameterAst] -or $n -is [Management.Automation.Language.ForEachStatementAst]},$true)
foreach($n in $declarations){
    $variable=if($n -is [Management.Automation.Language.ParameterAst]){$n.Name}else{$n.Variable}
    if($variable.VariablePath.UserPath -match ('^(?:\w+:)?('+$protected+')$')){ $conflicts+=,$n }
}
Assert (!$conflicts.Count) 'No protected automatic-variable assignment or declaration'
function New-TestZip([string]$File,[hashtable]$Entries){
    $archive=[IO.Compression.ZipFile]::Open($File,[IO.Compression.ZipArchiveMode]::Create)
    try { foreach($key in $Entries.Keys){
        $writer=New-Object IO.StreamWriter ($archive.CreateEntry($key).Open())
        try { $writer.Write($Entries[$key]) } finally { $writer.Dispose() }
    } } finally { $archive.Dispose() }
}
$zip=Join-Path $root 'native.zip'; $native=Join-Path $root 'native-output'
New-TestZip $zip @{'nested/test.dll'='native';'META-INF/excluded'='skip'}
Expand-Safe $zip $native @('meta-inf/')
Assert ([IO.File]::ReadAllText((Join-Path $native 'nested/test.dll')) -eq 'native') 'Nested native extraction'
Assert (!(Test-Path -LiteralPath (Join-Path $native 'META-INF/excluded'))) 'Native exclude prefix'
foreach($entry in @('../escape','a/../../escape','/escape','C:\escape','a:stream')){
    $zip=Join-Path $root ([guid]::NewGuid().ToString('N')+'.zip')
    New-TestZip $zip @{$entry='blocked'}
    $blocked=$false; try { Expand-Safe $zip (Join-Path $root 'unsafe-output') } catch { $blocked=$true }
    Assert $blocked 'Unsafe ZIP entry rejected'
}
$target=Join-Path $root 'junction-target'; $junction=Join-Path $root 'junction'
$null=[IO.Directory]::CreateDirectory($target)
$null=New-Item -ItemType Junction -Path $junction -Target $target
$blocked=$false; try { $null=[MMLCore025]::PathIn($root,'junction/file') } catch { $blocked=$true }
Assert $blocked 'Real junction rejected'
$install=@{
    Version=[pscustomobject]@{
        id='fixture'; assetIndex=@{id='fixture'}; mainClass='net.minecraft.client.main.Main'
        arguments=@{jvm=@('-Djava.library.path=${natives_directory}','-cp','${classpath}','-Dlauncher=${launcher_version}');game=@('--username','${auth_player_name}','--uuid','${auth_uuid}','--accessToken','${auth_access_token}','--gameDir','${game_directory}')}
    }
    Classpath='first.jar;second.jar;client.jar'; Natives=$native; LogFile=$null
}
$arguments=@(Build-Arguments $install 'Steve')
Assert ($arguments[0] -eq '-Xms512M' -and $arguments[1] -eq '-Xmx2G') 'JVM memory arguments'
Assert ($arguments -contains $install.Classpath -and $arguments -contains '-Dlauncher=0.2.5') 'Classpath order and launcher version preserved'
Assert ($arguments -contains 'MML_OFFLINE' -and $arguments -contains (Offline-UUID 'Steve')) 'Offline game arguments'
Assert ($arguments -contains (Data-Path 'instances/fixture')) 'Instance path stays in test data root'
$install.Version.arguments.game=@('${unknown_fixture}')
$blocked=$false; try { $null=@(Build-Arguments $install 'Steve') } catch { $blocked=$true }
Assert $blocked 'Unknown placeholder rejected'
# Model registry discovery with the real Find-Java function. No registry or environment writes.
& {
    $javaHome=Join-Path $root 'registry-java'; $expected=Join-Path $javaHome 'bin/java.exe'; $savedHome=$HOME
    function Test-Path { [CmdletBinding()]param([string]$Path,[string]$LiteralPath)
        return ($Path -eq 'HKLM:\SOFTWARE\JavaSoft' -or $Path -eq $javaHome -or $LiteralPath -eq $expected)
    }
    function Get-ChildItem { [CmdletBinding()]param([string]$Path,[switch]$Recurse,[switch]$Directory,[string]$Filter)
        if($Path -eq 'HKLM:\SOFTWARE\JavaSoft'){ [pscustomobject]@{PSPath='HKLM:\SOFTWARE\JavaSoft\fixture'} }
    }
    function Get-ItemProperty { [CmdletBinding()]param([string]$Path) [pscustomobject]@{JavaHome=$javaHome} }
    function Get-Command { [CmdletBinding()]param([string]$Name,[switch]$All) }
    function Probe-Java([string]$path,[int]$major){ return ($path -eq $expected -and $major -eq 17) }
    Assert ((Find-Java 17) -eq $expected) 'Java registry branch with JavaHome property (mocked registry)'
    Assert ($HOME -ceq $savedHome) 'HOME unchanged across registry detection'
}
# Missing Java follows metadata -> SHA256 resource -> extraction -> executable probe, all stubbed.
& {
    $script:testJavaInstalled=$false; $script:testJavaSteps=New-Object Collections.Generic.List[string]
    $expected=Join-Path (Data-Path 'java/17') 'bin/java.exe'
    function Test-Path { [CmdletBinding()]param([string]$Path,[string]$LiteralPath)
        return ($script:testJavaInstalled -and ($Path -eq (Data-Path 'java/17') -or $LiteralPath -eq $expected))
    }
    function Get-ChildItem { [CmdletBinding()]param([string]$Path,[switch]$Recurse,[switch]$Directory,[string]$Filter) }
    function Get-Command { [CmdletBinding()]param([string]$Name,[switch]$All) }
    function Probe-Java([string]$path,[int]$major){ return ($script:testJavaInstalled -and $path -eq $expected -and $major -eq 17) }
    function Get-Json([string]$url){ $script:testJavaSteps.Add('metadata'); [pscustomobject]@{binary=@{package=@{name='fixture.zip';link='https://api.adoptium.net/fixture';checksum=('a'*64)}}} }
    function Get-Resource($entry,[string]$relative,[switch]$Runtime){
        if(!$Runtime -or $entry.checksum.Length -ne 64){throw 'Runtime resource not requested'}
        $script:testJavaSteps.Add('SHA256'); return (Data-Path $relative)
    }
    function Expand-Safe([string]$zip,[string]$destination){ $script:testJavaSteps.Add('extract'); $script:testJavaInstalled=$true }
    Assert ((Find-Java 17 -Install) -eq $expected) 'Missing Java install orchestration (stubbed)'
    Assert (($script:testJavaSteps -join ',') -eq 'metadata,SHA256,extract') 'Java metadata, SHA256 and extraction order'
}
# C# 5 compile against .NET Framework in the actual Windows PowerShell process.
if($PSVersionTable.PSEdition -eq 'Desktop'){
    $provider=New-Object Microsoft.CSharp.CSharpCodeProvider
    $parameters=New-Object CodeDom.Compiler.CompilerParameters
    $parameters.GenerateInMemory=$true; $parameters.CompilerOptions='/langversion:5'
    $parameters.ReferencedAssemblies.AddRange([string[]]@('System.dll','System.Core.dll','System.Net.Http.dll'))
    try {
        $compiled=$provider.CompileAssemblyFromSource($parameters,[string[]]@($cs))
        Assert (!$compiled.Errors.HasErrors) 'Actual .NET Framework C# 5 compilation'
        if($compiled.Errors.HasErrors){throw ($compiled.Errors | Out-String)}
    } finally { $provider.Dispose() }
}
