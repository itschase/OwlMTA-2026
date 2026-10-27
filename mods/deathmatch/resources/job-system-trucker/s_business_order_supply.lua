--[[
 * ***********************************************************************************************************************
 * Copyright (c) 2015 OwlGaming Community - All Rights Reserved
 * All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * ***********************************************************************************************************************
 ]]

profitRate = tonumber(get( getResourceName( getResourceFromName("npc") ).. '.profitRate' ))
oneSupply = tonumber(get( getResourceName( getResourceFromName("npc") ).. '.oneSupply' ))

local function SmallestID() -- finds the smallest ID in the SQL instead of auto increment
	local result1 = mysql:query_fetch_assoc("SELECT MIN(e1.orderID+1) AS nextID FROM jobs_trucker_orders AS e1 LEFT JOIN jobs_trucker_orders AS e2 ON e1.orderID +1 = e2.orderID WHERE e2.orderID IS NULL")
	if result1 then
		return result1["nextID"] ~= mysql_null() and result1["nextID"] or "1"
	end
	return false
end

local function findRootInteriorMarker(dim)
	local foundRootInterior = false
	for key, interior in pairs(getElementsByType("interior")) do
		if dim == getElementData(interior, "dbid") then
			local marker = getElementData(interior, "entrance")
			if marker.int == 0 and marker.dim == 0 then
				return marker.x, marker.y, marker.z, getElementData(interior, "name") or "Unknown"
			else
				return false, marker.dim
			end
			break
		end
	end
end

function orderSupplies(thePlayer, commandName, money)
	money = tonumber(money) or 0
	if money%1~=0 or money <= 0 then
		outputChatBox("SYNTAX: /" .. commandName .. " [Money spend on supplies] - Place an order of supplies to RS Haul to maintain your business.", thePlayer, 255, 194, 14)
		return false
	end
	local supplies = money / oneSupply
	local isAdmin = string.lower(commandName) == "aordersupplies" and exports.integration:isPlayerAdmin(thePlayer)
	local done, why = remoteOrderSupplies(thePlayer, supplies, money, isAdmin)
	outputChatBox(why,thePlayer, 255, 194, 14)
	return done
end
addCommandHandler("ordersupplies", orderSupplies, false, false)

function adminOrderSupplies(thePlayer, commandName, money)
	if exports.integration:isPlayerAdmin(thePlayer) then
		local amount = tonumber(money) or 0
		orderSupplies(thePlayer, commandName, amount > 5000 and 5000 or amount) -- Noone should be able to give away too much supplies as it is expensive as fuck atm.
	end
end
addCommandHandler("aordersupplies", adminOrderSupplies, false, false)

local function canOrderSupplies(player, is_admin, money, useBank)
	money = tonumber(money)
	if not money or money%1~=0 or money <= 0 then
		return false, "Invalid money input."
	end

	-- fetch some info
	local dim = getElementDimension(player)
	local interior = exports.pool:getElement('interior', dim)
	local status = interior and getElementData(interior, 'status')
	local faction_owned = status and tonumber(status.faction)
	local owner = status and tonumber(status.owner)
	local int_type = status and tonumber(status.type)

	if dim <= 0 then
		return false, "You must be inside the business and have pair of keys to be able to order more supplies."
	end

	-- non business
	if int_type ~= 1 then
		return false, "You can not place a supplies order for a non business property"
	end
	if is_admin then
		return true, false
	end

	-- if faction owned
	if faction_owned and faction_owned > 0 then
		local is_faction_leader = exports.factions:hasMemberPermissionTo(player, faction_owned, "manage_finance")
		local faction = exports.pool:getElement('team', faction_owned)
		if not faction or not isElement(faction) then
			return false, "The business faction is unavailable."
		end
		if is_faction_leader or is_admin then
			if exports.bank:hasBankMoney(faction, money) then
				return true, faction
			else
				return false, "You don't have $"..exports.global:formatMoney(money).." in the bank of "..getTeamName(faction).."."
			end
		else
			return false, "You must be leader of "..getTeamName(faction).." to place a supplies order for this business."
		end
	end

	-- if player owned
	if is_admin or owner == tonumber(getElementData(player, 'dbid')) or exports.global:hasItem(player,4, dim) or exports.global:hasItem(player,5, dim) then
		local hasFunds
		if useBank then
			hasFunds = exports.bank:hasBankMoney(player, money)
		else
			hasFunds = exports.global:hasMoney(player, money)
		end
		if is_admin or hasFunds then
			return true, useBank and player or nil
		else
			return false, "You don't have $"..exports.global:formatMoney(money).."."
		end
	else
		return false, "You must be the owner of this property or posses a pair of keys to be able to order more supplies."
	end
