-- Application-manager authorization remains legacy-enforced while named
-- Discord capabilities are compared for migration evidence only.

local shadowTicks = setmetatable({}, { __mode = "k" })

function appsResolveManagerActor(proposedPlayer)
	if client then
		if source ~= client then
			outputDebugString("[APPS][AUTH] outcome=rejected reason=source_mismatch", 2)
			return false
		end
		return client
	end
	if isElement(proposedPlayer) and getElementType(proposedPlayer) == "player" then
		return proposedPlayer
	end
	outputDebugString("[APPS][AUTH] outcome=rejected reason=invalid_actor", 2)
	return false
end

function appsAuthorizeManager(player, action, capability)
	local accountID = isElement(player) and tonumber(getElementData(player, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID)
		or getElementData(player, "account:loggedin") ~= true then
		outputDebugString("[APPS][AUTH] outcome=rejected reason=invalid_session action=" .. tostring(action), 2)
		return false
	end

	local legacyAllowed = exports.integration:isPlayerTrialAdmin(player) == true
	local capabilityAllowed = false
	local resolverState = "unavailable"
	local accountResource = getResourceFromName("account")
	if accountResource and getResourceState(accountResource) == "running" then
		local callSucceeded, result = pcall(call, accountResource, "hasDiscordCapability", player, capability)
		if callSucceeded then
			capabilityAllowed = result == true
			resolverState = "resolved"
		else
			resolverState = "error"
		end
	end

	local now = getTickCount()
	local playerTicks = shadowTicks[player]
	local lastTick = playerTicks and playerTicks[action]
	if not lastTick or (now - lastTick) % 4294967296 >= 2000 then
		if not playerTicks then
			playerTicks = {}
			shadowTicks[player] = playerTicks
		end
		playerTicks[action] = now
		outputDebugString("[AUTH][CAPABILITY_SHADOW] action=" .. action
			.. " capability=" .. capability
			.. " legacy=" .. (legacyAllowed and "allow" or "deny")
			.. " discord=" .. (capabilityAllowed and "allow" or "deny")
			.. " resolver=" .. resolverState
			.. " comparison=" .. (legacyAllowed == capabilityAllowed and "match" or "mismatch")
			.. " enforcement=legacy", legacyAllowed == capabilityAllowed and 3 or 2)
	end

	if not legacyAllowed then
		outputDebugString("[APPS][AUTH] outcome=rejected reason=unauthorized action=" .. action, 2)
	end
	return legacyAllowed
end
