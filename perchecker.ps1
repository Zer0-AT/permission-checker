[CmdletBinding()]
param (
    [int]$n = 0,
    [string]$t = "o",
    [string]$o = "t",
    [string]$f = "d",
    [switch]$testing,
    [switch]$h
)

<#
    HELP
#>
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
if ($testing) {
    $n = 0
    $t = "o"
    $o = "t"
    $f = "d"
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
        [string]$Prompt = "GUI isch schu was nerviges aber besser als nix",
        [string]$InitialDirectory = $env:USERPROFILE
    )

    # Öffne den Dialog zur Auswahl eines Pfads
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Prompt
    $folderBrowser.SelectedPath = $InitialDirectory
    $folderBrowser.RootFolder = [System.Environment+SpecialFolder]::MyComputer

    # Zeige den Dialog an und speichere das Ergebnis
    $result = $folderBrowser.ShowDialog()

    # Überprüfe, ob der Dialog erfolgreich war
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    }
    else {
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
    }
    else {
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
        }
        elseif (-not $folder.PSIsContainer -and ($type -eq "d" -or $type -eq "b")) {
            $acl = Get-Acl -Path $folder.FullName
            $permissionString = $acl.Access | ForEach-Object {
                $_.IdentityReference.Value + "(" + $_.FileSystemRights + ")"
            }
            $result = "$($folder.Name) - $($permissionString -join ', ') - $($folder.FullName)`n"
        }
        $result | Out-File -FilePath $outputFile -Encoding UTF8 -Append
    }

    return $result
}

# Save-Permissions
function Save-Permissions {
    param (
        [string]$format = "t",
        [string]$runPath,
        [string]$permissions
    )
    $outputPath = $PSScriptRoot
    $date = Get-Date
    $date = $date.ToString("yyMMdd-HHmm")
    $outputFile = $outputPath + "\perout_" + $date + ".txt"
    if ($format -eq "t" -or $format -eq "T") {
        $permissions | Out-File -FilePath $outputFile -Encoding UTF8
    }
    elseif ($format -eq "x" -or $format -eq "X") {
        #$permissions | Out-File -FilePath $outputPath -Encoding UTF8
        # XML-Formatierung hier hinzufuegen
        Write-Warning "Not implemented yet"
    }
    else {
        Write-Host "Ungueltiges Format angegeben."
    }
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
$runHere = Read-Host "Soll das Skript hier ausgefuehrt werden? (Y/n/(g)ui)"
if ($runHere -eq "" -or $runHere -eq "y" -or $runHere -eq "Y") {
    $currentPath = $PSScriptRoot
}
elseif ($runHere -eq "gui" -or $runHere -eq "g" -or $runHere -eq "G") {
    $currentPath = Show-PathDialog
}
else {
    $currentPath = Read-Host "Wo denn dann?"
}
while (-not (Test-PathValidity -path $currentPath)) {
    $currentPath = Read-Host "Bitte noamal probieren"
}

# 2. wohin
$resultHere = Read-Host "Ergebnis hier speichern? (Y/n/(g)ui)"
if ($resultHere -eq "" -or $resultHere -eq "y" -or $resultHere -eq "Y") {
    $outputPath = $PSScriptRoot
}
elseif ($resultHere -eq "gui" -or $resultHere -eq "g" -or $resultHere -eq "G") {
    $outputPath = Show-PathDialog
}
else {
    $outputPath = Read-Host "Wo denn dann?"
}
while (-not (Test-PathValidity -path $outputPath)) {
    $outputPath = Read-Host "Bitte noamal probieren"
}

# 3. Settings
if ($args.Count -eq 0) {
    Write-Host "Ohne Argumente ausgefuehrt - default Werte verwendet" $myinputs
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
if ($confirm -eq "y" -or $confirm -eq "Y" -or $testing) {
    $startTime = Get-Date

    # Differenz berechnen

    $permissions = Get-Permissions -runPath $currentPath -depth $n -type $t -format $o -outPath $outputPath
    #Write-Host $permissions
    #Save-Permissions -format $o -outputPath $outputPath -permissions $permissions
    $endTime = Get-Date
    $executionTime = New-TimeSpan $startTime $endTime

    Write-Host "`nFertig! Dauer: $executionTime `nWurde unter" $outputFile $fileName "gespeichert."
}
else {
    exit
}