# Create HV2 VMs for Chapter 11
# 
# This snippet creates a set of VMs used in the Managing Hyper-V chapter.
# Run this on HV2


$VMLocation  = 'C:\Vm\VMs'
# Create VM1
$VMN1        = 'SQLAcct1'
New-VM -Name $VMN1 -Path "$VMLocation\$VMN1"
# Create VM2
$VMN2        = 'SQLAcct2'
New-VM -Name $VMN2 -Path "$VMLocation\$VMN2"
 # Create VM3
$VMN3        = 'SQLAcct3'
New-VM -Name $VMN3 -Path "$VMLocation\$VMN3"
# Create VM4
$VMN4        = 'SQLMfg1'
New-VM -Name $VMN4 -Path "$VMLocation\$VMN4"
# Create VM5
$VMN5        = 'SQLMfg2'
New-VM -Name $VMN5 -Path "$VMLocation\$VMN5"
