param(
    [string]$rutaProyecto = "ruta/al/proyecto",
    [string]$ramasAuxiliaresBackup = "ruta/para/guardar/backups",
    [int]$mesesAtras = 2
)

# Función para realizar el backup de las ramas auxiliares
function BackupRamasAuxiliares {
    foreach ($rama in $ramasAuxiliares) {
        $backupPath = Join-Path $ramasAuxiliaresBackup $rama
        git checkout -b $ramaBackup $rama
        git push origin $ramaBackup
        git checkout $rama
    }
}

# Función para eliminar las ramas auxiliares
function EliminarRamasAuxiliares {
    foreach ($rama in $ramasAuxiliares) {
        git branch -d $rama
    }
}

# Función para hacer rollback de las ramas auxiliares
function RollbackRamasAuxiliares {
    foreach ($rama in $ramasAuxiliares) {
        git checkout $ramaBackup
        git push --force origin $rama
        git checkout dev
    }
}

# Obtenemos la lista de ramas auxiliares
$ramasAuxiliares = git branch --list "*/*" | ForEach-Object { $_ -replace "^\s*", "" }

# Verificamos si cada rama auxiliar está fusionada en la rama dev
foreach ($rama in $ramasAuxiliares) {
    $mergeBase = git merge-base dev $rama
    $fechaMergeBase = git show -s --format=%ci $mergeBase
    $fechaLimite = (Get-Date).AddMonths(-$mesesAtras)
    
    if ($fechaMergeBase -lt $fechaLimite) {
        Write-Host "La rama $rama está fusionada en dev y se fusionó antes de $fechaLimite"
        BackupRamasAuxiliares
        EliminarRamasAuxiliares
    }
}

# Generamos el log
Get-Date | Out-File -FilePath "ruta/para/guardar/log.txt" -Append

# Opción de rollback
$rollback = Read-Host "¿Deseas hacer rollback de las ramas auxiliares eliminadas? (Sí/No)"

if ($rollback.ToLower() -eq "sí") {
    RollbackRamasAuxiliares
    Write-Host "Rollback completado."
} else {
    Write-Host "No se realizó rollback."
}
