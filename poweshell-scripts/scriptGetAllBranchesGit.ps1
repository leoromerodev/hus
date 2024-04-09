# Obtener todas las ramas locales
$ramasLocales = git branch --format="%(refname:short)" | ForEach-Object { $_.Trim() }

# Obtener todas las ramas remotas
$ramasRemotas = git branch -r --format="%(refname:short)" | ForEach-Object { $_.Trim() }

# Concatenar las ramas locales y remotas
$ramas = $ramasLocales + $ramasRemotas

foreach ($rama in $ramas) {
    # Obtener la fecha de creación de la rama
    $fechaCreacion = git log --pretty=format:"%cd" --date=iso --reverse --no-merges $rama | Select-Object -First 1
    # Obtener la rama base
    $ramaBase = git merge-base master $rama

    # Imprimir la fecha de creación, nombre de la rama y rama base
    Write-Output "$fechaCreacion | $rama | $ramaBase"
}