--CUSTOM SHOP / MAXIME

local mysql = exports.mysql

local warningDebtAmount, limitDebtAmount, wageRate = nil
settings = {}
function fetchSettings()
	settings.warningDebtAmount = tonumber(get( "warningDebtAmount" )) or 500
	settings.limitDebtAmount = tonumber(get( "limitDebtAmount" )) or 1000
	settings.wageRate = tonumber(get( "wageRate" )) or 5
end
addEventHandler("onResourceStart", resourceRoot, fetchSettings)

function requestSettings()
	triggerClientEvent(root, 'npc:receiveServerSettings', resourceRoot, settings)
end
addEvent('npc:requestSettings', true)
addEventHandler('npc:requestSettings', root, requestSettings)

addEvent("shop:saveContactInfo", true)
function saveContactInfo(shopElement, contactInfo)
	local npcID = getElementData(shopElement,"dbid")
	local sucessfullyUpdateToSQL = false
	if mysql:query_fetch_assoc("SELECT `npcID` FROM `shop_contacts_info` WHERE `npcID` = '"..tostring(npcID).."'") then
		if mysql:query_free("UPDATE `shop_contacts_info` SET `sOwner`='"..tostring(contactInfo[1]):gsub("'","''").."', `sPhone`='"..tostring(contactInfo[2]):gsub("'","''").."', `sEmail`='"..tostring(contactInfo[3]):gsub("'","''").."', `sForum`='"..tostring(contactInfo[4]):gsub("'","''").."' WHERE `npcID`='"..tostring(npcID).."'") then
			sucessfullyUpdateToSQL = true
		end
	else
		if mysql:query_free("INSERT INTO `shop_contacts_info` SET `sOwner`='"..tostring(contactInfo[1]):gsub("'","''").."', `sPhone`='"..tostring(contactInfo[2]):gsub("'","''").."', `sEmail`='"..tostring(contactInfo[3]):gsub("'","''").."', `sForum`='"..tostring(contactInfo[4]):gsub("'","''").."', `npcID`='"..tostring(npcID).."'") then
			sucessfullyUpdateToSQL = true
		end
	end
	if sucessfullyUpdateToSQL then
		setElementData(shopElement, "sContactInfo", contactInfo, true)
	end
	--outputDebugString(tostring(sucessfullyUpdateToSQL).. tostring(contactInfo[2]):gsub("'","''"))
	return sucessfullyUpdateToSQL
end
addEventHandler("shop:saveContactInfo", getRootElement(), saveContactInfo)


addEvent("shop:addItemToCustomShop", true)
function addItemToCustomShop(element, slot, event, worldItem)
	local id, itemID, itemValue, item = nil

	if slot ~= -1 then
		itemdata = exports['item-system']:getItems( source )[ slot ]
		itemID = itemdata[1]
		itemValue = itemdata[2]
		itemMetadata = itemdata[5]
		item = {}
		item['id'] = itemID
		item['value'] = itemValue
		item['metadata'] = itemMetadata
	elseif worldItem then
		item = {}
		id = getElementData( worldItem, "id" )
		itemID = getElementData( worldItem, "itemID" )
		item['id'] = itemID
		itemValue = getElementData( worldItem, "itemValue" )
		item['value'] = itemValue
		itemMetadata = getElementData( worldItem, "metadata" )
		item['metadata'] = itemMetadata
	else
		triggerClientEvent( source, event or "finishItemMove", source )
		return false
	end

	local dbid = getElementDimension(element)

	if exports.global:hasItem(source, 4, dbid) or exports.global:hasItem(source, 5, dbid) then
		if element then
			local npcID = getElementData(element, "dbid") or false
			triggerClientEvent( source, "shop:addItemToShop", source, source, item, slot, worldItem, npcID, element )
			triggerClientEvent( source, event or "finishItemMove", source )
			return true
		end
		outputChatBox("You must have key to be able to restock.",source, 255,0,0)
		return false
	end

	triggerClientEvent( source, event or "finishItemMove", source )
	return false
