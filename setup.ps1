# FLOP Agent Kit - Windows one-command setup
# Usage (PowerShell): powershell -ExecutionPolicy Bypass -File .\setup.ps1

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$WorkDir = $PSScriptRoot
$AgentScript = Join-Path $WorkDir 'flop_agent.py'
$KeyFile = Join-Path $WorkDir 'agent_key.json'

function Write-Status {
    param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Cyan)
    Write-Host $Message -ForegroundColor $Color
}

function Invoke-AgentPython {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    & $script:PythonExe @script:PythonPrefix @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Python command failed with exit code $LASTEXITCODE."
    }
}

Write-Host ''
Write-Status '==================================================' Green
Write-Status ' FLOP Agent Kit - Windows Setup' Green
Write-Status '==================================================' Green
Write-Host ''

if (-not (Test-Path -LiteralPath $AgentScript)) {
    throw "flop_agent.py was not found in $WorkDir. Run this script from the repository folder."
}

if (Get-Command python -ErrorAction SilentlyContinue) {
    $PythonExe = 'python'
    $PythonPrefix = @()
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $PythonExe = 'py'
    $PythonPrefix = @('-3')
} else {
    Write-Status '[!] Python 3 was not found.' Red
    Write-Host 'Install Python 3.8+ from https://www.python.org/downloads/windows/'
    Write-Host 'During installation, select “Add python.exe to PATH”, then run this script again.'
    exit 1
}

Write-Status "[OK] Using Python: $((& $PythonExe @PythonPrefix --version) 2>&1)" Green

Write-Status '[*] Installing/checking PyNaCl...'
try {
    Invoke-AgentPython -m pip install --user --quiet pynacl
    Invoke-AgentPython -c 'import nacl; print("[OK] PyNaCl is ready")'
} catch {
    Write-Status "[!] Could not install PyNaCl: $($_.Exception.Message)" Red
    Write-Host 'Try manually: python -m pip install --user pynacl'
    exit 1
}

Set-Location -LiteralPath $WorkDir
Write-Host ''
if (Test-Path -LiteralPath $KeyFile) {
    Write-Status '[*] Existing agent_key.json found. Your existing DID will be reused.' Yellow
} else {
    Write-Status '[*] No key found. A new Ed25519 DID will be created.' Yellow
}

try {
    Invoke-AgentPython $AgentScript run-all
} catch {
    Write-Status "[!] Setup did not finish: $($_.Exception.Message)" Red
    Write-Host ''
    Write-Host 'If Technocore returned HTTP 502/503 or timed out, the server may be unavailable.'
    Write-Host 'Wait a few minutes, then run this command again. The existing key will be reused.'
    exit 1
}

Write-Host ''
Write-Status '==================================================' Green
Write-Status ' Setup completed' Green
Write-Status '==================================================' Green
Write-Status "Private key file: $KeyFile" Yellow
Write-Status 'Back up agent_key.json securely. Never upload, commit, or share it.' Yellow
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Publish a genuinely useful public guide, tool, video, or post.'
Write-Host '  2. Run: python flop_agent.py contribute'
Write-Host '  3. Paste the public contribution URL and a short topic.'
