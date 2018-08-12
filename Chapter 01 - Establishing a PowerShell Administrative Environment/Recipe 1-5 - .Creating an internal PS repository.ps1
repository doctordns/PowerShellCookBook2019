# Recipe 1-6 - Creating an Internal PowerShell repository

#  Step 1 through step 5 (creating a local repository) are done in your browser.

# 6. Open the PowerShell ISE or console, and register your new repository:
$RepositoryURL = `
             'http://localhost:81/nuget/MyPowerShellPackages/'
Register-PSRepository -Name MyPowerShellPackages `
                      -SourceLocation $RepositoryURL `
                      -PublishLocation $RepositoryURL `
                      -InstallationPolicy Trusted

# 7. Publish a module you already have installed (Pester for example):
Publish-Module -Name Pester -Repository MyPowerShellPackages `
               -NuGetApiKey "Admin:Admin" `
               -Force

# 8. Download a module from PSGallery, save it to the C:\Foo folder, and
#   publish to your new repository (for example, Carbon):
Find-Module -Name Carbon -Repository PSGallery
If (-Not (Test-Path -path 'c:\foo')) {
    New-Item -ItemType Directory -Path 'C:\Foo'
}
Save-Module -Name Carbon -Path C:\foo
Publish-Module -Path C:\Foo\Carbon `
    -Repository MyPowerShellPackages `
    -NuGetApiKey "Admin:Admin"

# 9. Find all the modules available in your newly created and updated repository:
Find-Module -Repository MyPowerShellPackages 