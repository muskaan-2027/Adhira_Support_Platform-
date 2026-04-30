param(
    [int]$Port = 5000
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendPath = Join-Path $projectRoot "Backend"
$frontendPath = Join-Path $projectRoot "frontend"
$apiBaseUrl = "http://127.0.0.1:$Port"

if (!(Test-Path $backendPath)) {
    throw "Backend folder not found at: $backendPath"
}

if (!(Test-Path $frontendPath)) {
    throw "frontend folder not found at: $frontendPath"
}

Write-Host ""
Write-Host "Run these commands manually in Windows PowerShell."
Write-Host "Backend and frontend should use the same port."
Write-Host ""
Write-Host "1) Backend terminal:"
Write-Host ("cd `"{0}`"" -f $backendPath)
Write-Host "npm install"
Write-Host "if (!(Test-Path .env)) { Copy-Item .env.example .env }"
Write-Host ("`$env:PORT={0}" -f $Port)
Write-Host "npm run dev"
Write-Host ""
Write-Host "2) Frontend terminal:"
Write-Host ("cd `"{0}`"" -f $frontendPath)
Write-Host "flutter pub get"
Write-Host ("flutter run -d chrome --dart-define=API_BASE_URL={0}" -f $apiBaseUrl)
Write-Host ""
Write-Host "Optional (new terminal): set Groq key if you do not want fallback chatbot replies."
Write-Host ("setx GROQ_API_KEY `"your_groq_key`"")
Write-Host ""
Write-Host ("Note: If backend runs on a different port, update API_BASE_URL to match (current: {0})." -f $apiBaseUrl)
