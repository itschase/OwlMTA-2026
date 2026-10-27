local function canSaveDescription(player, theVehicle)
	if not (isElement(player) and getElementType(player) == "player" and isElement(theVehicle) and getElementType(theVehicle) == "vehicle") then
		return false
	end
	local playerId = getElementData(player, "dbid")
	local dbid = tonumber(getElementData(theVehicle, "dbid"))
	if not dbid or dbid <= 0 then
		return false
	end
	local factionId = getElementData(theVehicle, "faction")
	local owner = getElementData(theVehicle, "owner")

	return exports.global:hasItem(player, 3, dbid)
		or owner == playerId
		or exports.global:hasItem(theVehicle, 3, dbid)
		or exports.factions:isPlayerInFaction(player, factionId)
		or exports.integration:isPlayerTrialAdmin(player)
end

function saveToDescription(descriptions, requestedVehicle)
	local player = client
	if not (player and isElement(player) and getElementType(player) == "player" and source == player) then
		return false
	end

	local theVehicle = getPedOccupiedVehicle(player)
	if not theVehicle or requestedVehicle ~= theVehicle or not canSaveDescription(player, theVehicle) then
		return false
	end
	if type(descriptions) ~= "table" then
		return false
	end
	for i = 1, 5 do
		if type(descriptions[i]) ~= "string" or #descriptions[i] > 300 then
			return false
		end
	end
	if descriptions[6] ~= nil and (type(descriptions[6]) ~= "string" or #descriptions[6] > 300 or not exports.integration:isPlayerTrialAdmin(player)) then
		return false
	end

	local dbid = getElementData(theVehicle, "dbid")
	local connection = exports.mysql:getConn("mta")
	if not connection then
		return false
	end
	for i = 1, 5 do
		dbExec(connection, "UPDATE `vehicles` SET `??` = ? WHERE id = ?", "description"..i, tostring(descriptions[i]), tostring(dbid))
	
		exports.anticheat:changeProtectedElementDataEx(theVehicle, "description:"..i, descriptions[i], true)

	end
	if descriptions[6] then
		dbExec(connection, "UPDATE `vehicles` SET `descriptionadmin` = ? WHERE id = ?", tostring(descriptions[6]), dbid )
		exports.anticheat:changeProtectedElementDataEx(theVehicle, "description:admin", descriptions[6], true)
	end

	outputChatBox("Description saved succesfully.", player, 0, 255, 0)
	return true
	
	
end
addEvent("saveDescriptions", true)
addEventHandler("saveDescriptions", getRootElement(), saveToDescription)