end
addEventHandler("shop:addItemToCustomShop", getRootElement(), addItemToCustomShop)

function updateItemToShop(source, item, price, desc, npcID, slot, worldItem, shopElement)
	setElementData(source, "shop:NoAccess", true, true )

	local pedName = getPedName(shopElement)

	local playerName = getPlayerName(source):gsub("_", " ")

	if tonumber(getElementData(shopElement, "sIncome")) < tonumber(getElementData(shopElement, "sPendingWage")) then
		storeKeeperSay(source, "What about my wage??", pedName)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return false
	end

	local allowedWeapons = {
	[15] = true, -- Cane
	[14] = true, -- Flowers
	[2] = true, -- Golf Club
	[5] = true, -- Bat
	[10] = true, -- Dildo
	[11] = true, -- Dildo
	[12] = true, -- Vibrator
	[13] = true, -- Vibrator
	}

	-- ban all weapons except the above, ban all kinds of ammo.
	if item['id'] == 116 or ( item['id'] == 115 and not allowedWeapons[tonumber( split( item['value'], ":")[1] )] ) then
		storeKeeperSay(source, "Holyshit! We're not allowed to sell this!", pedName)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return false
	end

	if item['id'] == 3 or item['id'] == 4 or item['id'] == 5 then --Keys , to prevent alt->alt
		exports.global:sendLocalText(source, "* "..pedName.." laughs at "..playerName..".", 255, 51, 102, 30, {}, true)
		storeKeeperSay(source, "Haha, do you really think people would buy a crappy key?", pedName)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return false
	end

	local itemName = exports["item-system"]:getItemName(item['id'], item['value'], item['metadata'])
	if tonumber(price) < 0 then
		exports.global:sendLocalText(source, "* "..pedName.." doesn't agree with "..playerName.." on the price of a "..itemName..".", 255, 51, 102, 30, {}, true)
		storeKeeperSay(source, "One does not simply sell a thing for a negative price, yea?", pedName)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return false
	end
	local meta = null
	if type(item['metadata']) == 'table' then
		meta = toJSON(item['metadata'])
		if type(meta) ~= 'string' then
			meta = null
		else
			meta = "'" .. exports.mysql:escape_string(meta) .. "'"
		end
	end


	local addToShop = mysql:query_free("INSERT INTO `shop_products` SET `pItemID`='"..tostring(item['id']).."', `pItemValue`='"..tostring(item['value']):gsub("'","''").."', `pMetadata`="..(meta or 'NULL')..", `npcID`='"..tostring(npcID).."', `pPrice`='"..tostring(price).."', `pDesc`='"..tostring(desc):gsub("'","''").."' ") or false
	if addToShop then
		if slot == -1 and worldItem and isElement(worldItem) then
			local id = getElementData( worldItem, "id" )
			mysql:query_free("DELETE FROM `worlditems` WHERE `id`='" .. id .. "'")
			destroyElement(worldItem)
		else
			exports['item-system']:takeItemFromSlot( source, slot )
		end
		exports.logs:dbLog(source, 39, source, getPlayerName( source ) .. "-> PED: " .. pedName .. " - #" .. tostring(item['id']) .. " - " .. itemName .. " - " ..  tostring(item['value']))
		triggerEvent('sendAme', source, "hands "..pedName.." a "..itemName..".")
		local playerGender = getElementData(source,"gender")
		if playerGender == 0 then
			storeKeeperSay(source, "Alright, I got it, sir.", pedName)
		else
			storeKeeperSay(source, "Alright, I got it, ma'am.", pedName)
		end
		setElementData(source, "shop:NoAccess", false, true )
		local currentCap = tonumber(getElementData(shopElement, "currentCap")) + 1
		setElementData(shopElement, "currentCap", currentCap, true)
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return true
	end
end
addEvent("shop:updateItemToShop", true )
addEventHandler("shop:updateItemToShop", getRootElement(), updateItemToShop)

