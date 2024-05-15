[CmdletBinding()]
param (
    [int]$n = 0,
    [string]$t = "b",
    [string]$o = "t",
    [string]$f = "d",
    [switch]$h
)

<#
    HELP
#>

if ($h) {
    Write-Host "Hilfe:
    -n [int] Maximale tiefe der Ordnerstruktur 0=unlimited
    -t [string] Typ: (o)rdner (d)atein (B)eides
    -o [string] Output: (T)xt (x)ml
    -f [string] Format: (D)irekt (g)ruppiert (b)eides
    -h diese Hilfe"
    exit
}

# Admin Checker
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Path Checker
function Test-PathValidity {
    param (
        [string]$path
    )
    if (-not (Test-Path -Path $path -PathType Container)) {
        Write-Host "Path not valid -" $path
        return $false
    }
    return $true
}

<#
    INPUTS
 #>


if (-not (Test-Admin)) {
    Write-Host "Sie haben nicht genuegend Rechte, um das Skript mit erhoehten Rechten auszufuehren."
    $continueAsAdmin = Read-Host "Trotzdem weitermachen? (Y/n)"
    if ($continueAsAdmin -eq "n" -or $continueAsAdmin -eq "N") {
        exit
    }
}

# 1. was
$runHere = Read-Host "Soll das Skript hier ausgefuehrt werden? (Y/n)"
if ($runHere -eq "" -or $runHere -eq "y" -or $runHere -eq "Y") {
    $currentPath = $PSScriptRoot
}
else {
    $currentPath = Read-Host "Wo denn dann?"
}
while (-not (Test-PathValidity -path $currentPath)) {
    $currentPath = Read-Host "Bitte noamal probieren"
}

# 2. wohin
$resultHere = Read-Host "Ergebnis hier speichern? (Y/n)"
if ($resultHere -eq "" -or $resultHere -eq "y" -or $resultHere -eq "Y") {
    $outputPath = $PSScriptRoot
}
else {
    $outputPath = Read-Host "Wo denn dann?"
}
while (-not (Test-PathValidity -path $outputPath)) {
    $outputPath = Read-Host "Bitte noamal probieren"
}

# 3. Settings
if ($args.Count -eq 0) {
    Write-Host "Ohne Argumente ausgefuehrt
    -n [int] Maximale tiefe der Ordnerstruktur 0=unlimited
    -t [string] Typ: (o)rdner (d)atein (B)eides
    -o [string] Output: (T)xt (x)ml
    -f [string] Format: (D)direkt (g)ruppiert (b)eides
    -h diese Hilfe"
    #$userInput = Read-Host "Was soll geprueft werden? (-n 0 -t b -o t -f d)"
}
else {
    Write-Host "Mit folgenden Argumenten ausgefuehrt: $args"
}

# 4. Feedback
Write-Host "Pfad zum Pruefen:" $currentPath
Write-Host "Pfad zum Speichern:" $outputPath
Write-Host "Settings: -n $n -t $t -o $o -f $f"


# 5. Run
$confirm = Read-Host "Soll das Skript ausgefuehrt werden? (y/N)"
if ($confirm -eq "y" -or $confirm -eq "Y") {
    #funtionen :)
}
else {
    exit
}