end

function remoteOrderSupplies(thePlayer, supplies, money, isAdmin, stockOnly)
	stockOnly = stockOnly == true
	-- For client-triggered callers, the event's client is authoritative. Export
	-- callers and command handlers retain their explicit server-side player.
	if client and isElement(client) and getElementType(client) == "player" then
		thePlayer = client
	end
	if not isElement(thePlayer) or getElementType(thePlayer) ~= "player" then
		return false, "Invalid player."
	end
	local admin = isAdmin == true and exports.integration:isPlayerAdmin(thePlayer)
	local amount = tonumber(money)
	if type(supplies) ~= "number" and type(supplies) ~= "table" then
		return false, "Invalid supply amount."
	end
	if type(supplies) == "number" and (supplies <= 0 or supplies ~= supplies or supplies == math.huge) then
		return false, "Invalid supply amount."
	end
	if type(supplies) == "number" then
		amount = math.ceil(supplies * oneSupply)
	end
	if type(supplies) == "table" then
		local hasSupply = false
		for key, value in pairs(supplies) do
			local quantity = tonumber(value)
			if type(key) ~= "string" or not quantity or quantity < 0 or quantity % 1 ~= 0 or quantity ~= quantity or quantity == math.huge then
				return false, "Invalid supply amount."
			end
			if quantity > 0 then hasSupply = true end
		end
		if (not hasSupply and not stockOnly) or (hasSupply and stockOnly) then
			return false, "Invalid supply amount."
		end
	end
	local authorized, payerOrReason = canOrderSupplies(thePlayer, admin, amount, type(supplies) == "table")
	if not authorized then return false, payerOrReason end
	local payer = payerOrReason
	if payer == nil then payer = true end -- true means the player wallet
	if payer ~= true and payer ~= false and not isElement(payer) then return false, "Invalid business payer." end

	local x, y, z, name
	if not stockOnly then
		-- Find the closest interior on world map for a driver delivery.
		local safeCount = 0 -- To prevent freezing server in the worst case.
		x, y, z, name = findRootInteriorMarker(getElementDimension(thePlayer))
		while not x do
			x, y, z, name = findRootInteriorMarker(y)
			safeCount = safeCount + 1
			if safeCount >= 100 then
				break
			end
		end

		if not x then
			return false, "Your interior has no entrance from world map. Therefore, RS Haul Driver will not be able to reach here. Hit F1 for assistance."
		end
	end

	-- Confirm funds above before creating the delivery order. If the order
	-- cannot be recorded after payment, refund the same server-derived payer.
	local charged = false
	if payer == true then
		charged = exports.global:takeMoney(thePlayer, amount)
	elseif payer ~= false then
		charged = exports.bank:takeBankMoney(payer, amount)
	else
		charged = true -- administrator order
	end
	if not charged then return false, "The selected payer no longer has enough money." end
	if stockOnly then
		return true, "Shop stock payment completed."
	end
	local done, why = addOrder(getElementDimension(thePlayer), supplies, x, y, z, name)
	if done then
		if admin then
			exports["interior-manager"]:addInteriorLogs(getElementDimension(thePlayer), "aordersupplies ~ $"..money, thePlayer)
		else
			local gender = getElementData(thePlayer, 'gender')
			local customerName = exports.global:getPlayerName(thePlayer)
			notifyTruckers("RS Haul Operator: "..(gender == 0 and "Mr. " or "Mrs. ")..customerName.." ordered supplies to "..name..". Deliver them as soon as you can please.", true)
			if isElement(payer) and getElementType(payer) == "team" then
				exports.bank:addBankTransactionLog(-getElementData(payer, 'id'), 0, amount, 15, "RS Haul order for "..name.." ("..customerName..")", "RS Haul")
			end
			exports["interior-manager"]:addInteriorLogs(getElementDimension(thePlayer), "ordersupplies ~ $"..amount, thePlayer)
		end
		return true, "Half of your order has been sent to the RS Haul delivery drivers."
	else
		if payer == true then
			exports.global:giveMoney(thePlayer, amount)
		elseif payer ~= false then
			exports.bank:giveBankMoney(payer, amount)
		end
		return false, why
	end
end
