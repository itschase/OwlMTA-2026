--[[
* ***********************************************************************************************************************
* Copyright (c) 2016 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

local function getMapAccountId(player)
	if not isElement(player) or getElementData(player, 'loggedin') ~= 1 then
		return false
	end
	local accountId = tonumber(getElementData(player, 'account:id'))
	if not accountId or accountId < 1 or accountId ~= math.floor(accountId) then
		return false
	end
	return accountId
end

local function getValidMapId(mapId)
	mapId = tonumber(mapId)
	if not mapId or mapId < 1 or mapId ~= math.floor(mapId) then
		return false
	end
	return mapId
end

local function canReviewMap(player, uploaderId)
	if not getMapAccountId(player) or not canAdminMaps(player) then
		return false
	end
	-- Preserve the UI rule that only scripters and mapping team leaders can review their own uploads.
	if tonumber(uploaderId) == tonumber(getElementData(player, 'account:id'))
		and not exports.integration:isPlayerScripter(player)
		and not exports.integration:isPlayerMappingTeamLeader(player) then
		return false
	end
	return true
end

local function canTestMap(player, uploaderId)
	if not getMapAccountId(player) or not canAccessMgmtTab(player) then
		return false
	end
	if tonumber(uploaderId) == tonumber(getElementData(player, 'account:id'))
		and not exports.integration:isPlayerScripter(player)
		and not exports.integration:isPlayerMappingTeamLeader(player) then
		return false
	end
	return true
end

local function getMapRequest(mapId)
	local query = dbQuery(exports.mysql:getConn('mta'),
		"SELECT id, uploader, type, approved, enabled FROM maps WHERE id=? LIMIT 1", mapId)
	local rows, count = dbPoll(query, 10000)
	if rows and count > 0 then
		return rows[1]
	end
	if not rows then
		dbFree(query)
	end
	return false
end

local function validRequestText(value, minimum, maximum)
	return type(value) == 'string' and #value >= minimum and #value <= maximum
end

addEvent( 'maps:managerTabSync', true )
addEventHandler( 'maps:managerTabSync', resourceRoot, function( tabID, dontShowPopUp )
	if not getMapAccountId(client) then return end
	tabID = tonumber(tabID)
	if tabID == 1 then -- my reqs
		dbQuery( function( qh, client, tabID )
			local res, nums, id = dbPoll( qh, 0 )
			if res then
				triggerLatentClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'ok', res, dontShowPopUp )
			else
				dbFree( qh )
				triggerClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'Error code 21 occurred while synchronizing data.', nil, dontShowPopUp )
			end
		end , { client, tabID }, exports.mysql:getConn('mta'), "SELECT m.*, m.reviewer AS reviewer FROM maps m WHERE uploader=? ORDER BY m.approved, m.enabled, m.id DESC", getElementData( client, 'account:id' ) )
	elseif tabID == 3 then --mgmt
		if not canAccessMgmtTab(client) then return end
		dbQuery( function( qh, client, tabID )
			local res, nums, id = dbPoll( qh, 0 )
			if res then
				triggerLatentClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'ok', res, dontShowPopUp )
			else
				dbFree( qh )
				triggerClientEvent( client, 'maps:populateTab', resourceRoot, tabID, 'Error code 21 occurred while synchronizing data.', nil, dontShowPopUp )
			end
		end , { client, tabID }, exports.mysql:getConn('mta'), "SELECT m.*, m.reviewer AS reviewer_name, m.uploader AS uploader_name FROM maps m ORDER BY m.approved, m.enabled, m.id DESC" )
	end
end)

