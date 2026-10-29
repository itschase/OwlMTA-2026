local identityResourceName = "mta-discord-identity"
local requiredIdentityExports = {
	beginLogin = true,
	exchangeLoginTicket = true,
	activateLoginSession = true,
	hasCapability = true,
	clearPlayerSession = true,
}

local function hasRequiredIdentityExports(identityResource)
	local exportedFunctions = getResourceExportedFunctions(identityResource)
	if type(exportedFunctions) ~= "table" then return false end
	local remaining = {}
	for functionName in pairs(requiredIdentityExports) do remaining[functionName] = true end
	for _, functionName in ipairs(exportedFunctions) do
		remaining[functionName] = nil
	end
	return next(remaining) == nil
end

local function getRunningIdentityResource()
	local identityResource = getResourceFromName(identityResourceName)
	if not identityResource or getResourceState(identityResource) ~= "running" or not hasRequiredIdentityExports(identityResource) then
		return false
	end
	return identityResource
end

local function isTrustedIdentityEvent()
	local identityResource = getRunningIdentityResource()
	return identityResource
		and sourceResource == identityResource
		and source == getResourceRootElement(identityResource)
end

local function reportDiscordLoginFailure(player, outcome, message, level)
	outputDebugString("[ACCOUNT][DISCORD] outcome=" .. outcome, level or 2)
	if isElement(player) and getElementType(player) == "player" then
		triggerClientEvent(player, "set_warning_text", player, "Login",
			message or "Discord sign-in could not be completed. Please try again.")
		triggerClientEvent(player, "account:discord:failed", resourceRoot)
	end
end

local function callIdentity(player, functionName, ...)
	if not isElement(player) or getElementType(player) ~= "player" then
		return false, "invalid player"
	end
	if getElementData(player, "account:loggedin") == true then
		return false, "already authenticated"
	end
	local identityResource = getRunningIdentityResource()
	if not identityResource then
		triggerClientEvent(player, "account:discord:availability", resourceRoot, false)
		reportDiscordLoginFailure(player, "service_unavailable",
			"Discord sign-in is temporarily unavailable. Please try again later.", 2)
		return false, "identity service unavailable"
	end
	local callSucceeded, started, reason = pcall(call, identityResource, functionName, player, ...)
	if not callSucceeded or not started then
		reportDiscordLoginFailure(player, "request_not_started",
			"Discord sign-in is temporarily unavailable. Please try again later.", 2)
		return false, reason or "identity request failed"
	end
	return true
end

function beginDiscordLogin(player)
	if not getRunningIdentityResource() then
		return callIdentity(player, "beginLogin")
	end
	if not consumeAuthenticationBudget(player, "login", 10, 60, 40, 60) then
		reportDiscordLoginFailure(player, "request_throttled", "Too many login attempts. Please wait before trying again.")
		return false, "rate limited"
	end
	return callIdentity(player, "beginLogin")
end

function exchangeDiscordLoginTicket(player, ticket)
	if type(ticket) ~= "string" then
		return false, "invalid ticket"
	end
	ticket = ticket:match("^%s*(.-)%s*$")
	if ticket == "" or #ticket > 256 then
		return false, "invalid ticket"
	end
	return callIdentity(player, "exchangeLoginTicket", ticket)
end

function activateDiscordIdentitySession(player, accountID)
	return callIdentity(player, "activateLoginSession", accountID)
end

-- Server-only Owl authorization facade. The reusable adapter independently
-- re-resolves this resource's trusted account callback before returning a grant.
-- Callers must still enforce duty, hierarchy, target, ownership, proximity,
-- organization and action-state policy for the operation they are protecting.
function hasDiscordCapability(player, capability)
	if not isElement(player) or getElementType(player) ~= "player"
		or getElementData(player, "account:loggedin") ~= true then
		return false
	end
	local accountID = tonumber(getElementData(player, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID)
		or type(capability) ~= "string" or #capability < 1 or #capability > 128
		or not capability:match("^[a-z0-9][a-z0-9%._:%-]*$") then
		return false
	end
	local identityResource = getRunningIdentityResource()
	if not identityResource then return false end
	local callSucceeded, allowed = pcall(call, identityResource, "hasCapability", player, capability)
	return callSucceeded and allowed == true
end

function cancelDiscordLogin(player)
	if not isElement(player) or getElementType(player) ~= "player" then
		return false
	end
	local identityResource = getRunningIdentityResource()
	if not identityResource then return false end
	local callSucceeded, cleared = pcall(call, identityResource, "clearPlayerSession", player)
	return callSucceeded and cleared == true
end

-- The login UI may invoke only these narrow operations. Player identity is always
-- MTA's event client; account and Discord identifiers are never accepted.
addEvent("account:discord:begin", true)
addEventHandler("account:discord:begin", resourceRoot, function()
	if not client or source ~= resourceRoot then return end
	beginDiscordLogin(client)
end)

addEvent("account:discord:availability:request", true)
addEventHandler("account:discord:availability:request", resourceRoot, function()
	if not client or source ~= resourceRoot then return end
	triggerClientEvent(client, "account:discord:availability", resourceRoot, getRunningIdentityResource() ~= false)
end)

local function publishIdentityAvailability(available)
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "account:loggedin") ~= true then
			triggerClientEvent(player, "account:discord:availability", resourceRoot, available == true)
		end
	end
