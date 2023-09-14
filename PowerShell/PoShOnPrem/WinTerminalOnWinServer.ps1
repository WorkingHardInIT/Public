#This script will install Windows Terminal prerequisites aand Windows Terminal itself.
#The download urls should be upgraded to their current versions at the time you run this
#script. The url's are the most current supported versions at the time of writing.
#This script was tested on Windows Server 2022 Standard/Datacenter with Destop Experience


$msftuixamlName = 'Microsoft.UI.Xaml.2.7'
$MsftVCLibsName = 'Microsoft.VCLibs.140.00.UWPDesktop'
$WinTerminalAppName = 'Microsoft.WindowsTerminal'

# url for microsoft-ui-xaml 2.7.3 - there are more recent versions but at the time of writing
# Windows Terminal v1.17.11461.0 still has a dependcy on v2.7.3 - so install this version
$urlmsftuixaml = 'https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.7.3/Microsoft.UI.Xaml.2.7.x64.appx'
$urlmsftvclibs = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
$urlwinterminal = 'https://github.com/microsoft/terminal/releases/download/v1.17.11461.0/Microsoft.WindowsTerminal_1.17.11461.0_8wekyb3d8bbwe.msixbundle'

#region Prerequisit 1: microsoft-ui-xaml 2.7.3
try {
    $msftuixamlInstalled = $false

    #Grab the file name, we'll use it to download the file from github
    $FileName = Split-Path $urlmsftuixaml -Leaf
    $PathToInstallFile = Join-Path -Path "$home\Downloads" -ChildPath $FileName

    # Download
    Start-BitsTransfer -Source $urlmsftuixaml -Destination $PathToInstallFile

    # Install
    if (Test-Path -Path $PathToInstallFile -PathType Leaf) {
        Import-Module -Name Appx -UseWindowsPowerShell
        Add-AppxPackage -Path $PathToInstallFile
        if ((Get-AppxPackage -name $msftuixamlName).Status -eq 'Ok') {
            $msftuixamlInstalled = $true
        }
    }
}
catch {
    $msftuixamlInstalled = $false
}
Finally {
    #Clean up after our selves
    if (Test-Path -Path $PathToInstallFile -PathType Leaf) {
        Remove-Item -Path $PathToInstallFile  -force -Confirm:$false
        $msftuixamlInstalled = $True
    }
}
#endregion

#region Prerequisit 2: Microsoft.VCLibs.x64.14.00.Desktop
try {
    $msftvclibsInstalled = $false


    # Grab the file name, we'll use it to download the file from github
    $FileName = Split-Path $urlmsftvclibs -Leaf
    $PathToInstallFile = Join-Path -Path "$home\Downloads" -ChildPath $FileName

    # Download
    Start-BitsTransfer -Source $urlmsftvclibs -Destination $PathToInstallFile

    #Install
    if (Test-Path -Path $PathToInstallFile -PathType Leaf) {
        if ($true -eq $msftuixamlInstalled) {
            Import-Module -Name Appx -UseWindowsPowerShell
            Add-AppxPackage -Path $Destination
            if ((Get-AppxPackage -name $MsftVCLibsName).Status -eq 'Ok') {
                $msftvclibsInstalled = $true
            }
        }
    }
}
catch {
    $msftvclibsInstalled = $false
}
finally {
    #Clean up after our selves
    if (Test-Path -Path $PathToInstallFile -PathType Leaf) {
        Remove-Item -Path $PathToInstallFile  -force -Confirm:$false
    }
}
#endregion

#region Install Windows Terminal
# Provide URL to newest version of Windows Terminal Application
try {
    $msftwinterminalInstalled = $false
    $FileName = Split-Path $urlwinterminal -Leaf
    $PathToInstallFile = Join-Path -Path "$home\Downloads" -ChildPath $FileName

    # Download
    Start-BitsTransfer -Source $urlwinterminal -Destination $PathToInstallFile

    # Install
    if (Test-Path -Path $PathToInstallFile -PathType Leaf) {
        if ($true -eq $msftvclibsInstalled) {
            Import-Module -Name Appx -UseWindowsPowerShell
            Add-AppxPackage -Path $PathToInstallFile
            if ((Get-AppxPackage -name $WinTerminalAppName).Status -eq 'Ok') {
                $msftwinterminalInstalled = $true
            }
        }
    }
}
catch {
    $msftwinterminalInstalled = $false
}
Finally {
    #Clean up after our selves
    if (Test-Path -Path $PathToInstallFile -PathType Leaf) {
        Remove-Item -Path $PathToInstallFile  -force -Confirm:$false
    }
}
#endregion