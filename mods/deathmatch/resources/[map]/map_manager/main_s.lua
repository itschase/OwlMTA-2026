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

addEvent( 'maps:managerTabSync', true )
addEventHandler( 'maps:managerTabSync', resourceRoot, function( tabID, dontShowPopUp )
	if not getMapAccountId(client) then return end
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
	if not accountId or type(map) ~= 'table' then
		triggerClientEvent(client, 'maps:exteriorMapRequestResponse', resourceRoot, 'You must be logged in to submit a map request.')
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
	if not accountId or not mapId or type(name) ~= 'string' or type(url) ~= 'string'
		or type(who) ~= 'string' or type(what) ~= 'string' or type(why) ~= 'string'
		or #name < 1 or #name > 100 or #url < 1 or #url > 200
		or #who < 1 or #who > 200 or #what < 1 or #what > 200 or #why < 2 or #why > 200 then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'Invalid map request data.')
		return
	end
	if exports.map_load:isMapLoaded(mapId) then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'A loaded map request cannot be updated.')
		return
	end
	dbQuery(function(qh, player)
		local res, affectedRows = dbPoll(qh, 0)
		if res and affectedRows > 0 then
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot, 'ok', 1)
		else
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot,
				res and 'Only the uploader may update a pending request.' or 'Errors occurred while updating map data. Code 64.')
		end
	end, { client }, exports.mysql:getConn('mta'),
		"UPDATE maps SET name=?, preview=?, used_by=?, purposes=?, reasons=? WHERE id=? AND uploader=? AND approved=0 AND enabled=0",
		name, url, who, what, why, mapId, accountId)
end )

addEvent( 'maps:delReq', true )
addEventHandler( 'maps:delReq', resourceRoot, function ( tabID, id ) 
	local accountId, mapId = getMapAccountId(client), getValidMapId(id)
	if not accountId or not mapId then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'Invalid map request ID.')
		return
	end
	if exports.map_load:isMapLoaded(mapId) then
		triggerClientEvent(client, 'maps:updateMyReqResponse', resourceRoot, 'A loaded map request cannot be deleted.')
		return
	end
	dbQuery(function(qh, player, deletedMapId)
		local res, affectedRows = dbPoll(qh, 0)
		if res and affectedRows > 0 then
			dbExec(exports.mysql:getConn('mta'), "DELETE FROM maps_objects WHERE map_id=?", deletedMapId)
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot, 'ok', 1)
		else
			triggerClientEvent(player, 'maps:updateMyReqResponse', resourceRoot,
				res and 'Only the uploader may delete a pending request.' or 'Errors occurred while deleting map data. Code 73.')
		end
	end, { client, mapId }, exports.mysql:getConn('mta'),
		"DELETE FROM maps WHERE id=? AND uploader=? AND approved=0 AND enabled=0", mapId, accountId)
end )

addEvent( 'maps:testMap', true )
addEventHandler( 'maps:testMap', resourceRoot, function ( map_id ) 
	local accountId, mapId = getMapAccountId(client), getValidMapId(map_id)
	if not accountId or not mapId or not canAccessMgmtTab(client) then return end
	local lookup = dbQuery(exports.mysql:getConn('mta'), "SELECT uploader, approved FROM maps WHERE id=? LIMIT 1", mapId)
	local mapRows, mapCount = dbPoll(lookup, 10000)
	if not mapRows or mapCount < 1 or (tonumber(mapRows[1].uploader) ~= accountId and not canReviewMap(client, mapRows[1].uploader)) then return end
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
	dbQuery(function(qh, player, requestId, savedNote, isImplementing)
		local res, affectedRows = dbPoll(qh, 0)
		if res and affectedRows > 0 then
			local changed
			if isImplementing then
				changed = exports.map_load:loadMap(requestId)
			else
				changed = exports.map_load:unloadMap(requestId)
			end
			if changed then
				triggerClientEvent(player, 'maps:implement', resourceRoot, 'ok', requestId, isImplementing)
				notifyPlayer(requestId, "Your exterior map status updates.", "Hello <Username>!\n\nYour exterior map #"..requestId.." has been "..(isImplementing and "IMPLEMENTED" or "DISABLED")..".\n\n"..savedNote.."\nSincerely,\nOwlGaming Community\nOwlGaming Mapping Team")
			else
				dbExec(exports.mysql:getConn('mta'), "UPDATE maps SET enabled=? WHERE id=? AND enabled=?", isImplementing and 0 or 1, requestId, isImplementing and 1 or 0)
				triggerClientEvent(player, 'maps:implement', resourceRoot, 'Errors occurred while '..(isImplementing and 'implementing' or 'disabling')..' the map. Code 122.')
			end
		else
			triggerClientEvent(player, 'maps:implement', resourceRoot,
				res and 'Only an accepted map can be implemented, and only an enabled map can be disabled.' or 'Errors occurred while processing request. Code 124.')
		end
	end, { client, mapId, auditNote, implementing }, exports.mysql:getConn('mta'),
		"UPDATE maps SET enabled=?, note=CONCAT(note, ?), reviewer=? WHERE id=? AND type='exterior' AND approved=1 AND enabled=?",
		implementing and 1 or 0, auditNote, accountId, mapId, requiredEnabled)
end )
