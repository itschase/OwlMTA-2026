--Maxime
mysql = exports.mysql

local function getActiveAccount(player)
	if not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "loggedin") ~= 1 then
		return false
	end
	local accountID = tonumber(getElementData(player, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID) then
		return false
	end
	return accountID
end

-- Only accept a bounded list of integer notification IDs from network events.
local function getNotificationIDs(ids)
	if type(ids) == "number" or type(ids) == "string" then
		ids = { ids }
	end
	if type(ids) ~= "table" then
		return {}
	end
	local validated, seen = {}, {}
	for index = 1, 15 do
		local value = ids[index]
		if value == nil then break end
		local id = tonumber(value)
		if id and id >= 1 and id <= 2147483647 and id == math.floor(id) and not seen[id] then
			validated[#validated + 1] = id
			seen[id] = true
			if #validated >= 15 then break end
		end
	end
	return validated
end

local function updateNotifications(accountID, ids, markRead)
	ids = getNotificationIDs(ids)
	if #ids == 0 then return end
	local quoted = {}
	for _, id in ipairs(ids) do quoted[#quoted + 1] = tostring(id) end
	local quotedIDs = table.concat(quoted, ",")
	if markRead then
		mysql:query_free("UPDATE notifications SET `read`=1 WHERE userid="..accountID.." AND id IN ("..quotedIDs..")")
	else
		mysql:query_free("DELETE FROM notifications WHERE userid="..accountID.." AND id IN ("..quotedIDs..")")
	end
end

function givePmsToClient (deletes, reads)
	local userID = getActiveAccount(source)
	if not userID then
		return false
	end

	if deletes then
		updateNotifications(userID, deletes, false)
	end

	if reads then
		updateNotifications(userID, reads, true)
	end

	local noties = {}
	local excludeList = ""
	if getElementData(source, "noti_faction_updates") == "0" then
		excludeList = excludeList.." AND type != 'noti_faction_updates' "
	end
	if getElementData(source, "vehicle_inactivity_scanner") == "0" then
		excludeList = excludeList.." AND type != 'vehicle_inactivity_scanner' "
	end
	if getElementData(source, "support_center") == "0" then
		excludeList = excludeList.." AND type != 'support_center' "
	end
	if getElementData(source, "interior_inactivity_scanner") == "0" then
		excludeList = excludeList.." AND type != 'interior_inactivity_scanner' "
	end
	if getElementData(source, "noti_offline_pm") == "0" then
		excludeList = excludeList.." AND type NOT REGEXP '[0-9]+' "
	end

	local q = mysql:query("SELECT *, DATE_FORMAT(date,'%b %d, %Y %h:%i %p') AS fdate, TO_SECONDS(date) as datesec FROM notifications WHERE userid="..userID.." AND 1=1 "..excludeList.." ORDER BY `read` ASC, date DESC LIMIT 15")
	while true do
		local row = mysql:fetch_assoc(q)
		if not row then break end
		table.insert(noties, row )
	end
	mysql:free_result(q)

	triggerClientEvent(source, "integration:getPmsFromServer", source, noties)
	--outputDebugString("integration:givePmsToClient - "..getPlayerName(source))  Uncomment if you actually need to debug.
end
addEvent( "integration:givePmsToClient", true )
addEventHandler( "integration:givePmsToClient", root, givePmsToClient )

function readNoti(i)
	local accountID = getActiveAccount(client)
	local ids = getNotificationIDs(i)
	if not accountID or #ids ~= 1 then return false end
	local notification = mysql:query_fetch_assoc("SELECT `type`, details FROM notifications WHERE userid="..accountID.." AND id="..ids[1].." AND `read`=0 LIMIT 1")
	if not notification then return false end
	updateNotifications(accountID, ids, true)
	local senderID = tonumber(notification.type)
	local receiverName = getElementData(client, "account:username")
	if senderID and receiverName then
		local details = notification.details or ""
		if string.len(details) > 20 then details = string.sub(details, 1, 20)..".." end
		makePlayerNotification(senderID, receiverName.." has seen your PM '"..details.."'")
	end
end
addEvent( "readNoti", true )
addEventHandler( "readNoti", root, readNoti )

function deleteNoti(i)
	local accountID = getActiveAccount(client)
	if accountID then updateNotifications(accountID, i, false) end
end
addEvent( "deleteNoti", true )
addEventHandler( "deleteNoti", root, deleteNoti )

function clearNotis(deletes, reads)
	local id = getActiveAccount(client)
	if not id then return false end
	updateNotifications(id, deletes, false)
	updateNotifications(id, reads, true)
	mysql:query_free("DELETE FROM notifications WHERE userid="..id.." ORDER BY `read` ASC, date DESC LIMIT 15") -- Only allow them to delete the last 15.
	triggerEvent("integration:givePmsToClient", client)
	outputChatBox("Deleted latest 15 notifications.", client, 255, 0, 0)
end
addEvent("clearNotis", true)
addEventHandler("clearNotis", root, clearNotis)

function makePlayerNotification(player, title, details, type)
	local id = nil
	local elementFound = nil
	if isElement(player) and getElementType(player) == "player" then
		id = getElementData(player, "account:id")
		elementFound = player
	elseif tonumber(player) then
		id = tonumber(player)
	end
	if not id then
		return false
	end
	if not elementFound then
		for i, p in pairs(getElementsByType("player")) do
			if getElementData(p, "account:id") == id then
				elementFound = p
				break
			end
		end
	end

	mysql:query_free("INSERT INTO notifications SET userid="..id..", title='"..mysql:escape_string(title).."', "..(details and string.len(details)>0 and ("details='"..mysql:escape_string(details).."',") or "").." type='"..(type or "other").."'")
	if elementFound and getElementData(elementFound, "loggedin") == 1 then
		triggerEvent("integration:givePmsToClient", elementFound)
	end

	return true
end
