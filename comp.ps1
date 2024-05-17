[CmdletBinding()]
param (
    
)

if ($DebugPreference) {
    $DebugPreference = 'Continue'
    Write-Debug "*DEEP VOCE* Epic-Debug-Modus activated`n"
    $testingMode = $true
} else { 
    $testingMode = $false 
}
$startTime = Get-Date
$outputFile = $PSScriptRoot + "\compout_" + $($startTime.ToString("yyMMdd-HHmm")) + ".txt"
$diffCount = 0

# Files laden
$content1 = Get-Content -Encoding UTF8 -Path ".\testfiles\1.txt"
$content2 = Get-Content -Encoding UTF8 -Path ".\testfiles\2.txt"
Write-Host "Files geladen"

# Filter erstellen [WICHTG: Bei "\" immer 2 verwenden ^^]
$filter = @(
    "EMPL\\AdAdmins",
    "EMPL\\SRVAdmins",
    "EMPL\\Domänen-Admins"
)
Write-Debug "Filter: $filter"

# Go Nuts
foreach ($element in $filter) {
    # Write-Debug "$content1 --1-- $element"
    # Write-Debug "$content2 --2-- $element"
    $content1 = $content1 -replace "$element[^,\s]*([\s,])", ''
    $content2 = $content2 -replace "$element[^,\s]*([\s,])", ''
    $content1 = $content1 -replace ", -", ' -'
    $content2 = $content2 -replace ", -", ' -'
    $content1 = $content1 -replace "  ", ' '
    $content2 = $content2 -replace "  ", ' '
    Write-Host "$element erfolgreich entfernt"
}
Write-Host "`n"

# Vergleichen
$differences = Compare-Object -ReferenceObject $content1 -DifferenceObject $content2 -PassThru
#Write-Debug "$($content1.IndexOf($differences[0]))"
New-Item -ItemType file -Path $outputFile -Force | Out-Null
for ($i = 0; $i -lt $differences.Count; $i++) {
    $result = @()
    #Write-Debug $differences[$i]
    #Write-Debug $($content1.IndexOf($differences[$i]) + 1)
    if ($differences[$i] -ine "" -and $content1.IndexOf($differences[$i]) -ne -1) {
        $result = "Zeile $($content1.IndexOf($differences[$i]) + 1): $($differences[$i])"
        $result | Out-File -FilePath $outputFile -Encoding UTF8 -Append
        Write-Host $result
        $diffCount++
    }
}

$endTime = Get-Date
$executionTime = New-TimeSpan $startTime $endTime
Write-Host "`n`nEs gab $diffCount Unterschiede`nDauer: $executionTime`nSpeicherort: $outputFile"