#alternatively, instead of here in PowerShell via inline code, we can read the filter entries from a CSV file
#$DHCPFilterAllowList  = Import-Csv -Path "C:\SysAdmin\MacAddressesAllowFilter.csv"

$DomainName = 'image.analysis' #the domain name of our servers and client - i.e. the primary DNS suffix
$DHCPServer = "nwservices01.$DomainName" #FQDN of the DHCP server
$Scope = "192.168.3.0"

#Configure DHCP scope DNS settings
Set-DhcpServerv4DnsSetting -ComputerName $DHCPServer -scope $Scope -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry:$True -UpdateDnsRRForOlderClients:$True

#Enable the Allow and Deny filter for the DHCP server - This is a server-wide setting per IP type, not per scope
Set-DhcpServerv4FilterList -ComputerName $DHCPServer  -Allow $True -Deny $True

#Use this to explicitly allow which MAC addresses can get an IP from the DHCP server
<#
$DHCPFilterAllowList = @(
    @{
        "MAcAddress" = "1d-1b-1c-1d-1e-8f"
        "Description" ="Computer17.$DomainName"},
    @{
        "MAcAddress" = "1a-1b-1c-1d-1e-4f"
        "Description" ="Computer2.$DomainName"},
    @{
        "MAcAddress" = "2b-1b-1c-1d-1e-4f"
        "Description" ="Computer014.$DomainName"}
)
#>
<#
#USe this to block unwanted MAC addresses from getting an IP from the DHCP server

$DHCPFilterDenyList = @(
    @{
        "MAcAddress" = "1d-1b-1c-1d-1e-6f"
        "Description" ="Computer17.$DomainName"},
    @{
        "MAcAddress" = "1a-1b-1c-1d-1e-4f"
        "Description" ="Computer2.$DomainName"},
    @{
        "MAcAddress" = "2b-1b-1c-1d-1e-4f"
        "Description" ="Computer014.$DomainName"}
)
#>

