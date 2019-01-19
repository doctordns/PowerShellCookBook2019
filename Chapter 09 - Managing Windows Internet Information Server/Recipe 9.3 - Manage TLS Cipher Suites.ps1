# Recipe 10-3  Manage TLS Cipher Suites

# 1. Get the chipher suites on SRV1 and display
Get-TlsCipherSuite |
    Format-Table Name, Exchange, Cipher, Hash, Certificate

# 2. Find Cipher suites that support RC4
Get-TlsCipherSuite -Name RC4 |
    Format-Table Name, Exchange, Cipher, Hash, Certificate

# 3 Disable RC4 based cipher suites
Foreach ($P in (Get-TlsCipherSuite -name 'RC4'))
    {Disable-TlsCipherSuite -Name $P.name}

# 4. Find Cipher suites that support RC4
Get-TlsCipherSuite RC4 |
    Format-Table Name, Exchange, Cipher, Hash, Certificate

# 5. Re-enbable the two cipher suites
Enable-TlsCipherSuite -Name TLS_RSA_WITH_RC4_128_SHA
Enable-TlsCipherSuite -Name TLS_RSA_WITH_RC4_128_MD5

# 6. Find Cipher suites that support RC4
Get-TlsCipherSuite RC4 |
    Format-Table Name, Exchange, Cipher, Hash, Certificate
