# Vigilante: cada 30 segundos verifica que tool.exe siga corriendo y lo relanza si se detuvo.
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $dir 'tool.exe'
while ($true) {
    # Si quedo un agente Python viejo (agent.py) en conflicto, lo terminamos para evitar duplicados.
    Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'agent\.py' } | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }
    $running = Get-CimInstance Win32_Process -Filter "Name='tool.exe'" -ErrorAction SilentlyContinue
    if (-not $running) {
        Start-Process -FilePath $exe -WorkingDirectory $dir -WindowStyle Hidden
    }
    Start-Sleep -Seconds 30
}