function editItemToShop(source, price, desc, proID, itemName, shopElement)
	setElementData(source, "shop:NoAccess", true, true )

	local pedName = getPedName(shopElement)
	local playerName = getPlayerName(source):gsub("_", " ")

	if tonumber(getElementData(shopElement, "sIncome")) < tonumber(getElementData(shopElement, "sPendingWage")) then
		storeKeeperSay(source, "What about my wage??", pedName)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return false
	end

	if tonumber(price) < 0 then
		exports.global:sendLocalText(source, "* "..pedName.." doesn't agree with "..playerName.." on the price of a "..itemName..".", 255, 51, 102, 30, {}, true)
		storeKeeperSay(source, "One does not simply sell a thing for a negative price, yea?", pedName)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return false
	end

	local check = mysql:query_fetch_assoc("SELECT `pID` FROM `shop_products` WHERE `pID`='"..tostring(proID).."'") or false
	local checkingItem = false
	if check then
		checkingItem = check["pID"]
	end
	if checkingItem then
		local addToShop = mysql:query_free("UPDATE `shop_products` SET `pPrice`='"..tostring(price).."', `pDesc`='"..tostring(desc):gsub("'","''").."' WHERE `pID`='"..checkingItem.."'") or false
		if addToShop then
			triggerEvent("sendAme", source, "discusses with "..pedName.." about a "..itemName..".")
			storeKeeperSay(source, "Sure..sure..", pedName)
			setElementData(source, "shop:NoAccess", false, true )
			triggerClientEvent(source, "hideGeneralshopUI", source)
		end
	else
		outputChatBox(" "..itemName.." is not existed in the store anymore.", source, 255,0, 0)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
	end
end
addEvent("shop:EditItemToShop", true )
addEventHandler("shop:EditItemToShop", getRootElement(), editItemToShop)

function takeOffProductFromShop(source, proID, itemI, itemV, itemName, shopElement, metadata)
	itemI = tonumber(itemI)
	itemV = tostring(itemV)
	setElementData(source, "shop:NoAccess", true, true )

	local pedName = getPedName(shopElement)
	local playerName = getPlayerName(source):gsub("_", " ")

	if tonumber(getElementData(shopElement, "sIncome")) < tonumber(getElementData(shopElement, "sPendingWage")) then
		storeKeeperSay(source, "What about my wage??", pedName)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
		return false
	end


	if itemI == 115 or itemI == 116 then --weapons and ammo
		if getElementData( source, "license.gun" ) ~= 1 then
			storeKeeperSay(source, "Nah, sorry. I can't give you this unless you show me the license..", pedName)
			setElementData(source, "shop:NoAccess", false, true )
			triggerClientEvent(source, "hideGeneralshopUI", source)
			return false
		end
	end



	local check = mysql:query_fetch_assoc("SELECT `pID` FROM `shop_products` WHERE `pID`='"..tostring(proID).."'") or false
	local checkingItem = false
	if check then
		checkingItem = check["pID"]
	end
	if checkingItem then
		local success, reason = exports["item-system"]:giveItem( source, itemI, itemV, false, false, metadata )
		if success then
			exports.global:sendLocalText(source, "* "..playerName.." takes a "..itemName.." from "..pedName..".", 255, 51, 102, 30, {}, true)
			local playerGender = getElementData(source,"gender")
			if playerGender == 0 then
				storeKeeperSay(source, "There ya go, sir.", pedName)
			else
				storeKeeperSay(source, "There ya go, ma'am.", pedName)
			end
		else
			outputChatBox(reason,source, 255, 0, 0)
			setElementData(source, "shop:NoAccess", false, true )
			triggerClientEvent(source, "hideGeneralshopUI", source)
			return false
		end
		exports.logs:dbLog(source, 39, source, getPlayerName( source ) .. "<- PED: " .. pedName .. " - " .. itemName .. " - " ..  itemV)

		local addToShop = mysql:query_free("DELETE FROM `shop_products` WHERE `pID`='"..tostring(proID).."'") or false
		if addToShop then

			setElementData(shopElement, "currentCap", tonumber(getElementData(shopElement, "currentCap")) - 1, true)

			setElementData(source, "shop:NoAccess", false, true )
			triggerClientEvent(source, "hideGeneralshopUI", source)
		end
	else
		outputChatBox(" "..itemName.." is not existed in the store anymore.", source, 255,0, 0)
		setElementData(source, "shop:NoAccess", false, true )
		triggerClientEvent(source, "hideGeneralshopUI", source)
	end
