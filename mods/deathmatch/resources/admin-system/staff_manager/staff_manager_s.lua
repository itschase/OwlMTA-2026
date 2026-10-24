--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

local mysql = exports.mysql
local staffTitles = exports.integration:getStaffTitles()

local rankColumns = { "admin", "supporter", "vct", "scripter", "mapper", "fmt" }
local maxRanks = { 5, 2, 2, 3, 2, 2 }

local function getAuthenticatedRequester()
	local player = client
	if not player or not isElement(player) or getElementType(player) ~= "player" then
		return false
	end
	if getElementData(player, "loggedin") ~= 1 or not tonumber(getElementData(player, "account:id")) then
		return false
	end
	return player
end

local function canAccessStaffManager(player)
	-- Donator tiers do not grant staff management access.
	return exports.integration:isPlayerTrialAdmin(player)
		or exports.integration:isPlayerVCTMember(player)
		or exports.integration:isPlayerLeadScripter(player)
		or exports.integration:isPlayerMappingTeamLeader(player)
		or exports.integration:isPlayerFMTLeader(player)
end

local function denyStaffRequest(player, eventName, reason)
	local accountId = player and tonumber(getElementData(player, "account:id")) or 0
	outputDebugString("[staff_manager] denied " .. eventName .. " account=" .. tostring(accountId) .. " reason=" .. reason, 2)
	if player and isElement(player) then
		outputChatBox("You do not have permission to use the staff manager.", player, 255, 0, 0)
	end
end

local function canEditRank(player, rankIndex, requestedRank, currentRank)
	local adminLevel = tonumber(getElementData(player, "admin_level")) or 0
	local vctLevel = tonumber(getElementData(player, "vct_level")) or 0
	local mapperLevel = tonumber(getElementData(player, "mapper_level")) or 0

	if rankIndex == 1 then
		return exports.integration:isPlayerLeadAdmin(player) and adminLevel >= requestedRank and adminLevel >= currentRank
	elseif rankIndex == 2 then
		-- Donor tiers can only be assigned by a lead administrator, not by donors.
		return exports.integration:isPlayerLeadAdmin(player)
	elseif rankIndex == 3 then
		return exports.integration:isPlayerLeadAdmin(player)
			or (vctLevel > requestedRank and vctLevel > currentRank)
	elseif rankIndex == 4 then
		return exports.integration:isPlayerLeadScripter(player)
	elseif rankIndex == 5 then
		return mapperLevel > requestedRank and mapperLevel > currentRank
	elseif rankIndex == 6 then
		return exports.integration:isPlayerLeadAdmin(player) or exports.integration:isPlayerFMTLeader(player)
	end
	return false
end

local function getStaffInfoForPlayer(thePlayer, username, error)
	local error1 = error
	dbQuery(function(qh, username, error, player)
		if not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "loggedin") ~= 1 or not canAccessStaffManager(player) then
			outputDebugString("[staff_manager] staff detail response skipped because requester is no longer authorized", 2)
			return false
		end
		local result = dbPoll(qh, 0)
		if result and #result > 0 then
			local changelogs = {}
			local mQuery1 = nil
			mQuery1 = mysql:query("SELECT (CASE WHEN to_rank>from_rank THEN 1 ELSE 0 END) AS promoted, s.id, s.userid, team, from_rank, to_rank, s.`by` AS `by`, details, DATE_FORMAT(date,'%b %d, %Y %h:%i %p') AS date FROM staff_changelogs s WHERE s.userid="..result[1]["id"].." ORDER BY id DESC")
			while true do
				local row = mysql:fetch_assoc(mQuery1)
				if not row then break end
				row.userid = exports.cache:getUsernameFromId(row.userid)
				row.by = exports.cache:getUsernameFromId(row.by)
				table.insert(changelogs, row )
			end
			mysql:free_result(mQuery1)
			local staffInfo = {}
			staffInfo.user = result[1]
			staffInfo.changelogs = changelogs
			staffInfo.error = error1
			triggerClientEvent(player, "openStaffManager", player, staffInfo)
		end
	end, {username, error, thePlayer}, exports.mysql:getConn("core"), "SELECT id, username, admin, supporter, vct, scripter, mapper, fmt FROM accounts WHERE username=?", username)
end

function getStaffInfo(username, error)
	local thePlayer = getAuthenticatedRequester()
	if not thePlayer or not canAccessStaffManager(thePlayer) then
		denyStaffRequest(thePlayer or client, "staff:getStaffInfo", "unauthorized")
		return false
	end
	if type(username) ~= "string" or #username < 1 or #username > 64 then
		denyStaffRequest(thePlayer, "staff:getStaffInfo", "invalid_username")
		return false
	end
	return getStaffInfoForPlayer(thePlayer, username, error)
