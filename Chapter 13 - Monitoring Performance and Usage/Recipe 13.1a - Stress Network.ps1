# Script 6-1b - Bonus script to stress network
# This script allows you to variously stress systems to get perf counters to do nice things.

# dc1
Function Stress-DC1 {
$sb =
{
 invoke-command -computer DC1 -script {
 1..1000000 | ForEach-Object {$u = get-aduser -filter *; $c = get-adcomputer -filter *}
 }
}

Start-job -Script $sb
}

Function Stress-CA {
$sb =
{
 invoke-command -computer CA -script {
 1..10000000 | foreach {$i=0; $i++; $i=$i*$i*$i}

 }
}

Start-job -script $sb
}

Function Stress-FS1 {
Start-Job  -ScriptBlock {icm -ComputerName fs1 -ScriptBlock {dir . -rec}}
Start-Job  -ScriptBlock {icm -ComputerName fs1 -ScriptBlock {dir . -rec}}
Start-Job  -ScriptBlock {icm -ComputerName fs1 -ScriptBlock {dir . -rec}}
Start-Job  -ScriptBlock {icm -ComputerName fs1 -ScriptBlock {dir . -rec}}
}


#  Here invoke them
Stress-FS1
stress-dc1
stress-CA