addEvent( 'maps:submitExteriorMapRequest', true )
addEventHandler( 'maps:submitExteriorMapRequest', resourceRoot, function( name, url, who, what, why, map ) 
	local accountId = getMapAccountId(client)
	if not accountId then
		return
	end
	if not validRequestText(name, 1, 100) or not validRequestText(url, 1, 200)
		or not validRequestText(who, 1, 200) or not validRequestText(what, 1, 200)
		or not validRequestText(why, 1, 200) or not validateSubmittedMap(map, settings.external_map_max_objects) then
		triggerClientEvent(client, 'maps:exteriorMapRequestResponse', resourceRoot, 'Invalid map request data.')
		return
	end
	if not canAdminMaps( client ) then
		local check = dbQuery( exports.mysql:getConn('mta'), "SELECT COUNT(id) AS count FROM maps WHERE approved=0 AND type='exterior' AND uploader=?", accountId )
		local res1, nums1, id1 = dbPoll( check, 10000 )
		if res1 and nums1 > 0 then	
			if res1[1].count >= settings.external_map_max_concurrent_requests then
				return not triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, "You're currently having "..res1[1].count.." pending approval maps. Please wait or cancel your previous requests." )
			end
		else
			dbFree( check )
			triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, 'Internal Error. Code 34.' )
		end
	end

	local done, why_failed = submitExteriorMapRequest ( name, url, who, what, why, map, client ) 
	triggerClientEvent( client, 'maps:exteriorMapRequestResponse', resourceRoot, done and 'ok' or why_failed )
end )

addEvent( 'maps:updateReq', true )
addEventHandler( 'maps:updateReq', resourceRoot, function ( tabid, name, url, who, what, why, id ) 
	local accountId, mapId = getMapAccountId(client), getValidMapId(id)
	tabid = tonumber(tabid)
	if not accountId or not mapId or (tabid ~= 1 and tabid ~= 3)
		or not validRequestText(name, 1, 100) or not validRequestText(url, 1, 200)
		or not validRequestText(who, 1, 200) or not validRequestText(what, 1, 200)
		or not validRequestText(why, 2, 200) then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'Invalid map request data.')
		return
	end
	local request = getMapRequest(mapId)
	local authorized = request and ((tabid == 1 and tonumber(request.uploader) == accountId)
		or (tabid == 3 and canReviewMap(client, request.uploader)))
	if not authorized then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'You are not authorized to update this map request.')
		return
	end
	if tonumber(request.approved) ~= 0 or tonumber(request.enabled) ~= 0 or exports.map_load:isMapLoaded(mapId) then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'Only a pending, unloaded request can be updated.')
		return
	end
	local function updateComplete(qh, player)
		local res, affectedRows = dbPoll(qh, 0)
		if res and affectedRows > 0 then
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot, 'ok', tabid)
		else
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot,
				res and 'This request is no longer pending.' or 'Errors occurred while updating map data. Code 64.')
		end
	end
	if tabid == 3 then
		local auditNote = getCurrentTimeString().." "..exports.global:getPlayerFullIdentity(client, 1)..": Updated map request details.\n"
		dbQuery(updateComplete, { client }, exports.mysql:getConn('mta'),
			"UPDATE maps SET name=?, preview=?, used_by=?, purposes=?, reasons=?, note=CONCAT(note, ?), reviewer=? WHERE id=? AND approved=0 AND enabled=0",
			name, url, who, what, why, auditNote, accountId, mapId)
	else
		dbQuery(updateComplete, { client }, exports.mysql:getConn('mta'),
			"UPDATE maps SET name=?, preview=?, used_by=?, purposes=?, reasons=? WHERE id=? AND uploader=? AND approved=0 AND enabled=0",
			name, url, who, what, why, mapId, accountId)
	end
end )

