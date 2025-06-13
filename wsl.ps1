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

#Checking if WSL start working
$wslStatus = wsl echo "WSL"
if ($wslStatus -eq "WSL"){
    Write-Output "WSL works"
}

#Checking if docker run in WSL
Write-Host "Waiting for docker"
while (-not $dockerOutput) {
    $dockerOutput = wsl bash -l -c "docker ps" 2>$null
    
    if (-not $dockerOutput) {
        Write-Host "." -NoNewline 
        Start-Sleep -Seconds 1
    }
}

Write-Host "Docker works"

$tabs = @()

foreach ($item in $settings.folders) {
    $uniqueTitle = "$($item.title)"
    $color = $item.color
    $path = $item.path

    $tab = @(
        "nt",
        "--title", "`"$uniqueTitle`"",
        "--suppressApplicationTitle",
        "--tabColor", "`"$color`"",
        "-p", "`"Ubuntu`"",
        "--", "wsl", "--cd", $path 
        "--", "bash -l -c 'docker-compose up && exec bash'"
    ) -join " "

    $tabs += $tab
}

$allTabs = $tabs -join " ; "

Start-Process wt.exe -ArgumentList $allTabs