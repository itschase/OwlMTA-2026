param(
    [string] $InventoryPath = "RESOURCE_INVENTORY.csv",
    [string] $OutputPath = "RESOURCE_DOCUMENTATION_STATUS.csv"
)

$ErrorActionPreference = "Stop"

$published = @{
    "global" = @{ Number = 73; Dossier = "docs/resources/global.md"; State = "Full manifest-script source review; individual Discussion published" }
    "account" = @{ Number = 99; Dossier = "docs/resources/account.md"; State = "Full manifest-script source review; individual Discussion published" }
    "bank" = @{ Number = 100; Dossier = "docs/resources/bank.md"; State = "Full manifest-script source review; individual Discussion published" }
    "cards" = @{ Number = 356; Dossier = "docs/resources/cards.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "chance-system" = @{ Number = 362; Dossier = "docs/resources/chance-system.md"; State = "Full manifest-script source review; individual Discussion published" }
    "cockpit" = @{ Number = 365; Dossier = "docs/resources/cockpit.md"; State = "Full manifest-script source review; individual Discussion published" }
    "colorblender" = @{ Number = 366; Dossier = "docs/resources/colorblender.md"; State = "Full manifest and direct-caller source review; individual Discussion published" }
    "clubtec" = @{ Number = 369; Dossier = "docs/resources/clubtec.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "customblips" = @{ Number = 376; Dossier = "docs/resources/customblips.md"; State = "Full manifest and direct-caller source review; individual Discussion published" }
    "death" = @{ Number = 347; Dossier = "docs/resources/death.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "datetime" = @{ Number = 348; Dossier = "docs/resources/datetime.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "description" = @{ Number = 352; Dossier = "docs/resources/description.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "dancer-system" = @{ Number = 381; Dossier = "docs/resources/dancer-system.md"; State = "Full manifest and direct-caller source review; individual Discussion published" }
    "elections" = @{ Number = 378; Dossier = "docs/resources/elections.md"; State = "Full manifest and direct-caller source review; individual Discussion published" }
    "driveby" = @{ Number = 386; Dossier = "docs/resources/driveby.md"; State = "Full manifest/client/server/export source review; individual Discussion published" }
    "dynamic_lighting_flash" = @{ Number = 388; Dossier = "docs/resources/dynamic_lighting_flash.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
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
    "elevator-system" = @{ Number = 272; Dossier = "docs/resources/elevator-system.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "computers-system" = @{ Number = 283; Dossier = "docs/resources/computers-system.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "interior_load" = @{ Number = 284; Dossier = "docs/resources/interior_load.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "achievement" = @{ Number = 285; Dossier = "docs/resources/achievement.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "apps" = @{ Number = 286; Dossier = "docs/resources/apps.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "weapon" = @{ Number = 291; Dossier = "docs/resources/weapon.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "es-system" = @{ Number = 303; Dossier = "docs/resources/es-system.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "cargo" = @{ Number = 304; Dossier = "docs/resources/cargo.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "event-system" = @{ Number = 305; Dossier = "docs/resources/event-system.md"; State = "Full manifest-script and direct-caller source review; individual Discussion published" }
    "activities" = @{ Number = "316"; Dossier = "docs/resources/activities.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
    "bone_attach" = @{ Number = "317"; Dossier = "docs/resources/bone_attach.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
    "clothes" = @{ Number = "318"; Dossier = "docs/resources/clothes.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
    "official-interiors" = @{ Number = "319"; Dossier = "docs/resources/official-interiors.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
    "artifacts" = @{ Number = "328"; Dossier = "docs/resources/artifacts.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
    "gatekeepers-system" = @{ Number = "334"; Dossier = "docs/resources/gatekeepers-system.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
    "animation-system" = @{ Number = "336"; Dossier = "docs/resources/animation-system.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
    "help" = @{ Number = "339"; Dossier = "docs/resources/help.md"; State = "Full manifest-script and direct-caller source review; Discussion published" }
}

$inventoryByPath = @{}
foreach ($inventoryRow in (Import-Csv -LiteralPath $InventoryPath)) {
    $inventoryByPath[$inventoryRow.Path.Replace('\', '/')] = $inventoryRow
}

$manifestFiles = foreach ($resourceRoot in @('mods/deathmatch/resources', 'mods/deathmatch/resource-archive')) {
    Get-ChildItem -LiteralPath $resourceRoot -Recurse -Filter 'meta.xml' -File
}
$activeResourceNames = @{}
foreach ($manifest in ($manifestFiles | Where-Object { $_.FullName -notlike '*resource-archive*' })) {
    $activeResourceNames[(Split-Path -Leaf (Split-Path -Parent $manifest.FullName))] = $true
}

$repositoryRootUri = [Uri]::new(((Resolve-Path -LiteralPath '.').Path.TrimEnd('\') + '\'))
$statusRows = foreach ($manifest in ($manifestFiles | Sort-Object FullName)) {
    $manifestUri = [Uri]::new($manifest.FullName)
    $manifestPath = [Uri]::UnescapeDataString($repositoryRootUri.MakeRelativeUri($manifestUri).ToString()).Replace('\', '/')
    $resource = Split-Path -Leaf (Split-Path -Parent $manifest.FullName)
    $isArchived = $manifestPath -like "*resource-archive*"
    $isArchivedDuplicate = $isArchived -and $activeResourceNames.ContainsKey($resource)
    $record = if ($isArchivedDuplicate) { $null } else { $published[$resource] }
    $inventoryRow = $inventoryByPath[$manifestPath]
    $discussionNumber = if ($record -and $record.Number) { [string] $record.Number } else { "" }

    [pscustomobject]@{
        Resource = $resource
        ManifestPath = $manifestPath
        TreeState = if ($isArchived) { "Archived" } else { "Active tree" }
        StartupSnapshot = if ($isArchived) { "Not applicable" } elseif ($inventoryRow) { $inventoryRow.Startup } else { "Unknown" }
        DiscussionNumber = $discussionNumber
        DiscussionURL = if ($discussionNumber) { "https://github.com/itschase/OwlMTA-2026/discussions/$discussionNumber" } else { "" }
        DossierPath = if ($record) { $record.Dossier } else { "" }
        DocumentationState = if ($record) {
            if ($record.State) { $record.State } else { "Partial source review; individual Discussion published" }
        } else {
            "Cataloged only"
        }
        RuntimeState = "Unverified"
        NextAction = if ($isArchivedDuplicate) { "Compare archived copy to active resource and record an identical-source exception or archive-specific dossier and Discussion" } elseif (-not $record) { "Complete dossier and publish Script Resources topic" } elseif (-not $discussionNumber) { "Publish standardized Script Resource Discussion and link implementation tracking" } else { "Complete remaining source review and runtime gate" }
    }
}

$statusRows | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding utf8
Write-Output "Wrote $($statusRows.Count) resource documentation status rows to $OutputPath."
