param([Parameter(Mandatory=$true)][string]$Source)
$ErrorActionPreference='Stop'
$text=[IO.File]::ReadAllText((Resolve-Path -LiteralPath $Source).Path)
$tokens=$null; $parseErrors=$null
$ast=[Management.Automation.Language.Parser]::ParseInput($text,[ref]$tokens,[ref]$parseErrors)
if($parseErrors.Count){throw ($parseErrors | Out-String)}
$functions=@($ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]},$true))
if(!$functions.Count){throw 'Production functions not found'}
# Load initialization and function definitions only; never execute the game entry point.
$start=$text.IndexOf('{')+1
$init=[scriptblock]::Create($text.Substring($start,$functions[0].Extent.StartOffset-$start))
. $init
foreach($f in $functions){ . ([scriptblock]::Create($f.Extent.Text)) }
$cs=$text.Substring($text.IndexOf('using System;')); $cs=$cs.Substring(0,$cs.IndexOf("'@"))
function Add-TestType([string]$Definition){
    $options=@{}
    if($PSVersionTable.PSEdition -eq 'Desktop'){ $options.ReferencedAssemblies='System.Net.Http.dll' }
    else { $options.CompilerOptions=@('/langversion:5','/nowarn:SYSLIB0014') }
    Add-Type @options -TypeDefinition $Definition
}
