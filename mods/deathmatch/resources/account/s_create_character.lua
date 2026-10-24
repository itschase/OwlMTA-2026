local mysql = exports.mysql

local function characterCreationReject(player, errorCode, reason)
	local accountID = player and getElementData(player, "account:id") or "unknown"
	outputDebugString("[ACCOUNT][CHARACTER_CREATE] rejected account=" .. tostring(accountID) .. " reason=" .. tostring(reason), 2)
	if player and isElement(player) then
		triggerClientEvent(player, "accounts:characters:new", player, 1, errorCode or 1)
	end
	return false
end

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function newCharacter_create(characterName, characterDescription, race, gender, skin, height, weight, age, languageselected, month, day, location)
	if not client or not isElement(client) or getElementType(client) ~= "player" then
		return characterCreationReject(nil, 1, "invalid_event_client")
	end

	local accountID = tonumber(getElementData(client, "account:id"))
	if getElementData(client, "account:loggedin") ~= true or not accountID or accountID < 1 then
		return characterCreationReject(client, 10, "account_not_authenticated")
	end
	if (tonumber(getElementData(client, "dbid")) or 0) > 0 then
		return characterCreationReject(client, 10, "character_already_active")
	end

	if type(characterName) ~= "string" or not checkValidCharacterName(characterName) then
		return characterCreationReject(client, 1, "invalid_character_name")
	end

	race, gender, skin = tonumber(race), tonumber(gender), tonumber(skin)
	height, weight, age = tonumber(height), tonumber(weight), tonumber(age)
	languageselected, month, day = tonumber(languageselected), tonumber(month) or 1, tonumber(day) or 1
	if not isFiniteNumber(race) or race % 1 ~= 0 or race < 0 or race > 2 then
		return characterCreationReject(client, 2, "invalid_race")
	end
	if not isFiniteNumber(gender) or (gender ~= 0 and gender ~= 1) then
		return characterCreationReject(client, 3, "invalid_gender")
	end
	if not isFiniteNumber(skin) or skin % 1 ~= 0 or skin < 0 or skin > 312 then
		return characterCreationReject(client, 4, "invalid_skin")
	end
	if not isFiniteNumber(height) or height <= 149 or height >= 201 then
		return characterCreationReject(client, 5, "invalid_height")
	end
	if not isFiniteNumber(weight) or weight <= 49 or weight >= 200 then
		return characterCreationReject(client, 6, "invalid_weight")
	end
	if not isFiniteNumber(age) or age % 1 ~= 0 or age <= 15 or age >= 101 then
		return characterCreationReject(client, 7, "invalid_age")
	end
	local languageCount = tonumber(exports["language-system"]:getLanguageCount()) or 0
	if not isFiniteNumber(languageselected) or languageselected % 1 ~= 0 or languageselected < 1 or languageselected > languageCount then
		return characterCreationReject(client, 8, "invalid_language")
	end
	local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
	if not isFiniteNumber(month) or month % 1 ~= 0 or month < 1 or month > 12 or not isFiniteNumber(day) or day % 1 ~= 0 or day < 1 then
		return characterCreationReject(client, 9, "invalid_birth_date")
	end
	local year = calculateYearBornIn(age, month, day)
	if month == 2 and (year % 400 == 0 or (year % 4 == 0 and year % 100 ~= 0)) then daysInMonth[2] = 29 end
	if day > daysInMonth[month] then
		return characterCreationReject(client, 9, "invalid_birth_date")
	end

	-- The client spawn selector is currently disabled. Ignore its payload and use this server-owned default.
	local spawnX, spawnY, spawnZ = 1168.6484375, -1412.576171875, 13.497941017151
	local spawnRotation, spawnInterior, spawnDimension = 357.72854614258, 0, 0
	local spawnArea = "A bus stop near the mall"

	local quotaQuery = mysql:query("SELECT `max_characters`, (SELECT COUNT(*) FROM `characters` WHERE `account`=" .. accountID .. ") AS `character_count` FROM `account_details` WHERE `account_id`=" .. accountID .. " LIMIT 1")
	if not quotaQuery then
		return characterCreationReject(client, 10, "quota_query_failed")
	end
	local quota = mysql:fetch_assoc(quotaQuery)
	mysql:free_result(quotaQuery)
	local maxCharacters = quota and tonumber(quota.max_characters)
	local characterCount = quota and tonumber(quota.character_count)
	if not maxCharacters or not characterCount then
		return characterCreationReject(client, 10, "account_quota_missing")
	end
	if characterCount >= maxCharacters then
		return characterCreationReject(client, 10, "character_quota_reached")
	end


	characterName = string.gsub(tostring(characterName), " ", "_")

	--[[if #characterDescription < 50 or #characterDescription > 128 then
	triggerClientEvent(client, "accounts:characters:new", client, 1, 9) -- State 1:9: error validating data
		return
	end
	characterDescription = mysql:escape_string(characterDescription)]]

	local mQuery1 = mysql:query("SELECT charactername FROM characters WHERE charactername='" .. mysql:escape_string(characterName) .. "'")
	if not mQuery1 then
		outputDebugString("[ACCOUNT][CHARACTER_CREATE] character_name_query_failed account=" .. accountID, 1)
		return characterCreationReject(client, 10, "character_name_query_failed")
	end
	if (mysql:num_rows(mQuery1)>0) then
		mysql:free_result(mQuery1)
		triggerClientEvent(client, "accounts:characters:new", client, 2, 1) -- State 2:1: Name already in use
		return
	end
	mysql:free_result(mQuery1)

	local dob = string.format("%04d-%02d-%02d", year, month, day)
	local fingerprint = md5(mysql:escape_string(characterName) .. accountID .. race .. gender .. dob)

	local walkingstyle = 128
	if gender == 1 then
		walkingstyle = 129
	end


	local id = mysql:query_insert_free("INSERT INTO `characters` SET `charactername`='" .. mysql:escape_string(characterName).. "', `x`='"..spawnX.."', `y`='"..spawnY.."', `z`='"..spawnZ.."', `rotation`='"..spawnRotation.."', `interior_id`='"..spawnInterior.."', `dimension_id`='"..spawnDimension.."', `lastarea`='"..exports.global:toSQL(spawnArea).."', `gender`='" .. gender .. "', `skincolor`='" .. race .. "', `weight`='" .. weight .. "', `height`='" .. height .. "', `description`='', `account`='" .. accountID .. "', `skin`='" .. skin .. "', `age`='" .. age .. "', `fingerprint`='" .. mysql:escape_string(fingerprint) .. "', `lang1`='" .. languageselected .. "', `lang1skill`='100', `currLang`='1' , `month`='" .. month .. "', `day`='" .. day .. "', `walkingstyle`='" .. walkingstyle .. "', date_of_birth = '" .. mysql:escape_string(dob) .. "'")

	if (id) then --
		outputDebugString("[ACCOUNT][CHARACTER_CREATE] created account=" .. accountID .. " character=" .. tostring(id), 3)
		exports.logs:dbLog("ac"..tostring(accountID), 27, { "ac"..tostring(accountID), "ch" .. id } , "Created" )

		exports.anticheat:changeProtectedElementDataEx(client, "dbid", id, false)
		exports['item-system']:loadItems( client, true )
		exports.global:giveItem( client, 16, skin )
		exports.global:giveItem( client, 17, 1 )
		exports.global:giveItem( client, 262, 1 ) -- Tokens
		exports.global:giveItem( client, 263, 1 )
		-- ID CARD
		exports.global:giveItem( client, 152, characterName..";"..(gender==0 and "Male" or "Female")..";"..exports.global:numberToMonth(month).." "..exports.global:formatDate(day)..", "..year..";"..fingerprint)
		-- Briefcase
		if exports.global:giveItem( client, 160, 1 ) then
			triggerEvent("artifacts:toggle", client, client, "briefcase")
		end

		--Make a new phone and give it to player
		local attempts = 0
		local itemValue = 1
		while true do
			-- generate a larger phone number if we're totally out of numbers and/or too lazy to perform more than 20+ checks.
			attempts = attempts + 1
			itemValue = math.random(311111, attempts < 20 and 899999 or 8999999)

			local mysqlQ = mysql:query("SELECT `phonenumber` FROM `phones` WHERE `phonenumber` = '" .. itemValue .. "'")
			if mysql:num_rows(mysqlQ) == 0 then
				mysql:free_result(mysqlQ)
				break
			end
			mysql:free_result(mysqlQ)
		end
		exports.global:giveItem( client, 2, itemValue )

		exports.anticheat:changeProtectedElementDataEx(client, "dbid")
		triggerClientEvent(client, "accounts:characters:new", client, 3, tonumber(id)) -- State 3:<var>: Spic win!
	else
		outputDebugString("[ACCOUNT][CHARACTER_CREATE] database_insert_failed account=" .. accountID, 1)
		triggerClientEvent(client, "accounts:characters:new", client, 2, 2) -- State 2:2: Failed to update database
	end
