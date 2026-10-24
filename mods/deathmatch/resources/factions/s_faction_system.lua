mysql = exports.mysql
integration = exports.integration

-- EVENTS
addEvent("onPlayerJoinFaction", false)
addEventHandler("onPlayerJoinFaction", getRootElement(),
	function(theTeam)
		return
	end)

locations = {}
custom = {}

local function getValidFactionID(factionID)
	local id = tonumber(factionID)
	if not id or id < 1 or id ~= math.floor(id) or not exports.pool:getElement("team", id) then
		return false
	end
	return id
end

local function isActiveFactionMember(player, factionID)
	local id = getValidFactionID(factionID)
	if not id or not player or not isElement(player) or getElementType(player) ~= "player" then
		return false
	end
	if getElementData(player, "loggedin") ~= 1 or not tonumber(getElementData(player, "dbid")) then
		return false
	end
	local factions = getElementData(player, "faction")
	return type(factions) == "table" and type(factions[id]) == "table", id
end

local function authorizeFactionAction(player, factionID, permission, action)
	local isMember, id = isActiveFactionMember(player, factionID)
	if not isMember or not hasMemberPermissionTo(player, id or tonumber(factionID), permission) then
		if player and isElement(player) then
			exports.logs:dbLog(player, 35, "fa" .. tostring(id or factionID), "Denied faction action " .. tostring(action) .. " (requires " .. tostring(permission) .. ")")
		end
		return false, id
	end
	return true, id
end

function loadOneFaction(row)
	local id = tonumber(row.id)
	local theTeam = exports.pool:getElement('team', id)
	if theTeam then
		destroyElement(theTeam)
	end
	local name = row.name
	local money = tonumber(row.bankbalance)
	local factionType = tonumber(row.type)
	local rankQuery = dbQuery(allocateFactionRank, mysql:getConn("mta"), "SELECT *  FROM `faction_ranks` WHERE `faction_id` = ?", id)

	theTeam = createTeam(tostring(name))
	if theTeam then
		exports.pool:allocateElement(theTeam, id)
		exports.anticheat:setEld(theTeam, "type", factionType, 'all')
		exports.anticheat:setEld(theTeam, "money", money, 'all')
		exports.anticheat:setEld(theTeam, "id", id, 'all')

		local motd = row.motd
		local rank_order = row.rank_order 
		exports.anticheat:setEld(theTeam, "rank_order", rank_order, 'all')
		exports.anticheat:setEld(theTeam, "motd", motd, 'one')
		exports.anticheat:setEld(theTeam, "note", row.note == mysql_null() and "" or row.note, 'one')
		exports.anticheat:setEld(theTeam, "fnote", row.fnote == mysql_null() and "" or row.fnote, 'one')
		exports.anticheat:setEld(theTeam, "phone", row.phone ~= mysql_null() and row.phone or nil, 'one')
		exports.anticheat:setEld(theTeam, "max_interiors", tonumber(row.max_interiors), 'none') --Don't sync at all
		exports.anticheat:setEld(theTeam, "max_vehicles", tonumber(row.max_vehicles), 'none') --Don't sync at all
		exports.anticheat:setEld(theTeam, "before_tax_value", tonumber(row.before_tax_value), 'none') --Don't sync at all
		exports.anticheat:setEld(theTeam, "before_wage_charge", tonumber(row.before_wage_charge), 'none') --Don't sync at all
		exports.anticheat:setEld(theTeam, "permissions", { free_custom_ints = row.free_custom_ints, free_custom_skins = row.free_custom_skins }, 'all')
	end
	return theTeam
end

function loadAllFactions(res)
	setElementData(resourceRoot, "DutyGUI", {})
	setElementData(resourceRoot, "maxlindex", 0)
	setElementData(resourceRoot, "maxcindex", 0)

	local qh = dbQuery(function(qh)
		local result = dbPoll(qh, 0)
		if not result then dbFree(qh) return end
		for _, row in pairs(result) do
			loadOneFaction(row)
		end
	end, mysql:getConn("mta"), "SELECT * FROM factions ORDER BY id ASC")

	local customQ = dbQuery(function(customQ)
		local result, num_affected_rows = dbPoll(customQ, 0)
		if not result or num_affected_rows < 1 then dbFree(customQ) return end

		for _, row in pairs(result) do
			local skins = fromJSON(tostring(row.skins)) or {}
			local locations = fromJSON(tostring(row.locations)) or {}
			local items = fromJSON(tostring(row.items)) or {}
			custom[row.factionid] = custom[row.factionid] or {}
			custom[row.factionid][tonumber(row.id)] = { row.id, row.name, skins, locations, items }
			maxIndex = tonumber(row.id)
		end

		setElementData(resourceRoot, "maxcindex", maxIndex)
		setElementData(getResourceRootElement(getResourceFromName("duty")), "factionDuty", custom)
	end, mysql:getConn("mta"), "SELECT * FROM duty_custom ORDER BY id ASC", id)

	local locationQ = dbQuery(function(locationQ)
		local result, num_affected_rows = dbPoll(locationQ, 0)
		if not result or num_affected_rows < 1 then dbFree(locationQ) return end

		for _, row in pairs(result) do
			locations[row.factionid] = locations[row.factionid] or {}
			locations[row.factionid][tonumber(row.id)] = { row.id, row.name, row.x, row.y, row.z, row.radius, row.dimension, row.interior, row.vehicleid, row.model }
			if not tonumber(row.model) then -- If it's not a vehicle it must be a location. Right?
			exports.duty:createDutyColShape(row.x, row.y, row.z, row.radius, row.interior, row.dimension, row.factionid, row.id)
			end
			maxIndex = tonumber(row.id)
		end

		setElementData(resourceRoot, "maxlindex", maxIndex)
		setElementData(getResourceRootElement(getResourceFromName("duty")), "factionLocations", locations)
	end, mysql:getConn("mta"), "SELECT * FROM duty_locations ORDER BY id ASC", id)

	local citteam = createTeam("Citizen", 255, 255, 255)
	exports.pool:allocateElement(citteam, -1)

	-- set all players into their appropriate faction
	local players = exports.pool:getPoolElementsByType("player")
	for k, thePlayer in ipairs(players) do
		local dbid = getElementData(thePlayer, "dbid")

		local qh = dbQuery(function(qh)
			local result, num_affected_rows = dbPoll(qh, 0)

			if result and num_affected_rows > 0 then
				local factionT = {}
				local count = 0
				for _, row in pairs(result) do
					count = count + 1
					factionT[row.faction_id] = { rank = row.faction_rank, leader = row.faction_leader == 1 or false, phone = row.faction_phone, perks = type(row.faction_perks) == "string" and fromJSON(row.faction_perks) or {}, count = count }
				end

				setElementData(thePlayer, "factionMenu", 0)
				setElementData(thePlayer, "faction", factionT)
			else -- Aren't in any faction, just a citizen.
			setElementData(thePlayer, "factionMenu", 0)
			setElementData(thePlayer, "faction", {})
			dbFree(qh)
			end
			setPlayerTeam(thePlayer, citteam)
		end, mysql:getConn("mta"), "SELECT * FROM characters_faction WHERE character_id=? ORDER BY id ASC", dbid)

		if not (isKeyBound(thePlayer, "F3", "down", showFactionMenu)) then
			bindKey(thePlayer, "F3", "down", showFactionMenu)
		end
	end
end

addEventHandler("onResourceStart", resourceRoot, loadAllFactions)

function bindKeysOnJoin()
	bindKey(source, "F3", "down", showFactionMenu)
end
addEventHandler("onPlayerJoin", getRootElement(), bindKeysOnJoin)

function showFactionMenu(source)
	showFactionMenuEx(source)
end	
addCommandHandler("faction", showFactionMenu)