addEvent( 'maps:delReq', true )
addEventHandler( 'maps:delReq', resourceRoot, function ( tabID, id ) 
	local accountId, mapId = getMapAccountId(client), getValidMapId(id)
	tabID = tonumber(tabID)
	if not accountId or not mapId or (tabID ~= 1 and tabID ~= 3) then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'Invalid map request ID.')
		return
	end
	local request = getMapRequest(mapId)
	local isUploaderDelete = request and tabID == 1 and tonumber(request.uploader) == accountId and tonumber(request.approved) == 0
	local isModeratorDelete = request and tabID == 3 and canReviewMap(client, request.uploader)
	if not isUploaderDelete and not isModeratorDelete then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'You are not authorized to delete this map request.')
		return
	end
	if tonumber(request.enabled) ~= 0 or exports.map_load:isMapLoaded(mapId) then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'A loaded map request cannot be deleted.')
		return
	end
	local function deleteComplete(qh, player, deletedMapId, moderatorDelete)
		local res, affectedRows = dbPoll(qh, 0)
		if res and affectedRows > 0 then
			dbExec(exports.mysql:getConn('mta'), "DELETE FROM maps_objects WHERE map_id=?", deletedMapId)
			if moderatorDelete then
				exports.logs:dbLog(player, 4, player, "Deleted map request #"..deletedMapId)
			end
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot, 'ok', tabID)
		else
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot,
				res and 'This request can no longer be deleted.' or 'Errors occurred while deleting map data. Code 73.')
		end
	end
	if isUploaderDelete then
		dbQuery(deleteComplete, { client, mapId }, exports.mysql:getConn('mta'),
			"DELETE FROM maps WHERE id=? AND uploader=? AND approved=0 AND enabled=0", mapId, accountId)
	else
		dbQuery(deleteComplete, { client, mapId, true }, exports.mysql:getConn('mta'),
			"DELETE FROM maps WHERE id=? AND enabled=0", mapId)
	end
end )

addEvent( 'maps:testMap', true )
addEventHandler( 'maps:testMap', resourceRoot, function ( map_id ) 
	local accountId, mapId = getMapAccountId(client), getValidMapId(map_id)
	if not accountId or not mapId or not canAccessMgmtTab(client) then return end
	local request = getMapRequest(mapId)
	if not request or not canTestMap(client, request.uploader) then return end
	local res = exports.map_load:getMapObjects( mapId )
	if res then
		triggerLatentClientEvent( client, 'maps:testMap', resourceRoot, 'ok', res, mapId )
	else
		triggerClientEvent( client, 'maps:testMap', resourceRoot, 'Errors occurred while querying map contents. Code 97.' )
	end
end)

addEvent( 'maps:approveRequest', true )
addEventHandler( 'maps:approveRequest', resourceRoot, function( map_id, note, accepting )
	local accountId, mapId = getMapAccountId(client), getValidMapId(map_id)
	if not accountId or not mapId or type(note) ~= 'string' or #note < 2 or #note > 200 or type(accepting) ~= 'boolean' then return end
	local lookup = dbQuery(exports.mysql:getConn('mta'), "SELECT uploader FROM maps WHERE id=? AND type='exterior' LIMIT 1", mapId)
	local rows, count = dbPoll(lookup, 10000)
	if not rows or count < 1 or not canReviewMap(client, rows[1].uploader) then return end
	local auditNote = getCurrentTimeString().." "..exports.global:getPlayerFullIdentity(client, 1)..": "..(accepting and "ACCEPTED" or "DECLINED")..". "..note.."\n"
	dbQuery(function(qh, player, requestId, savedNote, isAccepting)
		local res, affectedRows = dbPoll(qh, 0)
		if res and affectedRows > 0 then
			triggerClientEvent(player, 'maps:approveRequest', resourceRoot, 'ok', requestId, isAccepting)
			notifyPlayer(requestId, "Your exterior map addition request status updates.", "Hello <Username>!\n\nYour exterior map addition request #"..requestId.." has been "..(isAccepting and "ACCEPTED" or "DECLINED")..".\n\n"..savedNote.."\nSincerely,\nOwlGaming Community\nOwlGaming Mapping Team")
		else
			triggerClientEvent(player, 'maps:approveRequest', resourceRoot,
				res and 'This request has already been reviewed or is no longer pending.' or 'Errors occurred while processing request. Code 110.')
		end
	end, { client, mapId, auditNote, accepting }, exports.mysql:getConn('mta'),
		"UPDATE maps SET approved=?, note=CONCAT(note, ?), reviewer=? WHERE id=? AND type='exterior' AND approved=0 AND enabled=0",
		accepting and 1 or 2, auditNote, accountId, mapId)
end)

