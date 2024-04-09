param(
    [string]$rutaProyecto = "C:\miProyecto", # Actualiza esto con la ruta real de tu proyecto
    [string]$ramasAuxiliaresBackup = "C:\backupRamas", # Actualiza esto con la ruta real para los backups
    [string]$fechaCorte = "2024-02-01", # Ajusta esta fecha según necesites
    [string]$ramaDev = "DEV",
    [string]$ramaRelease = "release/UAT",
    [string]$ramaMaster = "master"
)

# Convertir la fechaCorte a un objeto DateTime para comparaciones
$fechaCorte = [datetime]::ParseExact($fechaCorte, "yyyy-MM-dd", $null)

# Cambiar al directorio del proyecto
Set-Location -Path $rutaProyecto

# Asegurar que tenemos la última información del remoto
git fetch --prune

# Listar todas las ramas remotas y sus fechas de creación, excluyendo las ramas protegidas
$ramasAuxiliares = git for-each-ref --format='%(refname:short) %(creatordate:short)' refs/remotes/origin |
    Where-Object {
        $_ -match "origin/.*/.*" -and
        $_ -notmatch "origin/$ramaDev" -and
        $_ -notmatch "origin/$ramaRelease" -and
        $_ -notmatch "origin/$ramaMaster"
    }

foreach ($linea in $ramasAuxiliares) {
    $parts = $linea -split ' ', 2
    $rama = $parts[0] -replace 'origin/', ''
    $fechaRama = [datetime]::ParseExact($parts[1], "yyyy-MM-dd", $null)

    if ($fechaRama -lt $fechaCorte) {
        # Verificar si la rama ya está fusionada con dev
        $isMerged = git branch -r --merged $ramaDev | Select-String -Pattern "\b$rama\b"

        if ($isMerged) {
            Write-Host "La rama $rama está fusionada en $ramaDev y fue creada antes de $fechaCorte. Realizando backup..."
            # Crear backup de la rama
            $ramaBackup = "$rama-backup"
            git checkout -b $ramaBackup origin/$rama
            git push origin $ramaBackup
            git checkout $ramaDev

            # Eliminar la rama remota
            Write-Host "Eliminando rama $rama..."
            git push origin --delete $rama
        }
        else {
            Write-Host "La rama $rama no está fusionada con $ramaDev. Se omite."
        }
    }
}
