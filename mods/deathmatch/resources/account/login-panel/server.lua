--[[
* ***********************************************************************************************************************
* Copyright (c) 2015 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

addEvent( 'account:character:select', true )
local mysql = exports.mysql
local accountCharacters = {}
local tutorialSessions = {}
local tutorialSessionSequence = 0
local authenticationBudgets = { login = {}, registration = {} }

local function consumeAuthenticationBudget(player, action, playerLimit, playerWindow, ipLimit, ipWindow)
	local now = os.time()
	local ip = getPlayerIP(player)
	local ipKey = type(ip) == "string" and ip ~= "" and ip or tostring(player)
	local actionBudgets = authenticationBudgets[action]
	local playerBudget = actionBudgets[player]
	local ipBudget = actionBudgets[ipKey]

	local function isAvailable(budget, limit, window)
		return not budget or now < budget.startedAt or now - budget.startedAt >= window or budget.count < limit
	end

	if not isAvailable(playerBudget, playerLimit, playerWindow) or not isAvailable(ipBudget, ipLimit, ipWindow) then
		return false
	end

	local function consume(budget, limit, window)
		if not budget or now < budget.startedAt or now - budget.startedAt >= window then
			return { startedAt = now, count = 1 }
		end
		budget.count = budget.count + 1
		return budget
	end

	actionBudgets[player] = consume(playerBudget, playerLimit, playerWindow)
	actionBudgets[ipKey] = consume(ipBudget, ipLimit, ipWindow)
	return true
end

-- Keep the IP buckets bounded when many transient addresses connect.
setTimer(function()
	local now = os.time()
	for _, actionBudgets in pairs(authenticationBudgets) do
		for key, budget in pairs(actionBudgets) do
			if now < budget.startedAt or now - budget.startedAt > 3600 then
				actionBudgets[key] = nil
			end
		end
	end
end, 300000, 0)

addEventHandler("onPlayerQuit", root, function()
	for _, actionBudgets in pairs(authenticationBudgets) do
		actionBudgets[source] = nil
	end
end)

local function getAuthenticatedAccountID(player)
	if not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "account:loggedin") ~= true then
		return false
	end
	local accountID = tonumber(getElementData(player, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID) then
		return false
	end
	return accountID
end

local function getCharacterCount(accountID)
	local qh = dbQuery(exports.mysql:getConn("mta"), "SELECT COUNT(*) AS chars FROM characters WHERE account = ?", accountID)
	if not qh then
		return false
	end
	local result = dbPoll(qh, 10000)
	if not result or not result[1] then
		return false
	end
	return tonumber(result[1].chars)
end

function validateCredentials(username,password,checksave)
	if not isElement(client) or getElementType(client) ~= "player" then
		return false
	end
	if type(username) ~= "string" or #username < 1 or #username > 64 then
		outputDebugString("[ACCOUNT][LOGIN] rejected invalid username field", 2)
		triggerClientEvent(client,"set_warning_text",client,"Login","Please enter a valid username.")
		return false
	end
	if type(password) ~= "string" or #password < 1 or #password > 256 then
		outputDebugString("[ACCOUNT][LOGIN] rejected invalid password field", 2)
		triggerClientEvent(client,"set_warning_text",client,"Login","Please enter a valid password.")
		return false
	end
	if checksave == true then
		triggerClientEvent(client,"saveLoginToXML",client,username)
	else
		triggerClientEvent(client,"resetSaveXML",client)
	end
	return true
end
addEvent("onRequestLogin",true)
addEventHandler("onRequestLogin",getRootElement(),validateCredentials)

function getAccountDetails(id)
	data = false
	local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
	local result_mta = dbPoll(qb, -1)
	if not result_mta then
		outputDebugString("Magic Data connection failed!")
	elseif #result_mta == 0 then
		if dbExec(exports.mysql:getConn("mta", "INSERT INTO account_details SET `account_id`=?", id)) then
			local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
			local result_mta = dbPoll(qb, -1)
			if result_mta and #result_mta == 1 then
				data = result_mta[1]
			end
		else
			outputDebugString("Magic Data creation failed!")
		end
	else
		data = result_mta[1]
	end
	return data
end

function playerLogin(username,password,checksave)
	if not isElement(client) or getElementType(client) ~= "player" then
		outputDebugString("[ACCOUNT][LOGIN] rejected request without player event client", 2)
		return false
	end
	if isElement(client) then
		tutorialSessions[client] = nil
	end
	local encryptionRuleData, encryptionRuleQuery, accountCheckQuery, preparedQuery, accountData,newAccountHash,safeusername,safepassword = nil

	if not validateCredentials(username,password,checksave) then
		return false
	end
	if not consumeAuthenticationBudget(client, "login", 10, 60, 40, 60) then
		outputDebugString("[ACCOUNT][LOGIN] throttled authentication request", 2)
		triggerClientEvent(client,"set_warning_text",client,"Login","Too many login attempts. Please wait before trying again.")
		return false
	end

	--Get Encyption Rule for user.
	preparedQuery = "SELECT * FROM `accounts` WHERE `username`=?"
	dbQuery(function(qh, username, password, checksave, client)
			local result = dbPoll(qh, 0)
			if result and client then
				if #result > 0 then
					local accountData = result[1]
					-- Check if the account is banned
					if exports.bans:checkAccountBan(accountData["id"]) then
						triggerClientEvent(client,"set_warning_text",client,"Login","Account is banned. Appeal at www.owlgaming.net")
						exports.logs:dbLog("ac"..tostring(accountData["id"]), 27, "ac"..tostring(accountData["id"]), "Rejected connection from " .. getPlayerIP(client) .. " - ".. getPlayerSerial(client) .. " as account is banned.")
						return false
					end

					--Now check if passwords are matched or the account is activated, this is to prevent user with fake emails.
					triggerClientEvent(client,"set_authen_text",client,"Login","Password Accepted! Authenticating..")
					-- Check if old method
					if not string.find(accountData["password"], "$", 1, true) then -- Plain search, not regex
						local encryptionRule = accountData["salt"]
						local encryptedPW = string.lower(md5(string.lower(md5(password))..encryptionRule))

						if accountData["password"] ~= encryptedPW then
							triggerClientEvent(client,"set_warning_text",client,"Login","Password(legacy) is incorrect for account name '".. username .."'!")
							return false
						end

						triggerClientEvent(client,"set_authen_text",client,"Login","Converting Legacy Password..")
						-- Run conversions // https://docs.djangoproject.com/en/1.10/topics/auth/passwords/#increasing-the-work-factor // Since Django prefixes it's passwords with the type we do this for compatibility
						local new_pass = "bcrypt_sha256$" .. bcrypt_hashpw(sha256(password):lower(), bcrypt_gensalt(12)) -- 12 work factor // https://github.com/django/django/blob/master/django/contrib/auth/hashers.py#L404
						if not dbExec(exports.mysql:getConn("core"), "UPDATE `accounts` SET `password`=?, `salt`=NULL WHERE id=?", new_pass, accountData["id"]) then
							triggerClientEvent(client,"set_warning_text",client,"Login","Password conversion failed for account name '".. username .."'!")
							return false
						end
					else -- Else if new
						local verified = bcrypt_checkpw(sha256(password):lower(), accountData["password"]:gsub("bcrypt_sha256%$", "")) -- Take out Django's junk to verify

						if not verified then
							triggerClientEvent(client,"set_warning_text",client,"Login","Password is incorrect for account name '".. username .."'!")
							return false
						end
					end

					if tonumber(accountData["activated"]) == 0 then
						triggerClientEvent(client,"set_warning_text",client,"Login","Account '".. username .."' is not activated.")
						return false
					end

					--Validation is done, fetching some more details
					triggerClientEvent(client,"set_authen_text",client,"Login","Account authenticated!")

					-- Validate device policy before displacing an existing session or publishing account state.
					local requiresSerialWhitelist = (tonumber(accountData['admin']) or 0) >= 1
						or (tonumber(accountData['supporter']) or 0) >= 1
						or (tonumber(accountData['scripter']) or 0) >= 2
						or (tonumber(accountData['fmt']) or 0) >= 1
					if not exports.serialwhitelist:check(client, accountData.id, requiresSerialWhitelist) then
						triggerClientEvent(client,"set_warning_text",client,"Login","This account is not authorized to connect from this PC. Contact server staff for assistance.")
						return false
					end

					-- Check the account is already logged in
					local found = false
					for _, thePlayer in ipairs(exports.pool:getPoolElementsByType("player")) do
						local playerAccountID = tonumber(getElementData(thePlayer, "account:id"))
						if (playerAccountID) then
							if (playerAccountID == tonumber(accountData["id"])) and (thePlayer ~= client) then
								kickPlayer(thePlayer, thePlayer, "Someone else has logged into your account.")
								triggerClientEvent(client,"set_authen_text",client,"Login","Account is currently online. Disconnecting other user..")
								break
							end
						end
					end

					local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", accountData.id)
					local result_mta = dbPoll(qb, -1)
					if not result_mta then
						triggerClientEvent(client,"set_authen_text",client,"Login","Magic Data connection failed!")
						return
					elseif #result_mta == 0 then
						if dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?", accountData.id) then
							local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", accountData.id)
							local result_mta = dbPoll(qb, -1)

						else

						end
					else
						accountData_mta = result_mta[1]
					end

					local accountData_mta = getAccountDetails( accountData.id )
					if not accountData_mta then
						triggerClientEvent(client,"set_authen_text",client,"Login","Magic Data connection failed!")
						return
					end

					-----------------------------------------------------------------------START THE MAGIC-----------------------------------------------------------------------------------
					triggerClientEvent(client, "items:inventory:hideinv", client)
				
					-- Start the magic
					setElementDataEx(client, "account:loggedin", true, true)
					setElementDataEx(client, "account:id", tonumber(accountData["id"]), true)
					setElementDataEx(client, "account:username", accountData["username"], true)
					setElementDataEx(client, "account:email", accountData["email"], true)
					setElementDataEx(client, "electionsvoted", accountData_mta["electionsvoted"], true)
					setElementDataEx(client, "credits", tonumber(accountData["credits"]), true)
					setElementDataEx(client, "avatar", tonumber(accountData["avatar"]), true)
					setElementData(client, "account:forumid", tonumber(accountData["forumid"]), true)
				
					--STAFF PERMISSIONS
					setElementDataEx(client, "admin_level", tonumber(accountData['admin']), true)
					setElementDataEx(client, "supporter_level", tonumber(accountData['supporter']), true)
					setElementDataEx(client, "vct_level", tonumber(accountData['vct']), true)
					setElementDataEx(client, "mapper_level", tonumber(accountData['mapper']), true)
					setElementDataEx(client, "scripter_level", tonumber(accountData['scripter']), true)
					setElementDataEx(client, "fmt_level", tonumber(accountData['fmt']), true)
				
					-- Punishment points
					setElementDataEx(client, "punishment:points", tonumber(accountData['punishpoints']), true)
					setElementDataEx(client, "punishment:date", accountData['punishdate'], true)
				
					exports['report']:reportLazyFix(client)
				
					setElementDataEx(client, "adminreports", tonumber(accountData_mta["adminreports"]), true)
					setElementDataEx(client, "adminreports_saved", tonumber(accountData_mta["adminreports_saved"]))
				
					if accountData['referrer'] and tonumber(accountData['referrer']) then
						setElementDataEx(client, "referrer", tonumber(accountData['referrer']), false, true)
					end
				
					if exports.integration:isPlayerLeadAdmin(client) then
						setElementDataEx(client, "hiddenadmin", accountData_mta["hiddenadmin"], true)
					else
						setElementDataEx(client, "hiddenadmin", 0, true)
					end
				
					--[[
					--ADMINS
					local staffDuty = tonumber(accountData["duty_admin"]) or 0
					if exports.integration:isPlayerTrialAdmin(client) then
						setElementDataEx(client, "duty_admin", staffDuty , true)
						setElementDataEx(client, "wrn:style", tonumber(accountData["warn_style"]), true)
					end
				
					--GMs
					if exports.integration:isPlayerSupporter(client) then --GMs
						setElementDataEx(client, "duty_supporter", staffDuty , true)
					end
					]]
				
					--MAXIME / VEHICLECONSULTATIONTEAM / 18.02.14
					local vehicleConsultationTeam = exports.integration:isPlayerVehicleConsultant(client)
					setElementDataEx(client, "vehicleConsultationTeam", vehicleConsultationTeam, false)
				
					if  tonumber(accountData_mta["adminjail"]) == 1 then
						setElementDataEx(client, "adminjailed", true, true)
					else
						setElementDataEx(client, "adminjailed", false, true)
					end
					setElementDataEx(client, "jailtime", tonumber(accountData_mta["adminjail_time"]), true)
					setElementDataEx(client, "jailadmin", accountData_mta["adminjail_by"], true)
					setElementDataEx(client, "jailreason", accountData_mta["adminjail_reason"], true)
				
					if accountData_mta["monitored"] ~= "" then
						setElementDataEx(client, "admin:monitor", accountData_mta["monitored"], true)
					end
				
					exports.logs:dbLog("ac"..tostring(accountData["id"]), 27, "ac"..tostring(accountData["id"]), "Connected from "..getPlayerIP(client) .. " - "..getPlayerSerial(client) )
					mysql:query_free("UPDATE `account_details` SET `mtaserial`='" .. mysql:escape_string(getPlayerSerial(client)) .. "' WHERE `account_id`='".. mysql:escape_string(tostring(accountData["id"])) .."'")
					dbExec(exports.mysql:getConn("core"), "UPDATE `accounts` SET `ip`=? WHERE id=?", getPlayerIP(client), accountData.id)
					--[[
					local dataTable = { }
					table.insert(dataTable, { "account:characters", characterList( client ) } )
					accountCharacters[tonumber(accountData["id"])] = dataTable
					]]
					local sum = mysql:query_fetch_assoc("SELECT SUM(hoursPlayed) AS hours FROM `characters` WHERE account = " .. mysql:escape_string(accountData["id"]))
					if sum then
						setElementData(client, "account:hours", sum.hours)
					else
						setElementData(client, "account:hours", 0)
					end
				
					setElementDataEx(client, "jailreason", accountData_mta["adminjail_reason"], true)
					setElementDataEx(client, "account:lastlogin", accountData_mta["lastlogin"], true)
					setElementDataEx(client, "account:creationdate", accountData["registerdate"], true)
					setElementDataEx(client, "account:email", accountData["email"], true)
				
					triggerEvent("updateCharacters", client)
				
					exports.donators:loadAllPerks(client)
					local togNewsPerk, togNewsStatus = exports.donators:hasPlayerPerk(client, 3)
					if (togNewsPerk) then
						setElementDataEx(client, "tognews", tonumber(togNewsStatus), false, true)
					end
				
					--SETTINGS / MAXIME
					loadAccountSettings(client, accountData["id"])
				
					exports.anticheat:setEld(client, "appstate", tonumber(accountData_mta["appstate"])) --Server only
					--[[
					if exports.global:isResourceRunning("interior_system") and exports.global:isResourceRunning("elevator-system") then
						triggerClientEvent(client, "screenStandBy", client, "setState", true)
					else
						goFromLoginToSelectionScreen(client)
					end
					]]

					goFromLoginToSelectionScreen(client)
				else
					triggerClientEvent(client,"set_warning_text",client,"Login","Account name '".. username .."' doesn't exist!")
				end
			else
				triggerClientEvent(client,"set_warning_text",client,"Login","Failed to connect to game server. Database error!")
				dbFree(qh)
			end
		end, {username, password, checksave, client}, exports.mysql:getConn("core"), preparedQuery, username)
end
addEvent("accounts:login:attempt",true)
addEventHandler("accounts:login:attempt",getRootElement(),playerLogin)

function playerFinishTutorial(sessionID)
	local player = client
	local accountID = getAuthenticatedAccountID(player)
	local session = isElement(player) and tutorialSessions[player]
	local requestedSession = tonumber(sessionID)
	if not accountID or not session or session.accountID ~= accountID or not requestedSession or session.id ~= requestedSession then
		return false
	end

	local characterCount = getCharacterCount(accountID)
	if characterCount == false then
		triggerClientEvent(player, "accounts:tutorialFinishRetry", player, session.id)
		return false
	elseif characterCount ~= 0 then
		tutorialSessions[player] = nil
		triggerClientEvent(player, "accounts:tutorialFinishRejected", player, session.id)
		return false
	end

	-- Consume before advancing so replayed finish events cannot start login twice.
	tutorialSessions[player] = nil
	triggerClientEvent(player, "accounts:login:attempt", player, 0)
	triggerEvent("social:account", player, accountID)
end
addEvent("accounts:tutorialFinished", true)
addEventHandler("accounts:tutorialFinished", resourceRoot, playerFinishTutorial)

function goFromLoginToSelectionScreen(player)
	if source then
		player = source
	end

	-- Check if player passed application
	if (getElementData(player, "appstate") or 0) < 3 then
		if exports.integration:isPlayerTrialAdmin(player) or exports.integration:isPlayerSupporter(player) then
			dbExec( exports.mysql:getConn('mta'), "UPDATE account_details SET appstate=3, appreason=NULL WHERE account_id=? ", getElementData(player,"account:id") )
		else
			triggerClientEvent(player,"account:showRules",player, (getElementData(player, "appstate") or 0) )
			return false
		end
	end

	triggerClientEvent(player, "vehicle_rims", player)
	if tonumber(getElementData(player, "punishment:points")) > 0 then triggerEvent("points:checkexpiration", player, player) end

	-- TUTORIAL
	local accountID = getAuthenticatedAccountID(player)
	local characterCount = accountID and getCharacterCount(accountID)
	if characterCount == 0 then
		tutorialSessionSequence = tutorialSessionSequence + 1
		local sessionID = tutorialSessionSequence
		tutorialSessions[player] = { accountID = accountID, id = sessionID }
		triggerClientEvent(player, "tutorial:run", player, sessionID)
		triggerClientEvent(player, "hideLoginWindow", player)
		return false
	end
	tutorialSessions[player] = nil

	triggerClientEvent(player, "accounts:login:attempt", player, 0 )
	triggerEvent( "social:account", player, getElementData(player,"account:id") )
	triggerClientEvent (player,"hideLoginWindow",player)

	--[[local fid = getElementData(player, 'account:forumid')
	if fid then
		exports.integration:fetchForumInfo(fid, player)
	end]]
end
addEvent("goFromLoginToSelectionScreen", false)
addEventHandler("goFromLoginToSelectionScreen",root,goFromLoginToSelectionScreen)

addEventHandler("onPlayerQuit", root, function()
	tutorialSessions[source] = nil
end)

function playerFinishApps()
	if source then
		client = source
	end
	local index = getElementData(client, "account:id")
	triggerClientEvent(client, "accounts:login:attempt", client, 0)--, accountCharacters[index] )
	triggerEvent( "social:account", client, index )
	triggerClientEvent (client,"hideLoginWindow",client)
	triggerClientEvent (client,"apps:destroyGUIPart3",client)
	--accountCharacters[index] = nil
end
addEvent("accounts:playerFinishApps",true)
addEventHandler("accounts:playerFinishApps",getRootElement(),playerFinishApps)

--local lastClient = nil
function playerRegister(username,password,confirmPassword, email)
	if not client or not isElement(client) or getElementType(client) ~= "player" then
		outputDebugString("[ACCOUNT][REGISTER] rejected invalid event client", 2)
		return false
	end
	if type(username) ~= "string" or type(password) ~= "string" or type(confirmPassword) ~= "string" or type(email) ~= "string"
		or #username < 3 or #username > 18 or not username:match("^%w+$")
		or #password < 8 or #password > 25 or password:find("['\"]")
		or #email < 1 or #email > 100 or password ~= confirmPassword then
		outputDebugString("[ACCOUNT][REGISTER] rejected invalid or mismatched registration fields", 2)
		triggerClientEvent(client, "set_warning_text", client, "Register", "Please check your username, password confirmation, and email.")
		return false
	end
	local validEmail = exports.global:isEmail(email)
	if not validEmail then
		outputDebugString("[ACCOUNT][REGISTER] rejected invalid email field", 2)
		triggerClientEvent(client, "set_warning_text", client, "Register", "Please enter a valid email address.")
		return false
	end
	if not consumeAuthenticationBudget(client, "registration", 3, 600, 10, 3600) then
		outputDebugString("[ACCOUNT][REGISTER] throttled registration request", 2)
		triggerClientEvent(client, "set_warning_text", client, "Register", "Too many registration attempts. Please wait before trying again.")
		return false
	end
	--CHECK FOR EXISTANCE OF USERNAME AND EMAIL ADDRESS / MAXIME
	local preparedQuery1 = "SELECT `id` FROM `accounts` WHERE `username`=? OR `email`=? "
	dbQuery(function(qh, username, password, confirmPassword, email, client)
		local result = dbPoll(qh, 0)
		if result then
			if #result == 0 then
				--CHECK FOR EXISTANCE OF MTA SERIAL TO ENCOUNTER MULTIPLE ACCOUNTS PER USER / MAXIME.
				local mtaSerial = getPlayerSerial(client)
				local preparedQuery2 = "SELECT `account_id`, `mtaserial` FROM `account_details` WHERE `mtaserial`='".. toSQL(mtaSerial) .."' LIMIT 1"
				local Q2 = mysql:query(preparedQuery2)
				if not Q2 then
					outputDebugString("[ACCOUNT][REGISTER] serial lookup failed", 1)
					triggerClientEvent(client,"set_warning_text",client,"Register","Error code 0003 occurred.")
					return false
				end

				local accountExisted = mysql:fetch_assoc(Q2)
				local existingSerialCount = mysql:num_rows(Q2)
				if (existingSerialCount > 0) and tonumber(accountExisted and accountExisted["account_id"]) ~= 1 then
					mysql:free_result(Q2)
					outputDebugString("[ACCOUNT][REGISTER] duplicate serial blocked account=" .. tostring(accountExisted and accountExisted["account_id"] or "unknown"), 2)
					triggerClientEvent(client,"set_warning_text",client,"Register","Multiple Accounts is not allowed.")
					return false
				end
				mysql:free_result(Q2)

				--START CREATING ACCOUNT.
				local encryptedPW = "bcrypt_sha256$" .. bcrypt_hashpw(sha256(password):lower(), bcrypt_gensalt(12)) -- 12 work factor // https://github.com/django/django/blob/master/django/contrib/auth/hashers.py#L404
				local ipAddress = getPlayerIP(client)
				preparedQuery3 = "INSERT INTO `accounts` SET `username`=?, `password`=?, `email`=?, `registerdate`=NOW(), `ip`=?, `activated`='0' "
				local userid = dbExec(exports.mysql:getConn("core"), preparedQuery3, username, encryptedPW, email, ipAddress)
				if userid then
					outputDebugString("[ACCOUNT][REGISTER] account row created; provisioning account details", 3)
					triggerClientEvent(client,"accounts:register:complete",client, username, password)
					dbQuery(function(qh, client)
						local result = dbPoll(qh, 0)
						if result and #result == 1 then
							if dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?, `mtaserial`=?", result[1].id, mtaSerial) then
								callRemote("http://127.0.0.1:8000/api/send-activation-mail/",
									function(returns)
										if not returns.success then
											outputDebugString("MTA Activation Eamil Postback "..returns.error)
										end
									end,
								{id=result[1].id})
							else
								outputDebugString("[ACCOUNT][REGISTER] account details insert failed account=" .. tostring(result[1].id), 1)
								triggerClientEvent(client,"set_warning_text",client,"Register","Error code 0005 occurred.")
							end
						else
							triggerClientEvent(client,"set_warning_text",client,"Register","Error code 0004 occurred.")
							dbFree(qh)
						end
					end, {client}, exports.mysql:getConn("core"), "SELECT id FROM accounts WHERE username=?", username)
				else
					triggerClientEvent(client,"set_warning_text",client,"Register","Could not create new account.")
					return false
				end
			else
				triggerClientEvent(client,"set_warning_text",client,"Register","Username or email existed.")
			end
		else
			triggerClientEvent(client,"set_warning_text",client,"Register","Error code 0002 occurred.")
			dbFree(qh)
		end
	end, {username, password, confirmPassword, email, client}, exports.mysql:getConn("core"), preparedQuery1, username, email)
end
addEvent("accounts:register:attempt",true)
addEventHandler("accounts:register:attempt",getRootElement(),playerRegister)

function toSQL(stuff)
	return mysql:escape_string(stuff)
end
