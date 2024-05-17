[CmdletBinding()]
param (
    [int]$n = 0,
    [string]$t = "o",
    [string]$o = "t",
    [string]$f = "d",
    [switch]$h
)
###############################
##  START HELP AND PRESETS   ##
###############################
$myinputs = "
    -n [int] Maximale tiefe der Ordnerstruktur 0=unlimited
    -t [string] Typ: (O)rdner (d)atein (b)eides
    -o [string] Output: (T)xt (x)ml
    -f [string] Format: (D)irekt (g)ruppiert (b)eides
    -h diese Hilfe"
if ($h) {
    Write-Host "Hilfe:" $myinputs
    exit
}
if ($DebugPreference) {
    $DebugPreference = 'Continue'
    Write-Debug "*DEEP VOCE* Epic-Debug-Modus activated`n"
    $testingMode = $true
    $n = 0
    $t = "o"
    $o = "t"
    $f = "d"
} else { 
    $testingMode = $false 
}
###############################
##   END HELP AND PRESETS    ##
###############################
###############################
##      START FUNCTIONS      ##
###############################

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
    if (-not $path) {
        return $false
    }
    if (-not (Test-Path -Path $path -PathType Container)) {
        Write-Host "Path not valid -" $path
        return $false
    }
    return $true
}

# GUI Sheit
function Show-PathDialog {
    param (
        [string]$Prompt = "GUI isch schu was nerviges aber besser als nix"
    )
    Add-Type -AssemblyName System.Windows.Forms
    # Öffne den Dialog zur Auswahl eines Pfads
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Prompt
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer

    # Zeige den Dialog an und speichere das Ergebnis
    $result = $folderBrowser.ShowDialog()

    # Überprüfe, ob der Dialog erfolgreich war
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    } else {
        return $null
    }
}

# Get-Permissions
function Get-Permissions {
    param (
        [string]$runPath,
        [int]$depth = 0,
        [string]$type,
        [string]$format,
        [string]$outPath
    )

    $result = @()
    $date = Get-Date
    $date = $date.ToString("yyMMdd-HHmm")
    $outputFile = $outPath + "\perout_" + $date + ".txt"
    if ($depth -eq 0) {
        $folders = Get-ChildItem -Path $runPath -Recurse
    } else {
        $folders = Get-ChildItem -Path $runPath -Recurse -Depth $depth
    }
    New-Item -ItemType file -Path $outputFile -Force | Out-Null
    foreach ($folder in $folders) {
        $result = @()
        if ($folder.PSIsContainer -and ($type -eq "o" -or $type -eq "b")) {
            $acl = Get-Acl -Path $folder.FullName
            $permissionString = $acl.Access | ForEach-Object {
                $_.IdentityReference.Value + "(" + $_.FileSystemRights + ")"
            }
            $result = "$($folder.Name) - $($permissionString -join ', ') - $($folder.FullName)"
            Write-Host "$($folder.Name) - $($permissionString -join ', ') - $($folder.FullName)"
        } elseif (-not $folder.PSIsContainer -and ($type -eq "d" -or $type -eq "b")) {
            $acl = Get-Acl -Path $folder.FullName
            $permissionString = $acl.Access | ForEach-Object {
                $_.IdentityReference.Value + "(" + $_.FileSystemRights + ")"
            }
            $result = "$($folder.Name) - $($permissionString -join ', ') - $($folder.FullName)`n"
        }
        $result | Out-File -FilePath $outputFile -Encoding UTF8 -Append
    }

    return $outputFile
}


###############################
##       END FUNCTIONS       ##
###############################
###############################
###############################
##       START INPUTS        ##
###############################

# 0. Admin Check
if (-not (Test-Admin)) {
    Write-Host "Sie haben nicht genügend Rechte, um das Skript mit erhöhten Rechten auszuführen."
    $continueAsAdmin = Read-Host "Trotzdem weitermachen? (Y/n)"
    if ($continueAsAdmin -eq "n" -or $continueAsAdmin -eq "N") {
        exit
    }
}

# 1. Was soll geprüft werden
$runHere = Read-Host "Soll das Skript hier ausgeführt werden? (Y/n/(g)ui)"
if ($runHere -eq "" -or $runHere -eq "y" -or $runHere -eq "Y") {
    $currentPath = $PSScriptRoot
} elseif ($runHere -eq "gui" -or $runHere -eq "g" -or $runHere -eq "G") {
    $currentPath = Show-PathDialog -Prompt "Wo soll das Skript ausgeführt werden?"
} else {
    $currentPath = Read-Host "Wo denn dann?"
}
while (-not (Test-PathValidity -path $currentPath)) {
    $currentPath = Read-Host "Bitte noamal probieren"
}

# 2. Wo soll das Ergebnis gespeichert werden
$resultHere = Read-Host "Ergebnis hier speichern? (Y/n/(g)ui)"
if ($resultHere -eq "" -or $resultHere -eq "y" -or $resultHere -eq "Y") {
    $outputPath = $PSScriptRoot
} elseif ($resultHere -eq "gui" -or $resultHere -eq "g" -or $resultHere -eq "G") {
    $outputPath = Show-PathDialog -Prompt "Wo soll der Ergebnis gespeichert werden?"
} else {
    $outputPath = Read-Host "Wo denn dann?"
}
while (-not (Test-PathValidity -path $outputPath)) {
    $outputPath = Read-Host "Bitte noamal probieren"
}

# 3. Settings Check
if ($args.Count -eq 0) {
    Write-Host "Ohne Argumente ausgeführt - default Werte verwendet" $myinputs
} else {
    Write-Host "Mit folgenden Argumenten ausgeführt: $args"
}

# 4. Feedback
Write-Host "Pfad zum Prüfen:" $currentPath
Write-Host "Pfad zum Speichern:" $outputPath
Write-Host "Settings: -n $n -t $t -o $o -f $f"

###############################
##        END INPUTS         ##
###############################
###############################
###############################
##        START MAIN         ##
###############################

$confirm = Read-Host "Soll das Skript ausgeführt werden? (y/N)"
if ($confirm -eq "y" -or $confirm -eq "Y" -or $testingMode) {
    $startTime = Get-Date

    # Differenz berechnen

    $outputLocation = Get-Permissions -runPath $currentPath -depth $n -type $t -format $o -outPath $outputPath
    #Write-Host $permissions
    $endTime = Get-Date
    $executionTime = New-TimeSpan $startTime $endTime
    Write-Host "`nFertig! Dauer: $executionTime `nWurde unter" $outputLocation "gespeichert."
} else {
    exit
}

###############################
##         END MAIN          ##
###############################    