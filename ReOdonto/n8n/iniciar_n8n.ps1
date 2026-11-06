$raiz = Split-Path -Parent $PSScriptRoot
$envFile = Join-Path $raiz "backend\.env"

foreach ($linha in Get-Content $envFile) {
    if ($linha -match '^\s*(INTEGRACAO_API_KEY|ANTHROPIC_API_KEY)\s*=\s*(.+)$') {
        Set-Item -Path "Env:$($Matches[1])" -Value $Matches[2].Trim()
    }
}

$env:N8N_BLOCK_ENV_ACCESS_IN_NODE = "false"
$env:REODONTO_API_URL = "http://127.0.0.1:5000"
if (-not $env:DENTISTA_ID_PADRAO) { $env:DENTISTA_ID_PADRAO = "1" }
if (-not $env:WEBHOOK_URL -and (Test-Path (Join-Path $PSScriptRoot ".webhook_url"))) {
    $env:WEBHOOK_URL = (Get-Content (Join-Path $PSScriptRoot ".webhook_url")).Trim()
}

npx -y n8n start
