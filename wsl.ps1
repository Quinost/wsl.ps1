$settingsFilePath = Join-Path -Path $PSScriptRoot -ChildPath "settings.json"
try {
    $raw = Get-Content -Path $settingsFilePath -Raw
    $settings = ConvertFrom-Json -InputObject $raw
}
catch {
    Write-Error "Error reading or parsing the settings.json file: $($_.Exception.Message)"
    exit
}

if (-not $settings.folders -or $settings.folders.Count -eq 0) {
    Write-Error "The settings.json file must contain a non-empty list"
    exit
}

foreach ($item in $settings.folders) {
    if (!(Test-Path -Path $item.path -PathType Container)) {
        Write-Error "Folder '$item' does not exist."
        exit
    }
}

function Generate-RandomString {
    $length = 3
    $chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    -join ((1..$length) | ForEach-Object { $chars[(Get-Random -Minimum 0 -Maximum $chars.Length)] })
}

function Convert-WindowsPathToWSLPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WindowsPath
    )
    if ($WindowsPath -match "^([a-zA-Z]):\\") {
        $driveLetter = $Matches[1].ToLower()
        $wslPath = "/mnt/$driveLetter/" + ($WindowsPath -replace "^[a-zA-Z]:\\", "").Replace("\", "/")
        return $wslPath
    } else {
        Write-Warning "The path '$WindowsPath' does not appear to be a valid Windows path."
        return $WindowsPath
    }
}


$wslStatus = wsl echo "WSL"
if ($wslStatus -eq "WSL"){
    Write-Output "WSL works"
}

$dockerOutput = ""

Write-Host "Waiting for docker: "

while (-not $dockerOutput){
    $dockerOutput = wsl bash -l -c "docker ps" 2>$null

    if (-not $dockerOutput) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
}

Write-Output "Docker works"

$first = $true
$randomString = (Generate-RandomString)
$wshell = New-Object -ComObject WScript.Shell

foreach ($item in $settings.folders) {
    $uniqueTitle = $item.title + " - " + $randomString
    $color = $item.color
    Write-Host "Run" $uniqueTitle
    
    if ($first) {
        $null = Start-Process wt -ArgumentList "--title `"$uniqueTitle`" --suppressApplicationTitle --tabColor `"$color`" -p `"Ubuntu`"" -PassThru
        $first = $false
    } else {
        $null = Start-Process wt -ArgumentList "-w 0 nt --title `"$uniqueTitle`" --suppressApplicationTitle --tabColor `"$color`" -p `"Ubuntu`"" -PassThru
    }
    
    do {
        Start-Sleep -Milliseconds 100
        $activeWindows = Get-Process | Where-Object { $_.MainWindowTitle -match $uniqueTitle }
    } until ($activeWindows.Count -gt 0)
    

    $wshell.AppActivate($uniqueTitle)
    $wslPath = Convert-WindowsPathToWSLPath -WindowsPath $item.path
    $wshell.SendKeys("cd $wslPath && clear && docker-compose up{ENTER}")
}