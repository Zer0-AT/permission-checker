[CmdletBinding()]
param (
    [int]$n = 0,
    [string]$t = "b",
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
    -t [string] Typ: (o)rdner (d)atein (B)eides
    -o [string] Output: (T)xt (x)ml
    -f [string] Format: (D)irekt (g)ruppiert (b)eides
    -h diese Hilfe"
if ($h) {
    Write-Host "Hilfe:" $myinputs
    exit
}
if ($testing) {
    $n = 2
    $t = "b"
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
        [string]$path,
        [int]$depth = 0,
        [string]$type
    )

    $result = @()

    if ($depth -eq 0) {
        $folders = Get-ChildItem -Path $path -Recurse
    }
    else {
        $folders = Get-ChildItem -Path $path -Recurse -Depth $depth
    }

    foreach ($folder in $folders) {
        if ($folder.PSIsContainer -and ($type -eq "o" -or $type -eq "b")) {
            $acl = Get-Acl -Path $folder.FullName
            $permissionString = $acl.Access | ForEach-Object {
                $_.IdentityReference.Value + "(" + $_.FileSystemRights + ")"
            }
            $result += "$($folder.Name) - $($permissionString -join ', ') - $($folder.FullName)`n"
        }
        elseif (-not $folder.PSIsContainer -and ($type -eq "d" -or $type -eq "b")) {
            $acl = Get-Acl -Path $folder.FullName
            $permissionString = $acl.Access | ForEach-Object {
                $_.IdentityReference.Value + "(" + $_.FileSystemRights + ")"
            }
            $result += "$($folder.Name) - $($permissionString -join ', ') - $($folder.FullName)`n"
        }
    }

    return $result
}

# Save-Permissions
function Save-Permissions {
    param (
        [string]$format = "t",
        [string]$path,
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
elseif ($runHere -eq "gui") {
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
elseif ($resultHere -eq "gui") {
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
    $permissions = Get-Permissions -path $currentPath -depth $n -type $t
    #Write-Host $permissions
    Save-Permissions -format $o -outputPath $outputPath -permissions $permissions
    Write-Host "Fertig! Und wurde unter $outputFile $fileName gespeichert."
}
else {
    exit
}