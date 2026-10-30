local maxammo = { 2000, 250 }

local caps =
{
	-- [slot] = { ammo, ammo per donator level }
	[0] = { 1, 0 },
	[1] = { 1, 0 },
	[2] = { 250, 25 }, -- handguns
	[3] = { 200, 20 }, -- shotguns
	[4] = { 800, 50 }, -- mp5, tec9, uzi
	[5] = { 1200, 100 }, -- assault rifles
	[6] = { 200, 30 }, -- rifles
	[7] = { 3, 0 }, -- heavy weapons
	[8] = { 12, 2 }, -- projectiles
	[9] = { 1500, 250 }, -- spray can, fire ext.
	[10] = { 1, 0 },
	[11] = { 1, 0 },
	[12] = { 1, 0 }
}

local gtacaps = 
{
	[22] = 17,
	[23] = 17,
	[24] = 7,
	--[25] = 1,
	[26] = 2,
	[27] = 7,
	[28] = 50,
	[29] = 30,
	[32] = 50,
	[30] = 30,
	[31] = 50,
	--[33] = 1,
	--[34] = 1,
	--[35] = 1,
	--[36] = 1,
	[37] = 50,
	[38] = 500,
	--[16] = 1,
	--[17] = 1,
	--[18] = 1,
	--[39] = 1,
	[41] = 500,
	[42] = 500,
	[43] = 36,
	[46] = 35,
}

local rejectedReasons = {}

local function reject(reason)
	if not rejectedReasons[reason] then
		rejectedReasons[reason] = true
		outputDebugString("[WEAPONCAP] outcome=rejected reason=" .. reason, 2)
	end
	return false
end

local function getSupportedSlot(weapon)
	weapon = tonumber(weapon)
	if not weapon or weapon ~= math.floor(weapon) then
		return reject("invalid_weapon_id")
	end
	local slot = getSlotFromWeapon(weapon)
	if slot == false or not caps[slot] then
		return reject("unsupported_weapon_id")
	end
	return slot, weapon
end

local function isValidPed(element)
	if not isElement(element) then
		return false
	end
	local elementType = getElementType(element)
	return elementType == "player" or elementType == "ped"
end

function getGTACap(weaponID)
	weaponID = tonumber(weaponID)
	if not weaponID or weaponID ~= math.floor(weaponID) or weaponID < 0 or weaponID > 46 then
		reject("invalid_gta_weapon_id")
		return 0
	end
	return gtacaps[weaponID] or 2
end

-- counts the total number of ammo a player carries
function countAmmo(localPlayer)
	if not isValidPed(localPlayer) then
		reject("invalid_ped")
		return 0
	end
	local ammo = 0
	for slot = 2, 9 do
		ammo = ammo + getPedTotalAmmo( localPlayer, slot )
	end
	return ammo
end

--[[
if a weapon is specified and
   * the player has that weapon: returns pickupable amount
   * player has no weapon on the same slot: returns pickupable amount
   * player has other weapon on the slot: returns 0
otherwise, returns the total pickupable amount
]]
function getFreeAmmo(localPlayer, weapon )
	if not isValidPed(localPlayer) then
		reject("invalid_ped")
		return 0, 0
	end
	if weapon ~= nil then
		local slot, normalizedWeapon = getSupportedSlot(weapon)
		if not slot then
			return 0, getFreeAmmo(localPlayer)
		end
		weapon = normalizedWeapon
		if getPedWeapon( localPlayer, slot ) == weapon and getPedTotalAmmo( localPlayer, slot ) > 0 then
			return math.max( 0, getAmmoCap( localPlayer, weapon ) - getPedTotalAmmo( localPlayer, slot ) ), getFreeAmmo(localPlayer)
		elseif getPedWeapon( localPlayer, slot ) == 0 or getPedTotalAmmo( localPlayer, slot ) == 0 then
			return math.max( 0, getAmmoCap( localPlayer, weapon ) ), getFreeAmmo(localPlayer)
		else
			return 0, getFreeAmmo(localPlayer)
		end
	else
		return math.max(0, maxammo[1] - countAmmo(localPlayer))
	end
end

function getAmmoCap(localPlayer,  weapon )
	if not isValidPed(localPlayer) then
		reject("invalid_ped")
		return 0
	end
	local slot, normalizedWeapon = getSupportedSlot(weapon)
	if not slot then
		return 0
	end
	weapon = normalizedWeapon
	if getPedWeapon( localPlayer, slot ) == 0 or getPedTotalAmmo( localPlayer, slot ) == 0 or getPedWeapon( localPlayer, slot ) == weapon then
		local ammo = caps[slot][1] 
		return math.min( ammo, getFreeAmmo(localPlayer) )
	else
		return 0
	end
end
