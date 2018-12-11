# Recipe 13.6  -  Creating a Systems Diagnostic report
#
# Run on SRV1

# 1. Start the built-in data collector on the local system:
$PerfReportName="System\System Diagnostics"
$DataSet = New-Object -ComObject Pla.DataCollectorSet
$DataSet.Query($PerfReportName,$null)
$DataSet.Start($true)

# 2. Wait for the data collector to finish:
"Sleeping for [$($Dataset.Duration)] seconds"
Start-Sleep -Seconds $Dataset.Duration

# 3. Get the report and store it as HTML:
$Dataset.Query($PerfReportName,$null)
$PerfReport = $Dataset.LatestOutputLocation + "\Report.html"

# 4. View the report:
& $PerfReport