end
addEvent("shop:takeOffProductFromShop", true )
addEventHandler("shop:takeOffProductFromShop", getRootElement(), takeOffProductFromShop)

function customShopBuy(proID, itemI, itemV, itemPrice, itemName, payByBank, shopElement, metadata)
	local player = client
	local productID = tonumber(proID)
	if not isElement(player) or not productID or productID < 1 or not tonumber(getElementData(player, "dbid")) then return false end
	local function finish(message)
		setElementData(player, "shop:NoAccess", false, true)
		if message then outputChatBox(message, player, 255, 0, 0) end
		triggerClientEvent(player, "hideGeneralshopUI", player)
		return false
	end
	if not isElement(shopElement) or getElementType(shopElement) ~= "ped"
		or not getElementData(shopElement, "customshop")
		or getElementData(shopElement, "ped:type") ~= "shop"
		or tonumber(getElementData(shopElement, "shoptype")) ~= 17 then
		return finish("This shop is unavailable.")
	end
	local px, py, pz = getElementPosition(player)
	local sx, sy, sz = getElementPosition(shopElement)
	if getElementInterior(player) ~= getElementInterior(shopElement)
		or getElementDimension(player) ~= getElementDimension(shopElement)
		or getDistanceBetweenPoints3D(px, py, pz, sx, sy, sz) > 7 then
		return finish("You must be near the shop to purchase this item.")
	end
	setElementData(player, "shop:NoAccess", true, true)
	local shopID = tonumber(getElementData(shopElement, "dbid"))
	local productIDString = tostring(math.floor(productID))
	local product = shopID and mysql:query_fetch_assoc("SELECT pID,npcID,pItemID,pItemValue,pMetadata,pPrice,pDesc,pQuantity,pSetQuantity,pRestockInterval FROM shop_products WHERE pID='"..productIDString.."' AND npcID='"..tostring(shopID).."' LIMIT 1") or false
	if not product or (tonumber(product.pQuantity) or 0) < 1 then return finish("That product is no longer available.") end
	itemI = tonumber(product.pItemID)
	itemV = tostring(product.pItemValue or "")
	itemPrice = tonumber(product.pPrice)
	metadata = {}
	if product.pMetadata and product.pMetadata ~= mysql_null() then metadata = fromJSON(product.pMetadata) or {} end
	if not itemI or not itemPrice or itemPrice < 0 then return finish("That product is no longer available.") end
	itemName = exports["item-system"]:getItemName(itemI, itemV, metadata) or ("item #" .. tostring(itemI))
	local pedName = getPedName(shopElement)
	if (itemI == 115 or itemI == 116) and getElementData(player, "license.gun") ~= 1 then
		storeKeeperSay(player, "Nah, sorry. I can't sell you this unless you can show me the license..", pedName)
		return finish()
	end
	-- Reserve this one item before delivery so stale/replayed requests cannot buy it twice.
	if not mysql:query_free("DELETE FROM shop_products WHERE pID='"..productIDString.."' AND npcID='"..tostring(shopID).."' AND pQuantity > 0 LIMIT 1") then
		return finish("That product is no longer available.")
	end
	local function restoreProduct()
		local metaSQL = "NULL"
		if type(metadata) == "table" and next(metadata) then
			local encoded = toJSON(metadata)
			if type(encoded) == "string" then metaSQL = "'"..exports.mysql:escape_string(encoded).."'" end
		end
		local restored = mysql:query_free("INSERT INTO shop_products (npcID,pItemID,pItemValue,pMetadata,pPrice,pDesc,pQuantity,pSetQuantity,pRestockInterval) VALUES ('"..
			tostring(shopID).."','"..tostring(itemI).."','"..itemV:gsub("'","''").."',"..metaSQL..",'"..tostring(itemPrice).."','"..
			tostring(product.pDesc or ""):gsub("'","''").."','"..tostring(product.pQuantity).."','"..tostring(product.pSetQuantity or product.pQuantity).."','"..tostring(product.pRestockInterval or 0).."')")
		if not restored then outputDebugString("[npc/custom-shop] Failed to restore reserved product "..productIDString.." for shop "..tostring(shopID), 1) end
		return restored
	end
	local success, reason = exports["item-system"]:giveItem(player, itemI, itemV, false, false, metadata)
	if not success then
		restoreProduct()
		outputChatBox(reason, player, 255, 0, 0)
		return finish()
	end
	local paid
	playBuySound(shopElement)
	if payByBank then paid = exports.bank:takeBankMoney(player, itemPrice)
	else paid = exports.global:takeMoney(player, itemPrice) end
	if not paid then
		exports.global:takeItem(player, itemI, itemV)
		restoreProduct()
		storeKeeperSay(player, "Well, I'm sorry but this seems not enough..", pedName)
		return finish()
	end
	local now = getRealTime()
	local stamp = ("%02d/%02d/%04d %02d:%02d"):format(now.monthday, now.month + 1, now.year + 1900, now.hour, now.minute)
	local playerName = getPlayerName(player):gsub("_", " ")
	local payment = payByBank and "(Debit Card) " or ""
	local logString = "- "..stamp.." : "..payment..playerName.." bought a "..itemName.." for $"..exports.global:formatMoney(itemPrice)..".\n"
	logString = string.sub(logString..(getElementData(shopElement, "sSales") or ""), 1, 5000)
	setElementData(shopElement, "sSales", logString, true)
	if payByBank then
		exports.bank:addBankTransactionLog(getElementData(player, "dbid"), nil, itemPrice, 0, "Purchase", "Purchased "..itemName.." for "..itemPrice.."$ from "..tostring(getElementData(shopElement, "name")), nil, nil)
	end
	local income = tonumber(getElementData(shopElement, "sIncome")) or 0
	if mysql:query_free("UPDATE shops SET sIncome=sIncome+'"..tostring(itemPrice).."', sSales='"..logString:gsub("'","''").."' WHERE id='"..tostring(shopID).."'") then
		exports.anticheat:setEld(shopElement, "sIncome", income + itemPrice, "all")
	else
		outputDebugString("[npc/custom-shop] Product "..productIDString.." delivered but shop income update failed for shop "..tostring(shopID), 1)
	end
	setElementData(shopElement, "currentCap", math.max(0, (tonumber(getElementData(shopElement, "currentCap")) or 1) - 1), true)
	triggerEvent("sendAme", shopElement, "gave "..playerName.." a "..itemName..(payByBank and " and returns the debit card" or "")..".")
	storeKeeperSay(player, "Here you are. Thank you, have a nice day!", pedName)
	finish()
