param(
    [string] $InventoryPath = "RESOURCE_INVENTORY.csv",
    [string] $OutputPath = "RESOURCE_DOCUMENTATION_STATUS.csv"
)

$published = @{
    "global" = @{ Number = 73; Dossier = "docs/resources/global.md"; State = "Full manifest-script source review; individual Discussion published" }
    "account" = @{ Number = 99; Dossier = "docs/resources/account.md"; State = "Full manifest-script source review; individual Discussion published" }
    "bank" = @{ Number = 100; Dossier = "docs/resources/bank.md"; State = "Full manifest-script source review; individual Discussion published" }
    "factions" = @{ Number = 101; Dossier = "docs/resources/factions.md"; State = "Full manifest-script source review; individual Discussion published" }
    "item-system" = @{ Number = 102; Dossier = "docs/resources/item-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "vehicle" = @{ Number = 107; Dossier = "docs/resources/vehicle.md" }
    "vehicle_fuel" = @{ Number = 108; Dossier = "docs/resources/vehicle_fuel.md" }
    "vehicle-interiors" = @{ Number = 109; Dossier = "docs/resources/vehicle-interiors.md" }
    "vehicle_load" = @{ Number = 110; Dossier = "docs/resources/vehicle_load.md" }
    "vehicle_manager" = @{ Number = 111; Dossier = "docs/resources/vehicle_manager.md" }
    "carradio" = @{ Number = 115; Dossier = "docs/resources/carradio.md"; State = "Full manifest-script source review; individual Discussion published" }
    "carshop-system" = @{ Number = 116; Dossier = "docs/resources/carshop-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "vehicleplate" = @{ Number = 117; Dossier = "docs/resources/vehicleplate.md"; State = "Full manifest-script source review; individual Discussion published" }
    "mysql" = @{ Number = 123; Dossier = "docs/resources/mysql.md"; State = "Full manifest-script source review; individual Discussion published" }
    "data" = @{ Number = 124; Dossier = "docs/resources/data.md"; State = "Full manifest-script source review; individual Discussion published" }
    "pool" = @{ Number = 125; Dossier = "docs/resources/pool.md"; State = "Full manifest-script source review; individual Discussion published" }
    "integration" = @{ Number = 126; Dossier = "docs/resources/integration.md"; State = "Full manifest-script source review; individual Discussion published" }
    "cache" = @{ Number = 127; Dossier = "docs/resources/cache.md"; State = "Full manifest-script source review; individual Discussion published" }
    "logs" = @{ Number = 128; Dossier = "docs/resources/logs.md"; State = "Full manifest-script source review; individual Discussion published" }
    "phone" = @{ Number = 135; Dossier = "docs/resources/phone.md"; State = "Full manifest-script source review; individual Discussion published" }
    "chat-system" = @{ Number = 136; Dossier = "docs/resources/chat-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "advertisements" = @{ Number = 137; Dossier = "docs/resources/advertisements.md"; State = "Full manifest-script source review; individual Discussion published" }
    "social" = @{ Number = 138; Dossier = "docs/resources/social.md"; State = "Full manifest-script source review; individual Discussion published" }
    "announcement" = @{ Number = 139; Dossier = "docs/resources/announcement.md"; State = "Full manifest-script source review; individual Discussion published" }
    "anticheat" = @{ Number = 174; Dossier = "docs/resources/anticheat.md"; State = "Full manifest-script source review; individual Discussion published" }
    "anti-cmdspam" = @{ Number = 175; Dossier = "docs/resources/anti-cmdspam.md"; State = "Full manifest-script source review; individual Discussion published" }
    "serialwhitelist" = @{ Number = 176; Dossier = "docs/resources/serialwhitelist.md"; State = "Full manifest-script source review; individual Discussion published" }
    "bans" = @{ Number = 177; Dossier = "docs/resources/bans.md"; State = "Full manifest-script source review; individual Discussion published" }
    "admin-system" = @{ Number = 178; Dossier = "docs/resources/admin-system.md" }
    "payday" = @{ Number = 196; Dossier = "docs/resources/payday.md"; State = "Full manifest-script source review; individual Discussion published" }
    "business-system" = @{ Number = 197; Dossier = "docs/resources/business-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "prison-system" = @{ Number = 198; Dossier = "docs/resources/prison-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "camera-system" = @{ Number = 199; Dossier = "docs/resources/camera-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "mdc" = @{ Number = 200; Dossier = "docs/resources/mdc.md"; State = "Full manifest-script source review; individual Discussion published" }
    "saveplayer-system" = @{ Number = 232; Dossier = "docs/resources/saveplayer-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "resources" = @{ Number = 233; Dossier = "docs/resources/resources.md"; State = "Full manifest-script source review; individual Discussion published" }
    "duty" = @{ Number = 234; Dossier = "docs/resources/duty.md"; State = "Full manifest-script source review; individual Discussion published" }
    "donators" = @{ Number = 235; Dossier = "docs/resources/donators.md"; State = "Full manifest-script source review; individual Discussion published" }
    "pd-system" = @{ Number = 236; Dossier = "docs/resources/pd-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "interior_system" = @{ Number = 237; Dossier = "docs/resources/interior_system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "usercontrolpanel" = @{ Number = 247; Dossier = "docs/resources/usercontrolpanel.md"; State = "Full manifest-script source review; individual Discussion published" }
    "insurance" = @{ Number = 248; Dossier = "docs/resources/insurance.md"; State = "Full manifest-script source review; individual Discussion published" }
    "job-system" = @{ Number = 249; Dossier = "docs/resources/job-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "tow-system" = @{ Number = 250; Dossier = "docs/resources/tow-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "item-world" = @{ Number = 251; Dossier = "docs/resources/item-world.md"; State = "Full manifest-script source review; individual Discussion published" }
    "rightclick" = @{ Number = 252; Dossier = "docs/resources/rightclick.md"; State = "Full manifest-script source review; individual Discussion published" }
    "job-system-trucker" = @{ Number = 256; Dossier = "docs/resources/job-system-trucker.md"; State = "Full manifest-script source review; individual Discussion published" }
    "paynspray-system" = @{ Number = 257; Dossier = "docs/resources/paynspray-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "object-interaction" = @{ Number = 258; Dossier = "docs/resources/object-interaction.md"; State = "Full manifest-script source review; individual Discussion published" }
    "item-move" = @{ Number = 259; Dossier = "docs/resources/item-move.md"; State = "Full manifest-script source review; individual Discussion published" }
    "npc" = @{ Number = 262; Dossier = "docs/resources/npc.md"; State = "Full manifest-script source review; individual Discussion published" }
    "object-system" = @{ Number = 263; Dossier = "docs/resources/object-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "interior-manager" = @{ Number = 264; Dossier = "docs/resources/interior-manager.md"; State = "Full manifest-script source review; individual Discussion published" }
    "interior_keypad" = @{ Number = 265; Dossier = "docs/resources/interior_keypad.md"; State = "Full manifest-script source review; individual Discussion published" }
    "map_manager" = @{ Number = 266; Dossier = "docs/resources/map_manager.md"; State = "Full manifest-script source review; individual Discussion published" }
    "map_load" = @{ Number = 267; Dossier = "docs/resources/map_load.md"; State = "Full manifest-script source review; individual Discussion published" }
}

$inventoryByPath = @{}
foreach ($inventoryRow in (Import-Csv -LiteralPath $InventoryPath)) {
    $inventoryByPath[$inventoryRow.Path.Replace('\', '/')] = $inventoryRow
}

$manifestFiles = foreach ($resourceRoot in @('mods/deathmatch/resources', 'mods/deathmatch/resource-archive')) {
    Get-ChildItem -LiteralPath $resourceRoot -Recurse -Filter 'meta.xml' -File
}

$statusRows = foreach ($manifest in ($manifestFiles | Sort-Object FullName)) {
    $manifestPath = [IO.Path]::GetRelativePath((Get-Location).Path, $manifest.FullName).Replace('\', '/')
    $resource = Split-Path -Leaf (Split-Path -Parent $manifest.FullName)
    $record = $published[$resource]
    $isArchived = $manifestPath -like "*resource-archive*"
    $inventoryRow = $inventoryByPath[$manifestPath]
    $discussionNumber = if ($record) { [string] $record.Number } else { "" }

    [pscustomobject]@{
        Resource = $resource
        ManifestPath = $manifestPath
        TreeState = if ($isArchived) { "Archived" } else { "Active tree" }
        StartupSnapshot = if ($isArchived) { "Not applicable" } elseif ($inventoryRow) { $inventoryRow.Startup } else { "Unknown" }
        DiscussionNumber = $discussionNumber
        DiscussionURL = if ($record) { "https://github.com/itschase/OwlMTA-2026/discussions/$discussionNumber" } else { "" }
        DossierPath = if ($record) { $record.Dossier } else { "" }
        DocumentationState = if ($record) {
            if ($record.State) { $record.State } else { "Partial source review; individual Discussion published" }
        } else {
            "Cataloged only"
        }
        RuntimeState = "Unverified"
        NextAction = if ($record) { "Complete remaining source review and runtime gate" } else { "Complete dossier and publish Script Resources topic" }
    }
}

$statusRows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
Write-Output "Wrote $($statusRows.Count) resource documentation status rows to $OutputPath."
