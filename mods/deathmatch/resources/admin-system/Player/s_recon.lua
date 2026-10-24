-- DISAPPEAR

function toggleInvisibility(thePlayer)
	if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerScripter(thePlayer) then
		if getElementData(thePlayer, "supervising") then
			outputChatBox("Please disable /supervise first.", thePlayer, 255, 0, 0)
			return
		end
		local enabled = getElementData(thePlayer, "invisible")
		if (enabled == true) then
			setElementAlpha(thePlayer, 255)
			exports.anticheat:changeProtectedElementDataEx(thePlayer, "reconx", false, false)
			outputChatBox("You are now visible.", thePlayer, 255, 0, 0)
			exports.anticheat:changeProtectedElementDataEx(thePlayer, "invisible", false, false)
			exports.logs:dbLog(thePlayer, 4, thePlayer, "DISAPPEAR DISABLED")
		elseif (enabled == false or enabled == nil) then
			setElementAlpha(thePlayer, 0)
			exports.anticheat:changeProtectedElementDataEx(thePlayer, "reconx", true, false)
			outputChatBox("You are now invisible.", thePlayer, 0, 255, 0)
			exports.anticheat:changeProtectedElementDataEx(thePlayer, "invisible", true, false)
			exports.logs:dbLog(thePlayer, 4, thePlayer, "DISAPPEAR ENABLED")
		else
			outputChatBox("Please disable recon first.", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("disappear", toggleInvisibility)


-- TOGGLE NAMETAG
function toggleMyNametag(thePlayer)
	local visible = getElementData(thePlayer, "reconx")
	local username = getElementData(thePlayer, "account:username")
	if exports.integration:isPlayerLeadAdmin(thePlayer) then
		if (visible == true) then
			setPlayerNametagShowing(thePlayer, false)
			--exports.anticheat:changeProtectedElementDataEx(thePlayer, "reconx", false, false)
			outputChatBox("Your nametag is now visible.", thePlayer, 255, 0, 0)
		elseif (visible == false or visible == nil) then
			setPlayerNametagShowing(thePlayer, false)
			--exports.anticheat:changeProtectedElementDataEx(thePlayer, "reconx", true, false)
			outputChatBox("Your nametag is now hidden.", thePlayer, 0, 255, 0)
		else
			outputChatBox("Please disable recon first.", thePlayer, 255, 0, 0)
		end
	end
end
addCommandHandler("togmytag", toggleMyNametag)

-- RP SUPERVISE
function roleplaySupervise(thePlayer)
	if exports.integration:isPlayerTrialAdmin(thePlayer) or exports.integration:isPlayerSupporter(thePlayer) then
		if exports.global:isStaffOnDuty(thePlayer) then
			if getElementData(thePlayer, "invisible") then
				outputChatBox("Please disable /disappear first.", thePlayer, 255, 0, 0)
				return
			end

			local enabled = getElementData(thePlayer, "supervising")
			if (enabled == true) then
				setElementAlpha(thePlayer, 255)
				outputChatBox("You are now no longer in supervisor state.", thePlayer, 255, 0, 0)
				exports.logs:dbLog(thePlayer, 4, thePlayer, "RP SUPERVISOR DISABLED")
				exports.global:sendWrnToStaff("[AdmCmd] "..getElementData(thePlayer, "account:username").." has disabled RP supervisor mode.")

				setElementData(thePlayer, "supervising", false)
			elseif (enabled == false or enabled == nil) then
				setElementAlpha(thePlayer, 100)
				outputChatBox("You are now in supervisor state.", thePlayer, 0, 255, 0)
				exports.logs:dbLog(thePlayer, 4, thePlayer, "RP SUPERVISOR ENABLED")
				exports.global:sendWrnToStaff("[AdmCmd] "..getElementData(thePlayer, "account:username").." has enabled RP supervisor mode.")

				setElementData(thePlayer, "supervising", true)
			else
				outputChatBox("Please disable recon first.", thePlayer, 255, 0, 0)
			end
		end
	end
end
addCommandHandler("supervise", roleplaySupervise)

local reconReturnPositions = {}

addEvent("recon:reattach", true)
addEventHandler("recon:reattach", resourceRoot, function()
	local player = client
	if not player or source ~= resourceRoot or not exports.integration:isPlayerTrialAdmin(player) then return end
	local target = getElementData(player, "reconx")
	if not isElement(target) or getElementType(target) ~= "player" or getElementData(target, "loggedin") ~= 1 then return end
	local int, dim = getElementInterior(target), getElementDimension(target)
	local x, y, z = getElementPosition(target)
	setElementInterior(player, int)
	setElementDimension(player, dim)
	setCameraInterior(player, int)
	setElementPosition(player, x, y, z - 5)
	attachElements(player, target, 0, 0, -5)
end)

-- MAXIME's reworks
function asyncReconActivate(cur)
	local player = client
	if not player or source ~= player or getElementData(player, "loggedin") ~= 1 or not exports.integration:isPlayerTrialAdmin(player) then return end
	if type(cur) ~= "table" or not tonumber(cur.target) or getElementData(player, "reconx") then return end
	local target = exports.pool:getElement("player", tonumber(cur.target))
	if not isElement(target) or target == player or getElementData(target, "loggedin") ~= 1 then
		triggerClientEvent(player, "admin:recon", player)
		return
	end
	local x, y, z = getElementPosition(player)
	local rx, ry, rz = getElementRotation(player)
	reconReturnPositions[player] = { x = x, y = y, z = z, rx = rx, ry = ry, rz = rz, dim = getElementDimension(player), int = getElementInterior(player) }
	removePedFromVehicle(player)
	if exports.freecam:isEnabled(player) then
		triggerEvent("freecam:asyncDeactivateFreecam", player)
	end

	-- Set important element data
	setElementData(player, "reconx", target, true)
	setElementData(player, "recontp", true)

	setElementCollisionsEnabled ( player, false )
	triggerEvent('artifacts:removeAllOnPlayer', root, player)
	setElementAlpha(player, 0)
	setPedWeaponSlot(player, 0)

	local t_int = getElementInterior(target)
	local t_dim = getElementDimension(target)

	setElementDimension(player, t_dim)
	setElementInterior(player, t_int)
	setCameraInterior(player, t_int)

	local x1, y1, z1 = getElementPosition(target)
	setElementPosition(player, x1, y1, 0)

	setTimer(function(staff, targetElement) if isElement(staff) and isElement(targetElement) and getElementData(staff, "reconx") == targetElement then setElementPosition(staff, x1, y1, z1-5); attachElements(staff, targetElement, 0, 0, -5) end end, 500, 1, player, target)

	setCameraTarget(player,target)
	exports.logs:dbLog(player, 4, target, "RECON")
	local hiddenAdmin = getElementData(player, "hiddenadmin")
	if hiddenAdmin == 0 and not (exports.integration:isPlayerSeniorAdmin(player) and exports.integration:isPlayerTrialAdmin(target) and not exports.integration:isPlayerAdmin(target))  then
		local adminTitle = exports.global:getPlayerAdminTitle(player)
		exports.global:sendMessageToAdmins("AdmCmd: " .. tostring(adminTitle) .. " " .. getElementData(player, "account:username") .. " started reconning " .. getPlayerName(target):gsub("_", " ") .. " (" .. getElementData(target, "account:username") .. ").")
	elseif exports.integration:isPlayerSeniorAdmin(player) and exports.integration:isPlayerTrialAdmin(target) and not exports.integration:isPlayerAdmin(target) and hiddenAdmin == 0 then
		local adminTitle = exports.global:getPlayerAdminTitle(player)
		exports.global:sendMessageToSeniorAdmins("SeniorAdmCmd: " .. tostring(adminTitle) .. " " .. getElementData(player, "account:username") .. " started reconning " .. getElementData(target, "account:username") .. ".")
	end
end
addEvent("admin:recon:async:activate", true)
addEventHandler("admin:recon:async:activate", root, asyncReconActivate)

function asyncReconDeactivate(cur)
	local player = client
	local saved = player and reconReturnPositions[player]
	if not player or source ~= player or not exports.integration:isPlayerTrialAdmin(player) or not saved or not getElementData(player, "reconx") then return end
	if exports.freecam:isEnabled(player) then
		triggerEvent("freecam:asyncDeactivateFreecam", player)
	end
	setElementData(player, "reconx", false, true)
	removeElementData(player, "recontp")

	removePedFromVehicle(player)
	detachElements(player)

	setElementPosition(player, saved.x, saved.y, saved.z)
	setElementRotation(player, saved.rx, saved.ry, saved.rz)

	setElementDimension(player, saved.dim)
	setElementInterior(player, saved.int)
	setCameraInterior(player,saved.int)

	setCameraTarget(player, nil)
	setElementAlpha(player, 255)
	setElementCollisionsEnabled ( player, true )
	reconReturnPositions[player] = nil
end
addEvent("admin:recon:async:deactivate", true)
addEventHandler("admin:recon:async:deactivate", root, asyncReconDeactivate)


addEvent("admin:disabledisappear", true)
addEventHandler("admin:disabledisappear", root, function (thePlayer)
	local player = client
	if not player or source ~= player or thePlayer ~= nil or getElementData(player, "loggedin") ~= 1 then return end
	if not (exports.integration:isPlayerTrialAdmin(player) or exports.integration:isPlayerScripter(player)) then return end
	exports.anticheat:changeProtectedElementDataEx(player, "reconx", false, false)
	exports.anticheat:changeProtectedElementDataEx(player, "invisible", false, false)
end)
addEventHandler("onPlayerQuit", root, function()
	reconReturnPositions[source] = nil
end)
