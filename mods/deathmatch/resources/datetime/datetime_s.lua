--MAXIME

addEventHandler("onResourceStart", resourceRoot, function()
	lastTime = getRealTime().timestamp
	serverCurrentTimeSec = tonumber(exports.mysql:query_fetch_assoc("SELECT TO_SECONDS(NOW()) AS `timesec` ")['timesec'])
end)

function getServerCurrentTimeSec()
	local requestingPlayer = client
	if not (requestingPlayer and isElement(requestingPlayer) and getElementType(requestingPlayer) == "player") then
		return false
	end
	if source ~= requestingPlayer then
		return false
	end
	triggerClientEvent(requestingPlayer, "setServerCurrentTimeSec", requestingPlayer, now())
	return true
end
addEvent("getServerCurrentTimeSec", true)
addEventHandler("getServerCurrentTimeSec", root, getServerCurrentTimeSec)

function getNow(player)
	outputChatBox("[Server] "..now(), player)
	local serverSec = tonumber(exports.mysql:query_fetch_assoc("SELECT TO_SECONDS(NOW()) AS `timesec` ")['timesec'])
	outputChatBox("[SQL] "..serverSec, player)
	outputChatBox("------------------------", player)
end
addCommandHandler("now", getNow)
