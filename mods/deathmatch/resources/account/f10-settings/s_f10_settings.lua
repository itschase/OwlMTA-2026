local mysql = exports.mysql

local accountBooleanSettings = {
	graphic_motionblur = true,
	graphic_skyclouds = true,
	streams = true,
	graphic_nametags = true,
	settings_hud_style = true,
	graphic_logs = true,
	graphic_chatbub = true,
	graphic_typingicon = true,
	graphic_shaderradar = true,
	graphic_shaderwater = true,
	graphic_shaderveh = true,
	graphic_shaderveh_reflect = true,
	graphic_shader_darker_night = true,
	enableOverlayDescription = true,
	enableOverlayDescriptionVeh = true,
	enableOverlayDescriptionPro = true,
	enableOverlayDescriptionNote = true,
	autopark = true,
	graphic_chatbub_square = true,
	vehicle_hotkey = true,
	vehicle_rims = true,
	talk_anim = true,
	pm_username = true,
	weapon_show_selector = true,
	noti_faction_updates = true,
	noti_offline_pm = true,
	vehicle_inactivity_scanner = true,
	interior_inactivity_scanner = true,
	support_center = true,
	noti_no_noti = true,
	social_classic_user_interface = true,
	social_invite_only = true,
	social_friends_bypass_pmblock = true,
	social_friend_updates = true,
	social_friend_updates_on_off = true,
	social_friend_updates_msg = true,
	social_friend_updates_char = true,
	social_friend_updates_sound = true,
	bind_indicators = true,
	dynamic_lighting = true,
	groundsnow = true,
	snowfall = true,
	xmastreefx = true,
	auto_check = true,
	punishment_notification_selector = true,
	enableNewUIStyle = true,
	incoming_report_sound = true,
	incoming_priority_report_sound = true,
	misc_sounds = true,
	vehicle_description_altgr = true,
	cellphone_log = true,
	hide_hud = true,
}

local accountEnumSettings = {
	speedo = { ["0"] = true, ["1"] = true, ["2"] = true },
	report_panel_mod = { ["0"] = true, ["1"] = true, ["2"] = true, ["3"] = true },
}

local accountTextSettings = {
	cFontVeh = true,
	cFontPro = true,
}

local accountDutySettings = {
	duty_admin = true,
	duty_supporter = true,
}

local characterBooleanSettings = {
	phone_anim = true,
}

local characterEnumSettings = {
	head_turning = { ["0"] = true, ["1"] = true, ["2"] = true },
}

local function isPlayerElement(player)
	return player and isElement(player) and getElementType(player) == "player"
end