addEvent( 'maps:implement', true )
addEventHandler( 'maps:implement', resourceRoot, function( map_id, implementing )
	local accountId, mapId = getMapAccountId(client), getValidMapId(map_id)
	if not accountId or not mapId or type(implementing) ~= 'boolean' then return end
	local lookup = dbQuery(exports.mysql:getConn('mta'), "SELECT uploader FROM maps WHERE id=? AND type='exterior' LIMIT 1", mapId)
	local rows, count = dbPoll(lookup, 10000)
	if not rows or count < 1 or not canReviewMap(client, rows[1].uploader) then return end
	local auditNote = getCurrentTimeString().." "..exports.global:getPlayerFullIdentity(client, 1)..": "..(implementing and "Implemented map." or "Disabled map.").."\n"
	local requiredEnabled = implementing and 0 or 1
	dbQuery(function(qh, player, requestId, savedNote, isImplementing, reviewerId)
		local res, affectedRows = dbPoll(qh, 0)
		if res and affectedRows > 0 then
			local changed
			if isImplementing then
				changed = exports.map_load:loadMap(requestId)
			else
				changed = exports.map_load:unloadMap(requestId)
			end
			if changed then
				dbQuery(function(auditQh, auditPlayer, auditRequestId, auditSavedNote, auditImplementing)
					local auditRes, auditRows = dbPoll(auditQh, 0)
					if auditRes and auditRows > 0 then
						triggerClientEvent(auditPlayer, 'maps:implement', resourceRoot, 'ok', auditRequestId, auditImplementing)
						notifyPlayer(auditRequestId, "Your exterior map status updates.", "Hello <Username>!\n\nYour exterior map #"..auditRequestId.." has been "..(auditImplementing and "IMPLEMENTED" or "DISABLED")..".\n\n"..auditSavedNote.."\nSincerely,\nOwlGaming Community\nOwlGaming Mapping Team")
					else
						local runtimeRolledBack
						if auditImplementing then
							runtimeRolledBack = exports.map_load:unloadMap(auditRequestId)
						else
							runtimeRolledBack = exports.map_load:loadMap(auditRequestId)
						end
						local databaseRolledBack = dbExec(exports.mysql:getConn('mta'), "UPDATE maps SET enabled=? WHERE id=? AND enabled=?", auditImplementing and 0 or 1, auditRequestId, auditImplementing and 1 or 0)
						if not runtimeRolledBack or not databaseRolledBack then
							outputDebugString("[MAPS] Incomplete deployment rollback for map request #"..tostring(auditRequestId), 1)
							triggerClientEvent(auditPlayer, 'maps:implement', resourceRoot, 'Map status recovery was incomplete. Code 125.')
						else
							triggerClientEvent(auditPlayer, 'maps:implement', resourceRoot, 'Errors occurred while recording the map status change. Code 123.')
						end
					end
				end, { player, requestId, savedNote, isImplementing }, exports.mysql:getConn('mta'),
					"UPDATE maps SET note=CONCAT(note, ?), reviewer=? WHERE id=? AND enabled=?",
					savedNote, reviewerId, requestId, isImplementing and 1 or 0)
			else
				local databaseRolledBack = dbExec(exports.mysql:getConn('mta'), "UPDATE maps SET enabled=? WHERE id=? AND enabled=?", isImplementing and 0 or 1, requestId, isImplementing and 1 or 0)
				if not databaseRolledBack then
					outputDebugString("[MAPS] Failed to roll back enabled state for map request #"..tostring(requestId), 1)
					triggerClientEvent(player, 'maps:implement', resourceRoot, 'Map status recovery was incomplete. Code 125.')
				else
					triggerClientEvent(player, 'maps:implement', resourceRoot, 'Errors occurred while '..(isImplementing and 'implementing' or 'disabling')..' the map. Code 122.')
				end
			end
		else
			triggerClientEvent(player, 'maps:implement', resourceRoot,
				res and 'Only an accepted map can be implemented, and only an enabled map can be disabled.' or 'Errors occurred while processing request. Code 124.')
		end
	end, { client, mapId, auditNote, implementing, accountId }, exports.mysql:getConn('mta'),
		"UPDATE maps SET enabled=? WHERE id=? AND type='exterior' AND approved=1 AND enabled=?",
		implementing and 1 or 0, mapId, requiredEnabled)
end )