end

addEvent("shop:customShopBuy", true )
addEventHandler("shop:customShopBuy", getRootElement(), customShopBuy)

function expandBiz(shopID, capacity)
	mysql:query_free("UPDATE `shops` SET `sCapacity`='"..tostring(capacity).."' WHERE `id`='"..tostring(shopID).."'")
end
addEvent("shop:expand", true )
addEventHandler("shop:expand", getRootElement(), expandBiz)

function storeKeeperSay(thePlayer, content, pedName)
	local languageslot = getElementData(thePlayer, "languages.current") or 1
	local language = getElementData(thePlayer, "languages.lang" .. languageslot)
	local languagename = call(getResourceFromName("language-system"), "getLanguageName", language)
	pedName = string.gsub(pedName, "_" , " ")
	if languagename == "<Invalid/Bugged Language>" then
		outputDebugString("LANGUAGE " .. tostring(languageslot) .. " " .. tostring(language) )
	end
	exports.global:sendLocalText(thePlayer, "["..(languagename or 'English').."] "..tostring(pedName).." says: "..content, 255, 255, 255, 30, {}, true)
end
addEvent("shop:storeKeeperSay", true )
addEventHandler("shop:storeKeeperSay", getRootElement(), storeKeeperSay)

function updateSaleLogs(thePlayer, shopID, content)
	--outputDebugString(shopID.."-"..content)
	content = string.sub(content, 1, 5000)
	local update = mysql:query_free("UPDATE `shops` SET `sSales`='"..tostring(content).."' WHERE `id`='"..tostring(shopID).."' ") or false
	if update and thePlayer then
		outputChatBox("Updated SaleLogs.", thePlayer, 0, 255,0)
	end
