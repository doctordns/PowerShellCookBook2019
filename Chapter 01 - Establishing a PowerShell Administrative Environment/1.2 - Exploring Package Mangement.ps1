# Recipe 1.2 - Exploring Package Management
#
# Run from SRV1 

# 1. Review the cmdlets in the PackageManagement module:
Get-Command -Module PackageManagement

# 2. Review the installed providers with Get-PackageProvider:
Get-PackageProvider | 
  Format-Table -Property Name, 
                         Version, 
                         SupportedFileExtensions,
                         FromtrustedSource

# 3. The provider list initially includes msi, msu, and Programs
#    package  providers. These providers expose applications and
#     updates installed on your computer which you can explore.
Get-Package -ProviderName 'msu' |
    Select-Object -ExpandProperty Name

# 4. The NuGet source contains developer library packages. The 
#    details of NuGet are outside the scope of this book.
Get-PackageProvider -Name NuGet -ForceBootstrap

# 5. There are also other package providers you can explore:
Find-PackageProvider |
    Select-Object -Property Name,Summary |
        Format-Table -Wrap -AutoSize

# 6. Notice Chocolatey, which is another popular repository for Windows
#    administrators as well as  power users. 
#    Note that you cannot use this provider until you install it and
#    confirm the installation:
Install-PackageProvider -Name Chocolatey -Force

# 7. Verify Chocolatey is now in the list of installed providers:
Get-PackageProvider | Select-Object -Property Name,Version

# 8. Look for available software packages from the Chocolatey package provider.
$Packages = Find-Package -ProviderName Chocolatey
"$($Packages.Count) packages available from Chocolatey"
