# Vigilante: cada 30 segundos verifica que tool.exe siga corriendo y lo relanza si se detuvo.
# Si detecta mas de una instancia de tool.exe, mata las sobrantes para evitar
# peleas de conexion en el servidor (dos agentes con mismo deviceName se patean entre si).

# Evita watchdogs duplicados: este vigilante tampoco debe correr mas de una vez.
$watchdogName = 'SystemToolsWatchdog'
$me = Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'watchdog\.ps1' -and $_.ProcessId -ne $PID }
foreach ($other in $me) {
    Stop-Process -Id $other.ProcessId -Force -ErrorAction SilentlyContinue
}

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$exe = Join-Path $dir 'tool.exe'

while ($true) {
    # Mata cualquier agente Python viejo (agent.py) que pudiera quedar y causar conflicto.
    Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'agent\.py' } | ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
    }

    # Cuenta cuantas instancias de tool.exe hay.
    $running = @(Get-CimInstance Win32_Process -Filter "Name='tool.exe'" -ErrorAction SilentlyContinue)

    if ($running.Count -gt 1) {
        # Duplicados: deja solo la primera (la mas antigua), mata las demas.
        $keep = $running | Sort-Object ProcessId | Select-Object -First 1
        foreach ($p in $running) {
            if ($p.ProcessId -ne $keep.ProcessId) {
                Stop-Process -Id $p.ProcessId -Force -ErrorAction SilentlyContinue
            }
        }
        Write-Host "Watchdog: se encontraron $($running.Count) instancias de tool.exe, se dejo solo PID $($keep.ProcessId)"
    } elseif ($running.Count -eq 0) {
        # No hay ninguna: lanzamos una oculta.
        Start-Process -FilePath $exe -WorkingDirectory $dir -WindowStyle Hidden
        Write-Host "Watchdog: tool.exe no estaba corriendo, se relanzo oculto"
    }

    Start-Sleep -Seconds 30
}