end
addEvent("shop:updateSaleLogs", true )
addEventHandler("shop:updateSaleLogs", getRootElement(), updateSaleLogs)

function notifyAllShopOwners(shopElement, content)
	local maxDebt = exports.global:formatMoney(settings.limitDebtAmount)
	local warningDebt = exports.global:formatMoney(settings.warningDebtAmount)
	local contentList = {
		{	-- 1. Ask for money when debt exceeds $1500
			"Hey boss, You owe me at least $"..warningDebt.." now, wanna pay me or not..?",
			"Well, I don't want to be a dick but you owe me at least $"..warningDebt.." now..",
			"Come here and solve the fucking wage.. You owe me at least $"..warningDebt.." now.",
			"If you don't come and solve my damn wage, I'll quit..",
			"Boss! solve my wage now!!!",
		},
		{ 	-- 2. Quit
			"Hey boss, I quit my job, have fun with your empty shop..",
			"Bye bye boss, and sorry for your empty shop.. LOL",
			"I quit my job and you still owe me the fucking $"..maxDebt.."..",
			"Hey son of a bitch, you owe me fucking $"..maxDebt.." and don't wanna pay?? Say goodbye to your stuff then..",
			"Hi boss, I'm sorry that I have to quit my job, your business is just not profitable..",
		},
	}
	local contentTemp = nil
	if tonumber(content) then
		contentTemp = tonumber(content)
		content = contentList[content][math.random( 1, 5 )]
		if contentTemp == 0 then -- Temporarily disabled / MAXIME
			shopLeaveNoteOnLeave(shopElement, content)
		end
	end

	local pedName = getPedName(shopElement)
	setTimer(function()
		--exports.global:sendLocalText(shopElement, "*"..pedName.." takes out a cellphone and starts sending text messages.", 255, 51, 102, 30, {}, true)

		local possibleOwners = getElementsByType("player")
		--local number = {"545683", "234233", "887563", "686831", "222323", "777887", "999870", "434666", "109583", "667233"}
		local effectedPlayers = 0
		for _, owner in ipairs(possibleOwners) do
			local bizKey = getElementDimension(shopElement)
			local isBizOwner, bizName = isBizOwner(owner, bizKey)
			if isBizOwner then
				if exports.global:hasItem(owner, 2) then
					local languageslot = getElementData(owner, "languages.current") or 1
					local language = getElementData(owner, "languages.lang" .. languageslot)
					local languagename = call(getResourceFromName("language-system"), "getLanguageName", language)
					local ownerName = getPlayerName(owner):gsub("_", " ")

					exports.global:sendLocalText(owner, "*"..ownerName.." receives a text message.", 255, 51, 102, 30, {}, true)

					outputChatBox("["..languagename.."] SMS from "..pedName.." at "..bizName..": "..content, owner, 120, 255, 80)
					effectedPlayers = effectedPlayers + 1
				end
			end
		end
		if effectedPlayers == 0 then
			local r = getRealTime()
			local timeString = ("%02d/%02d/%04d %02d:%02d"):format(r.monthday, r.month + 1, r.year+1900, r.hour, r.minute)

			logString = "- "..timeString.." : "..content.." ("..pedName..")\n"
			local previousSales = getElementData(shopElement, "sSales") or ""
			logString = logString..previousSales
			logString = string.sub(logString, 1, 5000)
			setElementData(shopElement, "sSales", logString, true)
			mysql:query_free("UPDATE `shops` SET `sSales` = '"..logString:gsub("'","''").."' WHERE `id` = '"..tostring(getElementData(shopElement,"dbid")).."'")
		end
	end, 2000, 1)
