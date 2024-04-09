# Imprimir encabezado
Write-Output "Fecha de Creación | Último Commit | Nombre de la Rama | Rama Base"
Write-Output "---------------------------------------------------------------------"

# Obtener todas las ramas locales
$ramasLocales = git branch --format="%(refname:short)" | ForEach-Object { $_.Trim() }

# Obtener todas las ramas remotas
$ramasRemotas = git branch -r --format="%(refname:short)" | ForEach-Object { $_.Trim() }

# Concatenar las ramas locales y remotas
$ramas = $ramasLocales + $ramasRemotas

foreach ($rama in $ramas) {
    # Obtener la fecha de creación de la rama
    $fechaCreacion = git log --pretty=format:"%cd" --date=iso --reverse --no-merges $rama | Select-Object -First 1
    # Obtener la fecha del último commit en la rama
    $ultimoCommit = git log --pretty=format:"%cd" --date=iso --no-merges -1 $rama
    # Obtener la rama base
    $ramaBase = git merge-base master $rama

    # Imprimir la fecha de creación, fecha del último commit, nombre de la rama y rama base
    Write-Output "$fechaCreacion | $ultimoCommit | $rama | $ramaBase"
}
