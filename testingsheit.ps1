
$outputPath = $PSScriptRoot
$date = Get-Date
$date = $date.ToString("yyMMdd-HHmm")
$outputFile = $outputPath + "\perout_" + $date + ".txt"

Write-Host $outputFile