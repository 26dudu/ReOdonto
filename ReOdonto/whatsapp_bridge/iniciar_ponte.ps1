$raiz = Split-Path -Parent $PSScriptRoot
foreach ($linha in Get-Content (Join-Path $raiz "backend\.env")) {
    if ($linha -match '^\s*(WHATSAPP_NUMEROS_PERMITIDOS|WHATSAPP_NUMERO_DENTISTA|INTEGRACAO_API_KEY)\s*=\s*(.+)$') {
        Set-Item -Path "Env:$($Matches[1])" -Value $Matches[2].Trim()
    }
}
Set-Location $PSScriptRoot
node index.js