end
addEvent("staff:getStaffInfo", true)
addEventHandler("staff:getStaffInfo", root, getStaffInfo)

function getTeamsData()
	local thePlayer = getAuthenticatedRequester()
	if not thePlayer or not canAccessStaffManager(thePlayer) then
		denyStaffRequest(thePlayer or client, "staff:getTeamsData", "unauthorized")
		return false
	end
	staffTitles = exports.integration:getStaffTitles()
	local users = {}
	dbQuery(
		function(qh, staffTitles, users)
			if not isElement(thePlayer) or getElementType(thePlayer) ~= "player" or getElementData(thePlayer, "loggedin") ~= 1 or not canAccessStaffManager(thePlayer) then
				outputDebugString("[staff_manager] team roster response skipped because requester is no longer authorized", 2)
				return false
			end
			local result = dbPoll(qh, 0)
			if result then
				for _, row in pairs(result) do
					for i, k in ipairs(staffTitles) do
						if not users[i] then users[i] = {} end
						-- fetch report count
						local reportsQuery = dbQuery(exports.mysql:getConn("mta"), "SELECT adminreports FROM account_details WHERE account_id = ?", row.id)
						local reportsResult = dbPoll(reportsQuery, -1)
						row.adminreports = (reportsResult[1] and reportsResult[1].adminreports) or 0
						dbFree(reportsQuery)
						--
						if tonumber(row.admin) > 0 and i == 1 then
							if not row.rank then row.rank = {} end
							row.rank[i] = tonumber(row.admin)
							table.insert(users[i], row)
						end
						if tonumber(row.supporter) > 0 and i == 2 then
							if not row.rank then row.rank = {} end
							row.rank[i] = tonumber(row.supporter)
							table.insert(users[i], row)
						end
						if tonumber(row.vct) > 0 and i == 3 then
							if not row.rank then row.rank = {} end
							row.rank[i] = tonumber(row.vct)
							table.insert(users[i], row)
						end
						if tonumber(row.scripter) > 0 and i == 4 then
							if not row.rank then row.rank = {} end
							row.rank[i] = tonumber(row.scripter)
							table.insert(users[i], row)
						end
						if tonumber(row.mapper) > 0 and i == 5 then
							if not row.rank then row.rank = {} end
							row.rank[i] = tonumber(row.mapper)
							table.insert(users[i], row)
						end
						if tonumber(row.fmt) > 0 and i == 6 then
							if not row.rank then row.rank = {} end
							row.rank[i] = tonumber(row.fmt)
							table.insert(users[i], row)
						end
					end
				end
				triggerClientEvent(thePlayer, "openStaffManager", thePlayer, nil, users )
			else
				dbFree(qh)
			end
		end
	, {staffTitles, users}, exports.mysql:getConn("core"), "SELECT id, username, admin, supporter, vct, scripter, mapper, fmt FROM accounts  WHERE admin > 0 OR supporter > 0 OR vct > 0 OR scripter>0 OR mapper>0 OR fmt>0 GROUP BY id ORDER BY admin DESC, supporter DESC, vct DESC, scripter DESC, mapper DESC")
end
addEvent("staff:getTeamsData", true)
addEventHandler("staff:getTeamsData", root, getTeamsData)

function getChangelogs()
	local thePlayer = getAuthenticatedRequester()
	if not thePlayer or not canAccessStaffManager(thePlayer) then
		denyStaffRequest(thePlayer or client, "staff:getChangelogs", "unauthorized")
		return false
	end
	local changelogs = {}
	local mQuery1 = nil
	mQuery1 = mysql:query("SELECT (CASE WHEN to_rank>from_rank THEN 1 ELSE 0 END) AS promoted, s.id, s.userid, team, from_rank, to_rank, s.`by` AS `by`, details, DATE_FORMAT(date,'%b %d, %Y %h:%i %p') AS date FROM staff_changelogs s ORDER BY id DESC")
	while true do
		local row = mysql:fetch_assoc(mQuery1)
		if not row then break end
		row.userid = exports.cache:getUsernameFromId(row.userid)
		row.by = exports.cache:getUsernameFromId(row.by)
		table.insert(changelogs, row )
	end
	mysql:free_result(mQuery1)
	triggerClientEvent(thePlayer, "openStaffManager", thePlayer, nil, nil, changelogs )
end
addEvent("staff:getChangelogs", true)
addEventHandler("staff:getChangelogs", root, getChangelogs)

