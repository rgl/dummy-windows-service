Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
trap {
    Write-Output "ERROR: $_"
    Write-Output (($_.ScriptStackTrace -split '\r?\n') -replace '^(.*)$','ERROR: $1')
    Write-Output (($_.Exception.ToString() -split '\r?\n') -replace '^(.*)$','ERROR EXCEPTION: $1')
    Exit 1
}

$serviceName = 'dummy'

Write-Host "Creating the $serviceName service..."
# NB -action install is the equivalent of (minus installing the event log source):
# $result = sc.exe create $serviceName binPath= "$PWD/dummy-windows-service.exe"
# if ($result -ne '[SC] CreateService SUCCESS') {
#     throw "sc.exe sidtype failed with $result"
# }
./dummy-windows-service.exe -action install -name $serviceName
if ($LASTEXITCODE) {
    throw "dummy-windows-service.exe install failed with exit code $LASTEXITCODE"
}

Write-Host "Configuring the $serviceName service to use a Windows managed service account..."
$result = sc.exe sidtype $serviceName unrestricted
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe sidtype failed with $result"
}
$result = sc.exe config $serviceName obj= "NT SERVICE\$serviceName"
if ($result -ne '[SC] ChangeServiceConfig SUCCESS') {
    throw "sc.exe config failed with $result"
}
Write-Host "$serviceName service has the $(sc.exe showsid $serviceName) SID."

Write-Host "Configuring the $serviceName service to restart on any failure..."
$result = sc.exe failure $serviceName reset= 0 actions= restart/1000
if ($result -ne '[SC] ChangeServiceConfig2 SUCCESS') {
    throw "sc.exe failure failed with $result"
}

Write-Host "Starting the $serviceName service..."
$result = sc.exe start $serviceName
if ($result -like '* STATE *') {
    while ($true) {
        $result = sc.exe query $serviceName
        if ($result.Trim() -eq 'STATE              : 4  RUNNING') {
            break
        }
        Start-Sleep -Seconds 1
    }
} elseif ($result -ne '[SC] StartService SUCCESS') {
    throw "sc.exe config failed with $result"
}

Write-Host "Getting the $serviceName service logs..."
Start-Sleep -Seconds 2
Get-EventLog Application -Source $serviceName `
    | Format-List

Write-Host "Stopping the $serviceName service..."
$result = sc.exe stop $serviceName
if ($result -like '* STATE *') {
    while ($true) {
        $result = sc.exe query $serviceName
        if ($result.Trim() -eq 'STATE              : 1  STOPPED') {
            break
        }
        Start-Sleep -Seconds 1
    }
} elseif ($result -ne '[SC] ControlService SUCCESS') {
    throw "sc.exe config failed with $result"
}

Write-Host "Destroying the $serviceName service..."
# NB -action uninstall is the equivalent of (minus uninstalling the event log source):
# $result = sc.exe delete $serviceName
# if ($result -ne '[SC] DeleteService SUCCESS') {
#     throw "sc.exe config failed with $result"
# }
./dummy-windows-service.exe -action uninstall -name $serviceName
if ($LASTEXITCODE) {
    throw "dummy-windows-service.exe uninstall failed with exit code $LASTEXITCODE"
}
