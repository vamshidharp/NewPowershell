#Variable declaration
$vCenterIPorFQDN="" #put your vcenter FQDN
$vCenterUsername="Domain\username" #Vcenter user name, which have the access vCenter
$PasswordFile = "PasswordFilePath"
$KeyFile = "KeyFilePath"
$key = Get-Content $KeyFile
$VIcred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $vCenterUsername, (Get-Content $PasswordFile | ConvertTo-SecureString -Key $key)
$OutputFile="OutputFilePath" #Where you want to place generated report

$reportdate= "This report is generated"+" " +"on" + " " + (get-date)



Write-Host "Connecting to vCenter" -foregroundcolor "magenta"
Connect-VIServer -Server $vCenterIPorFQDN -Credential $VIcred #Connecting to vcenter	

#Generating VM Alarm Report
$alarmreport=Get-VM| Where {$_.ExtensionData.TriggeredAlarmState -ne $null -and $_.ExtensionData.TriggeredAlarmState.Time -ge $Y} | Select Name, @{N="AlarmName";E={(Get-View $_.ExtensionData.TriggeredAlarmState.Alarm).Info.Name}},
@{N="TimeTriggered"; E={$_.ExtensionData.TriggeredAlarmState.
Time}}, @{N="AlarmOverallStatus"; E={$_.ExtensionData.TriggeredAlarmState. OverallStatus}},@{N="Acknowledged"; E={$_.ExtensionData.TriggeredAlarmState.Acknowledged}},@{N="Acknowledgedtime"; E={$_.ExtensionData.TriggeredAlarmState.AcknowledgedTime}} | Format-Table -Wrap -Property Name,AlarmName,TimeTriggered,AlarmOverallStatus,Acknowledged

#Generating Host Alarm (Get-VMHOST) Report
$alarmreport1=Get-VMHOST| Where {$_.ExtensionData.TriggeredAlarmState -ne $null -and $_.ExtensionData.TriggeredAlarmState.Time -ge $Y} | Select Name, @{N="AlarmName";E={(Get-View $_.ExtensionData.TriggeredAlarmState.Alarm).Info.Name}},
@{N="TimeTriggered"; E={$_.ExtensionData.TriggeredAlarmState.
Time}}, @{N="AlarmOverallStatus"; E={$_.ExtensionData.TriggeredAlarmState. OverallStatus}},@{N="Acknowledged"; E={$_.ExtensionData.TriggeredAlarmState.Acknowledged}},@{N="Acknowledgedtime"; E={$_.ExtensionData.TriggeredAlarmState.AcknowledgedTime}} | Format-Table -Wrap -Property Name,AlarmName,TimeTriggered,AlarmOverallStatus,Acknowledged


#Generating Datastore Alarm (Get-Datastore) Report
$alarmreport2=Get-Datastore| Where {$_.ExtensionData.TriggeredAlarmState -ne $null -and $_.ExtensionData.TriggeredAlarmState.Time -ge $Y} | Select Name, @{N="AlarmName";E={(Get-View $_.ExtensionData.TriggeredAlarmState.Alarm).Info.Name}},
@{N="TimeTriggered"; E={$_.ExtensionData.TriggeredAlarmState.
Time}}, @{N="AlarmOverallStatus"; E={$_.ExtensionData.TriggeredAlarmState. OverallStatus}}, @{N="Acknowledged"; E={$_.ExtensionData.TriggeredAlarmState.Acknowledged}},@{N="Acknowledgedtime"; E={$_.ExtensionData.TriggeredAlarmState.AcknowledgedTime}} | Format-Table -Wrap -Property Name,AlarmName,TimeTriggered,AlarmOverallStatus,Acknowledged

#Pushing Report to Outputfile.
$alarmreport  > $outputfile
$alarmreport1 >> $outputfile
$alarmreport2 >> $outputfile


#Send Mail Function
Send-MailMessage -To "GIS.IOC.MON@computacenter.com","Vamshidhar.Peram@computacenter.com" -From "Vamshidhar.Peram@computacenter.com" -SmtpServer SMTP-GRP-PROD.computacenter.com -Subject $REPORTDATE -Body "Please find the attached alarmreport forall the Vcenters" -Attachments $outputfile


#Acknowledge Alarms

$alarmMgr = Get-View AlarmManager

 
Get-VM | where {$_.ExtensionData.TriggeredAlarmState} | %{
    $vm = $_
    $vm.ExtensionData.TriggeredAlarmState | %{
        $alarmMgr.AcknowledgeAlarm($_.Alarm,$vm.ExtensionData.MoRef)
    }
}

Get-VMHost | where {$_.ExtensionData.TriggeredAlarmState} | %{
    $esxihost = $_
    $esxihost.ExtensionData.TriggeredAlarmState | %{
        $alarmMgr.AcknowledgeAlarm($_.Alarm,$esxihost.ExtensionData.MoRef)
    }
}

Get-Datastore | where {$_.ExtensionData.TriggeredAlarmState} | %{
    $Datastore = $_
    $Datastore.ExtensionData.TriggeredAlarmState | %{
        $alarmMgr.AcknowledgeAlarm($_.Alarm,$Datastore.ExtensionData.MoRef)
    }
}