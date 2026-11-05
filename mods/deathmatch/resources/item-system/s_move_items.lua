local INVENTORY_SESSION_TTL = 300000
local MOVE_REQUEST_COOLDOWN = 250
local INVENTORY_DISTANCE = 6
local inventorySessions = {}
local lastMoveRequest = {}
local rejectionLogTicks = {}

local function elapsedTicks(now, previous)
	return (now - previous) % 4294967296
end

local function reportMoveRejection(reason)
	local now = getTickCount()
	local previous = rejectionLogTicks[reason]
	if not previous or elapsedTicks(now, previous) >= 30000 then
		rejectionLogTicks[reason] = now
		outputDebugString("[ITEM][MOVE_FROM] outcome=rejected reason=" .. reason, 2)
	end
end

local function isActiveInventoryActor(player)
	return isElement(player)
		and getElementType(player) == "player"
		and not isPedDead(player)
		and tonumber(getElementData(player, "loggedin")) == 1
		and (tonumber(getElementData(player, "account:id")) or 0) > 0
		and (tonumber(getElementData(player, "dbid")) or 0) > 0
end

local function isWorldStorageObject(player, element)
	if getElementType(element) ~= "object" then
		return false
	end

	local parent = getElementParent(element)
	local grandparent = parent and getElementParent(parent)
	local worldResource = getResourceFromName("item-world")
	if not worldResource or grandparent ~= getResourceRootElement(worldResource) then
		return false
	end

	local itemID = tonumber(getElementData(element, "itemID"))
	if not itemID or isStorageItem(itemID, getElementData(element, "itemValue")) ~= true then
		return false
	end

	local itemWorld = getResourceFromName("item-world")
	if not itemWorld or getResourceState(itemWorld) ~= "running" then
		return false
	end

	local ok, allowed = pcall(function()
		return exports["item-world"]:can(player, "use", element)
	end)
	return ok and allowed == true
end

local function hasInteriorStorageAccess(player, element)
	local interiorID = tonumber(getElementData(element, "dbid"))
	if not interiorID then
		return false
	end

	if hasItem(player, 4, interiorID) or hasItem(player, 5, interiorID)
		or tonumber(getElementData(player, "duty_admin")) == 1 then
		return true
	end

	local status = getElementData(element, "status")
	if type(status) == "table" and tonumber(status.type) == 2 then
		local factions = getResourceFromName("factions")
		if factions and getResourceState(factions) == "running" then
			local ok, allowed = pcall(function()
				return exports.factions:isInFactionType(player, 2) or exports.factions:isInFactionType(player, 3)
			end)
			return ok and allowed == true
		end
	end

	return false
end

local function hasSafeStorageAccess(player, element)
	local dimension = getElementDimension(player)
	if tonumber(getElementData(player, "admin_level")) and tonumber(getElementData(player, "admin_level")) >= 2
		and tonumber(getElementData(player, "duty_admin")) == 1 then
		return true
	elseif dimension < 19000 then
		return hasItem(player, 5, dimension) or hasItem(player, 4, dimension)
	elseif dimension >= 20000 then
		return hasItem(player, 3, dimension - 20000)
	end

	return false
end

local function isWithinInventoryDistance(player, element)
	local playerX, playerY, playerZ = getElementPosition(player)
	local elementX, elementY, elementZ = getElementPosition(element)
	if not playerX or not elementX then
		return false
	end

	return getDistanceBetweenPoints3D(playerX, playerY, playerZ, elementX, elementY, elementZ) <= INVENTORY_DISTANCE
end

local function canAccessInventoryContainer(player, element)
	if not isActiveInventoryActor(player) or not isElement(element) then
		return false
	end

	local elementType = getElementType(element)
	if elementType ~= "vehicle" and elementType ~= "interior" and elementType ~= "object" then
		return false
	end

	if elementType == "interior" then
		local interiorID = tonumber(getElementData(element, "dbid"))
		local isInside = interiorID and getElementDimension(player) == interiorID
		local isAtEntrance = getElementDimension(player) == getElementDimension(element)
			and getElementInterior(player) == getElementInterior(element)
			and isWithinInventoryDistance(player, element)
		return (isInside or isAtEntrance) and hasInteriorStorageAccess(player, element)
	end

	if getElementDimension(player) ~= getElementDimension(element)
		or getElementInterior(player) ~= getElementInterior(element)
		or not isWithinInventoryDistance(player, element) then
		return false
	end

	if elementType == "vehicle" then
		local vehicleID = tonumber(getElementData(element, "dbid"))
		local isDriver = getVehicleController(element) == player
		local hasKey = vehicleID and hasItem(player, 3, vehicleID)
		local factionID = tonumber(getElementData(element, "faction")) or -1
		local inOwningFaction = false
		local factions = getResourceFromName("factions")
		if factionID >= 0 and factions and getResourceState(factions) == "running" then
			local ok, allowed = pcall(function()
				return exports.factions:isPlayerInFaction(player, factionID)
			end)
			inOwningFaction = ok and allowed == true
		end

		if not isDriver and not hasKey and not inOwningFaction then
			return false
		end

		if (tonumber(getElementData(element, "Impounded")) or 0) > 0
			and not hasKey then
			return false
		end

		if isVehicleLocked(element) then
			return isDriver and tonumber(getElementData(player, "realinvehicle")) == 1
		end
		return true
	end

	local model = getElementModel(element)
	if model == 2332 then
		return hasSafeStorageAccess(player, element)
	end

	return isWorldStorageObject(player, element)
end

