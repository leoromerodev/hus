# Directorio donde se guardará el archivo CSV
$directorio = "C:\ramas"

# Verificar si el directorio existe, si no existe, crearlo
if (-not (Test-Path $directorio)) {
    New-Item -ItemType Directory -Path $directorio | Out-Null
}

# Nombre del archivo CSV con formato AAAAMMDDhhmmss.csv
$nombreArchivo = "ramas_" + (Get-Date).ToString("yyyyMMddHHmmss") + ".csv"
$rutaCompleta = Join-Path -Path $directorio -ChildPath $nombreArchivo

# Imprimir encabezado
$encabezado = "Contador, Fecha de Creación, Último Commit, Autor, Descripción, Nombre de la Rama, Rama Base"
$encabezado | Out-File -FilePath $rutaCompleta -Encoding UTF8

# Obtener todas las ramas locales y remotas, excluyendo las especificadas
$ramas = git branch --all --format="%(refname:short)" | ForEach-Object { $_.Trim() } | Where-Object { $_ -notmatch "^($excluirRama1|$excluirRama2|$excluirRama3|$excluirRama4|$excluirRama5)$" }

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

    # Incrementar el contador
    $contador++
}

Write-Output "El archivo CSV se ha guardado en: $rutaCompleta"
