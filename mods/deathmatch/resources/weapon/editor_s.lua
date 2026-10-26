--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

local function isPositiveInteger(value)
	return type(value) == "number" and value > 0 and value == math.floor(value)
end

local function rejectWeaponEdit(reason)
	outputDebugString("[weapon:modify] Rejected edit: " .. reason, 2)
	return false
end

function modifyWeapon(dbid, values)
	local player = client
	if not player or not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "loggedin") ~= 1 then
		return rejectWeaponEdit("invalid or unauthenticated caller")
	end

	local characterID = tonumber(getElementData(player, "dbid"))
	if not isPositiveInteger(characterID) then
		return rejectWeaponEdit("caller has no valid character")
	end

	if type(dbid) == "string" and not dbid:match("^%d+$") then
		return rejectWeaponEdit("invalid item DBID")
	end
	dbid = tonumber(dbid)
	if not isPositiveInteger(dbid) then
		return rejectWeaponEdit("invalid item DBID")
	end

	if type(values) ~= "table" or type(values[3]) ~= "string" then
		return rejectWeaponEdit("invalid edit values")
	end
	for key in pairs(values) do
		if key ~= 3 and key ~= 5 then
			return rejectWeaponEdit("unexpected edit field")
		end
	end
	local name = values[3]
	if #name < 1 or #name > 50 or name:find(":", 1, true) or name:find("%c") then
		return rejectWeaponEdit("invalid weapon name")
	end
	if values[5] ~= 1 and values[5] ~= "1" then
		return rejectWeaponEdit("invalid edit lock marker")
	end

	local weapon, inventorySlot = getPlayerWeaponFromDbid(player, dbid, true)
	if not weapon or weapon[1] ~= 115 or tonumber(weapon[3]) ~= dbid or not isPositiveInteger(inventorySlot) then
		return rejectWeaponEdit("weapon is not in caller inventory")
	end
	local oldValue = tostring(weapon[2] or "")
	local connection = exports.mysql:getConn("mta")
	local query = dbQuery(connection,
		"SELECT itemValue FROM items WHERE `index`=? AND type=1 AND owner=? AND itemID=115 LIMIT 1",
		dbid, characterID)
	local rows = query and dbPoll(query, 10000)
	if type(rows) ~= "table" or not rows[1] or tostring(rows[1].itemValue or "") ~= oldValue then
		return rejectWeaponEdit("database item ownership or value could not be verified")
	end

	local fields = exports.global:explode(":", oldValue)
	local weaponID = tonumber(fields[1])
	if not isPositiveInteger(weaponID) or not fields[2] or fields[2] == "" then
		return rejectWeaponEdit("invalid stored weapon data")
	end
	local allowed = exports.weapon:canRetrieve(player, 115, oldValue)
	if not allowed then
		return rejectWeaponEdit("weapon is duty-restricted or not licensed to caller")
	end
	if fields[5] == "1" and not exports.weapon:isWeapAmmoless(weaponID)
		and not (exports.integration:isPlayerTrialAdmin(player, true) or exports.integration:isPlayerSupporter(player)) then
		return rejectWeaponEdit("weapon edit permission denied")
	end

	local newValue = exports.weapon:modifyWeaponValue(oldValue, 3, name)
	newValue = exports.weapon:modifyWeaponValue(newValue, 5, 1)
	if not newValue then
		return rejectWeaponEdit("could not build updated weapon data")
	end

	local updated = dbExec(connection,
		"UPDATE items SET itemValue=? WHERE `index`=? AND type=1 AND owner=? AND itemID=115 AND itemValue=?",
		newValue, dbid, characterID, oldValue)
	if not updated then
		return rejectWeaponEdit("database update failed")
	end
	local verifyQuery = dbQuery(connection,
		"SELECT itemValue FROM items WHERE `index`=? AND type=1 AND owner=? AND itemID=115 LIMIT 1",
		dbid, characterID)
	local verifiedRows = verifyQuery and dbPoll(verifyQuery, 10000)
	if type(verifiedRows) ~= "table" or not verifiedRows[1] or tostring(verifiedRows[1].itemValue or "") ~= tostring(newValue) then
		return rejectWeaponEdit("database update could not be confirmed")
	end

	if exports["item-system"]:updateItemValue(player, inventorySlot, newValue) then
		updateLocalGuns(player)
	else
		outputDebugString("[weapon:modify] Persisted weapon edit but inventory cache update failed for item " .. dbid, 1)
	end
end
addEvent("weapon:modify", true)
addEventHandler("weapon:modify", resourceRoot, modifyWeapon)
