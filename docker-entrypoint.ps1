$deluged = Start-Process deluged -ArgumentList '-c c:\config -L=info -l c:\config\deluged.log' -PassThru
Start-Sleep -s 10
if (!(Test-Path 'c:\config\plugins\Label-0.3.egg')) {
	Stop-Process -InputObject $deluged
	Wait-Process -InputObject $deluged
	Copy-Item 'C:\Python\Lib\site-packages\deluge\plugins\Label-0.3-py3.7.egg' -Destination 'C:\config\plugins\Label-0.3.egg'
	$deluged = Start-Process deluged -ArgumentList '-c c:\config -L=info -l c:\config\deluged.log' -PassThru
	}
$delugeweb = Start-Process deluge-web -ArgumentList '-c c:\config -L=warning -l c:\config\deluge-web.log' -PassThru
Get-Content C:\config\deluged.log -Wait