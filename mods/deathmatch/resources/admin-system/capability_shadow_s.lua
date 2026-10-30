-- Capability migration is deliberately non-authoritative in this phase.
-- The caller's reviewed legacy decision remains the enforcement result while
-- the Discord-backed account facade is compared for operator review.

local function isValidShadowName(value, maximumLength)
	return type(value) == "string" and #value >= 1 and #value <= maximumLength
		and value:match("^[a-z0-9][a-z0-9%._:%-]*$") ~= nil
end

local shadowEvaluationTicks = setmetatable({}, { __mode = "k" })

function adminEvaluateCapabilityShadow(player, action, capability, legacyAllowed)
	legacyAllowed = legacyAllowed == true
	if not isElement(player) or getElementType(player) ~= "player"
		or not isValidShadowName(action, 96)
		or not isValidShadowName(capability, 128) then
		outputDebugString("[AUTH][CAPABILITY_SHADOW] outcome=rejected reason=invalid_input enforcement=legacy", 2)
		return legacyAllowed, false, "invalid_input"
	end


	local now = getTickCount()
	local playerTicks = shadowEvaluationTicks[player]
	local lastEvaluation = playerTicks and playerTicks[action]
	if lastEvaluation and (now - lastEvaluation) % 4294967296 < 2000 then
		return legacyAllowed, false, "rate_limited"
	end
	if not playerTicks then
		playerTicks = {}
		shadowEvaluationTicks[player] = playerTicks
	end
	playerTicks[action] = now

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

	local comparison = legacyAllowed == capabilityAllowed and "match" or "mismatch"
	local message = "[AUTH][CAPABILITY_SHADOW] action=" .. action
		.. " capability=" .. capability
		.. " legacy=" .. (legacyAllowed and "allow" or "deny")
		.. " discord=" .. (capabilityAllowed and "allow" or "deny")
		.. " resolver=" .. resolverState
		.. " comparison=" .. comparison
		.. " enforcement=legacy"
	outputDebugString(message, comparison == "match" and 3 or 2)

	-- Persist only decisions that an operator needs to reconcile. dbLog binds
	-- the actor itself; the message contains no raw Discord role or identity.
	if (legacyAllowed or capabilityAllowed) and (resolverState ~= "resolved" or comparison == "mismatch") then
		local auditCallSucceeded = pcall(function()
			exports.logs:dbLog(player, 4, player, message)
		end)
		if not auditCallSucceeded then
			outputDebugString("[AUTH][CAPABILITY_SHADOW] outcome=audit_unavailable action=" .. action, 1)
		end
	end

	-- Shadow capability results never grant access.
	return legacyAllowed, capabilityAllowed, resolverState
end