end
addEvent("shop:notifyAllShopOwners", true )
addEventHandler("shop:notifyAllShopOwners", getRootElement(), notifyAllShopOwners)

function isBizOwner(player, bizKey)
	local key = bizKey
	local possibleInteriors = getElementsByType("interior")
	local isOwner = false
	local interiorName = false
	for _, interior in ipairs(possibleInteriors) do
		if tonumber(key) == getElementData(interior, "dbid") then
			interiorName = getElementData(interior, "name") or ""
			local status = getElementData(interior, "status")
			interiorSupplies = status.supplies or 0
			if status.type ~= 2 then
				if status.owner == getElementData(player, "dbid") then
					isOwner = true
					break
				end
			end
		end
	end
	if not interiorName then
		return false, false
	end
	return isOwner, interiorName
end

function resetPendingWage(thePlayer)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		local adminUsername = getElementData(thePlayer, "account:username")
		local hiddenAdmin = getElementData(thePlayer, "hiddenadmin")
		local adminTitle = exports.global:getPlayerAdminTitle(thePlayer)

		outputDebugString("BIZ-SYSTEM SETTINGS: wageRate="..settings.wageRate..", limitDebtAmount="..settings.limitDebtAmount..", warningDebtAmount="..settings.warningDebtAmount.."")
		outputChatBox("BIZ-SYSTEM SETTINGS: wageRate="..settings.wageRate..", limitDebtAmount="..settings.limitDebtAmount..", warningDebtAmount="..settings.warningDebtAmount.."", thePlayer)
		outputDebugString("------------START RESETING SHOP WAGES------------")
		outputChatBox("------------START RESETING SHOP WAGES------------", thePlayer)
		local count = 0
		local possibleShops = getElementsByType("ped")
		for _, shop in ipairs(possibleShops) do
			if getElementData(shop, "customshop") then
				local shopID = getElementData(shop, "dbid") or false
				if shopID then
					local sPendingWage = tonumber(getElementData(shop, "sPendingWage")) or 0
					local update = mysql:query_free("UPDATE `shops` SET `sPendingWage`='0' WHERE `id`='"..tostring(shopID).."' ") or false
					if update then
						outputDebugString("Shop ID#"..shopID.." Reset Staff Wage "..sPendingWage.." -> 0")
						outputChatBox("Shop ID#"..shopID.." Reset Staff Wage "..sPendingWage.." -> 0", thePlayer)
						if hiddenAdmin == 0 then
							notifyAllShopOwners(shop, "(("..adminTitle.." "..adminUsername.." has reset this shop's wage to $0.))")
						else
							notifyAllShopOwners(shop, "((A hidden admin has reset this shop's wage to $0.))")
						end
						count = count + 1
						exports.anticheat:setEld(shop, "sPendingWage", 0, 'all')
					else
						outputDebugString("Shop ID#"..shopID.." Reset Staff Wage Failed.")
						outputChatBox("Shop ID#"..shopID.." Reset Staff Wage Failed.", thePlayer)
					end
				end
			end
		end
		outputDebugString("------------RESET "..count.." SHOP WAGES------------")
		outputChatBox("------------RESET "..count.." SHOP WAGES------------", thePlayer)

		if hiddenAdmin == 0 then
			exports.global:sendMessageToAdmins("[BIZ-SYSTEM]: "..adminTitle.." ".. getPlayerName(thePlayer):gsub("_", " ").. " ("..adminUsername..") has reset "..count.." custom shop wages to $0.")
		else
			exports.global:sendMessageToAdmins("[BIZ-SYSTEM]: A hidden admin has reset "..count.." custom shop wages to $0.")
		end
	end
