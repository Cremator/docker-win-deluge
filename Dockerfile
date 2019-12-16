FROM mcr.microsoft.com/dotnet/framework/runtime
ARG TARGETPLATFORM
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV PYTHON_VERSION 3.6.8
ENV PYTHON_RELEASE 3.6.8

RUN $url = ('https://www.python.org/ftp/python/{0}/python-{1}-amd64.exe' -f $env:PYTHON_RELEASE, $env:PYTHON_VERSION); \
	Write-Host ('Downloading {0} ...' -f $url); \
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
	Invoke-WebRequest -Uri $url -OutFile 'python.exe'; \
	\
	Write-Host 'Installing ...'; \
# https://docs.python.org/3.5/using/windows.html#installing-without-ui
	Start-Process python.exe -Wait \
		-ArgumentList @( \
			'/quiet', \
			'InstallAllUsers=1', \
			'TargetDir=C:\Python', \
			'PrependPath=1', \
			'Shortcuts=0', \
			'Include_doc=0', \
			'Include_pip=0', \
			'Include_test=0' \
		); \
	\
# the installer updated PATH, so we should refresh our local value
	$env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
	\
	Write-Host 'Verifying install ...'; \
	Write-Host '  python --version'; python --version; \
	\
	Write-Host 'Removing ...'; \
	Remove-Item python.exe -Force; \
	\
	Write-Host 'Complete.'

# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 19.3.1
# https://github.com/pypa/get-pip
ENV PYTHON_GET_PIP_URL https://github.com/pypa/get-pip/raw/ffe826207a010164265d9cc807978e3604d18ca0/get-pip.py
ENV PYTHON_GET_PIP_SHA256 b86f36cc4345ae87bfd4f10ef6b2dbfa7a872fbff70608a1e43944d283fd0eee

RUN Write-Host ('Downloading get-pip.py ({0}) ...' -f $env:PYTHON_GET_PIP_URL); \
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
	Invoke-WebRequest -Uri $env:PYTHON_GET_PIP_URL -OutFile 'get-pip.py'; \
	Write-Host ('Verifying sha256 ({0}) ...' -f $env:PYTHON_GET_PIP_SHA256); \
	if ((Get-FileHash 'get-pip.py' -Algorithm sha256).Hash -ne $env:PYTHON_GET_PIP_SHA256) { \
		Write-Host 'FAILED!'; \
		exit 1; \
	}; \
	\
	Write-Host ('Installing pip=={0} ...' -f $env:PYTHON_PIP_VERSION); \
	python get-pip.py \
		--disable-pip-version-check \
		--no-cache-dir \
		('pip=={0}' -f $env:PYTHON_PIP_VERSION) \
	; \
	Remove-Item get-pip.py -Force; \
	\
	Write-Host 'Verifying pip install ...'; \
	pip --version; \
	\
	Write-Host 'Complete.'
ADD release.zip C:/TEMP/
RUN Write-Host ('Installing deluge'); \
	Expand-Archive c:\TEMP\release.zip -DestinationPath C:\gvsbuild;
ADD Twisted-19.2.1-cp36-cp36m-win_amd64.whl C:/gvsbuild/
ADD setproctitle-1.1.10-cp36-cp36m-win_amd64.whl C:/gvsbuild/
RUN Write-Host ('Updating PATH ...'); \
	setx path '%path%;C:\gvsbuild\release\bin'; \
	$env:PATH = [Environment]::GetEnvironmentVariable('PATH', [EnvironmentVariableTarget]::Machine); \
	Invoke-WebRequest -Uri https://slproweb.com/download/Win64OpenSSL_Light-1_1_1d.msi -OutFile 'C:\TEMP\Win64OpenSSL_Light-1_1_1d.msi'; \
	Start-Process msiexec.exe -Wait -ArgumentList '/I C:\TEMP\Win64OpenSSL_Light-1_1_1d.msi /quiet'; \
	Invoke-WebRequest -Uri https://aka.ms/vs/16/release/vc_redist.x64.exe -OutFile 'C:\TEMP\vc_redist.x64.exe'; \
	Start-Process C:\TEMP\vc_redist.x64.exe -ArgumentList '/install /passive /norestart' -Wait; \
	Remove-Item "C:/TEMP" -Force -Recurse; \
	pip install C:\gvsbuild\release\python\pycairo-1.18.0-cp36-cp36m-win_amd64.whl; \
	pip install C:\gvsbuild\release\python\PyGObject-3.32.0-cp36-cp36m-win_amd64.whl; \
	pip install C:\gvsbuild\Twisted-19.2.1-cp36-cp36m-win_amd64.whl; \
	pip install C:\gvsbuild\setproctitle-1.1.10-cp36-cp36m-win_amd64.whl; \
	pip install deluge deluge-libtorrent; \
	\
	Write-Host 'Verifying deluge install ...'; \
	python -c 'import libtorrent; print(libtorrent.__version__)'; \
	\
	Write-Host 'Complete.'
	\
ADD docker-entrypoint.ps1 C:/
EXPOSE 8112 58846 58946 58946/udp	
VOLUME [ "C:/config", "C:/downloads" ]
ENTRYPOINT powershell -command c:\docker-entrypoint.ps1
	