param(
    [string] $OutputPath = 'docs/reference/RESOURCE_CATALOG.md'
)

$resourceRoots = @('mods/deathmatch/resources', 'mods/deathmatch/resource-archive')
$manifestFiles = foreach ($resourceRoot in $resourceRoots) {
    Get-ChildItem -LiteralPath $resourceRoot -Recurse -Filter 'meta.xml' -File
}

$rows = foreach ($manifest in $manifestFiles) {
    $relativePath = [IO.Path]::GetRelativePath((Get-Location).Path, $manifest.FullName).Replace('\', '/')
    $metadata = $null
    try {
        $metadata = [xml](Get-Content -LiteralPath $manifest.FullName -Raw)
    } catch {
        # Preserve malformed manifests in the catalog; their parse failure must be fixed separately.
    }

    $info = if ($metadata) { $metadata.SelectSingleNode('/meta/info') } else { $null }
    $resourceDirectory = Split-Path -Leaf (Split-Path -Parent $manifest.FullName)
    $group = Split-Path -Leaf (Split-Path -Parent (Split-Path -Parent $manifest.FullName))
    if ($group -in @('resources', 'resource-archive')) { $group = 'core' }

    if ($info -and $info.GetAttribute('description')) {
        $description = $info.GetAttribute('description')
    } elseif ($info -and $info.GetAttribute('name')) {
        $description = $info.GetAttribute('name')
    } else {
        $description = 'No description declared in meta.xml; source-level purpose review pending.'
    }

    $serverScripts = if ($metadata) { $metadata.SelectNodes('/meta/script[@type="server"]').Count } else { 0 }
    $clientScripts = if ($metadata) { $metadata.SelectNodes('/meta/script[@type="client"]').Count } else { 0 }
    $treeStatus = if ($manifest.FullName -match '[\\/]resource-archive[\\/]') { 'Archived' } else { 'Active tree' }

    [pscustomobject]@{
        Group = $group
        Resource = $resourceDirectory
        State = $treeStatus
        Path = $relativePath
        Description = $description
        ServerScripts = $serverScripts
        ClientScripts = $clientScripts
    }
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Resource catalog')
$lines.Add('')
$lines.Add('Generated from every checked-in manifest under the active resource tree and `resource-archive`. Manifest descriptions and script counts are metadata facts. Where a manifest has no description, the entry explicitly says source-level purpose review is pending. This is a complete manifest catalog, not a claim that every resource already has player/staff/operator instructions or runtime verification.')
$lines.Add('')
$lines.Add('## Documentation status')
$lines.Add('')
$lines.Add('Audience guides: [Player Wiki](../guides/PLAYER_WIKI.md), [Staff and Admin](../guides/STAFF_ADMIN_GUIDE.md), and [Server Operator](../guides/SERVER_OPERATOR_GUIDE.md). Detailed reviews are collected in the [resource dossier index](../resources/README.md). Each resource needs separate player, staff, operator, source-review, and runtime-validation statuses. `Active tree` means present under resources, not necessarily configured to start; `Archived` means stored outside the active tree.')
$lines.Add('')
$lines.Add('Detailed vehicle-domain dossiers now cover `vehicle`, `vehicle_fuel`, `vehicle-interiors`, `vehicle_load`, `vehicle_manager`, `carradio`, `carshop-system`, and `vehicleplate`; each links its matching `Script Resources` Discussion. Earlier individual topics cover `global`, `account`, `bank`, `factions`, and `item-system`. Coverage remains incomplete and is tracked by [Issue #95](https://github.com/itschase/OwlMTA-2026/issues/95).')
$lines.Add('')
$lines.Add('The first operator-infrastructure batch covers `mysql`, `data`, `pool`, `integration`, `cache`, and `logs`, including their implicit startup/data-flow contract and runtime-unverified failure paths.')
$lines.Add('')
$lines.Add('The communication and social batch covers `phone`, `chat-system`, `advertisements`, `social`, and `announcement` with full manifest-script source reviews and matching `Script Resources` Discussions. The reviews distinguish client-presented prerequisites from server-enforced invariants, identify the archive-only `business` dependency exposed by active chat code, and remain runtime-unverified.')
$lines.Add('')
$lines.Add('## Every resource manifest')
$lines.Add('')
$lines.Add('| Group | Resource | Tree status | Server scripts | Client scripts | Manifest purpose | Manifest |')
$lines.Add('|---|---|---:|---:|---:|---|---|')

foreach ($row in ($rows | Sort-Object State, Group, Resource)) {
    $description = ($row.Description -replace '\|', '\\|') -replace '\r?\n', ' '
    $lines.Add("| $($row.Group) | ``$($row.Resource)`` | $($row.State) | $($row.ServerScripts) | $($row.ClientScripts) | $description | ``$($row.Path)`` |")
}

$lines.Add('')
$lines.Add('## Coverage rule')
$lines.Add('')
$lines.Add('A resource is not complete in the documentation project until its purpose and dependencies are source-reviewed; player commands and prerequisites are documented or marked not applicable; staff authority is documented or marked not applicable; operator configuration/startup/data/logging are documented; and runtime status is stated explicitly. Archived source must be distinguished from a feature available to players.')
Set-Content -LiteralPath $OutputPath -Value $lines -Encoding utf8

Write-Output "Cataloged $($rows.Count) manifests ($(@($rows | Where-Object State -eq 'Active tree').Count) active-tree, $(@($rows | Where-Object State -eq 'Archived').Count) archived)."
