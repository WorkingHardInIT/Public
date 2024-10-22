#Typically this is associated with following events in the DNS log: 404,407 and 408

$NameList = @('veeam.com')
$ServerList = @('192.168.2.72') #The dedicated DNS Server(s) your isolated Veeam Fabirc uses
$CustomEventLogSource = "Veeam DNS Server Check"
Function CheckDnsService() {
    $DNSResults = @()
    foreach ($Name in $NameList) {
        $tempObj = "" | Select-Object Name, IPAddress, Status, ErrorMessage
        try {
            $dnsRecord = Resolve-DnsName $Name -Server $ServerList -ErrorAction Stop | Where-Object { $_.Type -eq 'A' }
            $tempObj.Name = $Name
            $tempObj.IPAddress = ($dnsRecord.IPAddress -join ',')
            $tempObj.Status = 'FAILED' #'SUCCEEDED'
            $tempObj.ErrorMessage = ''
        }
        catch {
            $tempObj.Name = $Name
            $tempObj.IPAddress = ''
            $tempObj.Status = 'FAILED'
            $tempObj.ErrorMessage = $_.Exception.Message
        }
        $DNSResults += $tempObj
    }

    #Create the "Veeam DNS Server Check" event source if it doesn not already exist
    If (-not [System.Diagnostics.Eventlog]::SourceExists("Veeam DNS Server Check")) {
        New-EventLog -LogName Application -Source "Veeam DNS Server Check"
    }

    #Check if the DNS test failed
    If ( $DNSResults.Status -eq 'FAILED') {
        #Grab the logs containing the 3 suspect ivent ids
        Try {
            $Logs = get-eventlog 'DNS Server' -ComputerName VBR -source Microsoft-Windows-DNS-Server-Service -InstanceId 404, 407, 408 -After (Get-Date).AddMinutes(-600) -erroraction stop}
        catch {
            $Logs = $Null
        }
        If ( $Null -ne $logs) {
            #If those event IDs exist, restart the DNS Servicer to fix the issue and log this
            $hostName = hostname
            Get-Service -ComputerName localhost -Name DNS  | Restart-Service
            Write-EventLog –LogName Application –Source $CustomEventLogSource –EntryType Warning –EventID 666 -Category 0 –Message "DNS query failed due to event ID's 404, 407 or 408. Error Message: $($DNSResults.ErrorMessage)"
            Write-EventLog –LogName Application –Source $CustomEventLogSource –EntryType Warning –EventID 667 -Category 0 –Message "DNS Service on $hostName has restarted"
        }
        Else {
            #The DNS test failed but it is another issue than te one we are scanning for.
            $hostName = hostname
            Write-EventLog –LogName Application –Source $CustomEventLogSource –EntryType Warning –EventID 668 -Category 0 –Message "DNS query failed on Veeam DNS Server $hostName but it is not releated to event ID's 404, 407 or 408. Error Message: $($DNSResults.ErrorMessage)"
            Write-EventLog –LogName Application –Source $CustomEventLogSource –EntryType Warning –EventID 669 -Category 0 –Message "Trouble shoot DNS issue yourself"
        }
    }
    Else {
        #Things are OK you can log this but frequent checking might inundate the event log with happy messages
        $hostName = hostname
        Write-EventLog –LogName Application –Source $CustomEventLogSource –EntryType Information –EventID 700 -Category 0 –Message "Veeams DNS Server $hostName is working just fine"
    }
}

CheckDnsService
