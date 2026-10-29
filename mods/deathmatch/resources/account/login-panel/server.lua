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
local pendingDiscordAdmissions = {}

function consumeAuthenticationBudget(player, action, playerLimit, playerWindow, ipLimit, ipWindow)
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
	pendingDiscordAdmissions[source] = nil
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
	local data = false
	local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
	if not qb then
		outputDebugString("[ACCOUNT][ADMISSION] account details query did not start", 1)
		return false
	end
	local result_mta = dbPoll(qb, -1)
	if not result_mta then
		outputDebugString("Magic Data connection failed!")
	elseif #result_mta == 0 then
		if dbExec(exports.mysql:getConn("mta"), "INSERT INTO account_details SET `account_id`=?", id) then
			local qb = dbQuery(exports.mysql:getConn("mta"), "SELECT * FROM account_details WHERE account_id=?", id)
			if not qb then
				outputDebugString("[ACCOUNT][ADMISSION] created account details but reload query did not start", 1)
				return false
			end
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

-- Reasons are server-owned constants; never include submitted credentials or identifiers.
local function reportLoginFailure(player, reason, message, level)
	outputDebugString("[ACCOUNT][LOGIN] outcome=" .. reason, level or 2)
	if isElement(player) and getElementType(player) == "player" then
		triggerClientEvent(player, "set_warning_text", player, "Login",
			message or "Unable to sign in. Check your credentials or contact server staff for assistance.")
	end
end

local function prepareAccountAdmission(player, accountData, method)
	if not isElement(player) or getElementType(player) ~= "player" then
		outputDebugString("[ACCOUNT][ADMISSION] outcome=requester_disconnected method=" .. tostring(method), 3)
		return false
	end
	if getElementData(player, "account:loggedin") == true then
		reportLoginFailure(player, "already_authenticated", "You are already signed in.")
		return false
	end

	local accountID = tonumber(accountData and accountData.id)
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID)
		or type(accountData.username) ~= "string" or accountData.username == "" then
		reportLoginFailure(player, "invalid_account_result", "Sign-in is temporarily unavailable. Please try again later.", 1)
		return false
	end

	local accountBanned = exports.bans:checkAccountBan(accountID)
	if accountBanned == nil then
		reportLoginFailure(player, "ban_check_failed", "Sign-in is temporarily unavailable. Please try again later.", 1)
		return false
	elseif accountBanned then
		reportLoginFailure(player, "account_banned", "This account is banned. Contact server staff for assistance.")
		exports.logs:dbLog("ac"..tostring(accountID), 27, "ac"..tostring(accountID), "Rejected account login: banned.")
		return false
	end

	if tonumber(accountData.activated) ~= 1 then
		reportLoginFailure(player, "account_inactive", "Your account is not activated. Contact server staff for assistance.")
		return false
	end

	local requiresSerialWhitelist = (tonumber(accountData.admin) or 0) >= 1
		or (tonumber(accountData.supporter) or 0) >= 1
		or (tonumber(accountData.scripter) or 0) >= 2
		or (tonumber(accountData.fmt) or 0) >= 1
	if not exports.serialwhitelist:check(player, accountID, requiresSerialWhitelist) then
		triggerClientEvent(player, "set_warning_text", player, "Login", "This account is not authorized to connect from this PC. Contact server staff for assistance.")
		outputDebugString("[ACCOUNT][ADMISSION] outcome=device_rejected method=" .. tostring(method), 2)
		return false
	end

	local accountDataMta = getAccountDetails(accountID)
	if not accountDataMta then
		reportLoginFailure(player, "account_details_unavailable", "Sign-in is temporarily unavailable. Please try again later.", 1)
		return false
	end
	return {
		player = player,
		accountData = accountData,
		accountDataMta = accountDataMta,
		accountID = accountID,
		method = method,
	}
end