-- Retained for legacy move-to/world-item paths until their own Issue #213
-- slices are caller-bound. The stricter session policy above is used for
-- opening a container and taking an item from it.
local function canAccessElement(player, element)
	if not isElement(player) or getElementType(player) ~= "player" or isPedDead(player)
		or not isElement(element) then
		return false
	end

	if getElementDimension(player) ~= getElementDimension(element) then
		return getElementType(element) == "interior"
			and tonumber(getElementData(element, "dbid")) == getElementDimension(player)
	end

	if getElementType(element) ~= "vehicle" or not isVehicleLocked(element) then
		return true
	end

	return getPedOccupiedVehicle(player) == element and tonumber(getElementData(player, "realinvehicle")) == 1
end

local function createInventorySession(actor, element)
	local accountID = tonumber(getElementData(actor, "account:id"))
	local characterID = tonumber(getElementData(actor, "dbid"))
	local sessionCharacterID = tonumber(getElementData(actor, "account:character:id"))
	if not accountID or accountID < 1 or not characterID or characterID < 1 then
		return false
	end

	inventorySessions[actor] = {
		element = element,
		accountID = accountID,
		characterID = characterID,
		sessionCharacterID = sessionCharacterID,
		refreshedAt = getTickCount()
	}
	return inventorySessions[actor]
end

local function getCurrentInventorySession(actor, element)
	local session = inventorySessions[actor]
	if not session or session.element ~= element
		or session.accountID ~= tonumber(getElementData(actor, "account:id"))
		or session.characterID ~= tonumber(getElementData(actor, "dbid"))
		or session.sessionCharacterID ~= tonumber(getElementData(actor, "account:character:id"))
		or elapsedTicks(getTickCount(), session.refreshedAt) > INVENTORY_SESSION_TTL then
		return false
	end
	return session
end

local function clearInventorySession(actor)
	local session = inventorySessions[actor]
	if session and isElement(session.element) and isElement(actor) then
		unsubscribeInventoryChanges(session.element, actor)
	end
	inventorySessions[actor] = nil
end

function canReceiveContainerInventoryChanges(actor, element)
	local allowed = isActiveInventoryActor(actor)
		and getCurrentInventorySession(actor, element) ~= false
		and canAccessInventoryContainer(actor, element)
	if not allowed and inventorySessions[actor] then
		clearInventorySession(actor)
	end
	return allowed
end

--

local function openInventory(element, ax, ay)
	local actor = client
	if not actor or source ~= actor then
		reportMoveRejection("open_invalid_caller")
		return false
	end

	if not canAccessInventoryContainer(actor, element) then
		reportMoveRejection("open_access_denied")
		return false
	end

	clearInventorySession(actor)
	local session = createInventorySession(actor, element)
	if not session then
		reportMoveRejection("open_session_failed")
		return false
	end
	if not subscribeInventoryChanges(element, actor, "container") then
		clearInventorySession(actor)
		reportMoveRejection("open_subscription_failed")
		return false
	end

	setTimer(function(player, expectedElement, accountID, characterID)
		local current = inventorySessions[player]
		if current and current.element == expectedElement and current.accountID == accountID
			and current.characterID == characterID
			and elapsedTicks(getTickCount(), current.refreshedAt) >= INVENTORY_SESSION_TTL then
			clearInventorySession(player)
		end
	end, INVENTORY_SESSION_TTL + 100, 1, actor, element, session.accountID, session.characterID)

	ax = tonumber(ax) or 0
	ay = tonumber(ay) or 0
	triggerClientEvent(actor, "openElementInventory", element, ax, ay)
	return true
end

addEvent( "openFreakinInventory", true )
addEventHandler( "openFreakinInventory", getRootElement(), openInventory )

--

local function closeInventory(element)
	local actor = client
	if not actor or source ~= actor then
		reportMoveRejection("close_invalid_caller")
		return false
	end

	local session = inventorySessions[actor]
	if not session or session.element ~= element then
		reportMoveRejection("close_session_mismatch")
		return false
	end

	clearInventorySession(actor)
	return true
end

addEvent( "closeFreakinInventory", true )
addEventHandler( "closeFreakinInventory", getRootElement(), closeInventory )

addEventHandler("onPlayerQuit", root, function()
	clearInventorySession(source)
	lastMoveRequest[source] = nil
end)

addEventHandler("savePlayer", root, function(reason)
	if reason == "Change Character" or reason == "Account Logout" then
		clearInventorySession(source)
		lastMoveRequest[source] = nil
	end
end)

addEventHandler("accounts:characters:logout", root, function()
	clearInventorySession(source)
	lastMoveRequest[source] = nil
end)

addEventHandler("onElementDestroy", root, function()
	for player, session in pairs(inventorySessions) do
		if session.element == source then
			inventorySessions[player] = nil
		end
	end
end)

--

