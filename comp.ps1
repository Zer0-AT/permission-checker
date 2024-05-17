$content1 = Get-Content -Path ".\testfiles\1.txt"
$content2 = Get-Content -Path ".\testfiles\2.txt"

# Array erstellen
$filter = @("baum", "ast", "ups")
#$filter = @("ha")

# Schleife durch alle Elemente des Arrays gehen
foreach ($element in $filter) {
    #Write-Host "$content1 ---- $element"

    $content1 = $content1 -replace "$element[^,\s]*([\s,])", ''
    $content2 = $content2 -replace "$element[^,\s]*([\s,])", ''
    $content1 = $content1 -replace ", -", ' -'
    $content2 = $content2 -replace ", -", ' -'
    $content1 = $content1 -replace "  ", ' '
    $content2 = $content2 -replace "  ", ' '

}
#Write-Host $content1
#Compare-Object $content1 $content2
$differences = Compare-Object -ReferenceObject $content1 -DifferenceObject $content2 -PassThru
#Write-Host "Anzahl Unterschiede: $($differences.Count)"
for ($i = 2; $i -lt $differences.Count; $i++) {
    Write-Host "Zeile" $($file1.IndexOf($differences[$i]) + 1)": $($differences[$i])"
}