function editStaff(userid, ranks, details)
	local thePlayer = getAuthenticatedRequester()
	if not thePlayer or not canAccessStaffManager(thePlayer) then
		denyStaffRequest(thePlayer or client, "staff:editStaff", "unauthorized")
		return false
	end

	userid = tonumber(userid)
	if not userid or userid < 1 or userid % 1 ~= 0 or type(ranks) ~= "table" then
		denyStaffRequest(thePlayer, "staff:editStaff", "invalid_request")
		return false
	end

	local requestedRanks = {}
	local hasRankChange = false
	for index, value in pairs(ranks) do
		if type(index) ~= "number" or index < 1 or index > #rankColumns or index % 1 ~= 0 then
			denyStaffRequest(thePlayer, "staff:editStaff", "invalid_rank_index")
			return false
		end
		local rank = tonumber(value)
		if not rank or rank < 0 or rank > maxRanks[index] or rank % 1 ~= 0 then
			denyStaffRequest(thePlayer, "staff:editStaff", "invalid_rank_value")
			return false
		end
		requestedRanks[index] = rank
		hasRankChange = true
	end
	if not hasRankChange or (details ~= nil and (type(details) ~= "string" or #details > 500)) then
		denyStaffRequest(thePlayer, "staff:editStaff", "invalid_request")
		return false
	end

	local target = false
	for _, player in pairs(getElementsByType("player")) do
		if tonumber(getElementData(player, "account:id")) == userid then
			target = player
			break
		end
	end

	staffTitles = exports.integration:getStaffTitles()
	dbQuery(function(qh, userid, titles, targetPlayer, ranks, details, actor)
		if not isElement(actor) or getElementType(actor) ~= "player" or getElementData(actor, "loggedin") ~= 1 or not canAccessStaffManager(actor) then
			outputDebugString("[staff_manager] rank update skipped because requester is no longer authorized", 2)
			return false
		end
		local result = dbPoll(qh, 0)
		if not result or not result[1] then
			outputDebugString("[staff_manager] edit failed account=" .. tostring(getElementData(actor, "account:id")) .. " target=" .. tostring(userid) .. " reason=account_lookup_failed", 2)
			return false
		end

		local user = result[1]
		local currentRanks = {
			tonumber(user.admin) or 0,
			tonumber(user.supporter) or 0,
			tonumber(user.vct) or 0,
			tonumber(user.scripter) or 0,
			tonumber(user.mapper) or 0,
			tonumber(user.fmt) or 0
		}
		local changes = {}
		for index = 1, #rankColumns do
			local newRank = ranks[index]
			if newRank ~= nil and newRank ~= currentRanks[index] then
				if not canEditRank(actor, index, newRank, currentRanks[index]) then
					denyStaffRequest(actor, "staff:editStaff", "rank_scope_denied")
					return false
				end
				table.insert(changes, { index = index, oldRank = currentRanks[index], newRank = newRank })
			end
		end
		if #changes == 0 then
			outputChatBox("No staff ranks changed.", actor, 255, 194, 14)
			return false
		end

		local assignments = {}
		local queryParams = {}
		for _, change in ipairs(changes) do
			table.insert(assignments, rankColumns[change.index] .. "=?")
			table.insert(queryParams, change.newRank)
		end
		table.insert(queryParams, userid)
		local updateQuery = "UPDATE accounts SET " .. table.concat(assignments, ", ") .. " WHERE id=?"
		if not dbExec(exports.mysql:getConn("core"), updateQuery, unpack(queryParams)) then
			outputDebugString("[staff_manager] edit failed account=" .. tostring(getElementData(actor, "account:id")) .. " target=" .. tostring(userid) .. " reason=rank_update_failed", 2)
			outputChatBox("Internal Error!", actor, 255, 0, 0)
			return false
		end

		-- The account row is durable before the separate audit, ticket, element-data, and notification side effects.
		local detailsValue = details and #details > 0 and ("'" .. mysql:escape_string(details) .. "'") or "NULL"
		local actorId = tonumber(getElementData(actor, "account:id"))
		local actorName = exports.global:getPlayerFullIdentity(actor, 1, true)
		local rankDataKeys = { "admin_level", "supporter_level", "vct_level", "scripter_level", "mapper_level", "fmt_level" }
		local byColumn = string.char(96) .. "by" .. string.char(96)

		for _, change in ipairs(changes) do
			local index = change.index
			local oldRank = change.oldRank
			local newRank = change.newRank
			local promoted = newRank > oldRank
			local action = promoted and "promoted" or "demoted"
			local oldTitle = titles[index][oldRank] or tostring(oldRank)
			local newTitle = titles[index][newRank] or tostring(newRank)
			local logQuery = "INSERT INTO staff_changelogs SET userid=" .. userid .. ", details=" .. detailsValue .. ", " .. byColumn .. "=" .. actorId .. ", team=" .. index .. ", from_rank=" .. oldRank .. ", to_rank=" .. newRank
			if not mysql:query_free(logQuery) then
				outputDebugString("[staff_manager] audit write failed account=" .. tostring(actorId) .. " target=" .. tostring(userid) .. " team=" .. tostring(index), 2)
			end

			if targetPlayer and isElement(targetPlayer) and tonumber(getElementData(targetPlayer, "account:id")) == userid then
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, rankDataKeys[index], newRank, true)
			else
				targetPlayer = false
			end

			exports.global:sendMessageToStaff("[STAFF UPDATE] " .. actorName .. " has " .. action .. " '" .. user.username .. "' from " .. oldTitle .. " to " .. newTitle .. ".", true)
			exports.announcement:makePlayerNotification(targetPlayer or user.id, "Staff Rank Updated", actorName .. " has " .. action .. " you from " .. oldTitle .. " to " .. newTitle .. ". " .. (promoted and "Congratulations!" or "Sorry!"))

			if index == 1 and newRank == 0 then
				if not dbExec(exports.mysql:getConn("core"), "UPDATE tc_tickets SET assign_to=NULL WHERE assign_to=?", userid) then
					outputDebugString("[staff_manager] ticket cleanup failed target=" .. tostring(userid), 2)
				end
			end
		end

		outputDebugString("[staff_manager] rank update account=" .. tostring(actorId) .. " target=" .. tostring(userid) .. " changed=" .. tostring(#changes), 3)
		getStaffInfoForPlayer(actor, user.username, "Staff rank for " .. user.username .. " has been set!")
	end, { userid, staffTitles, target, requestedRanks, details, thePlayer }, exports.mysql:getConn("core"), "SELECT id, username, admin, supporter, vct, scripter, mapper, fmt FROM accounts WHERE id=?", userid)
end
addEvent("staff:editStaff", true)
addEventHandler("staff:editStaff", root, editStaff)
function makePlayerStaff(thePlayer, commandName, who, rank) --/ MAXIME
	if exports.integration:isPlayerSeniorAdmin(thePlayer) or exports.integration:isPlayerVehicleConsultant(thePlayer) or exports.integration:isPlayerLeadScripter(thePlayer) or exports.integration:isPlayerMappingTeamLeader(thePlayer) then
		if not (who) or not (tonumber(rank)) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Player Partial Name/ID] [Staff Team ID] [Rank]", thePlayer, 255, 194, 14)
			outputChatBox("SYNTAX: /" .. commandName .. " [Exact Username] [Rank, -1 .. -4 = GMs, 1 .. 7 = Admins]", thePlayer, 255, 194, 14)
		else
			local targetPlayer, targetPlayerName = exports.global:findPlayerByPartialNick(thePlayer, who)
			local username = false
			local targetUsername = false
			local currentRank = false
			local adminID = false
			rank = tonumber(rank)

			if not targetPlayer then
				return false
			end

			targetUsername = getElementData(targetPlayer, "account:username")
			currentRank = getElementData(targetPlayer, "admin_level")
			adminID = getElementData(targetPlayer, "account:id")


			if (rank > 0) or (rank == -999999999) then
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_admin", 1, true)
			else
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_admin", 0, true)
			end

			if (rank < 0) then
				local gmrank = -rank
				outputChatBox("You set " .. targetPlayerName .. "'s GM rank to " .. tostring(gmrank) .. ".", thePlayer, 0, 255, 0)
				--outputChatBox(adminTitle .. " " .. username .. " set your GM rank to " .. gmrank .. ".", targetPlayer, 255, 194, 14)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "account:gmlevel", gmrank, false)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_supporter", 1, true)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "admin_level", 0, false)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_admin", 0, true)
			elseif rank == 0 then
				--outputChatBox(adminTitle .. " " .. username .. " removed your staff rank.", targetPlayer, 255, 194, 14)
				outputChatBox("You set " .. targetPlayerName .. " to Player.", thePlayer, 0, 255, 0)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "admin_level", 0, false)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_admin", 0, true)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "account:gmlevel", 0, false)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_supporter", 0, true)
			else
				--outputChatBox(adminTitle .. " " .. username .. " set your admin rank to " .. rank .. ".", targetPlayer, 255, 194, 14)
				outputChatBox("You set " .. targetPlayerName .. "'s Admin rank to " .. tostring(rank) .. ".", thePlayer, 0, 255, 0)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "admin_level", rank, false)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_admin", 1, true)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "account:gmlevel", 0, false)
				exports.anticheat:changeProtectedElementDataEx(targetPlayer, "duty_supporter", 0, true)
			end




			exports.logs:dbLog(thePlayer, 4, targetPlayer, "MAKEADMIN " .. rank)
			exports.global:updateNametagColor(targetPlayer)
		end
	end
end
--addCommandHandler("makestaff", makePlayerStaff, false, false)
