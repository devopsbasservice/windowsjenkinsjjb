# escape=`
FROM microsoft/windowsservercore:10.0.14393.206
MAINTAINER alexellis2@gmail.com

# docker push alexellisio`msbuild:12.0
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]
# Java
ENV JAVA_VERSION 1.8.0.111-1
ENV JAVA_ZIP_VERSION 1.8.0-openjdk-1.8.0.111-1.b15
ENV JAVA_SHA256 4e3679a3777e8c25f9dedcda6c28369e21eeaadd4ff2709dc1eed4d0a7eeb653

ENV JAVA_HOME C:\\java-${JAVA_ZIP_VERSION}.ojdkbuild.windows.x86_64

RUN (New-Object System.Net.WebClient).DownloadFile(('https://github.com/ojdkbuild/ojdkbuild/releases/download/{0}/java-{1}.ojdkbuild.windows.x86_64.zip' -f $env:JAVA_VERSION, $env:JAVA_ZIP_VERSION), 'openjdk.zip') ; `
    if ((Get-FileHash openjdk.zip -Algorithm sha256).Hash -ne $env:JAVA_SHA256) {exit 1} ; `
    Expand-Archive openjdk.zip -DestinationPath C:\ ; `
    $env:PATH = '{0}\bin;{1}' -f $env:JAVA_HOME, $env:PATH ; `
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine) ; `
    Remove-Item -Path openjdk.zip

# Note: Get MSBuild 12.
RUN Invoke-WebRequest -UseBasicParsing -Uri "https://download.microsoft.com/download/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/BuildTools_Full.exe" -OutFile "$env:TEMP\BuildTools_Full.exe"; `
    Start-Process -Wait -PassThru -FilePath "$env:TEMP\BuildTools_Full.exe" -ArgumentList '/Silent /Full'; `
    Remove-Item -Path "$env:TEMP\BuildTools_Full.exe" -Force
# Todo: delete the BuildTools_Full.exe file in this layer
RUN DIR
# Note: Add .NET + ASP.NET
RUN Install-WindowsFeature NET-Framework-45-ASPNET ; `
    Install-WindowsFeature Web-Asp-Net45

# Note: Add NuGet
RUN Invoke-WebRequest "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile "C:\windows\nuget.exe" -UseBasicParsing
WORKDIR "C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0"

# Note: Install Web Targets
RUN &  "C:\windows\nuget.exe" Install MSBuild.Microsoft.VisualStudio.Web.targets -Version 14.0.0.3
RUN mv 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath\*' 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0'

# Note: Add Msbuild ot path
RUN setx PATH '%PATH%;C:\\Program Files (x86)\\MSBuild\\14.0\\Bin\\'