function showFactionMenuEx(source, factionID, fromShowF)
	local logged = getElementData(source, "loggedin")

	if (logged == 1) then
		local menuVisible = getElementData(source, "factionMenu")

		if (menuVisible == 0) then
			if not factionID then
				local organizedTable = {}

				for i, k in pairs(getElementData(source, "faction")) do
					organizedTable[k.count] = i
				end
				factionID = organizedTable[1]
			end
			if (factionID) then
				local theTeam = exports.pool:getElement("team", factionID)
				local query = dbQuery(mysql:getConn("mta"), "SELECT characters.charactername, characters_faction.faction_rank, characters_faction.faction_perks, characters_faction.faction_leader, characters_faction.faction_phone, DATEDIFF(NOW(), characters.lastlogin) AS lastlogin FROM characters_faction INNER JOIN characters ON characters.id=characters_faction.character_id WHERE characters_faction.faction_ID=? ORDER BY faction_rank DESC, charactername ASC", factionID)
				local result, num_affected_rows = dbPoll(query, 10000)
				if result then
					local memberUsernames = {}
					local memberRanks = {}
					local memberLeaders = {}
					local memberOnline = {}
					local memberLastLogin = {}
					--[[local memberLocation = {}]]
					local memberPerks = {}
					local rankOrder = getElementData(theTeam, "rank_order") or ""
					local factionRanks = getElementData(theTeam, "ranks")
					local factionWages = getElementData(theTeam, "wages")
					local motd = getElementData(theTeam, "motd")
					local note = getElementData(theTeam, "note")
					local fnote = getElementData(theTeam, "fnote")
					local vehicleIDs = {}
					local vehicleModels = {}
					local vehiclePlates = {}
					local vehicleLocations = {}
					local properties = {}
					local memberOnDuty = {}
					local phone = getElementData(theTeam, "phone")
					local memberPhones = phone and {} or nil

					if (motd == "") then motd = nil end
					if (motd == "") then motd = nil end
					if rankOrder == "" then
						rankOrder = table.concat(getFactionRanks(tonumber(factionID), false), ",") 
						exports.anticheat:setEld(theTeam, "rank_order", rankOrder, 'all')
					end

					local factionRanksTbl = {}
					local factionRankID = {}
					local rankOrder = split(rankOrder, ",")
					for i,rankID in ipairs(rankOrder) do
						local rankID = tonumber(rankID)
						factionRanksTbl[rankID] = factionRanks[rankID]
						factionRankID[factionRanks[rankID]] = rankID
					end

					local i = 1
					for _, row in ipairs(result) do
						local playerName = row.charactername
						memberUsernames[i] = playerName
						memberRanks[i] = row.faction_rank
						memberPerks[i] = type(row.faction_perks) == "string" and fromJSON(row.faction_perks) or {}
						if phone and row.faction_phone ~= mysql_null() and tonumber(row.faction_phone) then
							memberPhones[i] = ("%02d"):format(tonumber(row.faction_phone))
						end

						if (tonumber(row.faction_leader) == 1) then
							memberLeaders[i] = true
						else
							memberLeaders[i] = false
						end

						local login = ""

						memberLastLogin[i] = tonumber(row.lastlogin)
						if getPlayerFromName(playerName) then
							local testingPlayer = getPlayerFromName(playerName)
							local onlineState = getElementData(testingPlayer, "loggedin")
							if (onlineState == 1) then
								--[[if getElementDimension(testingPlayer) == 0 and getElementInterior(testingPlayer) == 0 then
									memberLocation[i] = tostring(exports.global:getElementZoneName(testingPlayer, false))
								else
									memberLocation[i] = "Unknown"
								end]]
								memberOnline[i] = true

								local dutydata = getCurrentFactionDuty(testingPlayer)
								memberOnDuty[i] = (dutydata == factionID)
							end
						else
							memberOnline[i] = false
							memberOnDuty[i] = false
							--[[memberLocation[i] = "Unknown"]]
						end
						i = i + 1
					end

					local towstats = nil
					if hasMemberPermissionTo(source, factionID, "respawn_vehs") then
						local vehicleQuery = dbQuery(mysql:getConn("mta"), "SELECT id, model, plate FROM vehicles WHERE faction=? AND deleted=0", factionID)
						local vehResult, num_affected_rows = dbPoll(vehicleQuery, 10000)
						if vehResult then
							local j = 1
							for _, row in ipairs(vehResult) do
								vehicleIDs[j] = row.id
								vehiclePlates[j] = row.plate
								local veh = exports.pool:getElement("vehicle", row.id)
								vehicleModels[j] = exports.global:getVehicleName(veh)
								vehicleLocations[j] = exports.global:hasItem(veh, 139) and exports.global:getElementZoneName(veh) or "Unknown"
								j = j + 1
							end
						else
							dbFree(vehicleQuery)
						end

						local interiorQuery = dbQuery(mysql:getConn("mta"), "SELECT id, name FROM interiors WHERE faction=? AND deleted='0' AND disabled=0", factionID)
						local interiorResult, num_affected_rows = dbPoll(interiorQuery, 10000)
						if interiorResult then
							local j = 1
							for _, row in ipairs(interiorResult) do
								properties[j] = { row.id, row.name }
								local int = exports.pool:getElement("interior", row.id)
								--properties[j][3] = exports.global:getElementZoneName(int)
								properties[j][3] = "Unknown"
								j = j + 1
							end
						else
							dbFree(interiorQuery)
						end
						if factionID == 4 then -- TTR Towstats
						-- this basically returns a count of towed vehicles, by week -> so week 0 (current week) = X, week -1 (last week) = Y, etc.
						local towQuery = dbQuery(mysql:getConn("mta"), "SELECT ceil(datediff(`date`, curdate() + INTERVAL 6-WEEKDAY(curdate()) DAY) / 7) AS week, c.charactername, count(vehicle) AS count FROM towstats t JOIN characters c ON t.character = c.id WHERE (SELECT faction_id FROM characters_faction WHERE character_id = t.character and faction_id = 4) = 4 GROUP BY t.character, week ORDER BY t.character ASC, week DESC")
						local towResult, num_affected_rows = dbPoll(towQuery, 10000)
						if towResult then
							towstats = {}
							for _, row in ipairs(towResult) do
								if not towstats[row.charactername] then
									towstats[row.charactername] = {}
								end

								towstats[row.charactername][tonumber(row.week)] = tonumber(row.count)
							end
						else
							dbFree(towResult)
						end
						end
					end

					exports.anticheat:changeProtectedElementDataEx(source, "factionMenu", 1, false)
					triggerClientEvent(source, "showFactionMenu", source, motd, memberUsernames, memberRanks, memberPerks or {}, memberLeaders, memberOnline, memberLastLogin, --[[memberLocation,]] factionRanksTbl,  factionWages, theTeam, note, fnote, vehicleIDs, vehicleModels, vehiclePlates, vehicleLocations, memberOnDuty, towstats, phone, memberPhones, fromShowF, factionID, properties, factionRankID, rankOrder)
				else
					dbFree(query)
				end
			else
				outputChatBox("You are not in a faction.", source)
			end
		else
			triggerClientEvent(source, "hideFactionMenu", source)
		end
	end
end

