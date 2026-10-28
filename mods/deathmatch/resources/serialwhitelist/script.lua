mysql = exports.mysql
--MAXIME

local function fetchFirstRow(queryText)
	local queryHandle = mysql:query(queryText)
	if queryHandle == false then
		return false, false
	end
	local row = mysql:fetch_assoc(queryHandle)
	mysql:free_result(queryHandle)
	return row, true
end

function check(thePlayer, accountID, requiresWhitelist)
	if not isElement(thePlayer) or getElementType(thePlayer) ~= "player" then
		return false
	end

	local userid = tonumber(accountID)
	if not userid or userid < 1 or userid ~= math.floor(userid) then
		outputDebugString("[serialwhitelist] Login check rejected: invalid account identifier.", 2)
		return false
	end

	local serial = mysql:escape_string(getPlayerSerial(thePlayer))
	local ip = mysql:escape_string(getPlayerIP(thePlayer))
	if not serial or not ip then
		outputDebugString("[serialwhitelist] Login check failed: could not prepare device identity for account "..userid..".", 1)
		return false
	end
	local result, querySucceeded = fetchFirstRow("SELECT `id` FROM `serial_whitelist` WHERE `userid`=".. userid .." AND `serial`='"..serial.."' AND `status`='1' LIMIT 1")
	if not querySucceeded then
		outputDebugString("[serialwhitelist] Login check failed: whitelist lookup error for account "..userid..".", 1)
		return false
	end

	if result and result['id'] and tonumber(result['id']) then
		mysql:query_free("UPDATE `serial_whitelist` SET `serial`='"..serial.."', `last_login_ip`='"..ip.."', `last_login_date`=NOW() WHERE `userid`=".. userid .." AND `id`='"..tonumber(result['id']).."' AND `status`='1' ")
		outputDebugString("[serialwhitelist] Login check passed for account "..userid.." (registered device).", 3)
		return true
	end

	if requiresWhitelist == true then
		exports.global:sendMessageToAdmins("[SYSTEM] POSSIBLE STAFF ACCOUNT BREACHED! - A login for account #"..userid.." was attempted from an unregistered PC. (SERIAL: "..getPlayerSerial(thePlayer).." , IP: "..getPlayerIP(thePlayer)..")")
		outputDebugString("[serialwhitelist] Login check denied for restricted account "..userid.." (unregistered device).", 2)
		return false
	else
		local countResult, countQuerySucceeded = fetchFirstRow("SELECT COUNT(*) AS `count` FROM `serial_whitelist` WHERE `userid`=".. userid .." AND `status`='1' ")
		if not countQuerySucceeded or not countResult or not tonumber(countResult['count']) then
			outputDebugString("[serialwhitelist] Login check failed: device count lookup error for account "..userid..".", 1)
			return false
		end
		local addedSerials = tonumber(countResult['count'])
		if tonumber(addedSerials) > 0 then
			outputDebugString("[serialwhitelist] Login check denied for account "..userid.." (a different registered device exists).", 2)
			return false
		else 
			outputDebugString("[serialwhitelist] Login check passed for account "..userid.." (no device registration exists).", 3)
			return true
		end
	end
end

function addSerialWhiteList(thePlayer, commandName, username, serial)
	if exports.integration:isPlayerLeadAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) then
		if not username or not serial then
			outputChatBox("SYNTAX: /" .. commandName .. " [Exact Username] [Serial]", thePlayer, 255, 194, 14)
			return false
		end
		local user = mysql:query_fetch_assoc("SELECT `id`, `username` FROM `accounts` WHERE `username`='".. exports.global:toSQL(username) .."' LIMIT 1")
		if not user or not user['id'] or not tonumber(user['id']) then
			outputChatBox("No such username found.", thePlayer, 255,0,0)
			return false
		end
		if mysql:query_free("INSERT INTO `serial_whitelist` SET `userid`='"..user['id'].."', `serial`='"..exports.global:toSQL(serial).."' ") then
			outputChatBox("Serial whitelist successfully added for account '"..user['username'].."' with serial '"..serial.."'.", thePlayer, 0,255,0)
			exports.global:sendMessageToAdmins("[SYSTEM] "..exports.global:getPlayerFullIdentity(thePlayer, 2, true).." has added '"..user['username'].."' with serial '"..serial.."' to serial whitelist. ")
			return true
		else
			outputChatBox("Serial whitelist has failed to add.", thePlayer, 255,0,0)
			return false
		end
	end
end
--addCommandHandler("addserialwl", addSerialWhiteList, false, false)

function delSerialWhiteList(thePlayer, commandName, id)
	if exports.integration:isPlayerLeadAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) then
		if not id or not tonumber(id) then
			outputChatBox("SYNTAX: /" .. commandName .. " [Whitelist ID]", thePlayer, 255, 194, 14)
			return false
		end

		local existing = mysql:query_fetch_assoc("SELECT `serial_whitelist`.`id`, `username`, `serial` FROM `serial_whitelist` LEFT JOIN `accounts` ON `serial_whitelist`.`userid`=`accounts`.`id` WHERE `serial_whitelist`.`id`='"..id.."' LIMIT 1")
		if not existing or not existing['username'] then
			outputChatBox("Serial whitelist removing failed.", thePlayer, 255,0,0)
			return false
		end
		if mysql:query_free("DELETE FROM `serial_whitelist` WHERE `id`='"..id.."' ") then
			outputChatBox("Serial whitelist successfully removed from account '"..existing['username'].."' with serial '"..existing['serial'].."'.", thePlayer, 0,255,0)
			exports.global:sendMessageToAdmins("[SYSTEM] "..exports.global:getPlayerFullIdentity(thePlayer, 2, true).." has removed '"..existing['username'].."' with serial '"..existing['serial'].."' from the serial whitelist. ")
			return true
		else
			outputChatBox("Serial whitelist removing failed.", thePlayer, 255,0,0)
			return false
		end
	end
end
--addCommandHandler("delserialwl", delSerialWhiteList, false, false)

function showAllWhiteList(thePlayer, commandName)
	if exports.integration:isPlayerSupporter(thePlayer) or exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) then
		local whitelists = {}
		local mQuery1 = mysql:query("SELECT `serial_whitelist`.`id`, `username`, `serial` FROM `serial_whitelist` LEFT JOIN `accounts` ON `serial_whitelist`.`userid`=`accounts`.`id` ORDER BY `username`")
		while true do
			local row = mysql:fetch_assoc(mQuery1)
			if not row then break end
			table.insert(whitelists, row )
		end
		mysql:free_result(mQuery1)
		
		outputChatBox("SERIAL WHITELIST:", thePlayer, 255, 194, 14)
		
		if #whitelists < 1 then
			outputChatBox("  Serial Whitelist is empty. /addserialwl to add.", thePlayer, 255,0,0)
		end

		for i = 1, #whitelists do
			outputChatBox("  #"..whitelists[i]['id'].." - "..whitelists[i]['username'].." - "..whitelists[i]['serial'], thePlayer, 255, 194, 14)
		end
		outputChatBox("TIPS: /whitelists, /addserialwl /delserialwl", thePlayer, 255, 194, 14)
	end
end
--addCommandHandler("whitelists", showAllWhiteList, false, false)


