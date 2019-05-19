# Note:
# 1. Codefile: ServiceRequest.ps1
# 2. Update requisite $user and $passwd.
# 3. Logfile created in the current directory as "External_ServiceRequest_yyyy-MM-dd" updated after every run.
# 4. Ipfile: All_server_services.txt 


$CurrentDir = $(get-location).Path
#write-host $CurrentDir
$FileName = $CurrentDir + "\All_server_services.txt"

#write-host $FileName

$logfilename = "\External_ServiceRequest_" + (Get-Date -Format "yyyy-MM-dd") + ".log"
$logFilepath = $CurrentDir + $logfilename


Function LogWrite
{
   Param ([string]$logstring)

   Add-content $logFilepath -value $logstring
}
if (Test-Path $logFilepath) 
{
  Remove-Item $logFilepath
}


$IPaddress = @(Get-Content -Path $FileName )
#$IPaddress.Length
$user = "XXXXXX"
$passwd = "XXXXXXXXXXXXX"
For ($i=0; $i -lt $IPaddress.Length; $i++)
{
#$IPaddress.Length
	$IPs = "\\"+$IPaddress[$i]
	
	if($IPaddress[$i].Length -ne 0)
	{
		Write-host ("URL :	",$IPaddress[$i])
		logWrite ("URL :	",$IPaddress[$i])
		
		#Net use $IPs $passwd /user:$user
		Net use $IPs 9878qQ!! /user:605819
		$CurrentDir = $(get-location).Path
		
		#$serviceNames = @("TapiSrv", "aaaa", "UALSVC", "THREADORDER")
		$serviceNames = @("AMWeb-webseal-uat-external", "AMWeb-webseal-uat-external2", "AMWeb-webseal-uat-external3","AMWeb-webseal-slc-internal",
							"AMWeb-webseal-uat-internal", "AMWeb-webseal-uat-captcha", "AMWeb-webseal-uat-internal2","AMWeb-webseal-uat-internal3","AMWeb-webseal-uat-internal4","AMWeb-webseal-uat-internal5")
		foreach ($serviceName in $serviceNames) 
			{
		
		############################################ To stop the Service ###############################################
			Start-Sleep -s 3
			$a = sc.exe $IPs stop $serviceName > temp.txt
			#Start-Sleep -s 1

			$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "does not exist"					# The specified service does not exist as an installed service.
			
			
			if($a.length -eq 0)
				{
				sc.exe $IPs query $serviceName > temp.txt
				$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "STOPPED"
				if($a.length -ne 0)																														# match if service is running
					{
					write-host ($serviceName, " : Stopped")
					LogWrite ($serviceName, " : Stopped")
					}
				
				Else
					{
					$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "STOP_PENDING"
						
					if($a.length -ne 0)																														# match if service is Start-pending(-ne to 0 means more than 0, means string match)
						{
						$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "STOPPED"
						while($a.length -eq 0)																												# Continue While loop Until Service start Running
							{
							write-host ("Stop Pending")					
							LogWrite ("Stop Pending")
				
							Start-Sleep -s 2
							sc.exe $IPs query $serviceName > temp.txt
							Start-Sleep -s 1
							$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "STOPPED"
							}
						write-host ($serviceName, " : Stopped")
						LogWrite ($serviceName, " : Stopped")
						}
					else
						{
						$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "does not exist"
						if($a.length -eq 0)
							{
							write-host ($serviceName, " : Error1")
							LogWrite ($serviceName, " : Error")
							sc.exe $IPs query $serviceName
							}
						}
					}	
				
		############################################ To start the Service ###############################################
				Start-Sleep -s 3
				sc.exe $IPs start $serviceName > temp.txt
				Start-Sleep -s 1
				sc.exe $IPs query $serviceName > temp.txt
				
				Start-Sleep -s 2
				sc.exe $IPs query $serviceName > temp.txt
				Start-Sleep -s 1
				$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "RUNNING"
				if($a.length -ne 0)																														# match if service is running
					{
					write-host ($serviceName, " : Started")
					LogWrite ($serviceName, " : Started")
					}
				
				Else
					{
					
					$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "START_PEND"
					$a
					
					$cnt = 0
					if($a.length -ne 0)																														# match if service is Start-pending(-ne to 0 means more than 0, means string match)
						{
						$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "RUNNING"
						while($a.length -eq 0)																												# Continue While loop Until Service start Running
							{
							write-host ("Still Not Startt")					
							LogWrite ("Still Not Startt")
				
							Start-Sleep -s 10
							sc.exe $IPs query $serviceName
							sc.exe $IPs query $serviceName > temp.txt
							Start-Sleep -s 1
							
							$b = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "STOPPED"
							if(($b.length -ne 0) -and ($cnt -lt 1))																												# match if service is Start-pending(-ne to 0 means more than 0, means string match)
								{
								$cnt+=1
								write-host "again stopped"
								#sc.exe $IPs query $serviceName
								sc.exe $IPs start $serviceName > temp.txt
								Start-Sleep -s 10
								sc.exe $IPs query $serviceName > temp.txt
								sc.exe $IPs query $serviceName 
							    $b = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "STOPPED"
								}
							if(($b.length -ne 0) -and ($cnt -eq 1))	
							{
							write-host "Service Create problem to start right now" 
							LogWrite "Service Create problem to start right now" 
							break
							}
							
							$a = ChildItem -Path $CurrentDir -Include "temp.txt" -Recurse | Select-String -Pattern "RUNNING"
							}
						
							if($a.length -ne 0)																														# match if service is Start-pending(-ne to 0 means more than 0, means string match)
							{
							write-host ($serviceName, " : Started")
							LogWrite ($serviceName, " : Started")
							}
						}
					else
						{
						write-host ($serviceName, " : Error")
						LogWrite ($serviceName, " : Error")
						sc.exe $IPs query $serviceName
						}
					}
					
					
				}
			}
			
		}
		LogWrite "##################################################################"
	}			
				