-- // CALL BACKS FROM CLIENT GUI
function loadFaction(factionID)
	local isMember, validFactionID = isActiveFactionMember(client, factionID)
	if not isMember then
		if client and isElement(client) then
			exports.logs:dbLog(client, 35, "fa" .. tostring(validFactionID or factionID), "Denied faction roster access")
		end
		return false
	end
	factionID = validFactionID
	local theTeam = exports.pool:getElement("team", factionID)
	if (theTeam) then
		local theTeam = exports.pool:getElement("team", factionID)
		local query = dbQuery(mysql:getConn("mta"), "SELECT characters.charactername, characters_faction.faction_rank, characters_faction.faction_perks, characters_faction.faction_leader, characters_faction.faction_phone, DATEDIFF(NOW(), characters.lastlogin) AS lastlogin FROM characters_faction INNER JOIN characters ON characters.id=characters_faction.character_id WHERE characters_faction.faction_ID=? ORDER BY faction_rank DESC, charactername ASC", factionID)
		local result, num_affected_rows = dbPoll(query, 10000)
		if result then
			local memberUsernames = {}
			local memberRanks = {}
			local memberLeaders = {}
			local memberOnline = {}
			local memberLastLogin = {}
			--[[local memberLocation = {}]]
			local memberPerks = {}
			local rankOrder = getElementData(theTeam, "rank_order") or ""
			local factionRanks = getElementData(theTeam, "ranks")
			local factionWages = getElementData(theTeam, "wages")
			local motd = getElementData(theTeam, "motd")
			local note = getElementData(theTeam, "note")
			local fnote = getElementData(theTeam, "fnote")
			local vehicleIDs = {}
			local vehicleModels = {}
			local vehiclePlates = {}
			local vehicleLocations = {}
			local properties = {}
			local memberOnDuty = {}
			local phone = getElementData(theTeam, "phone")
			local memberPhones = phone and {} or nil

			if (motd == "") then motd = nil end

			if rankOrder == "" then
				rankOrder = table.concat(getFactionRanks(tonumber(factionID), false), ",")
				exports.anticheat:setEld(theTeam, "rank_order", rankOrder, 'all')
			end

			local factionRanksTbl = {}
			local factionRankID = {}
			local rankOrder = split(rankOrder, ",")
			for i,rankID in ipairs(rankOrder) do
				local rankID = tonumber(rankID)
				factionRanksTbl[rankID] = factionRanks[rankID]
				factionRankID[factionRanks[rankID]] = rankID
			end

			local i = 1
			for _, row in ipairs(result) do
				local playerName = row.charactername
				memberUsernames[i] = playerName
				memberRanks[i] = row.faction_rank
				memberPerks[i] = type(row.faction_perks) == "string" and fromJSON(row.faction_perks) or {}
				if phone and row.faction_phone ~= mysql_null() and tonumber(row.faction_phone) then
					memberPhones[i] = ("%02d"):format(tonumber(row.faction_phone))
				end

				if (tonumber(row.faction_leader) == 1) then
					memberLeaders[i] = true
				else
					memberLeaders[i] = false
				end

				local login = ""

				memberLastLogin[i] = tonumber(row.lastlogin)
				if getPlayerFromName(playerName) then
					local testingPlayer = getPlayerFromName(playerName)
					local onlineState = getElementData(testingPlayer, "loggedin")
					if (onlineState == 1) then
						memberOnline[i] = true

						local dutydata = getCurrentFactionDuty(testingPlayer)
						if dutydata == factionID then
							if (tonumber(dutydata) > 0) then
								memberOnDuty[i] = true
							else
								memberOnDuty[i] = false
							end
						else
							memberOnDuty[i] = false
						end
					end
				else
					memberOnline[i] = false
					memberOnDuty[i] = false
				end
				i = i + 1
			end

			local towstats = nil
			if hasMemberPermissionTo(client, factionID, "respawn_vehs") then
				local vehicleQuery = dbQuery(mysql:getConn("mta"), "SELECT id, model, plate FROM vehicles WHERE faction=? AND deleted=0", factionID)
				local vehResult, num_affected_rows = dbPoll(vehicleQuery, 10000)
				if vehResult then
					local j = 1
					for _, row in ipairs(vehResult) do
						vehicleIDs[j] = row.id
						vehiclePlates[j] = row.plate
						local veh = exports.pool:getElement("vehicle", row.id)
						vehicleModels[j] = exports.global:getVehicleName(veh)
						vehicleLocations[j] = exports.global:hasItem(veh, 139) and exports.global:getElementZoneName(veh) or "Unknown"
						j = j + 1
					end
				else
					dbFree(vehicleQuery)
				end

				local interiorQuery = dbQuery(mysql:getConn("mta"), "SELECT id, name FROM interiors WHERE faction=? AND deleted='0' AND disabled=0", factionID)
				local interiorResult, num_affected_rows = dbPoll(interiorQuery, 10000)
				if interiorResult then
					local j = 1
					for _, row in ipairs(interiorResult) do
						properties[j] = { row.id, row.name }
						local int = exports.pool:getElement("interior", row.id)
						--properties[j][3] = exports.global:getElementZoneName(int)
						properties[j][3] = "Unknown"
						j = j + 1
					end
				else
					dbFree(interiorQuery)
				end

				if factionID == 4 then -- TTR Towstats
				-- this basically returns a count of towed vehicles, by week -> so week 0 (current week) = X, week -1 (last week) = Y, etc.
				local towQuery = dbQuery(mysql:getConn("mta"), "SELECT ceil(datediff(`date`, curdate() + INTERVAL 6-WEEKDAY(curdate()) DAY) / 7) AS week, c.charactername, count(vehicle) AS count FROM towstats t JOIN characters c ON t.character = c.id WHERE (SELECT faction_id FROM characters_faction WHERE character_id = t.character and faction_id = 4) = 4 GROUP BY t.character, week ORDER BY t.character ASC, week DESC")
				local towResult, num_affected_rows = dbPoll(towQuery, 10000)
				if towResult then
					towstats = {}
					for _, row in ipairs(towResult) do
						if not towstats[row.charactername] then
							towstats[row.charactername] = {}
						end
						towstats[row.charactername][tonumber(row.week)] = tonumber(row.count)
					end
				else
					dbFree(towResult)
				end
				end
			end

			triggerClientEvent(client, "faction:fillFactionMenu", resourceRoot, motd, memberUsernames, memberRanks, memberPerks or {}, memberLeaders, memberOnline, memberLastLogin, --[[memberLocation,]] factionRanksTbl, factionWages, theTeam, note, fnote, vehicleIDs, vehicleModels, vehiclePlates, vehicleLocations, memberOnDuty, towstats, phone, memberPhones, fromShowF, factionID, properties, factionRankID, rankOrder)
		else
			dbFree(query)
		end
	else
		outputChatBox("Error finding this faction.", client)
	end
end

addEvent("faction:loadFaction", true)
addEventHandler("faction:loadFaction", resourceRoot, loadFaction)

function callbackRespawnVehicles(factionID)
	local theTeam = getFactionFromID(factionID)
	local factionCooldown = getElementData(theTeam, "cooldown")
	if not hasMemberPermissionTo(client, factionID, "respawn_vehs") then
		outputChatBox("Not allowed, sorry.", client)
		return
	end

	if not (factionCooldown) then
		for key, value in ipairs(exports.pool:getPoolElementsByType("vehicle")) do
			local faction = getElementData(value, "faction")
			if (faction == factionID and not getVehicleOccupant(value, 0) and not getVehicleOccupant(value, 1) and not getVehicleOccupant(value, 2) and not getVehicleOccupant(value, 3) and not getVehicleTowingVehicle(value)) then
				respawnVehicle(value)
				setElementInterior(value, getElementData(value, "interior"))
				setElementDimension(value, getElementData(value, "dimension"))
				setVehicleLocked(value, true)
				exports.anticheat:changeProtectedElementDataEx(value, "enginebroke", 0, true)
				exports.anticheat:changeProtectedElementDataEx(value, "handbrake", 1, true)
				setTimer(setElementFrozen, 2000, 1, value, true)	
				if exports.vehicle:getArmoredCars()[getElementModel(value)] or getElementData(value, "bulletproof") == 1 then
					setVehicleDamageProof(value, true)
				else
					setVehicleDamageProof(value, false)
				end
			end
		end

		-- Send message to everyone in the faction
		local teamPlayers = getPlayersInFaction(factionID)
		local username = getPlayerName(source)
		for k, v in ipairs(teamPlayers) do
			outputChatBox(username:gsub("_", " ") .. " respawned all unoccupied faction vehicles.", v, 255, 194, 14)
		end

		setTimer(resetFactionCooldown, 60000, 1, theTeam)
		exports.anticheat:changeProtectedElementDataEx(theTeam, "cooldown", true, false)
	else
		outputChatBox("You currently cannot respawn your factions vehicles, Please wait a while.", source, 255, 0, 0)
	end
end

addEvent("cguiRespawnVehicles", true)
addEventHandler("cguiRespawnVehicles", getRootElement(), callbackRespawnVehicles)

function resetFactionCooldown(theTeam)
	exports.anticheat:changeProtectedElementDataEx(theTeam, "cooldown")
end

function callbackRespawnOneVehicle(vehicleID, factionID)
	local theTeam = getFactionFromID(factionID)
	local theVehicle = exports.pool:getElement("vehicle", tonumber(vehicleID))
	if not hasMemberPermissionTo(client, factionID, "respawn_vehs") then
		outputChatBox("Not allowed, sorry.", source, 255, 0, 0)
		return
	end
	if theVehicle then
		local theVehicleID = getElementData(theVehicle, "faction")
		if (factionID == theVehicleID and not getVehicleOccupant(theVehicle, 0) and not getVehicleOccupant(theVehicle, 1) and not getVehicleOccupant(theVehicle, 2) and not getVehicleOccupant(theVehicle, 3) and not getVehicleTowingVehicle(theVehicle)) then
			if isElementAttached(theVehicle) then
				detachElements(theVehicle)
			end
			exports.logs:dbLog(source, 6, theVehicle, "FACTIONRESPAWN")
			respawnVehicle(theVehicle)
			setElementInterior(theVehicle, getElementData(theVehicle, "interior"))
			setElementDimension(theVehicle, getElementData(theVehicle, "dimension"))
			setVehicleLocked(theVehicle, true)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "enginebroke", 0, true)
			exports.anticheat:changeProtectedElementDataEx(theVehicle, "handbrake", 1, true)
			setTimer(setElementFrozen, 2000, 1, theVehicle, true)	
			if exports.vehicle:getArmoredCars()[getElementModel(theVehicle)] or getElementData(theVehicle, "bulletproof") == 1 then
				setVehicleDamageProof(theVehicle, true)
			else
				setVehicleDamageProof(theVehicle, false)
			end

			outputChatBox("Vehicle Respawned.", source, 0, 255, 0)
			local teamPlayers = getPlayersInFaction(factionID)
			local playerName = getPlayerName(source)
			for k, v in ipairs(teamPlayers) do
				outputChatBox(playerName:gsub("_", " ") .. " respawned faction vehicle " .. vehicleID .. ".", v, 255, 194, 14)
			end
		else
			outputChatBox("That vehicle is currently occupied.", source, 255, 0, 0)
		end
	else
		outputChatBox("Please select a vehicle you wish to respawn.", source, 255, 0, 0)
	end