local function output(from, to, itemID, itemValue, evenIfSamePlayer, metadata)
	if from == to and not evenIfSamePlayer then
		return false
	end

	-- player to player
	if getElementType(from) == "player" and getElementType(to) == "player" then
		exports.global:sendLocalMeAction( from, "gives " .. getPlayerName( to ):gsub("_", " ") .. " a " .. getItemName( itemID, itemValue, metadata ) .. "." )
	-- player to item
	elseif getElementType(from) == "player" then
		local name = getName(to)
		if itemID == 134 then
			triggerEvent('sendAme', from, "puts $" .. exports.global:formatMoney(itemValue) .. " inside the ".. name .."." )
		elseif itemID == 150 then --ATM card / MAXIME
			triggerEvent('sendAme',  from, "puts an ATM card into the "..name.."." )
		else
			triggerEvent('sendAme',  from, "puts a " .. getItemName( itemID, itemValue, metadata ) .. " inside the ".. name .."." )
		end
	-- item to player
	elseif getElementType(to) == "player" then
		local name = getName(from)
		if itemID == 134 then
			triggerEvent('sendAme',  to, "takes $" .. exports.global:formatMoney(itemValue) .. " from the ".. name .."." )
		elseif itemID == 150 then --ATM card / MAXIME
			triggerEvent('sendAme',  to, "takes an ATM from the "..name.."." )
		else
			triggerEvent('sendAme',  to, "takes a " .. getItemName( itemID, itemValue, metadata ) .. " from the ".. name .."." )
		end
	end

	if itemID == 2 then
		triggerClientEvent(to, "phone:clearAllCaches", to, itemValue)
		triggerClientEvent(from, "phone:clearAllCaches", from, itemValue)
	end

	return true
end
function x_output_wrapper( ... ) return output( ... ) end

--



