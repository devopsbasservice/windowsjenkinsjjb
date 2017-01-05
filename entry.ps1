cmd.exe /c 'C:\jenkins\apache\bin\startup.bat'
Start-Sleep -s 60
echo "stop"
cmd.exe /c 'C:\jenkins\apache\bin\shutdown.bat'
kill -processname java.exe
echo "stopped"
Remove-Item C:/Users/ContainerAdministrator/.jenkins/init.groovy.d/plugin.groovy
Start-Sleep -s 20
echo "restart"
cmd.exe /c 'C:\jenkins\apache\bin\startup.bat'
#replace IP in jenkins_jobs.ini
$ipaddress=([System.Net.DNS]::GetHostAddresses($env:COMPUTERNAME)|Where-Object {$_.AddressFamily -eq "InterNetwork"}   |  select-object IPAddressToString)[0].IPAddressToString
Write-Host $ipaddress
$path = "C:/Python27/jenkins-job-builder/jenkins_jobs/jenkins_job.ini"
(Get-Content $path).Replace("<IP>",$ipaddress) | Set-Content $path
Start-Sleep -s 20
#Update Jobs
cmd.exe /c 'jenkins-jobs --conf C:/Python27/jenkins-job-builder/jenkins_jobs/jenkins_job.ini update C:/Python27/jenkins-job-builder/jenkins_jobs/jobs/jobs.yaml'
echo "Update Done"
$path = "C:/Users/ContainerAdministrator/.jenkins/jobs/*/builds/1/log"
while (!(Test-Path "C:/Users/ContainerAdministrator/.jenkins/jobs/*/builds/1/log")) { Start-Sleep 10 }
Do{
$content = get-content $path | where {$_ -like "*Finished*"}
Sleep -milliseconds 1000
echo "wait"
}until($content)

echo "complete"