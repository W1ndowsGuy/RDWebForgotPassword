param([string]$InstallPath = "$env:ProgramFiles\RDWeb Recovery Helper")
$ErrorActionPreference='Stop'
$ServiceName='RDWebRecoveryHelper'
$Source=Join-Path $PSScriptRoot 'RDWebRecoveryHelper.cs'
$Compiler="$env:WINDIR\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if(-not(Test-Path $Compiler)){$Compiler="$env:WINDIR\Microsoft.NET\Framework\v4.0.30319\csc.exe"}
if(-not(Test-Path $Compiler)){throw 'The .NET Framework C# compiler was not found.'}
New-Item -ItemType Directory -Path $InstallPath -Force|Out-Null
$Exe=Join-Path $InstallPath 'RDWebRecoveryHelper.exe'
& $Compiler /nologo /target:exe /optimize+ /out:$Exe /reference:System.dll /reference:System.Core.dll /reference:System.DirectoryServices.dll /reference:System.ServiceProcess.dll $Source
if($LASTEXITCODE-ne 0){throw "Compilation failed with exit code $LASTEXITCODE."}
$existing=Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if($existing){if($existing.Status-ne'Stopped'){Stop-Service $ServiceName -Force}; & sc.exe config $ServiceName binPath= ('"'+$Exe+'"') start= auto obj= LocalSystem|Out-Null}
else{& sc.exe create $ServiceName binPath= ('"'+$Exe+'"') start= auto obj= LocalSystem DisplayName= "RDWeb Recovery Helper"|Out-Null;if($LASTEXITCODE-ne 0){throw 'Failed to create service.'}}
& sc.exe description $ServiceName "Local privileged helper for narrowly scoped RDWeb recovery operations."|Out-Null
Start-Service $ServiceName
Get-CimInstance Win32_Service -Filter "Name='$ServiceName'"|Select Name,State,StartMode,StartName,PathName