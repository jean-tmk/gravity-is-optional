Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Test-GravitySchema {
    param([Parameter(Mandatory)][string]$DatabasePath)
    if (-not (Test-Path -LiteralPath $DatabasePath)) { throw "Gravity database not found: $DatabasePath" }
    $checks = @('pragma foreign_key_check;','select count(*) >= 8 from gravity_rules;','select count(*) >= 6 from object_catalog;','select count(*) >= 3 from missions;','select count(*) = 0 from gravity_rules where angle_degrees < 0 or angle_degrees >= 360;','select count(*) = 0 from gravity_rules where strength_percent not between 0 and 100;')
    $results = foreach ($sql in $checks) { $value = (& sqlite3 $DatabasePath $sql).Trim(); [pscustomobject]@{ Query=$sql; Passed=$value -in @('','1') } }
    if ($results.Passed -contains $false) { throw 'Gravity schema validation failed.' }
    return $results
}
Export-ModuleMember -Function Test-GravitySchema
