param(
    [string]$rutaProyecto = "C:\GitHub\Soccer-Performance", # Actualiza esto con la ruta real de tu proyecto
    [string]$ramasAuxiliaresBackup = "C:\backupRamas", # Actualiza esto con la ruta real para los backups
    [string]$fechaCorte = "2023-12-31", # Actualizado al 31 de diciembre de 2023
    [string]$ramaDev = "DEV",
    [string]$ramaReleaseUAT = "release/UAT",
    [string]$ramaMaster = "master",
    [string]$ramaSIT = "SIT",
    [string]$ramaReleaseCOB = "release/COB"
)

# Convertir la fechaCorte a un objeto DateTime para comparaciones
$fechaCorte = [datetime]::ParseExact($fechaCorte, "yyyy-MM-dd", $null)

# Verificar si la carpeta de registros existe y, si no, crearla
$carpetaRegistros = "C:\ramas"
if (-not (Test-Path $carpetaRegistros)) {
    New-Item -ItemType Directory -Path $carpetaRegistros | Out-Null
}

# Nombre del archivo CSV con formato AAAAMMDDhhmmss.csv
$nombreArchivoCSV = (Get-Date).ToString("yyyyMMddHHmmss") + ".csv"
$rutaArchivoCSV = Join-Path $carpetaRegistros $nombreArchivoCSV

# Crear el archivo CSV y escribir el encabezado
"Rama,CreadaAntesDe,FusionadaEnDev,Acción" | Out-File -FilePath $rutaArchivoCSV -Encoding utf8

# Función para registrar las acciones en el archivo CSV
function RegistrarLog($mensaje) {
    $mensaje | Out-File -FilePath $rutaArchivoCSV -Append -Encoding utf8
}

# Cambiar al directorio del proyecto
Set-Location -Path $rutaProyecto

# Asegurar que tenemos la última información del remoto
git fetch --prune

# Listar todas las ramas remotas y sus fechas de creación, excluyendo las ramas protegidas
$ramasAuxiliares = git for-each-ref --format='%(refname:short) %(creatordate:short)' refs/remotes/origin |
    Where-Object {
        $_ -match "origin/.*/.*" -and
        $_ -notmatch "origin/$ramaDev" -and
        $_ -notmatch "origin/$ramaReleaseUAT" -and
        $_ -notmatch "origin/$ramaMaster" -and
        $_ -notmatch "origin/$ramaSIT" -and
        $_ -notmatch "origin/$ramaReleaseCOB"
    }

foreach ($linea in $ramasAuxiliares) {
    $parts = $linea -split ' ', 2
    $rama = $parts[0] -replace 'origin/', ''
    $fechaRama = [datetime]::ParseExact($parts[1], "yyyy-MM-dd", $null)

    if ($fechaRama -lt $fechaCorte) {
        # Verificar si la rama ya está fusionada con dev
        $isMerged = git branch -r --merged $ramaDev | Select-String -Pattern "\b$rama\b"

        if ($isMerged) {
            Write-Host "La rama $rama está fusionada en $ramaDev y fue creada antes de $fechaCorte. Realizando backup y eliminación..."
            # Crear backup de la rama
            $ramaBackup = "$rama-backup"
            git checkout -b $ramaBackup origin/$rama
            git push origin $ramaBackup
            git checkout $ramaDev

            # Eliminar la rama remota
            Write-Host "Eliminando rama $rama..."
            git push origin --delete $rama
            
            # Registrar la acción en el archivo CSV
            RegistrarLog "$rama,$fechaRama,Sí,Backup y Eliminación"
        }
        else {
            Write-Host "La rama $rama no está fusionada con $ramaDev. Se omite."
            # Registrar la acción en el archivo CSV
            RegistrarLog "$rama,$fechaRama,No,Omitida"
        }
    }
}

Write-Host "Registro completado. Se ha guardado en $rutaArchivoCSV"