local function commitAccountAdmission(context)
	local player = context.player
	local accountData = context.accountData
	local accountDataMta = context.accountDataMta
	local accountID = context.accountID
	local method = context.method
	if not isElement(player) or getElementType(player) ~= "player" then
		outputDebugString("[ACCOUNT][ADMISSION] outcome=requester_disconnected method=" .. tostring(method), 3)
		return false
	end
	if getElementData(player, "account:loggedin") == true then
		reportLoginFailure(player, "already_authenticated", "You are already signed in.")
		return false
	end

	-- Preserve the legacy single-session policy, but only displace the current session
	-- after every database-backed admission gate for the replacement session succeeded.
	for _, otherPlayer in ipairs(exports.pool:getPoolElementsByType("player")) do
		if otherPlayer ~= player and tonumber(getElementData(otherPlayer, "account:id")) == accountID then
			kickPlayer(otherPlayer, otherPlayer, "Someone else has logged into your account.")
			triggerClientEvent(player, "set_authen_text", player, "Login", "Account is currently online. Disconnecting other user..")
			break
		end
	end

	triggerClientEvent(player, "set_authen_text", player, "Login", "Account authenticated!")
	triggerClientEvent(player, "items:inventory:hideinv", player)

	setElementDataEx(player, "account:loggedin", true, true)
	setElementDataEx(player, "account:id", accountID, true)
	setElementDataEx(player, "account:username", accountData.username, true)
	setElementDataEx(player, "account:email", accountData.email, true)
	setElementDataEx(player, "electionsvoted", accountDataMta.electionsvoted, true)
	setElementDataEx(player, "credits", tonumber(accountData.credits), true)
	setElementDataEx(player, "avatar", tonumber(accountData.avatar), true)
	setElementData(player, "account:forumid", tonumber(accountData.forumid), true)

	-- Legacy account ranks remain source-compatible until the capability migration is explicit.
	setElementDataEx(player, "admin_level", tonumber(accountData.admin), true)
	setElementDataEx(player, "supporter_level", tonumber(accountData.supporter), true)
	setElementDataEx(player, "vct_level", tonumber(accountData.vct), true)
	setElementDataEx(player, "mapper_level", tonumber(accountData.mapper), true)
	setElementDataEx(player, "scripter_level", tonumber(accountData.scripter), true)
	setElementDataEx(player, "fmt_level", tonumber(accountData.fmt), true)

	setElementDataEx(player, "punishment:points", tonumber(accountData.punishpoints), true)
	setElementDataEx(player, "punishment:date", accountData.punishdate, true)
	exports.report:reportLazyFix(player)
	setElementDataEx(player, "adminreports", tonumber(accountDataMta.adminreports), true)
	setElementDataEx(player, "adminreports_saved", tonumber(accountDataMta.adminreports_saved))

	if accountData.referrer and tonumber(accountData.referrer) then
		setElementDataEx(player, "referrer", tonumber(accountData.referrer), false, true)
	end

	if exports.integration:isPlayerLeadAdmin(player) then
		setElementDataEx(player, "hiddenadmin", accountDataMta.hiddenadmin, true)
	else
		setElementDataEx(player, "hiddenadmin", 0, true)
	end

	local vehicleConsultationTeam = exports.integration:isPlayerVehicleConsultant(player)
	setElementDataEx(player, "vehicleConsultationTeam", vehicleConsultationTeam, false)

	setElementDataEx(player, "adminjailed", tonumber(accountDataMta.adminjail) == 1, true)
	setElementDataEx(player, "jailtime", tonumber(accountDataMta.adminjail_time), true)
	setElementDataEx(player, "jailadmin", accountDataMta.adminjail_by, true)
	setElementDataEx(player, "jailreason", accountDataMta.adminjail_reason, true)
	if type(accountDataMta.monitored) == "string" and accountDataMta.monitored ~= "" then
		setElementDataEx(player, "admin:monitor", accountDataMta.monitored, true)
	end

	exports.logs:dbLog("ac"..tostring(accountID), 27, "ac"..tostring(accountID), "Connected from "..getPlayerIP(player) .. " - "..getPlayerSerial(player))
	dbExec(exports.mysql:getConn("mta"), "UPDATE account_details SET mtaserial=? WHERE account_id=?", getPlayerSerial(player), accountID)
	dbExec(exports.mysql:getConn("core"), "UPDATE accounts SET ip=? WHERE id=?", getPlayerIP(player), accountID)

	local sum = mysql:query_fetch_assoc("SELECT SUM(hoursPlayed) AS hours FROM `characters` WHERE account = " .. mysql:escape_string(accountID))
	setElementData(player, "account:hours", sum and sum.hours or 0)
	setElementDataEx(player, "account:lastlogin", accountDataMta.lastlogin, true)
	setElementDataEx(player, "account:creationdate", accountData.registerdate, true)
	setElementDataEx(player, "account:email", accountData.email, true)

	triggerEvent("updateCharacters", player)
	exports.donators:loadAllPerks(player)
	local togNewsPerk, togNewsStatus = exports.donators:hasPlayerPerk(player, 3)
	if togNewsPerk then
		setElementDataEx(player, "tognews", tonumber(togNewsStatus), false, true)
	end

	loadAccountSettings(player, accountID)
	exports.anticheat:setEld(player, "appstate", tonumber(accountDataMta.appstate))
	outputDebugString("[ACCOUNT][ADMISSION] outcome=accepted method=" .. tostring(method), 3)
	goFromLoginToSelectionScreen(player)
	return true