end
addEventHandler("accounts:characters:new", getRootElement(), newCharacter_create)

function charactersQuotaCheck()
	local id = getElementData(client, 'account:id')
	dbQuery( function(qh, client)
		local res = dbPoll(qh, 0)
		if res and #res==1 then
			local ok = res[1].cap > res[1].cur
			triggerClientEvent( client, 'account:charactersQuotaCheck', resourceRoot, ok, ok and ("Quota: "..res[1].cur.."/"..res[1].cap) or ("You reached "..res[1].cur.."/"..res[1].cap.." characters.\nTo create more, make a report to admins with a proper reason or use Premium Feature.") )
		else
			triggerClientEvent( client, 'account:charactersQuotaCheck', resourceRoot, false, "Errors occurred while checking characters quota." )
		end
	end, { client }, exports.mysql:getConn('mta'), "SELECT COUNT(id) AS cur, (SELECT max_characters FROM account_details WHERE account_details.account_id=?) AS cap FROM characters WHERE account=?", id, id )
end
addEvent('account:charactersQuotaCheck', true)
addEventHandler('account:charactersQuotaCheck', resourceRoot, charactersQuotaCheck)

function calculateYearBornIn(age, month, day)
	local currentTime = getRealTime()
	local currentYear, currentMonth, currentDay = currentTime.year + 1900, currentTime.month + 1, currentTime.monthday
	local year = currentYear - age
	if month > currentMonth or (month == currentMonth and day > currentDay) then
		year = year - 1
	end
	return year
end
