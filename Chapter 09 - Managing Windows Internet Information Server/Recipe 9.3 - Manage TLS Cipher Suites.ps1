# Recipe 10-3  Manage TLS Cipher Suites

# 1. Get the cipher suites on SRV1 and display
Get-TlsCipherSuite |
  Format-Table Name, Exchange, Cipher, Hash, Certificate

# 2. Find Cipher suites that support 3DES
Get-TlsCipherSuite -Name 3DES |
  Format-Table Name, Exchange, Cipher, Hash, Certificate

# 3 Disable 3DES based cipher suites
Foreach ($CS in (Get-TlsCipherSuite -Name '3DES'))
  {Disable-TlsCipherSuite -Name $CS.Name}

# 4. See if any cipher suites remain that support 3DES
Get-TlsCipherSuite 3DES |
  Format-Table Name, Exchange, Cipher, Hash, Certificate

# 5. Re-enable the 3DES cipher suite
Enable-TlsCipherSuite -Name TLS_RSA_WITH_3DES_EDE_CBC_SHA

# 6. Find Cipher suites that support 3DES
Get-TlsCipherSuite 3DES |
  Format-Table -Property Name, Exchange, Cipher, 
                         ggeHash, Certificate