end

local function completeAccountAdmission(player, accountData, method)
	if pendingDiscordAdmissions[player] then
		reportLoginFailure(player, "admission_in_progress", "A Discord sign-in is already being processed.")
		return false
	end
	local context = prepareAccountAdmission(player, accountData, method)
	if not context then return false end
	if method ~= "discord" then
		return commitAccountAdmission(context)
	end
	pendingDiscordAdmissions[player] = context
	if type(activateDiscordIdentitySession) ~= "function" or not activateDiscordIdentitySession(player, tostring(context.accountID)) then
		pendingDiscordAdmissions[player] = nil
		reportLoginFailure(player, "identity_session_not_started", "Discord sign-in could not establish a secure session. Please try again.", 1)
		return false
	end
	outputDebugString("[ACCOUNT][ADMISSION] outcome=identity_session_pending method=discord", 3)
	return true
end

function finalizeDiscordAccountAdmission(player, accountID)
	local callerName = sourceResource and getResourceName(sourceResource)
	if callerName ~= "mta-discord-identity" then
		outputDebugString("[ACCOUNT][ADMISSION] rejected untrusted identity-session caller", 2)
		return false
	end
	local context = pendingDiscordAdmissions[player]
	local trustedAccountID = tonumber(accountID)
	if not context or not trustedAccountID or context.accountID ~= trustedAccountID then
		return false
	end
	pendingDiscordAdmissions[player] = nil
	local query = dbQuery(exports.mysql:getConn("core"), "SELECT * FROM accounts WHERE id=? LIMIT 1", trustedAccountID)
	if not query then
		reportLoginFailure(player, "identity_commit_query_start_failed", "Sign-in is temporarily unavailable. Please try again later.", 1)
		return false
	end
	local result = dbPoll(query, -1)
	if not result or #result ~= 1 then
		reportLoginFailure(player, "identity_commit_account_unavailable", "This linked account could not be revalidated. Please try again later.", 1)
		return false
	end
	local refreshedContext = prepareAccountAdmission(player, result[1], "discord")
	if not refreshedContext then return false end
	return commitAccountAdmission(refreshedContext)
end

function rejectDiscordAccountAdmission(player)
	local callerName = sourceResource and getResourceName(sourceResource)
	if callerName ~= "mta-discord-identity" then return false end
	if not pendingDiscordAdmissions[player] then return false end
	pendingDiscordAdmissions[player] = nil
	reportLoginFailure(player, "identity_session_failed", "Discord sign-in could not establish a secure session. Please start again.", 1)
	outputDebugString("[ACCOUNT][ADMISSION] outcome=identity_session_failed method=discord", 2)
	return true
end

function cancelPendingDiscordAccountAdmissions()
	for player in pairs(pendingDiscordAdmissions) do
		pendingDiscordAdmissions[player] = nil
		if isElement(player) and getElementType(player) == "player" then
			reportLoginFailure(player, "identity_resource_stopped", "Discord sign-in became unavailable. Please try again later.", 2)
		end
	end
end