end

addEvent("cguiRespawnOneVehicle", true)
addEventHandler("cguiRespawnOneVehicle", getRootElement(), callbackRespawnOneVehicle)

function callbackUpdateMOTD(motd, factionID)
	local theTeam = getFactionFromID(factionID)
	if not hasMemberPermissionTo(client, factionID, "edit_motd") then
		outputChatBox("Not allowed, sorry.", client)
		return
	end

	if (factionID ~= -1) then
		if dbExec(mysql:getConn("mta"), "UPDATE factions SET motd=? WHERE id=?", motd, factionID) then
			outputChatBox("You changed your faction's MOTD to '" .. motd .. "'", client, 0, 255, 0)
			exports.anticheat:changeProtectedElementDataEx(theTeam, "motd", motd, false)
		else
			outputChatBox("Error 300000 - Report on Forums.", client, 255, 0, 0)
		end
	end
end

addEvent("cguiUpdateMOTD", true)
addEventHandler("cguiUpdateMOTD", getRootElement(), callbackUpdateMOTD)

function callbackUpdateNote(note, factionID)
	local theTeam = getFactionFromID(factionID)
	if not hasMemberPermissionTo(client, factionID, "modify_factionl_note") or not note then
		outputChatBox("Not allowed, sorry.", client)
		return
	end

	if (factionID ~= -1) then
		if dbExec(mysql:getConn("mta"), "UPDATE factions SET note=? WHERE id=?", note, factionID) then
			outputChatBox("You successfully changed your faction's leader note.", client, 0, 255, 0)
			exports.anticheat:changeProtectedElementDataEx(theTeam, "note", note, false)
		else
			outputChatBox("Error 30000A - Report on mantis.", client, 255, 0, 0)
		end
	end
end

addEvent("faction:note", true)
addEventHandler("faction:note", getRootElement(), callbackUpdateNote)

function callbackUpdateFNote(fnote, factionID)
	local theTeam = getFactionFromID(factionID)
	if not hasMemberPermissionTo(client, factionID, "modify_faction_note") or not fnote then
		outputChatBox("Not allowed, sorry.", client)
		return
	end

	if (factionID ~= -1) then
		if dbExec(mysql:getConn("mta"), "UPDATE factions SET fnote=? WHERE id=?", fnote, factionID) then
			outputChatBox("You successfully changed your faction's faction-wide note.", client, 0, 255, 0)
			exports.anticheat:changeProtectedElementDataEx(theTeam, "fnote", fnote, false)
		else
			outputChatBox("Error 30000B - Report on mantis.", client, 255, 0, 0)
		end
	end
end

addEvent("faction:fnote", true)
addEventHandler("faction:fnote", getRootElement(), callbackUpdateFNote)

function callbackRemovePlayer(removedPlayerName, factionID)
	local theTeam = getFactionFromID(factionID)
	if not hasMemberPermissionTo(client, factionID, "del_member") then
		outputChatBox("Not allowed, sorry.", client)
		return
	end

	local _, factionDetails, removedPlayer = getPlayerFactions(removedPlayerName)
	if removedPlayer and not factionDetails[factionID] then
		outputChatBox("Newp, not going to happen, sorry.", client)
		return
	end

	if dbExec(mysql:getConn("mta"), "DELETE FROM characters_faction WHERE character_id=(SELECT id FROM characters WHERE charactername=?) AND faction_id=?", removedPlayerName, factionID) then
		local theTeamName = "None"
		if (theTeam) then
			theTeamName = getTeamName(theTeam)
		end

		local username = getPlayerName(client)

		if (removedPlayer) then -- Player is online
		if (getElementData(removedPlayer, "factionMenu") == 1) then
			triggerClientEvent(removedPlayer, "hideFactionMenu", getRootElement())
		end
		outputChatBox(username:gsub("_", " ") .. " removed you from the faction '" .. tostring(theTeamName) .. "'", removedPlayer, 255, 0, 0)
		local organizedTable = {}

		for i, k in pairs(factionDetails) do
			organizedTable[k.count] = i
		end

		local found = false
		for k, v in ipairs(organizedTable) do
			if v == factionID then
				found = true
			end

			if found then
				factionDetails[v].count = factionDetails[v].count - 1
			end
		end

		factionDetails[factionID] = nil
		setElementData(removedPlayer, "faction", factionDetails)
		triggerEvent("duty:offduty", removedPlayer)
		end

		-- Send message to everyone in the faction
		exports.factions:sendNotiToAllFactionMembers(factionID, removedPlayerName:gsub("_", " ") .. " was removed from faction '" .. tostring(theTeamName) .. "'.", "Removed by " .. username:gsub("_", " ") .. ".")
	else
		outputChatBox("Failed to remove " .. removedPlayerName:gsub("_", " ") .. " from the faction, Contact an admin.", source, 255, 0, 0)
	end
end

addEvent("cguiKickPlayer", true)
addEventHandler("cguiKickPlayer", getRootElement(), callbackRemovePlayer)

function callbackPerkEdit(perkIDTable, playerName, factionID)
	if not hasMemberPermissionTo(client, factionID, "set_member_duty") then
		outputChatBox("Not allowed, sorry.", client)
		return
	end

	local _, factionInfo, targetPlayer = getPlayerFactions(playerName)
	if targetPlayer and not factionInfo[factionID] then
		outputChatBox("Newp, not going to happen, sorry.", client)
		return
	end

	local jsonPerkIDTable = toJSON(perkIDTable)
	if dbExec(mysql:getConn("mta"), "UPDATE `characters_faction` SET `faction_perks`=? WHERE character_id=(SELECT id FROM characters WHERE charactername=?) AND faction_id=?", jsonPerkIDTable, playerName, factionID) then
		outputChatBox(" Duty perks updated for " .. playerName:gsub("_", " ") .. ".", client, 255, 0, 0)
		if targetPlayer then
			factionInfo[factionID].perks = perkIDTable
			setElementData(targetPlayer, "faction", factionInfo)

			outputChatBox(" Your duty perks have been updated by " .. getPlayerName(client):gsub("_", " ") .. ".", targetPlayer, 255, 0, 0)
		end
	end
end

addEvent("faction:perks:edit", true)
addEventHandler("faction:perks:edit", getRootElement(), callbackPerkEdit)

function callbackQuitFaction(factionID)
	local isMember, validFactionID = isActiveFactionMember(client, factionID)
	if not isMember then
		if client and isElement(client) then
			exports.logs:dbLog(client, 35, "fa" .. tostring(validFactionID or factionID), "Denied faction leave request")
		end
		return false
	end
	factionID = validFactionID
	local theTeam = getFactionFromID(factionID)
	local username = getPlayerName(client)
	local theTeamName = getTeamName(theTeam)

	if dbExec(mysql:getConn("mta"), "DELETE FROM characters_faction WHERE character_id=? AND faction_id=?", getElementData(client, "dbid"), factionID) then
		outputChatBox("You quit the faction '" .. theTeamName .. "'.", client)

		local factionInfo = getElementData(client, "faction")
		local organizedTable = {}

		for i, k in pairs(factionInfo) do
			organizedTable[k.count] = i
		end

		local found = false
		for k, v in ipairs(organizedTable) do
			if v == factionID then
				found = true
			end

			if found then
				factionInfo[v].count = factionInfo[v].count - 1
			end
		end
		factionInfo[factionID] = nil
		setElementData(client, "faction", factionInfo)
		triggerEvent("duty:offduty", client)

		-- Send message to everyone in the faction
		exports.factions:sendNotiToAllFactionMembers(factionID, username:gsub("_", " ") .. " left your faction '" .. theTeamName .. "'.")
	else
		outputChatBox("Failed to quit the faction, Contact an admin.", client, 255, 0, 0)
	end
end

addEvent("cguiQuitFaction", true)
addEventHandler("cguiQuitFaction", getRootElement(), callbackQuitFaction)