# Create the Allow List for the DHCP filters incode as a table - We will extend this table later for use with DHCP Scope reservations
# This is our record and list of MAC addresses and clients to allow
$DHCPFilterAllowList  = New-Object System.Data.DataTable
[void]$DHCPFilterAllowList.Columns.Add("MacAddress")
[void]$DHCPFilterAllowList.Columns.Add("Description")
[void]$DHCPFilterAllowList.Rows.Add("1d-1b-1c-1d-1e-1f", "goodcomputer01.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("2a-2b-2c-2d-2e-2f", "goodcomputer02.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("3b-3b-3c-3d-3e-3f", "goodcomputer03.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("00-15-5D-64-0A-82", "imagews-001.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("30-d0-42-e4-42-6c","aocsrv325.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("30-d0-42-e2-3d-4e","aocsrv326.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("30-d0-42-e2-3c-98","aocsrv327.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("d8-9e-f3-28-e2-6e","aocsrv311.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("74-86-e2-09-22-1c","aocsrv312.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("a4-ba-db-10-e4-48","aocsrv07.$DomainName")
[void]$DHCPFilterAllowList.Rows.Add("14-18-77-4b-4f-09","aocsrv09.$DomainName")


# Create the Deny List for the DHCP filters incode as a table - these are dummy entries as examples, as we do not have any yet.
# This is our record and list of MAC addresses and clients to deny
$DHCPFilterDenyList  = New-Object System.Data.DataTable
[void]$DHCPFilterDenyList.Columns.Add("MacAddress")
[void]$DHCPFilterDenyList.Columns.Add("Description")
[void]$DHCPFilterDenyList.Rows.Add("7a-7b-7c-7d-7e-7f", "badcomputer01.$DomainName")
[void]$DHCPFilterDenyList.Rows.Add("8a-8b-8c-8d-8e-8f", "badcomputer02.$DomainName")
[void]$DHCPFilterDenyList.Rows.Add("9a-9b-9c-9d-9e-9f", "badcomputer03.$DomainName")


#Grab the complete current Allow List
$CompleteDHCPAllowFilter = Get-DhcpServerv4Filter -ComputerName $DHCPServer -List Allow
#Grab the complete current Deny List
$CompleteDHCPDenyFilter = Get-DhcpServerv4Filter -ComputerName $DHCPServer -List Deny

write-Host -foregroundcolor green "+++   DHCP ALLOW FILTER LIST ENTRIES BLOCK   +++"
write-Host -foregroundcolor green ""
write-Host -foregroundcolor green "Looping through the allow filter list to see if they need and can be added."
$Counter = 0
Foreach ($FilterEntry in $DHCPFilterAllowList ){
$Counter = $Counter +1
write-Host -foregroundcolor green ""
write-Host -foregroundcolor green "***  Attempting allow list filter number $Counter  ***"
    $checkIfMacAddressExistsInAllowFilter = gET-DhcpServerv4Filter -ComputerName $DHCPServer -List Allow | Where-Object MacAddress -EQ $FilterEntry.MacAddress
    #$checkIfMacAddressExistsinAllowFilter
    If ([string]::IsNullOrEmpty($checkIfMacAddressExistsInAllowFilter)){
        Write-Host -foregroundcolor yellow "MAC Address $($FilterEntry.MacAddress) is not yet used in an existing allow filter entry. Proceeding with check of description."
        If ($FilterEntry.Description -in $CompleteDHCPAllowFilter.description ){
            Write-Host -foregroundcolor yellow "Description $($FilterEntry.Description) has already been used another allow filter entry. Please choose another description to avoid confusion."}
        else{
        Write-Host -foregroundcolor yellow "Description $($FilterEntry.Description) for $($FilterEntry.MacAddress) Was not used in any other allow filter yet. Proceeding to add this entry.."
        write-Host -foregroundcolor cyan "Adding Allow Filter entry with description $($FilterEntry.Description) for MAC Address $($FilterEntry.MacAddress)"
        Add-DhcpServerv4Filter -ComputerName $DHCPServer -List Allow -MacAddress $FilterEntry.MacAddress -Description $FilterEntry.Description
        write-Host -foregroundcolor green "Allow Filter entry with description $($FilterEntry.Description) with MAC Address $($FilterEntry.MacAddress) succesfully added."
        }
    }
    else {
        write-Host -ForegroundColor Magenta "Allow Filter for MAC Address $($checkIfMacAddressExistsInAllowFilter.MacAddress) with description $($checkIfMacAddressExistsInAllowFilter.Description) allready exists"
        If ($FilterEntry.Description -ne $checkIfMacAddressExistsInAllowFilter.Description ){write-Host -ForegroundColor Magenta "Note that the existing MAC address entry has a different description than what you entered ($($FilterEntry.Description))"}
    }
}


write-Host -foregroundcolor green ""
write-Host -foregroundcolor green "+++   DHCP ALLOW FILTER LIST ENTRIES BLOCK   +++"
write-Host -foregroundcolor green ""
write-Host -foregroundcolor green "Looping through the deny filter list to see if they need and can be added."
$Counter = 0
Foreach ($FilterEntry in $DHCPFilterDenyList ){
$Counter = $Counter +1
write-Host -foregroundcolor green ""
write-Host -foregroundcolor green "***  Attempting deny list filter number $Counter  ***"
    $checkIfMacAddressExistsInDenyFilter = gET-DhcpServerv4Filter -ComputerName $DHCPServer -List Deny | Where-Object MacAddress -EQ $FilterEntry.MacAddress
    #$checkIfMacAddressExistsinAllowFilter
    If ([string]::IsNullOrEmpty($checkIfMacAddressExistsInDenyFilter)){
        Write-Host -foregroundcolor yellow "MAC Address $($FilterEntry.MacAddress) is not yet used in an existing deny filter entry. Proceeding with a check of description."
        If ($FilterEntry.Description -in $CompleteDHCPDenyFilter.description ){
            Write-Host -foregroundcolor yellow "Description $($FilterEntry.Description) has already been used by another deny filter entry. Please choose another description to avoid confusion."}
        else{
        Write-Host -foregroundcolor yellow "Description $($FilterEntry.Description) for $($FilterEntry.MacAddress) was not used in any other deny filter yet. Proceeding to add this entry.."
        write-Host -foregroundcolor cyan "Adding deny Filter entry with description $($FilterEntry.Description) for MAC Address $($FilterEntry.MacAddress)"
        Add-DhcpServerv4Filter -ComputerName $DHCPServer -List deny -MacAddress $FilterEntry.MacAddress -Description $FilterEntry.Description
        write-Host -foregroundcolor green "Deny Filter entry with description $($FilterEntry.Description) with MAC Address $($FilterEntry.MacAddress) succesfully added."
        }
    }
    else {
        write-Host -ForegroundColor Magenta "deny Filter for MAC Address $($checkIfMacAddressExistsinDenyFilter.MacAddress) with description $($checkIfMacAddressExistsinDenyFilter.Description) already exists"
        If ($FilterEntry.Description -ne $checkIfMacAddressExistsinDenyFilter.Description ){write-Host -ForegroundColor Magenta "Note that the existing MAC address entry has a different description than what you entered ($($FilterEntry.Description))"}
    }
}



#region RESERVATION
$Type = "Both"

#Base the DHCP reservation list on the Allow List and extend the table with the needed columns.
#
$DHCPReservations = $DHCPFilterAllowList
[void]$DHCPReservations.Columns.Add("Name")
[void]$DHCPReservations.Columns.Add("Scope")
[void]$DHCPReservations.Columns.Add("Type")
foreach ($Row in $DHCPReservations){
    $Row.Name  = $Row.Description
    $Row.Scope  = $Scope
    $Row.Type  = $Type
}


#$DHCPReservations | ft
write-Host -foregroundcolor green ""
write-Host -foregroundcolor green "+++   DHCP RESERVATION ENTRIES BLOCK   +++"
write-Host -foregroundcolor green ""
write-Host -foregroundcolor green "Looping through the reservations list to see if they need and can be added."

$AllExitingDHCPReservations = gET-DhcpServerv4Reservation -ComputerName $DHCPServer -ScopeId $Scope
$Counter = 0
Foreach ($Row in $DHCPReservations ){
    $Counter = $Counter +1
    write-Host -foregroundcolor green ""
    write-Host -foregroundcolor green "***  Attempting to add Reservation number $Counter  ***"
        $checkIfMacAddressExistsInReservation = gET-DhcpServerv4Reservation -ComputerName $DHCPServer -Scope $Row.Scope | Where-Object ClientID -EQ $Row.MacAddress
        #$checkIfMacAddressExistsinAllowFilter
        #$row
        If ([string]::IsNullOrEmpty($checkIfMacAddressExistsInReservation)){
            Write-Host -foregroundcolor yellow "MAC Address $($Row.MacAddress) is not yet used in an existing reservation. Proceeding with check of name."
            If ($row.Name -in $AllExitingDHCPReservations.Name ){
                Write-Host -foregroundcolor yellow "The name $($Row.Name) has already been used another allow filter entry. Please choose another name to avoid confusion."}
            else{
            Write-Host -foregroundcolor yellow "Name $($Row.Name) for $($Row.MacAddress) Was not used in any other allow filter yet. Proceeding to add this entry.."
            write-Host -foregroundcolor cyan "Adding Allow Filter with name $($Row.Name) with MAC Address $($Row.MacAddress)"
            $FreeIP = Get-DhcpServerv4FreeIPAddress -ComputerName $DHCPServer -ScopeId $Scope
            Add-DhcpServerv4Reservation -ComputerName $DHCPServer -ScopeID $Row.Scope -ClientId $Row.MacAddress -Name $Row.Name -Description $Row.Description -IPAddress $FreeIP -type Both | Out-Null
            write-Host -foregroundcolor green "Allow Filter with name $($Row.Name) with MAC Address $($Row.MacAddress) succesfully added."
            }
        }
        else {
            write-Host -ForegroundColor Magenta "Reservation for MAC Address $($checkIfMacAddressExistsInReservation.ClientID) with name $($checkIfMacAddressExistsInReservation.Name) already exists"
            If ($Row.Description -ne $checkIfMacAddressExistsInReservation.Name ){write-Host -ForegroundColor Magenta "Note that the existing MAC address entry has a different description than what you entered ($($Row.Name))"}
        }
}


#endregion
