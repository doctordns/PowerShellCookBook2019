#  Recipe 14.1 - Check connectivity
#
#  Run on SRV1
#  Uses SRV1, DC1, DC2

# 1. Use Test-NetConnnection to test connection to DC1
Test-Connection -ComputerName DC1

# 2. Test with simple true/false return
Test-Connection -ComputerName DC1 -Quiet

# 3. Test multiple systems at once
Test-Connection -ComputerName 'DC1','DC2','SRV2' -Count 1

# 4. Test connectivity for SMB traffic with DC1
Test-NetConnection -ComputerName DC1 -CommonTCPPort SMB 

# 5. Get detailed connectivity check, using DC1 with HTTP
$TNCHT = @{
    ComputerName     = 'DC1'
    CommonTCPPort    = 'HTTP'
    InformationLevel = 'Detailed'
}
Test-NetConnection @TNCHT

# 6. Look for a particular port (i.e SMV#  Recipe 14.1 - Check connectivity
#
#  Run on SRV1
#  Uses SRV1, DC1, DC2

# 1. Use Test-NetConnnection to test connection to DC1
Test-Connection -ComputerName DC1

# 2. Test with simple true/false return
Test-Connection -ComputerName DC1 -Quiet

# 3. Test multiple systems at once
Test-Connection -ComputerName 'DC1','DC2','SRV2' -Count 1

# 4. Test connectivity for SMB traffic with DC1
Test-NetConnection -ComputerName DC1 -CommonTCPPort SMB 

# 5. Get detailed connectivity check, using DC1 with HTTP
$TNCHT = @{
    ComputerName     = 'DC1'
    CommonTCPPort    = 'HTTP'
    InformationLevel = 'Detailed'
}
Test-NetConnection @TNCHT

# 6. Look for a particular port (i.e LDAP on DC1)
Test-NetConnection -ComputerName DC1 -Port 389

# 7. Look for a host that does not exist
Test-NetConnection -ComputerName 10.10.10.123

# 8. Look for a host that exists but a port/application
#    that does not exist:
Test-NetConnection -ComputerName DC1 -PORT 9999


 on DC1)
Test-NetConnection -ComputerName DC1 -Port 445

# 7. Look for a host that does not exist
Test-NetConnection -ComputerName 10.10.10.123

# 8. Look for a host that exists but a port/application
#    that does not exist:
Test-NetConnection -ComputerName DC1 -PORT 9999



