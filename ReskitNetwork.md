# Reskit Network Topology

This file contains the details of the Reskit Network
Suitably updated - this is nearly a hosts file for the HV host.

## Core Servers

``` powershell
# Domain Controllers
10.10.10.10      DC1.Reskit.Org  
10.10.10.11      DC2.Reskit.Org  

# Certificate servers
10.10.10.20      RootCA.Reskit.Org  
10.10.10.21      CA.Reskit.Org

# General Purpose servers
10.10.10.50      SRV1.Reskit.Org  
10.10.10.51      SRV2.Reskit.Org  
```

## File Servers

```powershell
# Scale-Out Fle server Cluster address
10.10.10.100     FS.Reskit.Org   # Cluster  address  

# Individual nodes
10.10.10.101     FS1.Reskit.Org  
10.10.10.102     FS2.Reskit.Org  

# Storage Server (iSCSI target)
10.10.10.110     SSRV.Reskit.Org
```

## Hyper-V nodes

```powershell
# Hyper-V Cluster address
10.10.10.200     HV.Reskit.Org
# Individual Hyper-V nodes
10.10.10.201     HV1.Reskit.Org  
10.10.10.202     HV2.Reskit.Org  
```

## Windows Systems Update Services (WSUS)

```powershell
# WSUS server
10.10.10.240     WSUS1.Reskit.Org
```

## IP address for the host

```powershell
# Assign nice name for host
10.10.10.252       Home.Reskit.Org  
```