function admitAccountById(player, accountID, method)
	local callerName = sourceResource and getResourceName(sourceResource)
	if callerName ~= "mta-discord-identity" then
		outputDebugString("[ACCOUNT][ADMISSION] rejected untrusted resource caller", 2)
		return false, "untrusted caller"
	end
	if method ~= "discord" then
		return false, "unsupported admission method"
	end
	if not isElement(player) or getElementType(player) ~= "player" then
		return false, "invalid player"
	end
	local trustedAccountID = tonumber(accountID)
	if not trustedAccountID or trustedAccountID < 1 or trustedAccountID ~= math.floor(trustedAccountID) then
		return false, "invalid account"
	end
	tutorialSessions[player] = nil
	local query = dbQuery(function(qh, player, admissionMethod)
		local result = dbPoll(qh, 0)
		if not isElement(player) or getElementType(player) ~= "player" then
			outputDebugString("[ACCOUNT][ADMISSION] outcome=requester_disconnected method=" .. admissionMethod, 3)
			return
		end
		if not result then
			reportLoginFailure(player, "core_query_failed", "Sign-in is temporarily unavailable. Please try again later.", 1)
			if type(cancelDiscordLogin) == "function" then cancelDiscordLogin(player) end
			return
		end
		if #result ~= 1 then
			reportLoginFailure(player, "identity_account_unavailable", "This linked account is no longer available. Contact server staff for assistance.")
			if type(cancelDiscordLogin) == "function" then cancelDiscordLogin(player) end
			return
		end
		if not completeAccountAdmission(player, result[1], admissionMethod) and type(cancelDiscordLogin) == "function" then
			cancelDiscordLogin(player)
		end
	end, {player, method}, exports.mysql:getConn("core"), "SELECT * FROM accounts WHERE id=? LIMIT 1", trustedAccountID)
	if not query then
		reportLoginFailure(player, "core_query_start_failed", "Sign-in is temporarily unavailable. Please try again later.", 1)
		if type(cancelDiscordLogin) == "function" then cancelDiscordLogin(player) end
		return false, "query failed"
	end
	return true
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
	local loginQuery = dbQuery(function(qh, username, password, checksave, client)
			local result = dbPoll(qh, 0)
			-- Consume the result even if the requester disconnected while the query ran.
			if not isElement(client) or getElementType(client) ~= "player" then
				outputDebugString("[ACCOUNT][LOGIN] outcome=requester_disconnected", 3)
				return
			end
			if result then
				if #result > 0 then
					local accountData = result[1]
					-- Prove account control before checking ban/activation state or producing their side effects.
					-- Check if old method
					if not string.find(accountData["password"], "$", 1, true) then -- Plain search, not regex
						local encryptionRule = accountData["salt"]
						local encryptedPW = string.lower(md5(string.lower(md5(password))..encryptionRule))

						if accountData["password"] ~= encryptedPW then
							reportLoginFailure(client, "credentials_rejected")
							return false
						end

						triggerClientEvent(client,"set_authen_text",client,"Login","Converting Legacy Password..")
						-- Run conversions // https://docs.djangoproject.com/en/1.10/topics/auth/passwords/#increasing-the-work-factor // Since Django prefixes it's passwords with the type we do this for compatibility
						local new_pass = "bcrypt_sha256$" .. bcrypt_hashpw(sha256(password):lower(), bcrypt_gensalt(12)) -- 12 work factor // https://github.com/django/django/blob/master/django/contrib/auth/hashers.py#L404
						if not dbExec(exports.mysql:getConn("core"), "UPDATE `accounts` SET `password`=?, `salt`=NULL WHERE id=?", new_pass, accountData["id"]) then
							reportLoginFailure(client, "legacy_upgrade_failed", "Sign-in is temporarily unavailable. Please try again later.", 1)
							return false
						end
					else -- Else if new
						local verified = bcrypt_checkpw(sha256(password):lower(), accountData["password"]:gsub("bcrypt_sha256%$", "")) -- Take out Django's junk to verify

						if not verified then
							reportLoginFailure(client, "credentials_rejected")
							return false
						end
					end

					completeAccountAdmission(client, accountData, "password")
				else
					reportLoginFailure(client, "credentials_rejected")
				end
			else
				-- dbPoll releases a failed query handle itself.
				reportLoginFailure(client, "core_query_failed", "Sign-in is temporarily unavailable. Please try again later.", 1)
			end
		end, {username, password, checksave, client}, exports.mysql:getConn("core"), preparedQuery, username)
	if not loginQuery then
		reportLoginFailure(client, "core_query_start_failed", "Sign-in is temporarily unavailable. Please try again later.", 1)
	end
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
