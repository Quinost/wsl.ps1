$settingsFilePath = Join-Path -Path $PSScriptRoot -ChildPath "settings.json"
try {
    $raw = Get-Content -Path $settingsFilePath -Raw
    $settings = ConvertFrom-Json -InputObject $raw
}
catch {
    Write-Error "Error reading or parsing the settings.json file: $($_.Exception.Message)"
    exit
}

foreach ($item in $settings.folders) {
    if (!(Test-Path -Path $item.path -PathType Container)) {
        Write-Error "Folder '$item' does not exist."
        exit
    }
}

$wslStatus = wsl echo "WSL"
if ($wslStatus -eq "WSL") {
    Write-Output "WSL works"
}

Write-Host "Waiting for docker"
while ($true) {
    $dockerOutput = wsl bash -l -c "docker ps" 2>$null
    
    if (-not $dockerOutput) {
        Write-Host "." -NoNewline 
        Start-Sleep -Seconds 1
    }
    else {
        Write-Host "Docker works"
        break;
    }
}

$tabs = @()

foreach ($item in $settings.folders) {
    if (-not $item.enabled) {continue}

    $title = "$($item.title)"
    $color = $item.color
    $path = $item.path
    $terminalProfile = $settings.terminalProfile

    Write-Host "Running $title"

    $tab = @(
        "nt",
        "--title", "`"$title`"",
        "--suppressApplicationTitle",
        "--tabColor", "`"$color`"",
        "-p", "`"$terminalProfile`"",
        "--", "wsl", "--cd", $path 
        "--", "bash -l -c 'docker-compose up && exec bash'"
    ) -join " "

    $tabs += $tab
}

$allTabs = $tabs -join " ; "

Start-Process wt.exe -ArgumentList $allTabs