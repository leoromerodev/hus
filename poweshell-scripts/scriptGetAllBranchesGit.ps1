param (
    # Directorio del repositorio de Git, predeterminado a la ubicación actual del script
    [string]$RutaRepositorio = (Get-Location).Path,
    
    # Directorio para guardar el archivo CSV
    [string]$Directorio = "C:\ramas",
    
    # Array de ramas a excluir
    [string[]]$ExcluirRamas = @("DEV", "release/COB", "SIT", "release/UAT", "master"),
    
    # Nombre base del archivo CSV
    [string]$NombreBaseArchivo = "ramas_"
)

# Función para crear el directorio si no existe
function CrearDirectorioSiNoExiste {
    param (
        [string]$path
    )
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Output "Directorio creado: $path"
    }
}

# Cambiar al directorio del repositorio
Push-Location $RutaRepositorio
Write-Output "Cambiando al directorio del repositorio: $RutaRepositorio"

# Verificar y crear el directorio del CSV si no existe
CrearDirectorioSiNoExiste -path $Directorio

# Extraer el nombre del último directorio de la ruta del repositorio
$nombreRepositorio = Split-Path -Path $RutaRepositorio -Leaf

# Nombre del archivo CSV con formato NombreRepositorio_AAAAMMDDhhmmss.csv
$nombreArchivo = $NombreBaseArchivo + $nombreRepositorio + "_" + (Get-Date).ToString("yyyyMMddHHmmss") + ".csv"
$rutaCompleta = Join-Path -Path $Directorio -ChildPath $nombreArchivo

# Imprimir encabezado
$encabezado = "Contador, Fecha de Creación, Último Commit, Autor, Descripción, Nombre de la Rama, Rama Base"
$encabezado | Out-File -FilePath $rutaCompleta -Encoding UTF8
Write-Output "Encabezado escrito en: $rutaCompleta"

# Patrón regex para las ramas a excluir
$exclusionPattern = "^(" + ($ExcluirRamas -join '|') + ")$"

# Obtener todas las ramas locales y remotas, excluyendo las especificadas
$ramas = git branch --all --format="%(refname:short)" | ForEach-Object { $_.Trim() } | Where-Object { $_ -notmatch $exclusionPattern }

# Inicializar contador
$contador = 1

foreach ($rama in $ramas) {
    # Saltar ramas duplicadas en remoto/local
    if ($rama.StartsWith("origin/") -and $ramas -contains $rama.Substring(7)) {
        continue
    }

    # Obtener la fecha de creación de la rama
    $fechaCreacion = git log --pretty=format:"%cd" --date=iso --reverse --no-merges $rama | Select-Object -First 1
    # Obtener la fecha del último commit en la rama, el autor y la descripción (mensaje)
    $ultimoCommitInfo = git log --pretty=format:"%cd|%an|%s" --date=iso --no-merges -1 $rama
    # Separar la información del último commit en fecha, autor y descripción
    $infoParts = $ultimoCommitInfo -split '\|'
    $ultimoCommitFecha = $infoParts[0]
    $ultimoCommitAutor = $infoParts[1]
    $ultimoCommitDescripcion = $infoParts[2]
    # Obtener la rama base, ajustar según la necesidad de cálculo de rama base
    $ramaBase = git merge-base master $rama

    # Construir la línea CSV
    $linea = "$contador, $fechaCreacion, $ultimoCommitFecha, `"$ultimoCommitAutor`", `"$ultimoCommitDescripcion`", `"$rama`", `"$ramaBase`""

    # Añadir la línea al archivo CSV
    $linea | Out-File -FilePath $rutaCompleta -Encoding UTF8 -Append
    Write-Output "Añadido: $linea"

    # Incrementar el contador
    $contador++
}

# Volver al directorio anterior
Pop-Location

Write-Output "El archivo CSV se ha guardado en: $rutaCompleta"