ENV JRE_HOME C:\\java-1.8.0-openjdk-1.8.0.111-1.b15.ojdkbuild.windows.x86_64\\jre
ENV CATALINA_HOME C:\\Jenkins\\apache
ENV CATALINA_BASE C:\\Jenkins\\apache
ENV CATALINA_TMPDIR C:\\Jenkins\\apache\\temp
ENV CLASSPATH C:\\Jenkins\\apache\\bootstrap.jar
ENV GIT_VERSION 2.11.0
ENV GIT_TAG v${GIT_VERSION}.windows.1
ENV GIT_DOWNLOAD_URL https://github.com/git-for-windows/git/releases/download/${GIT_TAG}/Git-${GIT_VERSION}-64-bit.exe
ENV GIT_DOWNLOAD_SHA256 fd1937ea8468461d35d9cabfcdd2daa3a74509dc9213c43c2b9615e8f0b85086
# steps inspired by "chcolateyInstall.ps1" from "git.install" (https://chocolatey.org/packages/git.install)
RUN Write-Host ('Downloading {0} ...' -f $env:GIT_DOWNLOAD_URL); `
	Invoke-WebRequest -Uri $env:GIT_DOWNLOAD_URL -OutFile 'git.exe'; `
	`
	Write-Host ('Verifying sha256 ({0}) ...' -f $env:GIT_DOWNLOAD_SHA256); `
	if ((Get-FileHash git.exe -Algorithm sha256).Hash -ne $env:GIT_DOWNLOAD_SHA256) { `
		Write-Host 'FAILED!'; `
		exit 1; `
	}; `
	`
	Write-Host 'Installing ...'; `
	Start-Process `
		-Wait `
		-FilePath ./git.exe `
# http://www.jrsoftware.org/ishelp/topic_setupcmdline.htm
		-ArgumentList @( `
			'/VERYSILENT', `
			'/NORESTART', `
			'/NOCANCEL', `
			'/SP-', `
			'/SUPPRESSMSGBOXES', `
			`
# https://github.com/git-for-windows/build-extra/blob/353f965e0e2af3e8c993930796975f9ce512c028/installer/install.iss#L87-L96
			'/COMPONENTS=assoc_sh', `
			`
# set "/DIR" so we can set "PATH" afterwards
# see https://disqus.com/home/discussion/chocolatey/chocolatey_gallery_git_install_1710/#comment-2834659433 for why we don't use "/LOADINF=..." to let the installer set PATH
			'/DIR=C:\git' `
		); `
	`
	Write-Host 'Updating PATH ...'; `
	$env:PATH = 'C:\git\bin;C:\git\mingw64\bin;C:\git\usr\bin;' + $env:PATH; `
	[Environment]::SetEnvironmentVariable('PATH', $env:PATH, [EnvironmentVariableTarget]::Machine); `
	`
	Write-Host 'Verifying install ...'; `
	Write-Host '  git --version'; git --version; `
	Write-Host '  bash --version'; bash --version; `
	Write-Host '  curl --version'; curl.exe --version; `
	`
	Write-Host 'Removing installer ...'; `
	Remove-Item git.exe -Force; `
	`
    Write-Host 'Complete.';
#PYTHON INSTALLATION 
RUN setx PATH '%PATH%;C:\\Python27\\;C:\\Python27\\scripts'

ENV PYTHONIOENCODING=UTF-8

RUN $ErrorActionPreference = 'Stop'; `
    wget https://www.python.org/ftp/python/2.7.12/python-2.7.12.msi -OutFile python-2.7.12.msi ; `
    Start-Process python-2.7.12.msi -ArgumentList '/quiet InstallAllUsers=1 PrependPath=1' -Wait ; `
    Remove-Item python-2.7.12.msi -Force ; `
    python -m pip install --upgrade pip ; `
# Define our command to be run when launching the container
CMD ["C:\\Python27\\python.exe"]
WORKDIR "c:/Python27"
RUN DIR
RUN git clone https://git.openstack.org/openstack-infra/jenkins-job-builder
WORKDIR "c:/Python27/jenkins-job-builder"
RUN python setup.py install
RUN pip install -r requirements.txt
RUN powershell -Command mkdir c:\Python27\jenkins-job-builder\jenkins_jobs\jobs
COPY job.yaml C:/Python27/jenkins-job-builder/jenkins_jobs/jobs/jobs.yaml
COPY jenkins_job.ini C:/Python27/jenkins-job-builder/jenkins_jobs/jenkins_job.ini

ENV HOME /jenkins
RUN mkdir \jenkins

COPY apache.zip c:/jenkins/apache.zip
RUN powershell -Command Expand-Archive c:/jenkins/apache.zip -DestinationPath c:/jenkins
COPY jenkins.war c:/jenkins/apache/webapps/jenkins.war
COPY entry.ps1 c:/jenkins/entry.ps1
RUN powershell -Command mkdir C:/Users/ContainerAdministrator/.jenkins/init.groovy.d
COPY plugins.txt C:/Users/ContainerAdministrator/.jenkins/init.groovy.d/plugins.txt
COPY simple_user.groovy C:/Users/ContainerAdministrator/.jenkins/init.groovy.d/simple_user.groovy
COPY executors.groovy C:/Users/ContainerAdministrator/.jenkins/init.groovy.d/executors.groovy
COPY plugin.groovy C:/Users/ContainerAdministrator/.jenkins/init.groovy.d/plugin.groovy
EXPOSE 8080
EXPOSE 50000

ENTRYPOINT ["powershell", "c:/jenkins/entry.ps1"]