function callbackInvitePlayer(invitedPlayer, factionID)
	local allowed, factionID = authorizeFactionAction(client, factionID, "add_member", "invite member")
	if not allowed then
		outputChatBox("Not allowed, sorry.", client)
		return
	end
	local theTeam = getFactionFromID(factionID)
	if not invitedPlayer or not isElement(invitedPlayer) or getElementType(invitedPlayer) ~= "player"
		or invitedPlayer == client or getElementData(invitedPlayer, "loggedin") ~= 1
		or not tonumber(getElementData(invitedPlayer, "dbid")) or not theTeam then
		outputChatBox("Not allowed, sorry.", client)
		return
	end

	local invitedPlayerNick = getPlayerName(invitedPlayer)
	local factionInfo = getElementData(invitedPlayer, "faction")
	if type(factionInfo) ~= "table" then
		outputChatBox("Not allowed, sorry.", client)
		return
	end
	local defaultRank = getDefaultRank(factionID)
	if not defaultRank or getRankFaction(defaultRank) ~= factionID then
		outputChatBox("This faction has no valid default rank.", client, 255, 0, 0)
		return
	end
	local count = 0
	for _ in pairs(factionInfo) do count = count + 1 end
	if count >= 3 then
		outputChatBox("Player has joined the maximum amount of allowed factions.", client, 255, 0, 0)
		return
	elseif isPlayerInFaction(invitedPlayer, factionID) then
		outputChatBox("Player is already a member of that faction.", client, 255, 0, 0)
		return
	end
	local dbid = getElementData(invitedPlayer, "dbid")

	if dbExec(mysql:getConn("mta"), "INSERT INTO characters_faction SET faction_leader = 0, faction_id = ?, faction_rank = ?, character_id = ?", factionID, defaultRank, dbid) then
		local theTeamName = getTeamName(theTeam)

		local max = 0
		for id, _ in pairs(factionInfo) do
			if not max then max = _.count end
			if _.count >= max then
				max = _.count
			end
		end

		factionInfo[factionID] = { rank = defaultRank, leader = false, phone = nil, perks = { {} }, count = max + 1 }
		exports.anticheat:changeProtectedElementDataEx(invitedPlayer, "faction", factionInfo, false)
		outputChatBox("Player " .. invitedPlayerNick:gsub("_", " ") .. " is now a member of faction '" .. tostring(theTeamName) .. "'.", client, 0, 255, 0)
		exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Invited " .. invitedPlayerNick .. " to faction")
		exports.factions:sendNotiToAllFactionMembers(factionID, invitedPlayerNick:gsub("_", " ") .. " joined as a new member of your faction '" .. tostring(theTeamName) .. "'.")
		triggerEvent("onPlayerJoinFaction", invitedPlayer, theTeam)
		outputChatBox("You were set to Faction '" .. tostring(theTeamName) .. "'.", invitedPlayer, 255, 194, 14)
	else
		outputChatBox("Player is already in a faction.", client, 255, 0, 0)
	end
end

addEvent("cguiInvitePlayer", true)
addEventHandler("cguiInvitePlayer", getRootElement(), callbackInvitePlayer)

function hideFactionMenu()
	exports.anticheat:changeProtectedElementDataEx(client, "factionMenu", 0, false)
end

addEvent("factionmenu:hide", true)
addEventHandler("factionmenu:hide", getRootElement(), hideFactionMenu)

