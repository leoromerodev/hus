param (
    [string]$RutaRepositorio = (Get-Location).Path,
    [string]$Directorio = "C:\ramas",
    [string[]]$ExcluirRamas = @("DEV", "release/COB", "SIT", "release/UAT", "master"),
    [string]$NombreBaseArchivo = "ramas_"
)

function CrearDirectorioSiNoExiste {
    param ([string]$path)
    if (-not (Test-Path $path)) {
        New-Item -ItemType Directory -Path $path | Out-Null
        Write-Output "Directorio creado: $path"
    }
}

Push-Location $RutaRepositorio
CrearDirectorioSiNoExiste -path $Directorio

$nombreRepositorio = Split-Path -Path $RutaRepositorio -Leaf
$nombreArchivo = $NombreBaseArchivo + $nombreRepositorio + "_" + (Get-Date).ToString("yyyyMMddHHmmss") + ".csv"
$rutaCompleta = Join-Path -Path $Directorio -ChildPath $nombreArchivo

$encabezado = "Contador, Fecha de Creacion, Ultimo Commit, Autor, Descripcion, Nombre de la Rama, Rama Base"
$encabezado | Out-File -FilePath $rutaCompleta -Encoding UTF8

$exclusionPattern = "^(" + ($ExcluirRamas -join '|') + ")$"
$ramas = git branch --all --format="%(refname:short)" | Where-Object { $_ -notmatch $exclusionPattern }

$contador = 1

foreach ($rama in $ramas) {
    if ($rama.StartsWith("origin/") -and $ramas -contains $rama.Substring(7)) { continue }
    
    $fechaCreacion = git log $rama --reverse --format="%ci" --no-merges | Select-Object -First 1
    $ultimoCommitInfo = git log $rama -1 --pretty=format:"%ci|%an|%s"
    $infoParts = $ultimoCommitInfo -split '\|'
    $ultimoCommitFecha = $infoParts[0]
    $ultimoCommitAutor = $infoParts[1]
    $ultimoCommitDescripcion = $infoParts[2]

    $hashBase = git merge-base master $rama
    $ramaBase = git show-ref | Where-Object { $_ -match $hashBase } | ForEach-Object { $_ -split ' ' } | Select-Object -First 1

    $linea = "$contador, $fechaCreacion, $ultimoCommitFecha, `"$ultimoCommitAutor`", `"$ultimoCommitDescripcion`", `"$rama`", `"$ramaBase`""
    $linea | Out-File -FilePath $rutaCompleta -Encoding UTF8 -Append
    $contador++
}

Pop-Location
Write-Output "El archivo CSV se ha guardado en: $rutaCompleta"
