# Function to get the structure of a recipe
function get-recipestructure 
{
  $Lines = Get-Content $psise.CurrentFile.FullPath
  $lineno = 0
  Foreach ($Line in $Lines) {  
    $Lineno++
    if ($line -match '^#') {
     "[{0,4}]  {1}" -F $lineno,$line
    }
  }
}

set-alias grs get-recipeStructure
grs