function getFactionFinance(factionID)
	if not factionID then return end

	if hasMemberPermissionTo(client, factionID, "manage_finance") then
		local bankThisWeek = {}
		local bankPrevWeek = {}
		local transactions = {}

		-- `w.time` - INTERVAL 1 hour as 'newtime'
		-- hour correction
		--local query = mysql:query("SELECT w.*, a.charactername as characterfrom, b.charactername as characterto,w.`time` - INTERVAL 1 hour as 'newtime', WEEKOFYEAR(w.`time` - INTERVAL 1 hour) as 'week', WEEKOFYEAR(CURDATE() - INTERVAL 1 hour) as 'currentWeek' FROM wiretransfers w LEFT JOIN characters a ON a.id = `from` LEFT JOIN characters b ON b.id = `to` WHERE ( `from` = '" .. mysql:escape_string(tostring(-factionID)) .. "' OR `to` = '" .. mysql:escape_string(tostring(-factionID)) .. "' ) ORDER BY id DESC")
		local query = mysql:query("SELECT w.*, a.charactername as characterfrom, b.charactername as characterto,w.`time` as 'newtime', WEEKOFYEAR(w.`time`) as 'week', WEEKOFYEAR(CURDATE()) as 'currentWeek' FROM wiretransfers w LEFT JOIN characters a ON a.id = `from` LEFT JOIN characters b ON b.id = `to` WHERE ( `from` = '" .. mysql:escape_string(tostring(-factionID)) .. "' OR `to` = '" .. mysql:escape_string(tostring(-factionID)) .. "' ) ORDER BY id DESC")

		--outputConsole("SELECT w.*, a.charactername as characterfrom, b.charactername as characterto,w.`time` - INTERVAL 1 hour as 'newtime', WEEKOFYEAR(w.`time` - INTERVAL 1 hour) as 'week', WEEKOFYEAR(CURDATE() - INTERVAL 1 hour) as 'currentWeek' FROM wiretransfers w LEFT JOIN characters a ON a.id = `from` LEFT JOIN characters b ON b.id = `to` WHERE ( `from` = " .. -factionID .. " OR `to` = " .. -factionID .. " ) ORDER BY id DESC")

		local mostRecentWeek = 0
		local currentWeek = 0
		if query then
			while true do
				row = mysql:fetch_assoc(query)
				if not row then break end

				local id = tonumber(row["id"])
				local amount = tonumber(row["amount"])
				local time = row["newtime"]
				local week = tonumber(row["week"])
				currentWeek = tonumber(row["currentWeek"])
				if week > mostRecentWeek then mostRecentWeek = week end
				if not transactions[week] then transactions[week] = {} end
				local type = tonumber(row["type"])
				local reason = row["reason"]
				if reason == mysql_null() then
					reason = ""
				end

				local from, to = "-", "-"
				if row["characterfrom"] ~= mysql_null() then
					from = row["characterfrom"]:gsub("_", " ")
				elseif tonumber(row["from"]) then
					num = tonumber(row["from"])
					if num < 0 then
						from = exports.cache:getFactionNameFromId(-num) or "-"
					elseif num == 0 and (type == 6 or type == 7) then
						from = "Government"
					end
				end
				if row["characterto"] ~= mysql_null() then
					to = row["characterto"]:gsub("_", " ")
				elseif tonumber(row["to"]) and tonumber(row["to"]) < 0 then
					to = exports.cache:getFactionNameFromId(-tonumber(row["to"])) or "-"
				end

				if tostring(row["from"]) == tostring(-factionID) and amount > 0 then
					amount = -amount
				end

				table.insert(transactions[week], { id = id, amount = amount, time = time, type = type, from = from, to = to, reason = reason, week = week })
				--outputDebugString("transactions["..tostring(week).."]="..tostring(#transactions[week]))
			end
			mysql:free_result(query)

			--outputDebugString("mostRecentWeek="..tostring(mostRecentWeek))
			bankThisWeek = transactions[currentWeek] or {}
			if currentWeek == 1 then
				bankPrevWeek = transactions[52] or {}
			else
				bankPrevWeek = transactions[currentWeek - 1] or {}
			end
			outputDebugString("server: bankThisWeek="..tostring(#bankThisWeek).." bankPrevWeek="..tostring(#bankPrevWeek))

			local faction = getFactionFromID(factionID)
			local bankmoney = exports.global:getMoney(faction)

			local vehicles = {}
			local result = mysql:query("SELECT vehicle_shop_id FROM vehicles WHERE faction='" .. mysql:escape_string(tostring(factionID)) .. "' AND deleted=0 AND chopped=0 AND vehicle_shop_id IS NOT NULL")
			if result then
				while true do
					local row = mysql:fetch_assoc(result)
					if not row then break end
					local vehicleShopID = tonumber(row["vehicle_shop_id"])
					if vehicleShopID > 0 then
						table.insert(vehicles, vehicleShopID)
					end
				end
				mysql:free_result(result)
			end

			local vehiclesvalue = 0
			if not vehPrice then vehPrice = {} end
			for k, v in ipairs(vehicles) do
				if vehPrice[v] then
					local price = tonumber(vehPrice[v]) or 0
					vehiclesvalue = vehiclesvalue + price
				else
					local result2 = mysql:query("SELECT vehprice FROM vehicles_shop WHERE id='" .. mysql:escape_string(tostring(v)) .. "'")
					if result2 then
						while true do
							local row = mysql:fetch_assoc(result2)
							if not row then break end
							local price = tonumber(row["vehprice"]) or 0
							vehPrice[v] = price
							vehiclesvalue = vehiclesvalue + price
						end
						mysql:free_result(result2)
					end
				end
			end

			propertyValue = 0
			local result = mysql:query("SELECT cost FROM interiors WHERE faction='" .. mysql:escape_string(tostring(factionID)) .. "' AND owner=-1")
			if result then
				while true do
					local row = mysql:fetch_assoc(result)
					if not row then break end
					local cost = tonumber(row["cost"])
					propertyValue = propertyValue + cost
				end
				mysql:free_result(result)
			end
			triggerClientEvent(client, "factionmenu:fillFinance", getResourceRootElement(), factionID, bankThisWeek, bankPrevWeek, bankmoney, vehiclesvalue, propertyValue)
		else
			outputDebugString("Mysql error @ tellTransfers", 2)
		end
	end
end

addEvent("factionmenu:getFinance", true)
addEventHandler("factionmenu:getFinance", getResourceRootElement(), getFactionFinance)


addEvent('factionmenu:setphone', true)
addEventHandler('factionmenu:setphone', root,
	function(playerName, number, factionID)
		local allowed, factionID = authorizeFactionAction(client, factionID, "set_member_duty", "set faction member phone")
		if not allowed or type(playerName) ~= "string" or #playerName < 1 or #playerName > 64 then
			return false
		end
		if number ~= nil and tostring(number) ~= "" then
			local parsedNumber = tonumber(number)
			if not parsedNumber or parsedNumber ~= math.floor(parsedNumber) or parsedNumber < 0 or parsedNumber > 99 then
				return false
			end
		end
		local targetCharacterID = exports.global:getCharacterIDFromName(playerName)
		if not targetCharacterID then return false end
		local membershipQuery = dbQuery(mysql:getConn("mta"), "SELECT id FROM characters_faction WHERE character_id=? AND faction_id=? LIMIT 1", targetCharacterID, factionID)
		local membershipRows = dbPoll(membershipQuery, 10000)
		if not membershipRows then
			dbFree(membershipQuery)
			return false
		elseif #membershipRows == 0 then
			return false
		end

		local parsedNumber = tonumber(number)
		local storedNumber = parsedNumber or "NULL"

		local success = false
		if parsedNumber then
			success = dbExec(mysql:getConn("mta"), "UPDATE characters_faction SET faction_phone=? WHERE character_id=? AND faction_id=?", storedNumber, targetCharacterID, factionID)
		else
			success = dbExec(mysql:getConn("mta"), "UPDATE characters_faction SET faction_phone=NULL WHERE character_id=? AND faction_id=?", targetCharacterID, factionID)
		end

		if success then
			local thePlayer = getPlayerFromCharacterID(targetCharacterID)
			if (thePlayer) then -- Player is online, set them
				local factionInfo = getElementData(thePlayer, "faction")
				if type(factionInfo) == "table" and factionInfo[factionID] then
					factionInfo[factionID].phone = parsedNumber
					setElementData(thePlayer, "faction", factionInfo)
				end
			end
			exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Set member phone for " .. playerName .. " to " .. tostring(storedNumber))
		end
	end)

function isLeapYear(year)
	return year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0)
end

local lastDayOfMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
function fromDatetime(string)
	local split1 = exports.global:split(string, " ")
	local date = split1[1]
	local time = split1[2]

	local datesplit = exports.global:split(date, "-")
	local year = tonumber(datesplit[1])
	local month = tonumber(datesplit[2])
	local day = tonumber(datesplit[3])

	local timesplit = exports.global:split(date, ":")
	local hour = tonumber(timesplit[1])
	local minute = tonumber(timesplit[2])
	local second = tonumber(timesplit[3])

	--calculate yearday
	local prevdays = 0
	local addmonth = 1
	while true do
		if addmonth >= month then break end
		if addmonth == 2 and isLeapYear(year) then
			prevdays = prevdays + lastDayOfMonth[addmonth] + 1
		else
			prevdays = prevdays + lastDayOfMonth[addmonth]
		end
		addmonth = addmonth + 1
	end
	local yearday = prevdays + day

	local time = { year = year, month = month, day = day, hour = hour, minute = minute, second = second, yearday = yearday }
	return time
end

function getWeekNumFromYearDay(yearday)
	local weekNum = math.floor(yearday / 7)
	return weekNum
end

-- Chaos's Custom Duty Stuff for OwlGaming > Script Stealers go away

addEvent("fetchDutyInfo", true)
addEventHandler("fetchDutyInfo", resourceRoot, function(factionID)
	local allowed, factionID = authorizeFactionAction(client, factionID, "modify_duty_settings", "view duty configuration")
	if not allowed then return false end

	local elementInfo = getElementData(resourceRoot, "DutyGUI")
	elementInfo[client] = factionID
	setElementData(resourceRoot, "DutyGUI", elementInfo)

	triggerClientEvent(client, "importDutyData", resourceRoot, custom[tonumber(factionID)], locations[tonumber(factionID)], factionID)
end)

addEvent("Duty:Grab", true)
addEventHandler("Duty:Grab", resourceRoot, function(factionID)
	local allowed, factionID = authorizeFactionAction(client, factionID, "modify_duty_settings", "view duty allowlist")
	if not allowed then return false end

	local t = getAllowList(factionID)

	triggerClientEvent(client, "gotAllow", resourceRoot, t)
end)

addEvent("Duty:GetPackages", true)
addEventHandler("Duty:GetPackages", resourceRoot, function(factionID)
	local allowed, factionID = authorizeFactionAction(client, factionID, "set_member_duty", "view member duty packages")
	if not allowed then return false end

	triggerClientEvent(client, "Duty:GotPackages", resourceRoot, custom[factionID])
end)

function refreshClient(message, factionID, dontSendToClient)
	for k, v in pairs(getElementData(resourceRoot, "DutyGUI")) do
		if dontSendToClient then
			if v == factionID and k ~= dontSendToClient then
				triggerClientEvent(k, "importDutyData", resourceRoot, custom[tonumber(factionID)], locations[tonumber(factionID)], factionID, message)
			end
		else
			if v == factionID then
				triggerClientEvent(k, "importDutyData", resourceRoot, custom[tonumber(factionID)], locations[tonumber(factionID)], factionID, message)
			end
		end
	end
	local resource = getResourceRootElement(getResourceFromName("duty"))
	if resource then
		setElementData(resource, "factionDuty", custom)
		setElementData(resource, "factionLocations", locations)
	end
end

function disconnectThem()
	local t = getElementData(resourceRoot, "DutyGUI")
	t[source] = nil
	setElementData(resourceRoot, "DutyGUI", t)
end

addEventHandler("onPlayerQuit", getRootElement(), disconnectThem)

local function isFiniteNumber(value)
	local number = tonumber(value)
	return number and number == number and number ~= math.huge and number ~= -math.huge and number
end

local function isPositiveInteger(value)
	local number = tonumber(value)
	return number and number > 0 and number == math.floor(number) and number
end

local function validDutyPayload(t, maxEntries)
	if type(t) ~= "table" then return false end
	local count = 0
	for key, value in pairs(t) do
		count = count + 1
		if count > maxEntries or (type(key) ~= "number" and type(key) ~= "string") then return false end
		if type(value) ~= "table" and type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then return false end
	end
	local ok, encoded = pcall(toJSON, t)
	return ok and type(encoded) == "string" and #encoded <= 65536
end

local function validDutyItems(dutyItems, factionID)
	if not validDutyPayload(dutyItems, 256) then return false end
	local allowedItems = {}
	for _, row in pairs(getAllowList(factionID) or {}) do
		if type(row) == "table" and tonumber(row[1]) and tonumber(row[2]) then
			allowedItems[tonumber(row[1])] = { itemID = tonumber(row[2]), value = row[3] }
		end
	end
	for key, item in pairs(dutyItems) do
		if type(item) ~= "table" or not tonumber(item[1]) or tostring(tonumber(item[1])) ~= tostring(tonumber(key)) then return false end
		local allowed = allowedItems[tonumber(item[1])]
		if not allowed or tonumber(item[2]) ~= allowed.itemID then return false end
		if allowed.itemID < 0 then
			local amount, maximum = tonumber(item[3]), tonumber(allowed.value)
			if not amount or not maximum or amount < 0 or amount > maximum then return false end
		elseif tostring(item[3]) ~= tostring(allowed.value) then
			return false
		end
	end
	return true
end

local function validDutyLocations(dutyLocations, factionID)
	if not validDutyPayload(dutyLocations, 128) then return false end
	local normalized = {}
	for key, name in pairs(dutyLocations) do
		local locationID = isPositiveInteger(key)
		local location = locationID and locations[factionID] and locations[factionID][locationID]
		if not location or type(name) ~= "string" then return false end
		normalized[tostring(locationID)] = location[2]
	end
	return normalized
end

local function validDutySkins(dutySkins, factionID)
	if not validDutyPayload(dutySkins, 256) then return false end
	local clothingQuery = dbQuery(mysql:getConn("mta"), "SELECT id, skin FROM clothing WHERE distribution=5 AND creator_char=?", -factionID)
	local clothingRows = clothingQuery and dbPoll(clothingQuery, 10000)
	if not clothingRows then
		if clothingQuery then dbFree(clothingQuery) end
		return false
	end
	local factionClothing = {}
	for _, row in ipairs(clothingRows) do
		factionClothing[tonumber(row.id)] = tonumber(row.skin)
	end
	for _, skin in pairs(dutySkins) do
		if type(skin) ~= "table" then return false end
		local modelID = tonumber(skin[1])
		if not modelID or modelID ~= math.floor(modelID) or modelID < 0 or modelID > 312 then return false end
		if skin[2] ~= "N/A" then
			local clothingID = tonumber(skin[2])
			if not clothingID or clothingID < 1 or clothingID ~= math.floor(clothingID) or factionClothing[clothingID] ~= modelID then return false end
		end
	end
	return true
end

local function authorizeDutyMutation(action, factionID)
	local allowed, id = authorizeFactionAction(client, factionID, "modify_duty_settings", action)
	if not allowed then outputChatBox("Not allowed, sorry.", client, 255, 0, 0) end
	return allowed, id
end

function addDuty(dutyItems, finalLocations, dutyNewSkins, name, factionID, dutyID)
	local allowed, factionID = authorizeDutyMutation("edit faction duty", factionID)
	if not allowed then return false end
	dutyID = tonumber(dutyID)
	local validatedLocations = validDutyLocations(finalLocations, factionID)
	if type(name) ~= "string" or #name < 1 or #name > 64 or not name:match("%S")
		or not validDutyItems(dutyItems, factionID) or not validatedLocations
		or not validDutySkins(dutyNewSkins, factionID) or not dutyID or dutyID < 0 or dutyID ~= math.floor(dutyID) then
		return false
	end
	finalLocations = validatedLocations
	if dutyID ~= 0 and (not custom[factionID] or not custom[factionID][dutyID]) then return false end

	if not custom[factionID] then
		custom[factionID] = {}
	end

	if dutyID == 0 then
		local index = getElementData(resourceRoot, "maxcindex") + 1
		mysql:query_free("INSERT INTO duty_custom SET id=" .. index .. ", factionID=" .. mysql:escape_string(factionID) .. ", name='" .. mysql:escape_string(name) .. "', skins='" .. mysql:escape_string(toJSON(dutyNewSkins)) .. "', locations='" .. mysql:escape_string(toJSON(finalLocations)) .. "', items='" .. mysql:escape_string(toJSON(dutyItems)) .. "'")
		setElementData(resourceRoot, "maxcindex", index)

		custom[factionID][index] = { index, name, dutyNewSkins, finalLocations, dutyItems }

		refreshClient("> " .. getPlayerName(client):gsub("_", " ") .. ": Added duty '" .. name .. "'.", factionID, false)
		exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Added duty " .. name .. " Database ID #" .. index)
	else
		mysql:query_free("UPDATE duty_custom SET name='" .. mysql:escape_string(name) .. "', skins='" .. mysql:escape_string(toJSON(dutyNewSkins)) .. "', locations='" .. mysql:escape_string(toJSON(finalLocations)) .. "', items='" .. mysql:escape_string(toJSON(dutyItems)) .. "' WHERE id=" .. dutyID .. " AND factionID=" .. factionID)

		custom[factionID][dutyID] = { dutyID, name, dutyNewSkins, finalLocations, dutyItems }

		refreshClient("> " .. getPlayerName(client):gsub("_", " ") .. ": Revised duty ID #" .. dutyID .. ".", factionID, false)
		exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Revised duty " .. name .. " Database ID #" .. dutyID)
	end
end

addEvent("Duty:AddDuty", true)
addEventHandler("Duty:AddDuty", resourceRoot, addDuty)

function addLocation(x, y, z, r, i, d, name, factionID, index)
	local allowed, factionID = authorizeDutyMutation("edit faction duty location", factionID)
	if not allowed then return false end
	local nx, ny, nz, radius = isFiniteNumber(x), isFiniteNumber(y), isFiniteNumber(z), isFiniteNumber(r)
	local interior, dimension = tonumber(i), tonumber(d)
	if not nx or not ny or not nz or not radius or nx < -3000 or nx > 3000 or ny < -3000 or ny > 3000
		or nz < -1000 or nz > 2000 or radius < 1 or radius > 10
		or not interior or interior < 0 or interior > 65535 or interior ~= math.floor(interior)
		or not dimension or dimension < 0 or dimension > 65535 or dimension ~= math.floor(dimension)
		or type(name) ~= "string" or #name < 1 or #name > 64 or not name:match("%S") then
		return false
	end
	x, y, z, r, i, d = nx, ny, nz, radius, interior, dimension
	if index ~= nil then
		index = isPositiveInteger(index)
		if not index or not locations[factionID] or not locations[factionID][index] or locations[factionID][index][9] then return false end
	end
	local interiorElement = exports.pool:getElement("interior", d) or d == 0
	if interiorElement then
		local interiorF = 0
		if isElement(interiorElement) then
			local interiorStatus = getElementData(interiorElement, "status")
			interiorF = type(interiorStatus) == "table" and interiorStatus.faction or 0
		end

		if tonumber(interiorF) == tonumber(factionID) or d == 0 then
			if not locations[tonumber(factionID)] then
				locations[tonumber(factionID)] = {}
			end

			if not index then -- Index is used if the event is from a edit
			local newIndex = getElementData(resourceRoot, "maxlindex") + 1
			mysql:query_free("INSERT INTO duty_locations SET id=" .. newIndex .. ", factionID=" .. mysql:escape_string(factionID) .. ", name='" .. mysql:escape_string(name) .. "', x=" .. mysql:escape_string(x) .. ", y=" .. mysql:escape_string(y) .. ", z=" .. mysql:escape_string(z) .. ", radius=" .. mysql:escape_string(r) .. ", dimension=" .. mysql:escape_string(d) .. ", interior=" .. mysql:escape_string(i))
			setElementData(resourceRoot, "maxlindex", newIndex)
			exports.duty:createDutyColShape(x, y, z, r, i, d, factionID, newIndex)
			locations[tonumber(factionID)][newIndex] = { newIndex, name, x, y, z, r, d, i, nil, nil }
			refreshClient("> " .. getPlayerName(client):gsub("_", " ") .. ": Added location '" .. name .. "'.", factionID, false)
			exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Added location, Name:" .. name .. " Database ID:" .. newIndex .. " x:" .. x .. " y:" .. y .. " z:" .. z .. " radius:" .. r .. " interior:" .. i .. " dimension:" .. d)
			else
				mysql:query_free("UPDATE duty_locations SET name='" .. mysql:escape_string(name) .. "', x=" .. mysql:escape_string(x) .. ", y=" .. mysql:escape_string(y) .. ", z=" .. mysql:escape_string(z) .. ", radius=" .. mysql:escape_string(r) .. ", dimension=" .. mysql:escape_string(d) .. ", interior=" .. mysql:escape_string(i) .. " WHERE id=" .. index .. " AND factionID=" .. factionID)
				exports.duty:destroyDutyColShape(factionID, index)
				exports.duty:createDutyColShape(x, y, z, r, i, d, factionID, index)
				locations[tonumber(factionID)][index] = { index, name, x, y, z, r, d, i, nil, nil }
				refreshClient("> " .. getPlayerName(client):gsub("_", " ") .. ": Revised location ID #" .. index .. ".", factionID, false)
				exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Revised location ID #" .. index .. " x:" .. x .. " y:" .. y .. " z:" .. z .. " radius:" .. r .. " interior:" .. i .. " dimension:" .. d)
			end
		else
			outputChatBox("The interior you entered must be owned by the faction to be added as a duty location.", client, 255, 0, 0)
		end
	else
		outputChatBox("Server could not find the interior you entered!", client, 255, 0, 0)
	end
end

addEvent("Duty:AddLocation", true)
addEventHandler("Duty:AddLocation", resourceRoot, addLocation)

function addVehicle(vehicleID, factionID)
	local allowed, factionID = authorizeDutyMutation("add faction duty vehicle", factionID)
	if not allowed then return false end
	vehicleID = isPositiveInteger(vehicleID)
	if not vehicleID then return false end
	local element = exports.pool:getElement("vehicle", vehicleID)
	if element then
		if tonumber(getElementData(element, "faction")) == factionID then
			local newIndex = getElementData(resourceRoot, "maxlindex") + 1
			mysql:query_free("INSERT INTO duty_locations SET id=" .. newIndex .. ", factionID=" .. mysql:escape_string(factionID) .. ", name='VEHICLE', vehicleid=" .. mysql:escape_string(vehicleID) .. ", model=" .. getElementModel(element))
			setElementData(resourceRoot, "maxlindex", newIndex)
			if not locations[tonumber(factionID)] then
				locations[tonumber(factionID)] = {}
			end
			locations[tonumber(factionID)][newIndex] = { newIndex, "VEHICLE", nil, nil, nil, nil, nil, nil, tonumber(vehicleID), getElementModel(element) }
			refreshClient("> " .. getPlayerName(client):gsub("_", " ") .. ": Added vehicle #" .. vehicleID .. ".", factionID, false)
			exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Added Vehicle #" .. vehicleID .. " Database ID:" .. newIndex)
			--outputChatBox("Added vehicle "..vehicleID.." successfully.", client, 0, 255, 0)
		else
			outputChatBox("You can only add faction vehicles as duty locations.", client, 255, 0, 0)
		end
	else
		outputChatBox("Error finding your vehicle, did you type the ID in right?", client, 255, 0, 0)
	end
end

addEvent("Duty:AddVehicle", true)
addEventHandler("Duty:AddVehicle", resourceRoot, addVehicle)

function removeLocation(removeID, factionID)
	local allowed, factionID = authorizeDutyMutation("remove faction duty location", factionID)
	if not allowed then return false end
	removeID = isPositiveInteger(removeID)
	if not removeID or not locations[factionID] or not locations[factionID][removeID] then return false end
	locations[factionID][removeID] = nil
	exports.duty:destroyDutyColShape(factionID, removeID)
	mysql:query_free("DELETE FROM duty_locations WHERE id=" .. removeID .. " AND factionID=" .. factionID)
	exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Removed Location #" .. removeID)
	--outputChatBox("Duty Location removed!", client, 0, 255, 0)

	refreshClient("> " .. getPlayerName(client):gsub("_", " ") .. ": removed location " .. removeID .. ".", factionID, client)
end

addEvent("Duty:RemoveLocation", true)
addEventHandler("Duty:RemoveLocation", resourceRoot, removeLocation)

function removeDuty(removeID, factionID)
	local allowed, factionID = authorizeDutyMutation("remove faction duty package", factionID)
	if not allowed then return false end
	removeID = isPositiveInteger(removeID)
	if not removeID or not custom[factionID] or not custom[factionID][removeID] then return false end
	custom[factionID][removeID] = nil
	mysql:query_free("DELETE FROM duty_custom WHERE id=" .. removeID .. " AND factionID=" .. factionID)
	exports.logs:dbLog(client, 35, "fa" .. tostring(factionID), "Removed duty #" .. removeID)
	--outputChatBox("Custom Duty Loadout removed!", client, 0, 255, 0)

	refreshClient("> " .. getPlayerName(client):gsub("_", " ") .. ": removed duty " .. removeID .. ".", factionID, client)
end

addEvent("Duty:RemoveDuty", true)
addEventHandler("Duty:RemoveDuty", resourceRoot, removeDuty)


addCommandHandler('gotoduty',
	function(player, command, id)
		if integration:isPlayerTrialAdmin(player) then
			if id then
				local conn = mysql:getConn()
				local query = conn:query('SELECT name, x, y, z, dimension, interior FROM duty_locations WHERE id = ? LIMIT 1', id)
				local result = query:poll(-1)

				if #result == 1 then
					local location = result[1]
					player:setDimension(location.dimension)
					player:setInterior(location.interior)
					player:setPosition(location.x, location.y, location.z)
					outputChatBox('You have teleported to [' .. location.name ..'] duty location.', player, 100, 255, 100)
				else
					outputChatBox('No such duty location exists with ID: ' .. id, player, 255, 100, 100)
				end
			else
				outputChatBox('Syntax: /' .. command .. ' [location id]', player, 255, 194, 14)
			end
		end
	end,
	false,
	false
)

function allocateFactionRank(query)
	local factionRanks = {}
	local factionWages = {}
	if query then
		local theTeam = nil
        local pollResult = dbPoll(query, -1)
        if not pollResult then
            dbFree(query)
            return
        else
			for i, row in pairs(pollResult) do
				theTeam = getFactionFromID(tonumber(row['faction_id']))
				local rankID = tonumber(row.id)
				factionRanks[rankID] = row.name
				factionWages[rankID] = row.wage
			end
			exports.anticheat:setEld(theTeam, "ranks", factionRanks, 'all')
			exports.anticheat:setEld(theTeam, "wages", factionWages, 'all')
        end
	end
    dbFree(query)
end 

addEvent("faction-system.showChangeRankGUI", true)
addEventHandler("faction-system.showChangeRankGUI", root, function(playerName, factionID)
	local allowed, factionID = authorizeFactionAction(client, factionID, "change_member_rank", "open member rank editor")
	if not allowed or type(playerName) ~= "string" or #playerName < 1 or #playerName > 64 then return false end
	local targetCharacterID = exports.global:getCharacterIDFromName(playerName)
	if not targetCharacterID then return false end
	local membershipQuery = dbQuery(exports.mysql:getConn("mta"), "SELECT faction_rank FROM characters_faction WHERE character_id=? AND faction_id=? LIMIT 1", targetCharacterID, factionID)
	local membershipRows = dbPoll(membershipQuery, 10000)
	if not membershipRows or #membershipRows == 0 then
		if not membershipRows then dbFree(membershipQuery) end
		return false
	end

	local ranks = {}	-- Ranks Table
	local def_table		-- Default Rank Table

	local theTeam = getFactionFromID(factionID)
	local rankOrder = getElementData(theTeam, "rank_order") or ""
	rankOrder = split(rankOrder, ",")

	for i,rankID in ipairs(rankOrder) do
		local rankID = tonumber(rankID)
		local rankName = getRankName(rankID)
		table.insert(ranks, {rankID, rankName})
	end
	triggerClientEvent(client, "faction-system.showChangeRankGUI", resourceRoot, ranks, playerName, rankName)
end)

addEvent("faction-system.saveNewRank", true)
addEventHandler("faction-system.saveNewRank", root, 
	function(playerName, oldRank, newRank, factionID)
		local allowed, fID = authorizeFactionAction(client, factionID, "change_member_rank", "change member rank")
		if not allowed or type(playerName) ~= "string" or #playerName < 1 or #playerName > 64
			or type(oldRank) ~= "string" or type(newRank) ~= "string" then return false end
		local oldRank = getFactionRankIDByName(fID, oldRank)
		local newRank = getFactionRankIDByName(fID, newRank)
		local charID = exports.global:getCharacterIDFromName(playerName)
		if not oldRank or not newRank or getRankFaction(oldRank) ~= fID or getRankFaction(newRank) ~= fID or not charID then return false end
		local membershipQuery = dbQuery(exports.mysql:getConn("mta"), "SELECT cf.faction_rank FROM characters_faction cf INNER JOIN characters c ON c.id=cf.character_id WHERE cf.character_id=? AND cf.faction_id=? AND c.charactername=? LIMIT 1", charID, fID, playerName)
		local membershipRows = dbPoll(membershipQuery, 10000)
		if not membershipRows or #membershipRows == 0 or tonumber(membershipRows[1].faction_rank) ~= oldRank then
			if not membershipRows then dbFree(membershipQuery) end
			return false
		end

		if (oldRank == newRank) then
			outputChatBox("You cannot change a person's faction rank to the same rank.", client, 255, 125, 0)
			return
		end
		
		if not dbExec(exports.mysql:getConn("mta"), "UPDATE `characters_faction` SET `faction_rank` = ? WHERE `character_id` = ? AND `faction_id` = ?", newRank, charID, fID) then return false end
		local highOrLow = ""
		if (getSeniorRank(fID, newRank, oldRank) == newRank) then
			highOrLow = "promoted"
		else
			highOrLow = "demoted"
		end
		local thePlayer = exports.global:getPlayerFromCharacterID(charID)
		if thePlayer then
			local factionInfo = getElementData(thePlayer, "faction")
			if type(factionInfo) == "table" and factionInfo[fID] then
				factionInfo[fID].rank = newRank
				exports.anticheat:changeProtectedElementDataEx(thePlayer, "faction", factionInfo, true)
			end
		end	

		local rankName = getRankName(newRank)
		exports.factions:sendNotiToAllFactionMembers(fID, playerName:gsub("_", " ") .. " was "..highOrLow.." from '" .. getRankName(oldRank) .. "' to '" .. rankName .. "' by "..getPlayerName(client):gsub("_", " "))
		exports.logs:dbLog(client, 35, "fa" .. tostring(fID), "Changed faction rank for " .. playerName .. " from " .. tostring(oldRank) .. " to " .. tostring(newRank))
	end
)
