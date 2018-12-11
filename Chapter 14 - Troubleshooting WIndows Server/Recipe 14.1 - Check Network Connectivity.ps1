#  Recipe 14.1 - Check connectivity
#
#  Run on SRV1
#  Uses SRV1, DC1, DC2

# 1. Use Ping to test connectivity to DC1
Ping DC1

# 2. Use Test-NetConnnection to test connection to DC1
Test-Connection -ComputerName DC1

# 3. Test with simple true/false return
Test-Connection -ComputerName DC1 -Quiet

# 4. Test multiple systems at once
Test-Connection -computer 'DC1','DC2','SRV1' -Count 1

# 5. Test connectivity for SMB traffic
Test-NetConnection -ComputerName DC1 -CommonTCPPort SMB

# 6. Get detailed connectivity check, using DC1 with HTTP
$TNCHT = @{
    ComputerName     = 'DC1'
    CommonTCPPort    = 'HTTP'
    InformationLevel = 'Detailed'
}
 Test-NetConnection $TNCHT

# 7. Look for a particular port (i.e LDAP on DC1)
Test-NetConnection -ComputerName dc1 -Port 445

# 8. Look for a host that does not exist
Test-NetConnection -ComputerName 10.10.10.123

# 9. Look for a host that exists but a port/application
#    that does not exist:
Test-NetConnection -ComputerName DC1 -PORT 9999



