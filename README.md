# Windows Terminal Automation Script

## Overview
This script automates the process of launching Docker Compose environments in Windows Subsystem for Linux (WSL) through Windows Terminal.

## Features
- Automatically opens Windows Terminal
- Creates multiple tabs based on your `settings.json` configuration
- Launches Ubuntu WSL in each tab
- Executes a predefined sequence of commands:
  - Navigates to the specified directory
  - Clears the terminal
  - Runs `docker-compose up`

## Usage
You can run the script in two ways:

### 1. Direct PowerShell Execution
```powershell
./YourScriptName.ps1
```

### 2. Batch File Execution
1. Open `RunPS.bat` in a text editor
2. Update the script path in the `.bat` file
3. Double-click the `.bat` file to run

## Customization

### Command Customization
You can customize the commands run in each tab by modifying the `SendKeys` section in the script:

```powershell
$wshell.SendKeys("<your-command>{ENTER}")
```

For example, replace `docker-compose up` with your desired command.

### Terminal Profile Selection
You can change the Windows Terminal profile used for new tabs by modifying the `-p` parameter in the `Start-Process` command:

```powershell
Start-Process wt -ArgumentList '-p "Ubuntu"'
```

Replace `"Ubuntu"` with any profile name from your Windows Terminal settings (e.g., `"PowerShell"`, `"Command Prompt"`, `"Git Bash"`).