local function moveToElement( element, slot, ammo, event )
	if not canAccessElement( source, element ) then
		outputChatBox("You cannot access this inventory at the moment.", source, 255, 0, 0)
		triggerClientEvent( source, event or "finishItemMove", source )
		return
	end

	local name = getName(element)

	if not ammo then
		local item = getItems( source )[ slot ]
		if item then
			-- ANTI ALT-ALT FOR NON AMMO ITEMS, CHECK THIS FUNCTION FOR AMMO ITEM BELOW AND FOR WORLD ITEM CHECK s_world_items.lua/ MAXIME
			--31 -> 43  = DRUGS
			if ( (item[1] >= 31 and item[1] <= 43) or itemBannedByAltAltChecker[item[1]]) and not (getElementModel(element) == 2942 and item[1] == 150) then
				local hoursPlayedFrom = getElementData( source, "hoursplayed" )
				local hoursPlayedTo = 99
				if isElement(element) and getElementType(element) == "player" then
					hoursPlayedTo = getElementData( element, "hoursplayed" )
				end

				if not exports.global:isStaffOnDuty(source) and not exports.global:isStaffOnDuty(element) then
					if hoursPlayedFrom < 10 then
						outputChatBox("You require 10 hours of playing time to move a "..getItemName( item[1] ).." to a "..name..".", source, 255, 0, 0)
						triggerClientEvent( source, event or "finishItemMove", source )
						return false
					end

					if hoursPlayedTo < 10 then
						outputChatBox(string.gsub(getPlayerName(element), "_", " ").." requires 10 hours of playing time to receive a "..getItemName( item[1] ).." from you.", source, 255, 0, 0)
						outputChatBox("You require 10 hours of playing time to receive a "..getItemName( item[1] ).." from "..string.gsub(getPlayerName(source), "_", " ")..".", element, 255, 0, 0)
						triggerClientEvent( source, event or "finishItemMove", source )
						return false
					end
				end
				--outputDebugString(hoursPlayedFrom.." "..hoursPlayedTo)
			end
			
			-- Attempted to put an item INTO their alternate characters vehicle (not really much need to make a warning, as long as it's prevented)
			if getElementType(element) == "vehicle" and getElementData(element, "faction") < 0 then 
				local accountID = exports.cache:getAccountFromCharacterId(getElementData(source, "account:character:id"))
				local vehicleAccountID = exports.cache:getAccountFromCharacterId(getElementData(element, "owner"))
				if vehicleAccountID and accountID.id == vehicleAccountID.id and getElementData(source, "account:character:id") ~= getElementData(element, "owner") then
					--exports.global:sendWrnToStaff(getPlayerName(source):gsub("_", " ") .. " (" .. getElementData(source, "account:username") .. ") has attempted to put a " .. getItemName(item[1]) .. " into their alternate characters vehicle (#" .. getElementData(element, "dbid") .. ").", "ALT>ALT")
					outputChatBox(" You are not allowed to put items into your alternate characters vehicle!", source, 255, 0, 0)
					triggerClientEvent( source, event or "finishItemMove", source )
					return false
				end
			end
		
			if (getElementType(element) == "ped") and getElementData(element,"shopkeeper") then
				--[[if item[1] == 121 and not getElementData(element,"customshop") then-- supplies box
					triggerEvent("shop:handleSupplies", source, element, slot, event)
					return true
				end]] -- Removed by MAXIME
				if getElementData(element,"customshop") then
					if item[1] == 134 then -- money
						triggerClientEvent( source, event or "finishItemMove", source )
						return false
					end
					local restricted = {[27] = true, [29] = true, [177] = true, [76] = true, [219] = true, [221] = true, [220] = true, [126] = true, [217] = true, [162] = true, [137] = true}
					if restricted[item[1]] then
						outputChatBox('You cannot sell this item in the store.', source, 255, 100, 100)
						triggerClientEvent( source, event or "finishItemMove", source )
						return false
					end

					triggerEvent("shop:addItemToCustomShop", source, element, slot, event)
					return true
				end
				triggerClientEvent( source, event or "finishItemMove", source )
				return false
			end
			--outputDebugString(tostring(hasSpaceForItem(element, item[1], item[2]))	)
			if not (getElementModel( element ) == 2942) and not hasSpaceForItem( element, item[1], item[2] ) then --Except for ATM Machine
				outputChatBox( "The inventory is full.", source, 255, 0, 0 )
			else
				if (item[1] == 115) then -- Weapons
					local itemCheckExplode = exports.global:explode(":", item[2])
					-- itemCheckExplode: [1] = gta weapon id, [2] = serial number, [3] = weapon name
					local weaponDetails = exports.global:retrieveWeaponDetails( itemCheckExplode[2]  )
					if tonumber(weaponDetails[2]) then
						local gun_source = tonumber(weaponDetails[2])
						-- duty weapon
						if gun_source == 2  then
							outputChatBox("You can't put your duty weapon in a " .. name .. ".", source, 255, 0, 0)
							triggerClientEvent( source, event or "finishItemMove", source )
							return
						-- bought from ammunation, it's ok, let them move/stash it. We block it when someone else is picking it up.
						--[[
						elseif gun_source == 3 then
							outputChatBox("(( This "..itemCheckExplode[3].." was bought  ))", source, 255, 0, 0)
							triggerClientEvent( source, event or "finishItemMove", source )
							return
						end
						]]
						end
					end
				--[[elseif (item[1] == 179 and getElementType(element) == "vehicle") then --vehicle texture
					outputDebugString("vehicle texture")
					local vehID = getElementData(element, "dbid")
					local veh = element
					if(exports.global:isStaffOnDuty(source) or exports.integration:isPlayerScripter(source) or exports.global:hasItem(source, 3, tonumber(vehID)) or (getElementData(veh, "faction") > 0 and exports.factions:isPlayerInFaction(source, getElementData(veh, "faction"))) ) then
						outputDebugString("access granted")
						local itemExploded = exports.global:explode(";", item[2])
						local url = itemExploded[1]
						local texName = itemExploded[2]
						if url and texName then
							local res = exports["item-texture"]:addVehicleTexture(source, veh, texName, url)
							if res then
								takeItemFromSlot(source, slot)
								outputDebugString("success")
								outputChatBox("success", source)
							else
								outputDebugString("item-system/s_move_items: Failed to add vehicle texture")
							end
							triggerClientEvent(source, event or "finishItemMove", source)
							return
						end
					end
				--]]
				end

				if (item[1] == 137 or item[1] == 162 or item[1] == 219 or item[1] == 220 or item[1] == 221 or item[1] == 262 or item[1] == 263) then -- Snake cam and armors
					outputChatBox("You cannot move this item.", source, 255, 0, 0)
					triggerClientEvent( source, event or "finishItemMove", source )
					return
				elseif item[1] == 138 then
					if not exports.integration:isPlayerTrialAdmin(source) and getElementType(element) == "Vehicle" then
						outputChatBox("Only a admin can install this item.", source, 255, 0, 0)
						triggerClientEvent( source, event or "finishItemMove", source )
						return
					end
				elseif item[1] == 139 then
					if not exports.integration:isPlayerTrialAdmin(source) then
						outputChatBox("It requires a trial administrator to move this item.", source, 255, 0, 0)
						triggerClientEvent(source, event or "finishItemMove", source)
						return
					end
				end

				if (item[1] == 134) then -- Money
					if not exports.global:isStaffOnDuty(source) and not exports.global:isStaffOnDuty(element) then
						local hoursPlayedFrom = getElementData( source, "hoursplayed" ) or 99
						local hoursPlayedTo = getElementData( element, "hoursplayed" ) or 99
						if (getElementType(element) == "player") and (getElementType(source) == "player") then
							if hoursPlayedFrom < 10 or hoursPlayedTo < 10 then
								outputChatBox("You require 10 hours of playing time to give money to another player.", source, 255, 0, 0)
								outputChatBox(exports.global:getPlayerName(source).." requires 10 hours of playing time to give money to you.", element, 255, 0, 0)
								triggerClientEvent( source, event or "finishItemMove", source )

								outputChatBox("You require 10 hours of playing time to receive money from another player.", element, 255, 0, 0)
								outputChatBox(exports.global:getPlayerName(element).." requires 10 hours of playing time to receive money from you.", source, 255, 0, 0)
								triggerClientEvent( source, event or "finishItemMove", source )
								return false
							end
						elseif (getElementType(element) == "vehicle") and (getElementType(source) == "player") then
							if hoursPlayedFrom < 10 then
								outputChatBox("You require 10 hours of playing time to store money in a vehicle.", source, 255, 0, 0)
								triggerClientEvent( source, event or "finishItemMove", source )
								return false
							end
						elseif (getElementType(element) == "object") and (getElementType(source) == "player") then
							if hoursPlayedFrom < 10 then
								outputChatBox("You require 10 hours of playing time to store money in that.", source, 255, 0, 0)
								triggerClientEvent( source, event or "finishItemMove", source )
								return false
							end
						end
					end

					if exports.global:takeMoney(source, tonumber(item[2])) then
						if getElementType(element) == "player" then
							if exports.global:giveMoney(element, tonumber(item[2])) then
								triggerEvent('sendAme', source, "gives $" .. exports.global:formatMoney(item[2]) .. " to ".. exports.global:getPlayerName(element) .."." )
							end
						else
							if exports.global:giveItem(element, 134, tonumber(item[2])) then
								triggerEvent('sendAme', source, "puts $" .. exports.global:formatMoney(item[2]) .. " inside the "..  name .."." )
							end
						end
					end
				else -- not money
					if getElementType( element ) == "object" then
						local elementModel = getElementModel(element)
						local elementItemID = getElementData(element, "itemID")
						if elementItemID then
							if elementItemID == 166 then --video player
								if item[1] ~= 165 then --if item being moved to video player is not a valid video item
									exports.hud:sendBottomNotification(source, "Video Player", "That is not a valid disc.")
									triggerClientEvent( source, event or "finishItemMove", source )
									return
								end
							end
						end
						if ( getElementDimension( element ) < 19000 and ( item[1] == 4 or item[1] == 5 ) and getElementDimension( element ) == item[2] ) or ( getElementDimension( element ) >= 20000 and item[1] == 3 and getElementDimension( element ) - 20000 == item[2] ) then -- keys to that safe as well
							if countItems( source, item[1], item[2] ) < 2 then
								outputChatBox("You can't place your only key to that safe in the safe.", source, 255, 0, 0)
								triggerClientEvent( source, event or "finishItemMove", source )
								return
							end
						end
					end

					local success, reason = moveItem( source, element, slot )
					if not success then
						if not elementItemID then elementItemID = getElementData(element, "itemID") end
						local fakeReturned = false
						if elementItemID then
							if elementItemID == 166 then --video system
								exports.hud:sendBottomNotification(source, "Video Player", "There is already a disc inside. Eject old disc first.")
								fakeReturned = true
							end
						end
						if not fakeReturned then --only check by model IDs if we didnt already find a match on itemID
							if getElementModel(element) == 2942 then
								exports.hud:sendBottomNotification(source, "ATM Machine", "There is another ATM stuck inside the ATM machine's slot. Right-click for interactions.")
							end
						end
						outputDebugString( "Item Moving failed: " .. tostring( reason ))
					else
						if getElementModel(element) == 2942 then
							exports.bank:playAtmInsert(element)
						elseif item[1] == 165 then --video disc
							if exports.clubtec:isVideoPlayer(element) then
								--triggerEvent("sendAme",  source, "ejects a disc from the video player." )
								for key, value in ipairs(getElementsByType("player")) do
									if getElementDimension(value)==getElementDimension(element) then
										triggerEvent("fakevideo:loadDimension", value)
									end
								end
							end
						elseif getElementType(element) == "vehicle" and item[1] == 212 then  --snow tires
							if getResourceFromName("shader_snow_ground") and getResourceState(getResourceFromName("shader_snow_ground")) == "running" then
								local driver = getVehicleController(element)
								local hasSnowTires = true --hasItem(element, 212)
								triggerClientEvent(driver, "shader_snow_ground:applySlippery", root, element, hasSnowTires)
							end
						end
						--exports.logs:dbLog(source, 39, source, getPlayerName( source ) .. "->" .. name .. " #" .. getElementID(element) .. " - " .. getItemName( item[1] ) .. " - " .. item[2] )
						doItemGiveawayChecks( source, item[1] )
						output(source, element, item[1], item[2], nil, item[5])
					end
				end
				exports.logs:dbLog(source, 39, source, getPlayerName( source ) .. "->" .. name .. " #" .. getElementID(element) .. " - Item ID: " .. item[1] .. " - " .. getItemName(item[1], item[2], item[5]) .. " @ "..getCoordinates( element ))
			end
		end
	else -- IF AMMO
		if not ( ( slot == -100 and hasSpaceForItem( element, slot ) ) or ( slot > 0 and hasSpaceForItem( element, -slot ) ) ) then
			outputChatBox( "The Inventory is full.", source, 255, 0, 0 )
		else
			if tonumber(getElementData(source, "duty")) > 0 then
				outputChatBox("You can't put your weapons in a " .. name .. " while being on duty.", source, 255, 0, 0)
			elseif tonumber(getElementData(source, "job")) == 4 and slot == 41 then
				outputChatBox("You can't put this spray can into a " .. name .. ".", source, 255, 0, 0)
			else
				if slot == -100 then
					local ammo = math.ceil( getPedArmor( source ) )
					if ammo > 0 then
						setPedArmor( source, 0 )
						giveItem( element, slot, ammo )
						exports.logs:dbLog(source, 39, source, getPlayerName(source) .. " moved " .. getItemName(slot) " - " .. ammo .. " #" .. getElementID(element) )
						output(source, element, -100)
					end
				else
					local getCurrentMaxAmmo = exports.global:getWeaponCount(source, slot)
					if ammo > getCurrentMaxAmmo then
						exports.global:sendMessageToAdmins("[items\moveToElement] Possible duplication of gun from '"..getPlayerName(source).."' // " .. getItemName( -slot ) )
						exports.logs:dbLog(source, 39, source, getPlayerName(source) .. " moved " .. getItemName(-slot) " -  #" .. getElementID(element) .. " - BLOCKED DUE POSSIBLE DUPING" )
						triggerClientEvent( source, event or "finishItemMove", source )
						return
					end
					exports.global:takeWeapon( source, slot )
					if ammo > 0 then
						giveItem( element, -slot, ammo )
						exports.logs:dbLog(source, 39, source, getPlayerName(source) .. " moved " .. getItemName(-slot) " - " .. ammo .. " #" .. getElementID(element) )
						output(source, element, -slot)
					end
				end
			end
		end
	end
	--outputDebugString("moveToElement")
	triggerClientEvent( source, event or "finishItemMove", source )
end

addEvent( "moveToElement", true )
addEventHandler( "moveToElement", getRootElement(), moveToElement )

--

local function moveWorldItemToElement( item, element )
	if false then
		return outputDebugString("[ITEM] moveWorldItemToElement / Disabled ")
	end

	if not isElement( item ) or not isElement( element ) or not canAccessElement( source, element ) then
		return
	end

	local id = tonumber(getElementData( item, "id" ))
	if not id then
		outputChatBox("Error: No world item ID. Notify a scripter. (s_move_items)",source,255,0,0)
		destroyElement(element)
		return
	end
	local itemID = getElementData( item, "itemID" )
	local itemValue = getElementData( item, "itemValue" ) or 1
	local metadata = getElementData( item, "metadata" )
	local name = getName(element)

	-- ANTI ALT-ALT  MAXIME
	--31 -> 43  = DRUGS
	if ((itemID >= 31) and (itemID <= 43)) or itemBannedByAltAltChecker[itemID] or itemID == 223 then
		outputChatBox(getItemName(itemID).." can only moved directly from your inventory to this "..name..".", source, 255, 0, 0)
		return false
	end


	if (getElementType(element) == "ped") and getElementData(element,"shopkeeper") then
		return false
	end

	if not canPickup(source, item) then
		outputChatBox("You can not move this item. Contact an admin via F1.", source, 255, 0, 0)
		return
	end

	if itemID == 138 then
		if not exports.integration:isPlayerTrialAdmin(source) and getElementType(element) == "Vehicle" then
			outputChatBox("Only an admin can install this item.", source, 255, 0, 0)
			return
		end
	end

	if itemID == 169 or itemID == 262 or itemID == 263 then
		--outputChatBox("Nay.")
		return
	end

	if giveItem( element, itemID, itemValue, false, false, metadata ) then
		--[[
		if itemID == 166 then --video player
			local videoplayerDisc = exports.clubtec:getVideoPlayerCurrentVideoDisc(item) or 2
			local videoplayerObject = nil
			local dimensionPlayers = {}
			for key, value in ipairs(getElementsByType("player")) do
				if getElementDimension(value)==getElementDimension(item) then
					table.insert(dimensionPlayers,value)
				end
			end
			triggerClientEvent(dimensionPlayers, "fakevideo:removeOne", source, videoplayerDisc, itemValue, videoplayerObject)
		end
		--]]

		if getElementType(element) == "vehicle" then
			if itemID == 212 then --snow tires
				if getResourceFromName("shader_snow_ground") and getResourceState(getResourceFromName("shader_snow_ground")) == "running" then
					local driver = getVehicleController(element)
					local hasSnowTires = true --hasItem(element, 212)
					triggerClientEvent(driver, "shader_snow_ground:applySlippery", root, element, hasSnowTires)
				end
			end
		end

		output(source, element, itemID, itemValue, true, metadata)
		exports.logs:dbLog( source, 39, source, getPlayerName( source ) .. " put item #" .. id .. " (" .. itemID .. ":" .. getItemName( itemID ) .. ") - " .. itemValue .. " in " .. name .. " #" .. getElementID(element))
		mysql:query_free("DELETE FROM worlditems WHERE id='" .. id .. "'")

		while #getItems( item ) > 0 do
			moveItem( item, element, 1 )
		end
		destroyElement( item )

		if itemID == 166 then --video player
			for key, value in ipairs(getElementsByType("player")) do
				if getElementDimension(value)==getElementDimension(source) then
					triggerEvent("fakevideo:loadDimension", value)
				end
			end
		end
	else
		outputChatBox( "The Inventory is full.", source, 255, 0, 0 )
	end
end

addEvent( "moveWorldItemToElement", true )
addEventHandler( "moveWorldItemToElement", getRootElement(), moveWorldItemToElement )

--

local function finishElementMove(actor, forceUpdate)
	if not isElement(actor) then
		return
	end
	if forceUpdate then
		triggerClientEvent(actor, "forceElementMoveUpdate", actor)
	end
	triggerClientEvent(actor, "finishItemMove", actor)
end

local function getServerAmmoGrant(actor, itemID, storedAmount)
	local normalizedItemID = tonumber(itemID)
	local weaponID = normalizedItemID and -normalizedItemID
	storedAmount = tonumber(storedAmount)
	if not weaponID or weaponID ~= math.floor(weaponID) or weaponID < 0 or weaponID > 46
		or not storedAmount or storedAmount ~= math.floor(storedAmount) or storedAmount < 1 then
		return false, "invalid_weapon_item"
	end

	local weaponcap = getResourceFromName("weaponcap")
	if not weaponcap or getResourceState(weaponcap) ~= "running" then
		return false, "weaponcap_unavailable"
	end

	local ok, freeForWeapon, freeTotal = pcall(function()
		return exports.weaponcap:getFreeAmmo(actor, weaponID)
	end)
	freeForWeapon = tonumber(freeForWeapon)
	freeTotal = tonumber(freeTotal)
	if not ok or not freeForWeapon or not freeTotal then
		return false, "weaponcap_error"
	end

	local grant = math.min(storedAmount, math.floor(freeForWeapon), math.floor(freeTotal))
	if grant < 1 then
		return false, "capacity_exhausted"
	end

	return grant, nil, weaponID
end

local function compensateWeaponPickup(actor, settlement, reason)
	reportMoveRejection(reason)
	restoreWeaponPickupSettlement(settlement, function(restored, restoreReason)
		if not restored then
			reportMoveRejection("compensation_" .. tostring(restoreReason or "failed"))
		end
		if isElement(actor) then
			outputChatBox("The item could not be moved. Please try again.", actor, 255, 0, 0)
			finishElementMove(actor, true)
		end
	end)
end

local function processWeaponPickup(actor, element, slot, item, itemIndex, name)
	local grant, grantError, weaponID = getServerAmmoGrant(actor, item[1], item[2])
	if not grant then
		reportMoveRejection(grantError)
		outputChatBox("You cannot carry any more of that weapon or ammunition.", actor, 255, 0, 0)
		finishElementMove(actor, false)
		return false
	end

	local started, startError = settleWeaponPickup(element, slot, itemIndex, grant, function(settled, settleError, settlement)
		if not settled then
			reportMoveRejection("settlement_" .. tostring(settleError or "failed"))
			if isElement(actor) then
				outputChatBox("The item changed before it could be moved. Please try again.", actor, 255, 0, 0)
				finishElementMove(actor, true)
			end
			return
		end

		local session = isActiveInventoryActor(actor) and getCurrentInventorySession(actor, element)
		if not isElement(element) or not session or not canAccessInventoryContainer(actor, element) then
			clearInventorySession(actor)
			compensateWeaponPickup(actor, settlement, "post_commit_access_changed")
			return
		end

		local currentGrant = getServerAmmoGrant(actor, item[1], settlement.pickupAmount)
		if not currentGrant or currentGrant < settlement.pickupAmount then
			compensateWeaponPickup(actor, settlement, "post_commit_capacity_changed")
			return
		end

		settlement.grantAttempted = true
		if not giveWeapon(actor, weaponID, settlement.pickupAmount, false) then
			compensateWeaponPickup(actor, settlement, "weapon_grant_failed")
			return
		end
		settlement.grantApplied = true

		if not completeWeaponPickupSettlement(settlement) then
			reportMoveRejection("post_grant_settlement_indeterminate")
			finishElementMove(actor, true)
			return
		end
		output(element, actor, item[1], nil, nil, item[5])
		local auditOK = pcall(function()
			exports.logs:dbLog(
				actor,
				39,
				{ actor, element },
				name .. " #" .. getElementID(element) .. "->" .. getPlayerName(actor)
					.. " - " .. getItemName(item[1], item[2], item[5]) .. " - " .. settlement.pickupAmount
			)
		end)
		if not auditOK then
			reportMoveRejection("audit_unavailable_after_commit")
		end
		finishElementMove(actor, true)
	end)

	if not started and startError then
		reportMoveRejection("settlement_" .. tostring(startError))
	end
	return started
end

local function moveFromElement(element, slot, index)
	local actor = client
	local eventSource = source
	if not actor or eventSource ~= actor or not isActiveInventoryActor(actor) then
		reportMoveRejection("invalid_caller")
		return false
	end

	local source = actor
	slot = tonumber(slot)
	index = tonumber(index)
	if not isElement(element) or not slot or slot ~= math.floor(slot) or slot < 1
		or not index or index ~= math.floor(index) or index < 1 then
		reportMoveRejection("invalid_item_reference")
		finishElementMove(source, false)
		return false
	end

	local session = getCurrentInventorySession(source, element)
	if not session then
		clearInventorySession(source)
		reportMoveRejection("missing_inventory_session")
		finishElementMove(source, false)
		return false
	end

	local now = getTickCount()
	if lastMoveRequest[source] and elapsedTicks(now, lastMoveRequest[source]) < MOVE_REQUEST_COOLDOWN then
		reportMoveRejection("rate_limited")
		finishElementMove(source, false)
		return false
	end
	lastMoveRequest[source] = now

	if not canAccessInventoryContainer(source, element) then
		reportMoveRejection("access_denied")
		finishElementMove(source, false)
		return false
	end

	local items = getItems(element)
	local item = items and items[slot]
	if not item or tonumber(item[3]) ~= index then
		reportMoveRejection("stale_item_reference")
		finishElementMove(source, true)
		return false
	end

	if not canPickup(source, item) then
		outputChatBox("You can not move this item. Contact an admin via F1.", source, 255, 0, 0)
		finishElementMove(source, false)
		return false
	end


	local name = getName(element)

	if item and tonumber(item[3]) == index then
		-- ANTI ALT-ALT FOR NON AMMO ITEMS, CHECK THIS FUNCTION FOR AMMO ITEM BELOW AND FOR WORLD ITEM CHECK s_world_items.lua
		--31 -> 43  = DRUGS
		if ( (item[1] >= 31 and item[1] <= 43) or itemBannedByAltAltChecker[item[1]]) and not (getElementModel(element) == 2942 and item[1] == 150) then
			local hoursPlayedTo = nil

			if isElement(source) and getElementType(source) == "player" then
				hoursPlayedTo = getElementData( source, "hoursplayed" )
			end

			if not exports.global:isStaffOnDuty(source) and not exports.global:isStaffOnDuty(element) then
				if hoursPlayedTo < 10 then
					if not (item[1] == 3 and getElementData(exports.pool:getElement("vehicle", item[2]), "owner") == getElementData(source, "dbid")) then -- Checks if they own the vehicle for the key
						outputChatBox("You require 10 hours of playing time to receive a "..getItemName( item[1] ).." from a "..name..".", source, 255, 0, 0)
						triggerClientEvent( source, "forceElementMoveUpdate", source )
						triggerClientEvent( source, "finishItemMove", source )
						return false
					end
				end
			end
		end

		-- Attempted to take an item FROM their alternate characters vehicle
		if getElementType(element) == "vehicle" and getElementData(element, "faction") < 0 then 
			local accountID = exports.cache:getAccountFromCharacterId(getElementData(source, "account:character:id"))
			local vehicleAccountID = exports.cache:getAccountFromCharacterId(getElementData(element, "owner"))
			if vehicleAccountID and accountID.id == vehicleAccountID.id and getElementData(source, "account:character:id") ~= getElementData(element, "owner") then
				exports.global:sendWrnToStaff(getPlayerName(source):gsub("_", " ") .. " (" .. getElementData(source, "account:username") .. ") has attempted to take a " .. getItemName(item[1]) .. " from their alternate characters vehicle (#" .. getElementData(element, "dbid") .. ").", "ALT>ALT")
				outputChatBox(" You are not allowed to take items from your alternate characters vehicle!", source, 255, 0, 0)
				triggerClientEvent( source, event or "finishItemMove", source )
				return false
			end
		end
		
		-- now check if it's duty weapon or bought from ammunation and if player is authorized
		if item[1] == 115 or item[1] == 116 then
			local can, why = exports.weapon:canRetrieve(source, item[1], item[2])
			if not can then
				outputChatBox(why, source, 255,0,0)
				triggerClientEvent( source, "finishItemMove", source )
				return false
			end
		end

		if not hasSpaceForItem( source, item[1], item[2] ) then
			outputChatBox( "The inventory is full.", source, 255, 0, 0 )
		elseif not exports.integration:isPlayerTrialAdmin( source ) and getElementType( element ) == "vehicle" and ( item[1] == 61 or item[1] == 85  or item[1] == 117 or item[1] == 140) then
			outputChatBox( "Please contact an admin via F1 to move this item.", source, 255, 0, 0 )
		elseif not exports.integration:isPlayerAdmin(source) and (item[1] == 138) then
			outputChatBox("This item requires a regular admin to be moved.", source, 255, 0, 0)
		elseif not exports.integration:isPlayerTrialAdmin(source) and (item[1] == 139) then
			outputChatBox("This item requires an admin to be moved.", source, 255, 0, 0)
		elseif item[1] > 0 then
			if moveItem( element, source, slot ) then
				output( element, source, item[1], item[2], nil, item[5])
				exports.logs:dbLog(source, 39, source, name .. " #" .. getElementID(element) .. "->" .. getPlayerName( source ) .. " - " .. getItemName( item[1], item[2], item[5] ) .. " - " .. item[2])
				doItemGivenChecks(source, tonumber(item[1]))
				if getElementType(element) == "vehicle" then
					if item[1] == 3 then
						if getVehicleEngineState(element) and tonumber(item[2]) == tonumber(getElementData(element, "dbid")) then
							setVehicleEngineState(element, false)
							exports.anticheat:setEld(element, 'engine', 0)
						end
					elseif item[1] == 212 then --snow tires
						if getResourceFromName("shader_snow_ground") and getResourceState(getResourceFromName("shader_snow_ground")) == "running" then
							local driver = getVehicleController(element)
							local hasSnowTires = false --hasItem(element, 212)
							triggerClientEvent(driver, "shader_snow_ground:applySlippery", root, element, hasSnowTires)
						end
					end
				end
			end
		elseif item[1] == -100 then
			local faction = getElementData( source, "faction" )
			local armor = math.max( 0, ( ( faction[1] or ( faction[3] and ( (faction[1].rank == 4 or faction[3].rank == 4) or (faction[1].rank == 5 or faction[3].rank == 5) or (faction[1].rank == 13 or faction[3].rank == 13) ) ) ) and 100 or 50 ) - math.ceil( getPedArmor( source ) ) )

			if armor == 0 then
				outputChatBox( "You can't wear any more armor.", source, 255, 0, 0 )
			else
				output( element, source, item[1], nil, nil, item[5])
				takeItemFromSlot( element, slot )

				local leftover = math.max( 0, item[2] - armor )
				if leftover > 0 then
					giveItem( element, item[1], leftover )
				end

				setPedArmor( source, math.ceil( getPedArmor( source ) + math.min( item[2], armor ) ) )
				exports.logs:dbLog(source, 39, source, name .. " #" .. getElementID(element) .. "->" .. getPlayerName( source ) .. " - " .. getItemName( item[1], item[2], item[5] ) .. " - " .. ( math.min( item[2], armor ) ))
			end
			triggerClientEvent( source, "forceElementMoveUpdate", source )
		else
			processWeaponPickup(source, element, slot, item, index, name)
			return
		end
	else
		outputDebugString( "Index mismatch: " .. tostring( item and item[3] or "nil" ) .. " " .. tostring( index ) )
	end

	--outputDebugString("moveFromElement")
	triggerClientEvent( source, "finishItemMove", source )
end
addEvent( "moveFromElement", true )
addEventHandler( "moveFromElement", getRootElement(), moveFromElement )

function getName(element)
	local elementType = getElementType(element)
	if elementType == "vehicle" then
		return exports.global:getVehicleName(element)
	elseif elementType == "interior" then
		return getElementData(element, "name").."'s Mailbox"
	elseif elementType == "player" then
		return "player"
	elseif elementType == "object" then
		local model = getElementModel(element)
		if model == 2942 then
			return "ATM Machine"
		elseif model == 2147 then
			return "fridge"
		elseif model == 3761 then
			return "shelf"
		elseif model == 2332 then
			return "safe"
		elseif getElementParent(getElementParent(element)) == getResourceRootElement(getResourceFromName("item-world")) then
			local itemID = tonumber(getElementData(element, "itemID")) or 0
			local itemValue = getElementData(element, "itemValue")
			if itemID == 166 then --video player
				return "video player"
			else
				return getItemName(itemID, itemValue):lower()
			end
		else
			return "storage"
		end
	else
		return "storage"
	end
end

function getCoordinates( element )
	if isElement( element ) then
		local x, y, z = getElementPosition( element )
		local int = getElementInterior( element )
		local dim = getElementDimension( element )
		return "("..x..", "..y..", "..z..") in (int "..int..", dim "..dim..")"
	else
		return ""
	end
end
