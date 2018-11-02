# Recipe 4-2 Publishing a printer

# 1. Get the printer to publish and store the returned object in $Printer:
$Printer = Get-Printer -Name SGCP1

# 2. Observe the publication status:
$Printer | Format-Table -Property Name, Published

# 3. Publish the printer to AD:
$Printer | Set-Printer -Published $true `
                       -Location '10th floor 10E4'

# 4. View the updated publication status:
Get-Printer -Name SGCP1 |
    Format-Table -Property Name, Published, Location