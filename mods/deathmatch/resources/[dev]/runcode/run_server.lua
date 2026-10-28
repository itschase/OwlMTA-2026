------------------------------------------
-- 		 	  	 GUIRuncode	 		 	--
------------------------------------------
-- Developer: Braydon Davis	(xXMADEXx)	--
-- File: run_server.lua					--
-- Copyright 2013 (C) RoS				--
-- All rights reserved.					--

-- Modified by anumaz, for owlgaming    --
------------------------------------------
sec = {{{{{{},{},{},{}}}}}}				--
------------------------------------------

local command = 'runcode' -- Command to open panel
local MAX_CODE_BYTES = 16384
local DENIAL_LOG_INTERVAL = 60000
local lastDeniedLog = {}

local function isLeadScripter(player)
	if not player or not isElement(player) or getElementType(player) ~= "player" then
		return false
	end

	local ok, allowed = pcall(function()
		return exports.integration:isPlayerLeadScripter(player)
	end)
	return ok and allowed == true
end

local function logEvent(actor, outcome, side, codeBytes)
	local name = getPlayerName(actor) or "unknown"
	name = tostring(name):gsub("[%c]", "?"):sub(1, 64)
	local message = ("[runcode] actor=%q outcome=%s side=%s bytes=%d")
		:format(name, outcome, side or "none", codeBytes or 0)
	outputDebugString(message, outcome == "denied" and 2 or 3)
	outputServerLog(message)
end

local function rejectRemoteRequest(actor)
	if not actor or not isElement(actor) or getElementType(actor) ~= "player" then
		return
	end

	local now = getTickCount()
	if not lastDeniedLog[actor] or now - lastDeniedLog[actor] >= DENIAL_LOG_INTERVAL then
		lastDeniedLog[actor] = now
		logEvent(actor, "denied", "server", 0)
	end
end

function openClientRuncodePanel ( player )
	if isLeadScripter(player) then
		triggerClientEvent ( player, "GUIRuncode:onClientOpenPanel", player )
	end
end
addCommandHandler ( command, openClientRuncodePanel )

local runString
addEvent ( "GUIRuncode:runServerCode", true )
addEventHandler ( "GUIRuncode:runServerCode", root, function ( code )
	local actor = client
	if not isLeadScripter(actor) then
		rejectRemoteRequest(actor)
		return
	end
	if type(code) ~= "string" or #code == 0 or #code > MAX_CODE_BYTES then
		logEvent(actor, "rejected_payload", "server", type(code) == "string" and #code or 0)
		return
	end
	runString ( code, actor )
end )

runString = function ( code, player )
	local notReturned
	local commandFunction,errorMsg = loadstring("return "..code)
	if errorMsg then
		notReturned = true
		commandFunction, errorMsg = loadstring(code)
	end
	if errorMsg then
		logEvent(player, "compile_error", "server", #code)
		triggerClientEvent ( player, 'GUIRuncode:setClientResultText', player, "Results: "..errorMsg )
		return
	end
	local results = { pcall(commandFunction) }
	if not results[1] then
		logEvent(player, "runtime_error", "server", #code)
		triggerClientEvent ( player, 'GUIRuncode:setClientResultText', player, "Results: "..results[2] )
		return
	end
	logEvent(player, "executed", "server", #code)
	if not notReturned then
		local resultsString = ""
		local first = true
		for i = 2, #results do
			if first then
				first = false
			else
				resultsString = resultsString..", "
			end
			local resultType = type(results[i])
			if isElement(results[i]) then
				resultType = "element:"..getElementType(results[i])
			end
			resultsString = resultsString..tostring(results[i]).." ["..resultType.."]"
		end
		triggerClientEvent ( player, 'GUIRuncode:setClientResultText', player, "Results: "..resultsString )
	elseif not errorMsg then
		triggerClientEvent ( player, 'GUIRuncode:setClientResultText', player, "Results: Command executed" )
	end
end

local function outputToLogs ( player, execution, side )
	logEvent(player, "client_reported", side, #execution)
end
addEvent ( 'GUIRuncode:outputLogs', true )
addEventHandler ( 'GUIRuncode:outputLogs', root, function ( _claimedActor, code, side )
	local actor = client
	if not isLeadScripter(actor) then
		rejectRemoteRequest(actor)
		return
	end
	if side ~= "client" or type(code) ~= "string" or #code == 0 or #code > MAX_CODE_BYTES then
		logEvent(actor, "rejected_payload", "client", type(code) == "string" and #code or 0)
		return
	end
	outputToLogs(actor, code, "client")
end)

addEventHandler("onPlayerQuit", root, function()
	lastDeniedLog[source] = nil
end)