end

addEventHandler("onResourceStart", root, function()
	local identityResource = getResourceFromName(identityResourceName)
	if identityResource and source == getResourceRootElement(identityResource) then
		setTimer(function() publishIdentityAvailability(getRunningIdentityResource() ~= false) end, 50, 1)
	end
end)

addEventHandler("onResourceStop", root, function()
	local identityResource = getResourceFromName(identityResourceName)
	if identityResource and source == getResourceRootElement(identityResource) then
		cancelPendingDiscordAccountAdmissions()
		publishIdentityAvailability(false)
	end
end)

addEvent("account:discord:exchange", true)
addEventHandler("account:discord:exchange", resourceRoot, function(ticket)
	if not client or source ~= resourceRoot then return end
	local started, reason = exchangeDiscordLoginTicket(client, ticket)
	if not started and reason == "invalid ticket" then
		reportDiscordLoginFailure(client, "invalid_ticket_field", "Enter a valid one-time Discord sign-in ticket.")
	end
end)

addEvent("account:discord:cancel", true)
addEventHandler("account:discord:cancel", resourceRoot, function()
	if not client or source ~= resourceRoot then return end
	cancelDiscordLogin(client)
end)

-- Register the reusable adapter contract even when that optional resource is not
-- installed. Its own addEvent calls are idempotent when it starts later.
addEvent("mta-discord-identity:resolve-account", false)
addEvent("mta-discord-identity:login-challenge", false)
addEvent("mta-discord-identity:login-authorized", false)
addEvent("mta-discord-identity:login-failed", false)
addEvent("mta-discord-identity:login-session-activated", false)
addEvent("mta-discord-identity:login-session-failed", false)

addEventHandler("mta-discord-identity:resolve-account", root, function(player, reply)
	if not isTrustedIdentityEvent() or type(reply) ~= "function" then
		outputDebugString("[ACCOUNT][DISCORD] rejected untrusted account resolver event", 2)
		return
	end
	if not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "account:loggedin") ~= true then
		return
	end
	local accountID = tonumber(getElementData(player, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID) then
		return
	end
	reply(tostring(accountID))
end)

addEventHandler("mta-discord-identity:login-challenge", root, function(player, result)
	if not isTrustedIdentityEvent() then
		outputDebugString("[ACCOUNT][DISCORD] rejected untrusted login challenge event", 2)
		return
	end
	if not isElement(player) or getElementType(player) ~= "player" or type(result) ~= "table"
		or type(result.challengeId) ~= "string" or type(result.code) ~= "string"
		or type(result.expiresAt) ~= "number" or type(result.verificationUrl) ~= "string" then
		reportDiscordLoginFailure(player, "invalid_challenge_response",
			"Discord sign-in is temporarily unavailable. Please try again later.", 1)
		return
	end
	triggerClientEvent(player, "account:discord:challenge", resourceRoot, {
		code = result.code,
		verificationUrl = result.verificationUrl,
	})
	outputDebugString("[ACCOUNT][DISCORD] outcome=challenge_created", 3)
end)

addEventHandler("mta-discord-identity:login-authorized", root, function(player, accountID)
	if not isTrustedIdentityEvent() then
		outputDebugString("[ACCOUNT][DISCORD] rejected untrusted login authorization event", 2)
		return
	end
	if not isElement(player) or getElementType(player) ~= "player" then return end
	local started = admitAccountById(player, accountID, "discord")
	if not started then
		cancelDiscordLogin(player)
		reportDiscordLoginFailure(player, "account_admission_not_started",
			"This linked account could not be loaded. Contact server staff for assistance.", 1)
	end
end)

addEventHandler("mta-discord-identity:login-failed", root, function(player, statusCode)
	if not isTrustedIdentityEvent() then
		outputDebugString("[ACCOUNT][DISCORD] rejected untrusted login failure event", 2)
		return
	end
	local statusClass = type(statusCode) == "number" and math.floor(statusCode / 100) or 0
	reportDiscordLoginFailure(player, "identity_rejected status_class=" .. tostring(statusClass),
		"Discord sign-in could not be completed. Restart the sign-in and try again.")
end)

addEventHandler("mta-discord-identity:login-session-activated", root, function(player, accountID)
	if not isTrustedIdentityEvent() then
		outputDebugString("[ACCOUNT][DISCORD] rejected untrusted login-session activation event", 2)
		return
	end
	if not finalizeDiscordAccountAdmission(player, accountID) then
		cancelDiscordLogin(player)
		reportDiscordLoginFailure(player, "local_admission_commit_failed",
			"Discord sign-in could not complete local account admission. Please start again.", 1)
		return
	end
	outputDebugString("[ACCOUNT][DISCORD] outcome=session_activated", 3)
end)

addEventHandler("mta-discord-identity:login-session-failed", root, function(player, statusCode)
	if not isTrustedIdentityEvent() then
		outputDebugString("[ACCOUNT][DISCORD] rejected untrusted login-session failure event", 2)
		return
	end
	local statusClass = type(statusCode) == "number" and math.floor(statusCode / 100) or 0
	rejectDiscordAccountAdmission(player)
	outputDebugString("[ACCOUNT][DISCORD] outcome=session_activation_failed status_class=" .. tostring(statusClass), 2)
end)
