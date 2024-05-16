$file1 = Get-Content -Path ".\testfiles\1.txt"
$file2 = Get-Content -Path ".\testfiles\2.txt"

#Compare-Object $file1 $file2

$differences = Compare-Object -ReferenceObject $file1 -DifferenceObject $file2 -PassThru

for ($i = 1; $i -lt $differences.Count; $i++) {
    Write-Host "Zeile $($file1.IndexOf($differences[$i]) + 1): $($differences[$i])"
}