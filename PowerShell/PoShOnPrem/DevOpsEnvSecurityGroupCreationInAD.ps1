Clear-Host    
#OU where you want to create the group(s)
$OUGroup = 'OU=Accounting,OU=DevOps,OU=Groups,OU=HeadQuarters,DC=datawisetech,DC=corp'
#OU where you want to create the user(s)
$OUUser = 'OU=Accounting,OU=Devops,OU=Users,OU=HeadQuarters,DC=datawisetech,DC=corp'
$DomainUpnSuffix = '@datawisetech.corp'

#In this example this stands for development, test. beta, production)
$EnvTypes = @('d', 't', 'b', 'p')
   
foreach ($EnvType in $EnvTypes) {

    switch ($EnvType) {
        'd' { $UserType = 'Dev' }
        't' { $UserType = 'Test' }
        'b' { $UserType = 'Beta' }
        'p' { $UserType = 'Prod' }
    }
    
    $localgroup = "lg-devops-" + $EnvType + "-acountingreports"
    $globalgroup = "gg-devops-" + $EnvType + "-accountingreports"
    $user = $UserType + "AppuserForAccountingReports"
    if ($user.Length -gt 20) { $SamAccountName = $user.Substring(0, 20) } else { $SamAccountName = $user }
    $UserDescription = "Gecko $UserType Azure Account"
    $UserPassword = 'SomePassword' | ConvertTo-SecureString -AsPlainText -Force

        
    #Create the new user
    try {
        write-host -foregroundcolor Green "Creating $user"
        New-ADUser -Name $user -GivenName $user  -SamAccountName $SamAccountName -UserPrincipalName "$user$DomainUpnSuffix" -path $OUUser `
            -Enabled $True -AccountPassword $UserPassword  -PasswordNeverExpires $True -CannotChangePassword $True `
            -Description $UserDescription
    } 
    catch {
        Write-Host "An error occurred:"  -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
        Write-Host $_.ScriptStackTrace  -ForegroundColor yellow
        Write-Host $PSItem.Exception -ForegroundColor cyan
    } 
    finally { $Error.Clear() }

    #Create the local and the global security groups.
    try {
        write-host -foregroundcolor Green "Creating $localgroup"
        New-ADGroup -GroupCategory Security -GroupScope DomainLocal -Name $localgroup -SamAccountName $localgroup -path $OUGroup
        write-host -foregroundcolor Green "Creating write-host $globalgroup"
        New-ADGroup -GroupCategory Security -GroupScope Global -Name $globalgroup -SamAccountName $globalgroup -path $OUGroup
    }

    catch {
        Write-Host "An error occurred:"  -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
        Write-Host $_.ScriptStackTrace  -ForegroundColor yellow
        #Write-Host $PSItem.Exception -ForegroundColor cyan
    } 
    finally { $Error.Clear() }

    #Add the global security group to the domain local and the user to the global security group.
    try {
        write-host -foregroundcolor Green "Adding $globalgroup to $localgroup."
        Add-ADGroupMember -Identity $localgroup -Members $globalgroup
        write-host -foregroundcolor Green "Adding user $User to $globalgroup."
        Add-ADGroupMember -Identity $globalgroup -Members $SamAccountName
    }
    catch {
        Write-Host "An error occurred:"  -ForegroundColor Red
        Write-Host $_ -ForegroundColor Red
        Write-Host $_.ScriptStackTrace  -ForegroundColor yellow
        #Write-Host $PSItem.Exception -ForegroundColor cyan
    } 
    finally { $Error.Clear() }
}

    