end
addCommandHandler("resetshopwage", resetPendingWage)

function shopLeaveNoteOnLeave(shopElement, content)
	local itemID = 72 -- note
	local itemValue = content
	local x, y, z = getElementPosition(shopElement)
	local dimension = getElementDimension(shopElement)
	local interior = getElementInterior(shopElement)
	local rz2 = -1
	local creator = 14652 -- The Storekeeper
	local protected = 0
	local modelid = exports['item-system']:getItemModel(itemID, itemValue)
	local rx, ry, rz, zoffset = exports['item-system']:getItemRotInfo(itemID)
	local id = SmallestID()
	local insert = mysql:query_free("INSERT INTO `worlditems` SET `id` = '"..tostring(id).."', `itemid`='"..tostring(itemID).."',`itemvalue`='"..tostring(itemValue):gsub("'","''").."', `x`='"..tostring(x).."', `y`='"..tostring(y).."', `z`='"..tostring(z).."', `dimension`='"..tostring(dimension).."', `interior`='"..tostring(interior).."', `rz`='"..tostring(rz2).."', `creator`='"..tostring(creator).."' ") or false

	if insert then
		local obj = exports["item-world"]:createItem(id, itemID, itemValue, modelid, x, y, z + ( zoffset or 0 ), rx, ry, rz+rz2)
		exports.pool:allocateElement(obj)
		setElementDimension(obj, dimension)
		setElementInterior(obj, interior)
		setElementData(obj, "creator", creator, false)
	end
end

function showCustomShopStatus(thePlayer)
	outputDebugString("BIZ-SYSTEM SETTINGS: wageRate="..settings.wageRate..", limitDebtAmount="..settings.limitDebtAmount..", warningDebtAmount="..settings.warningDebtAmount.."")
	outputDebugString("------------START------------")
	if thePlayer then
		outputChatBox("BIZ-SYSTEM SETTINGS: wageRate="..settings.wageRate..", limitDebtAmount="..settings.limitDebtAmount..", warningDebtAmount="..settings.warningDebtAmount.."", thePlayer)
		outputChatBox("------------START------------", thePlayer)
	end
	local count = 0
	local possibleShops = getElementsByType("ped", resourceRoot)
	for _, shop in ipairs(possibleShops) do
		if getElementData(shop, "customshop") then
			local shopID = getElementData(shop, "dbid") or false
			if shopID then
				local sCapacity = tonumber(getElementData(shop, "sCapacity")) or 0
				local sPendingWage = tonumber(getElementData(shop, "sPendingWage")) or 0
				local sNewPendingWage = math.floor((sCapacity/wageRate)) + sPendingWage
				local sIncome = tonumber(getElementData(shop, "sIncome")) or 0
				local sProfit = sIncome-sNewPendingWage
				local currentCap = tonumber(getElementData(shop, "currentCap")) or 0

				outputDebugString("CShop ID#"..shopID..": Cap: "..currentCap.."/"..sCapacity..", Income: $"..sIncome..", Wage: $"..sPendingWage.." (->$"..sNewPendingWage.."), Profit: $"..sProfit..".")
				if thePlayer then
					outputChatBox("CShop ID#"..shopID..": Cap: "..currentCap.."/"..sCapacity..", Income: $"..sIncome..", Wage: $"..sPendingWage.." (->$"..sNewPendingWage.."), Profit: $"..sProfit..".", thePlayer)
				end
				count = count + 1
			end
		end
	end
	outputDebugString("------------SHOWED "..count.." CSHOPS------------")
	if thePlayer then
		outputChatBox("------------SHOWED "..count.." CSHOPS------------", thePlayer)
	end
end

function forceShowAllCustomShop(thePlayer)
	if (exports.integration:isPlayerTrialAdmin(thePlayer)) then
		showCustomShopStatus(thePlayer)
	end
end
addCommandHandler("showallcustomshops", forceShowAllCustomShop)