local function getAccountID(player)
	if not isPlayerElement(player) then return false end
	local accountID = tonumber(getElementData(player, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID) then return false end
	return accountID
end

local function getCharacterID(player)
	if not isPlayerElement(player) or getElementData(player, "loggedin") ~= 1 then return false end
	local characterID = tonumber(getElementData(player, "dbid"))
	local activeCharacterID = tonumber(getElementData(player, "account:character:id"))
	if not characterID or characterID < 1 or characterID ~= math.floor(characterID) or characterID ~= activeCharacterID then
		return false
	end
	return characterID
end

local function hasExplicitGameMasterGrant(player)
	local level = isPlayerElement(player) and tonumber(getElementData(player, "account:gmlevel"))
	return level and level > 0 or false
end

local function normalizeScalar(value)
	if type(value) ~= "string" and type(value) ~= "number" then return false end
	local normalized = tostring(value)
	if #normalized < 1 or #normalized > 64 or normalized:find("%c") then return false end
	return normalized
end

local function normalizeBoolean(value)
	local normalized = normalizeScalar(value)
	if normalized == "0" or normalized == "1" then return normalized end
	return false
end

local function normalizeSetting(player, scope, name, value)
	if type(name) ~= "string" or #name < 1 or #name > 64 then return false end
	local normalized = normalizeScalar(value)
	if not normalized then return false end

	if scope == "account" then
		if accountBooleanSettings[name] then
			return normalizeBoolean(value)
		end

		local enumValues = accountEnumSettings[name]
		if enumValues and enumValues[normalized] then
			if name == "report_panel_mod"
				and not exports.integration:isPlayerTrialAdmin(player)
				and not hasExplicitGameMasterGrant(player) then
				return false
			end
			return normalized
		end

		if accountTextSettings[name] then
			if #normalized <= 64 and normalized:match("^[%w_%. %-]+$") then
				return normalized
			end
			return false
		end

		if accountDutySettings[name] then
			if normalized ~= "0" and normalized ~= "1" then return false end
			if name == "duty_admin" and not exports.integration:isPlayerTrialAdmin(player) then return false end
			-- Donor/supporter tiers are not GameMaster grants. Only an explicit GM grant may change GM duty.
			if name == "duty_supporter" and not hasExplicitGameMasterGrant(player) then return false end
			return tonumber(normalized)
		end
	elseif scope == "character" then
		if characterBooleanSettings[name] then
			return normalizeBoolean(value)
		end
		local enumValues = characterEnumSettings[name]
		if enumValues and enumValues[normalized] then return normalized end
	end

	return false
end

local function logDenied(scope, player, reason)
	local accountID = getAccountID(player) or "unknown"
	outputDebugString("[account-settings][security] denied scope=" .. tostring(scope)
		.. " account=" .. tostring(accountID) .. " reason=" .. tostring(reason), 2)
end

local function queueSetting(queue, player, name, value, characterID)
	local settings = queue[player]
	if not settings then
		settings = {}
		queue[player] = settings
	end
	for index, setting in ipairs(settings) do
		if setting[1] == name then
			setting[2] = value
			if characterID then setting[3] = characterID end
			return
		end
	end
	table.insert(settings, { name, value, characterID })
end

-- These save events are local server events. Only the validated client-facing
-- save handlers below may enqueue values for persistence.
function updateSetting(name, value)
	if client then return false end
	local player = source
	local accountID = getAccountID(player)
	local normalized = normalizeSetting(player, "account", name, value)
	if not accountID or not normalized then
		logDenied("account-persist", player, "invalid_internal_setting")
		return false
	end
	return dbExec(mysql:getConn("mta"), "REPLACE INTO account_settings (id, name, value) VALUES (?, ?, ?)", accountID, name, tostring(normalized))
end
addEvent("accounts:settings:update", false)
addEventHandler("accounts:settings:update", root, updateSetting)

function updateCharacterSetting(name, value, characterID)
	if client then return false end
	local player = source
	local accountID = getAccountID(player)
	characterID = tonumber(characterID) or getCharacterID(player)
	local normalized = normalizeSetting(player, "character", name, value)
	if not accountID or not characterID or characterID < 1 or characterID ~= math.floor(characterID) or not normalized then
		logDenied("character-persist", player, "invalid_internal_setting_or_character")
		return false
	end
	return dbExec(mysql:getConn("mta"), "REPLACE INTO character_settings (id, name, value) VALUES (?, ?, ?)", characterID, name, tostring(normalized))
end
addEvent("accounts:settings:updateCharacterSetting", false)
addEventHandler("accounts:settings:updateCharacterSetting", root, updateCharacterSetting)

function loadAccountSettings(player, id)
	local accountID = getAccountID(player)
	if not accountID or tonumber(id) ~= accountID then return false end

	local query = dbQuery(mysql:getConn("mta"), "SELECT name, value FROM account_settings WHERE id=?", accountID)
	if not query then return false end
	local rows = dbPoll(query, 10000)
	if not rows then
		dbFree(query)
		return false
	end

	local settings = {}
	for _, row in ipairs(rows) do
		local value = normalizeSetting(player, "account", row.name, row.value)
		if row.name == "duty_admin" and not exports.integration:isPlayerTrialAdmin(player) then
			value = 0
		elseif row.name == "duty_supporter" and not hasExplicitGameMasterGrant(player) then
			value = 0
		elseif row.name == "report_panel_mod"
			and not exports.integration:isPlayerTrialAdmin(player)
			and not hasExplicitGameMasterGrant(player) then
			value = "0"
		end
		if value then
			table.insert(settings, { row.name, value })
		end
	end
	if #settings > 0 then
		triggerClientEvent(player, "accounts:settings:loadAccountSettings", player, settings)
	end
	return true
end

function loadCharacterSettings(player, id)
	local accountID = getAccountID(player)
	local characterID = getCharacterID(player)
	if not accountID or not characterID or tonumber(id) ~= characterID then
		return false
	end

	local query = dbQuery(mysql:getConn("mta"), "SELECT name, value FROM character_settings WHERE id=?", characterID)
	if not query then return false end
	local rows = dbPoll(query, 10000)
	if not rows then
		dbFree(query)
		return false
	end

	local settings = {}
	for _, row in ipairs(rows) do
		local value = normalizeSetting(player, "character", row.name, row.value)
		if value then table.insert(settings, { row.name, value }) end
	end
	if #settings > 0 then
		triggerClientEvent(player, "accounts:settings:loadCharacterSettings", player, settings)
	end
	return true
end

-- Loading is performed by trusted account/character server code via direct
-- function calls. Do not expose account IDs or target player elements as a
-- remote request surface.
addEvent("accounts:settings:loadAccountSettings", false)
addEvent("accounts:settings:loadCharacterSettings", false)

function reconnectPlayer()
	if client and isPlayerElement(client) then
		redirectPlayer(client, "", 0)
	end
end
addEvent("accounts:settings:reconnectPlayer", true)
addEventHandler("accounts:settings:reconnectPlayer", root, reconnectPlayer)

local clientAccountSettings = {}
local clientCharacterSettings = {}

function whenPlayerQuit(quitType)
	local player = source
	if clientAccountSettings[player] then
		for _, setting in ipairs(clientAccountSettings[player]) do
			triggerEvent("accounts:settings:update", player, setting[1], setting[2])
		end
		clientAccountSettings[player] = nil
	end

	if clientCharacterSettings[player] then
		for _, setting in ipairs(clientCharacterSettings[player]) do
			triggerEvent("accounts:settings:updateCharacterSetting", player, setting[1], setting[2], setting[3])
		end
		clientCharacterSettings[player] = nil
	end
end
addEventHandler("onPlayerQuit", root, whenPlayerQuit)

function whenPlayerChangeChar()
	local player = source
	if clientCharacterSettings[player] then
		for _, setting in ipairs(clientCharacterSettings[player]) do
			triggerEvent("accounts:settings:updateCharacterSetting", player, setting[1], setting[2], setting[3])
		end
		clientCharacterSettings[player] = nil
	end
end
addEventHandler("accounts:characters:change", root, whenPlayerChangeChar)

function saveClientAccountSettingsOnServer(name, value)
	local player = client
	local accountID = getAccountID(player)
	local normalized = normalizeSetting(player, "account", name, value)
	if not accountID or getElementData(player, "loggedin") ~= 1 or source ~= player or not normalized then
		logDenied("account", player, "unauthenticated_or_disallowed_setting")
		return false
	end

	queueSetting(clientAccountSettings, player, name, normalized)
	setElementData(player, name, normalized)
	if name == "duty_admin" or name == "duty_supporter" then
		exports.global:updateNametagColor(player)
	end
	return true
end
addEvent("saveClientAccountSettingsOnServer", true)
addEventHandler("saveClientAccountSettingsOnServer", root, saveClientAccountSettingsOnServer)

function saveClientCharacterSettingsOnServer(name, value)
	local player = client
	local accountID = getAccountID(player)
	local characterID = getCharacterID(player)
	local normalized = normalizeSetting(player, "character", name, value)
	if not accountID or not characterID or source ~= player or not normalized then
		logDenied("character", player, "unauthenticated_or_disallowed_setting")
		return false
	end

	queueSetting(clientCharacterSettings, player, name, normalized, characterID)
	setElementData(player, name, normalized)
	return true
end
addEvent("saveClientCharacterSettingsOnServer", true)
addEventHandler("saveClientCharacterSettingsOnServer", root, saveClientCharacterSettingsOnServer)
