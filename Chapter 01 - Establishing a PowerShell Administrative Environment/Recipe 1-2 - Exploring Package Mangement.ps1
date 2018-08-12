# Recipe 1-5 - Exploring PackageManagement

# 1. Review the cmdlets in the PackageManagement module:
Get-Command -Module PackageManagement

# 2. Review the installed providers with Get-PackageProvider:
Get-PackageProvider | Select-Object -Property Name, Version

# 3. The provider list includes msi, msu, and Programs package providers. These
#    providers expose applications and updates installed on your computer which
#    you can explore:
Get-Package -ProviderName msi |
    Select-Object -ExpandProperty Name | sort name
Get-Package -ProviderName msu |
    Select-Object -ExpandProperty Name
Get-Package -ProviderName Programs |
    Select-Object -ExpandProperty Name

# 4. The NuGet source contains developer library packages. This functionality is
#    outside the scope of this book, but worth exploring if you do Windows or web
#    development:
Get-PackageProvider -Name NuGet

# 5. There are also other package providers you can explore:
Find-PackageProvider |
    Select-Object -Property Name,Summary |
        Format-Table -Wrap -AutoSize

# 6. Notice Chocolatey, which is a very useful tool for Windows administrators and
#    power users. Those with some Linux background may think of Chocolatey as
#    apt-get for Windows. You cannot use this provider until you install it and
#    confirm the installation:
Install-PackageProvider -Name Chocolatey -Verbose

# 7. Verify Chocolatey is now in the list of installed providers:
Get-PackageProvider | Select-Object Name,Version

# 8. Look for available software packages from the Chocolatey package provider.
#    Store these in a variable so you don't request the collection more than once, and
#    explore it:
$AvailableChocolateyPackages = `
      Find-Package -ProviderName Chocolatey
# How many software packages are available at Chocolatey?
$AvailableChocolateyPackages | Measure-Object