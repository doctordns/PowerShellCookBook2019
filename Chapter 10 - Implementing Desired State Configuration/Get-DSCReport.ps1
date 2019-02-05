function Get-DscReport
{
   [CmdletBinding()]
    param
    (
        $AgentId = "$(throw 'Please enter an agaet ID')", 
        $serviceURL = "httpS://SRV1.RESKIT.ORG:8080/PSDSCPullServer.svc"
    )

    $RequestUri = "$serviceURL/Nodes(AgentId= '$AgentId')/Reports"
    Write-Verbose "ServiceURI: [$RequestUri]"
    $request = Invoke-WebRequest -Uri $requestUri  -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" `
               -UseBasicParsing -Headers @{Accept = "application/json";ProtocolVersion = "2.0"} `
               -ErrorAction SilentlyContinue -ErrorVariable ev
    Write-Verbose $Request
    $object = ConvertFrom-Json $request.content
    Write-Verbose $object
    return $object.value
}

$Session = New-CimSession srv2
$AgentID = (Get-DscLocalConfigurationManager -CimSession $session).AgentId
$Reports = Get-DscReport -verbose -AgentId $AgentID 
 
Foreach ($Reportin $Reports)
 |  FT jobid, operationtype, refreshmode, status, EndTime
