mysql = exports.mysql

local JFOX_MDC = 532

function string:split(sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end

function getRow(removeid)
    for k,v in pairs(t) do
        if tonumber(removeid) and tonumber(removeid) == tonumber(v[1]) then
            return k
        end
    end
end

local function getPrisonActorAccess(actor)
    if not isElement(actor) or getElementType(actor) ~= "player" or getElementData(actor, "loggedin") ~= 1 then
        return false, false, false
    end
    local admin = exports.integration:isPlayerTrialAdmin(actor) == true
    local duty = tonumber(getElementData(actor, "duty")) or 0
    local law = (exports.factions:isInFactionType(actor, 2) or exports.factions:isPlayerInFaction(actor, 81)) and duty > 0
    local offlineManager = exports.factions:isPlayerInFaction(actor, pd_update_access) and duty > 0
    return true, admin, law == true, offlineManager == true
end

local function prisonMutationAllowed(actor, targetOnline, operation)
    local active, admin, law, offlineManager = getPrisonActorAccess(actor)
    if not active then return false end
    if admin then return true end
	if operation ~= "add" and offlineManager then return true end
	if targetOnline then return law end
    if operation == "add" then return pd_offline_jail == true and law end
    return offlineManager
end

local function findOnlinePrisoner(characterName, charID)
    for _, player in ipairs(exports.pool:getPoolElementsByType("player")) do
        if getElementData(player, "loggedin") == 1 and
            ((charID and tonumber(getElementData(player, "dbid")) == tonumber(charID)) or
            (characterName and string.lower(getPlayerName(player)) == string.lower(characterName))) then
            return player
        end
    end
    return false
end

local function validateSentence(days, hours, allowSpecial)
    if days == "" then days = 0 end
    if allowSpecial and days == "Life" and hours == "Sentence" then
        days, hours = 9999, 999
    elseif allowSpecial and days == "Awaiting" and hours == "Release" then
        days, hours = 0, 0
    end
    days, hours = tonumber(days), tonumber(hours)
    if not days or not hours or days < 0 or hours < 0 or days > 9999 or hours > 999 or days ~= math.floor(days) or hours ~= math.floor(hours) then
        return false
    end
    local totalHours = days * 24 + hours
    if hourLimit > 0 and totalHours > hourLimit then return false end
    return days, hours
end

local function validatePrisonFields(cell, days, hours, charges, fine, allowSpecial)
    if type(cell) ~= "string" or not cells[cell] or type(cells[cell].type) ~= "number" then return false end
    if type(charges) ~= "string" or #charges < 1 or #charges > 500 then return false end
    local validDays, validHours = validateSentence(days, hours, allowSpecial)
    if validDays == false then return false end
    if fine ~= nil then
        fine = tonumber(fine)
        if not fine or fine < 0 or fine > 2147483647 or fine ~= math.floor(fine) then return false end
    end
    return validDays, validHours, fine
end

addEventHandler("onResourceStart", resourceRoot, function()
	local result = mysql:query( "SELECT * FROM jailed ORDER BY id ASC" )
	if result then
			 	t = { }
				while true do
					local row = mysql:fetch_assoc( result )
					if row then
						table.insert(t, { row.id, row.charid, row.charactername, row.jail_time, row.convictionDate, row.updatedBy, row.charges, row.cell, row.fine, row.jail_time_online })
					else
						break
					end
				end
				mysql:free_result( result )
			end
			timeReleaseCheck(true)
			setTimer(timeReleaseCheck, 300000, 0)
		end
	)

addEventHandler("onResourceStop", resourceRoot, function()
    local players = exports.pool:getPoolElementsByType("player")
	for key, value in ipairs(players) do
		if getElementData(value, "loggedin")==1 and getElementData(value, "jailed") then
            dbExec(exports.mysql:getConn("mta"), "UPDATE jailed SET jail_time=?, jail_time_online=? WHERE charid=?", getElementData(value, "jail_time"), getElementData(value, "jail_time_online"), getElementData(value, "dbid"))
        end
    end
end)

function startGUI(player)
	-- Remote open requests may only open the caller's UI; UI access is not mutation authority.
	if client then
		if player and player ~= client then return end
		player = client
	end
	local logged = getElementData(player, "loggedin")
	if (logged==1) then
		if exports.factions:isInFactionType(player, 2) or exports.factions:isPlayerInFaction(player, 81) and getElementData(player, "duty") > 0 or exports.integration:isPlayerTrialAdmin(player) then
			triggerClientEvent(player, "PrisonGUI", player, t)
		end
	end
end
addCommandHandler("arrest", startGUI)
addEvent("startPrisonGUI", true)
addEventHandler("startPrisonGUI", root, startGUI)

local function removePrisonRecord(removeid)
	local row = getRow(removeid)
	if not row then return false end

	local record = t[row]
	local jailID = tonumber(record[1])
	local charID = tonumber(record[2])
	if not jailID or not charID then return false end

	if not mysql:query_free("DELETE FROM jailed WHERE id=" .. mysql:escape_string(jailID)) then
		return false
	end

	mysql:query_free("UPDATE characters SET pdjail=0 WHERE id=" .. mysql:escape_string(charID))
	table.remove(t, row)
	return record
end

addEvent("removePrisoner", true)
addEventHandler("removePrisoner", resourceRoot,
	function( removeid, fromGUI )
			local row = getRow(removeid)
			if not row or not tonumber(t[row][2]) or not prisonMutationAllowed(client, findOnlinePrisoner(t[row][3], t[row][2]) ~= false, "remove") then
				if isElement(client) then outputChatBox("You are not authorized to release this prisoner.", client, 255, 0, 0) end
				return
			end
			local target = findOnlinePrisoner(t[row][3], t[row][2])
			if target and not isCloseTo(client, target) then
				outputChatBox("You must be near this prisoner to remove them.", client, 255, 0, 0)
				return
			end
			local record = removePrisonRecord(removeid)
			if record then
				sendPrisonMsg(getPlayerName(client).." removed "..record[3].." from jail.")
					local players = exports.pool:getPoolElementsByType("player")
					for key, value in ipairs(players) do
						if getElementData(value, "dbid") == tonumber(record[2]) then
							outputChatBox("You were removed from jail by ".. string.gsub(getPlayerName(client), "_", " "), value, 0, 255, 0)
                            if not getElementData(value, "adminjailed") then
                                local cell = getElementData(value, "jail:cell")
                                local cellData = cells[cell]
                                local rel = cellData and releaseLocations[cellData.location]
                                if rel then
                                    setElementPosition(value, rel[1], rel[2], rel[3])
                                    setElementDimension(value, rel[5])
                                    setElementInterior(value, rel[4])
                                end
                            end
                            local jailTimer = getElementData(value, "jail:timer")
                            if isTimer(jailTimer) then killTimer(jailTimer) end
                            if getElementData(value, "jailed") then
                                removeElementData(value, "jailed")
                                removeElementData(value, "jail_time")
                                removeElementData(value, "jail:id")
                                removeElementData(value, "jail_time_online")
                                removeElementData(value, "jail:cell")
                                removeElementData(value, "jail:timer")
                            end
                            assignSkin(value)
                            break
    					end
    				end
				triggerClientEvent(client, "PrisonGUI:Refresh", client, t)
            else
                outputChatBox("Error, PS#01. Report on Mantis: bugs.owlgaming.net", client, 255, 0, 0)
			end
		end
)

addEvent("addPrisoner", true)
addEventHandler("addPrisoner", resourceRoot,
	function( name, cell, days, hours, charges, fine, online )
		local target
		if online == true then
			if not isElement(name) or getElementType(name) ~= "player" or getElementData(name, "loggedin") ~= 1 then return end
			target = name
			name = getPlayerName(target)
		else
			if type(name) ~= "string" then return end
			name = string.gsub(name, " ", "_")
			if #name < 3 or #name > 64 or string.find(name, "[^%w_%-]") then return end
			if findOnlinePrisoner(name) then
				outputChatBox("Select the online player to process this prisoner.", client, 255, 0, 0)
				return
			end
			local characterResult = mysql:query("SELECT id FROM characters WHERE charactername='" .. mysql:escape_string(name) .. "' LIMIT 1")
			local character = characterResult and mysql:fetch_assoc(characterResult)
			if characterResult then mysql:free_result(characterResult) end
			if not character or not tonumber(character.id) then
				outputChatBox("No character found with that name.", client, 255, 0, 0)
				return
			end
		end
		online = target ~= nil
		if not prisonMutationAllowed(client, target ~= nil, "add") then
			outputChatBox("You are not authorized to add this prisoner.", client, 255, 0, 0)
			return
		end
		if not isInArrestColshape(target or client) then
			outputChatBox(target and "The target player must be within the processing area." or "You must be within the processing area to add a prisoner.", client, 255, 0, 0)
			return
		end
		local validDays, validHours, validFine = validatePrisonFields(cell, days, hours, charges, fine, false)
		if validDays == false then
			outputChatBox("Invalid cell, sentence, charges, or fine.", client, 255, 0, 0)
			return
		end
		days, hours, fine = validDays, validHours, validFine
		local r = getRealTime()

		if duplicateCheck(returnWhat(name, online)) then
			outputChatBox("This player is already serving a sentence, use update prisoner instead.", client, 255, 0, 0)
			return
		end

		local days = tonumber(days)*24
        if cells[cell].type == 1 then
            onlineTime = ( (days + tonumber(hours)) * 60 ) * onlineRatio -- In minutes
            offlineTime = ( (days + tonumber(hours)) * 60 ) * offlineRatio -- In minutes
		    jailTime = ( r.timestamp + (offlineTime) * 60  ) -- For timestamp usage
        else
            jailTime = ( r.timestamp + (tonumber(hours) + days) * 60 * 60  )
            onlineTime = 0
        end
		local query = mysql:query_free("INSERT INTO jailed SET charid=(SELECT id FROM characters WHERE charactername='".. mysql:escape_string(returnWhat(name, online)) .. "'), charactername='" .. mysql:escape_string(returnWhat(name, online)) .. "', jail_time=".. mysql:escape_string(jailTime) ..", jail_time_online=".. mysql:escape_string(onlineTime) ..", updatedBy='".. mysql:escape_string(updatedWho(client, online)) .."', charges='" .. mysql:escape_string(charges) .. "', cell='" .. mysql:escape_string(cell) .. "', fine='" .. mysql:escape_string(fine) .. "'")
		if query then
			mysql:query_free("UPDATE characters SET pdjail=1 WHERE charactername='".. mysql:escape_string(returnWhat(name, online)) .. "'")

			local result = mysql:query( "SELECT * FROM jailed WHERE id=LAST_INSERT_ID()")
			local row = mysql:fetch_assoc( result )
			if row then
				table.insert(t, #t+1, { row.id, row.charid, row.charactername, row.jail_time, row.convictionDate, row.updatedBy, row.charges, row.cell, row.fine, row.jail_time_online })
				exports.logs:dbLog(client, 35, returnWhat(name, online), "Added to jail cell: "..row.cell.." character: "..row.charactername.." JailStamp: "..row.jail_time.." OnlineTime: "..row.jail_time_online.." Charges: "..row.charges.." Fine: "..row.fine)
				if online then
					local charid = getElementData(client, "dbid") or 0
					-- attempt to find mdc account, otherwise use John Fox
					local officer = JFOX_MDC
					if ( getElementData( client, 'mdc_account' ) or exports.mdc:login( charid, true ) ) and exports.mdc:canAccess( client, 'canSeeWarrants' ) then
						officer = charid
					end

					-- automatically submit to MDC
					local charID = getElementData( name, 'dbid' )
					triggerEvent( 'mdc-system:add_crime', client, charID, getPlayerName( name ), charges, 'Fine: ' .. fine .. ' & Prison: ' .. ( days + hours ) .. ' hours.', officer )

					triggerClientEvent(client, "PrisonGUI:Close", client, t) -- close the prison window as it will open MDC window
					-- END MDC CRAP --

					outputChatBox("You have been placed in jail by "..string.gsub(getPlayerName(client), "_", " ")..".", name, 0, 255, 0)
					sendPrisonMsg(getPlayerName(client).." added "..getPlayerName(name).." to jail cell: "..row.cell)
					-- FINE
					if tonumber(fine)>0 then -- Issue Fine
						local amount = tonumber(fine) -- Math
						local bankmoney = getElementData(name, "bankmoney")

						exports.anticheat:changeProtectedElementDataEx(name, "bankmoney", bankmoney-amount) -- Take from player
						mysql:query_free("UPDATE characters SET bankmoney=bankmoney-" .. mysql:escape_string(amount) .." WHERE charactername='".. mysql:escape_string(returnWhat(name, online)) .. "'")

						local tax = exports.global:getTaxAmount() -- Split between gov and PD
						local factionID = exports.factions:getCurrentFactionDuty(client)
						local theTeam = exports.factions:getFactionFromID(factionID)
						--local DOC = exports.factions:getFactionFromID(84)
						exports.global:giveMoney(exports.factions:getFactionFromID(3), amount*tax)
						exports.global:giveMoney(theTeam, math.ceil((1-tax)*amount*0.85)) -- PD/HP
						--exports.global:giveMoney(DOC, math.ceil((1-tax)*amount*0.15)) -- 15% after tax for DOC
						-- PD/HP
						mysql:query_free("INSERT INTO wiretransfers (`from`, `to`, `amount`, `reason`, `type`) VALUES (" .. mysql:escape_string((charID)) .. ", " .. mysql:escape_string(-getElementData( theTeam, "id" ) ) .. ", " .. mysql:escape_string(math.ceil((1-tax)*amount)) .. ", '"..mysql:escape_string("#" .. row.id .. " JAIL FINE").."', 5)" )
					    -- DOC
						--mysql:query_free("INSERT INTO wiretransfers (`from`, `to`, `amount`, `reason`, `type`) VALUES (" .. mysql:escape_string((charid)) .. ", " .. mysql:escape_string(-getElementData( DOC, "id" ) ) .. ", " .. mysql:escape_string(math.ceil((1-tax)*amount)) .. ", '"..mysql:escape_string("#" .. row.id .. " JAIL FINE").."', 5)" )

						outputChatBox("Fine of $"..amount.." issued.", name, 0, 255, 0)
					end
					-- RESTRAINTS/WEAP
					local restrainedObj = getElementData(name, "restrainedObj") -- Remove restraints
					if restrainedObj then
						toggleControl(name, "sprint", true)
						toggleControl(name, "jump", true)
						toggleControl(name, "accelerate", true)
						toggleControl(name, "brake_reverse", true)
						exports.anticheat:changeProtectedElementDataEx(name, "restrain", 0, true)
						exports.anticheat:changeProtectedElementDataEx(name, "restrainedBy", false, true)
						exports.anticheat:changeProtectedElementDataEx(name, "restrainedObj", false, true)
						if restrainedObj == 45 then -- If handcuffs.. take the key
							local dbid = getElementData(name, "dbid")
							exports['item-system']:deleteAll(47, dbid)
						end
						exports.global:giveItem(client, restrainedObj, 1)
						mysql:query_free("UPDATE characters SET cuffed = 0, restrainedby = 0, restrainedobj = 0 WHERE id = " .. mysql:escape_string(getElementData( name, "dbid" )) )
					end
					setPedWeaponSlot(name,0)

					activateJail(row.charid, name)
				else
					outputChatBox("[WARNING] No prisoner has been added to the MDC automatically. Please file this manually.", client, 255, 0, 0)
				end
				mysql:free_result(result)
			else
				outputChatBox("Error, PS#02. Report on Mantis: bugs.owlgaming.net", client, 255, 0, 0)
			end
		else
			outputChatBox("No character found with that name.", client, 255, 0, 0)
		end
	end
)

addEvent("changePrisoner", true)
addEventHandler("changePrisoner", resourceRoot,
	function( name, cell, days, hours, charges, removeid, online )
		local rowIndex = getRow(removeid)
		if not rowIndex or type(name) ~= "string" or string.lower(string.gsub(name, " ", "_")) ~= string.lower(t[rowIndex][3]) then
			outputChatBox("Invalid prisoner record.", client, 255, 0, 0)
			return
		end
		local target = findOnlinePrisoner(t[rowIndex][3], t[rowIndex][2])
		if not prisonMutationAllowed(client, target ~= false, "change") then
			outputChatBox("You are not authorized to update this prisoner.", client, 255, 0, 0)
			return
		end
		online = target ~= false
		if online and not isCloseTo(client, target) then
			outputChatBox("You must be near this prisoner to update them.", client, 255, 0, 0)
			return
		end
		name = t[rowIndex][3]
		local validDays, validHours = validatePrisonFields(cell, days, hours, charges, nil, true)
		if validDays == false then
			outputChatBox("Invalid cell, sentence, or charges.", client, 255, 0, 0)
			return
		end
		days, hours = validDays, validHours
		local r = getRealTime()
		local days = tonumber(days)*24
        if cells[cell].type == 1 then
            onlineTime = ( (days + tonumber(hours)) * 60 ) * onlineRatio -- In minutes
            offlineTime = ( (days + tonumber(hours)) * 60 ) * offlineRatio -- In minutes
            jailTime = ( r.timestamp + (offlineTime) * 60  ) -- For timestamp usage
        else
            jailTime = ( r.timestamp + (tonumber(hours) + days) * 60 * 60  )
            onlineTime = 0
        end
		local query = mysql:query_free("UPDATE jailed SET jail_time=".. mysql:escape_string(jailTime) ..", jail_time_online=".. mysql:escape_string(onlineTime) ..", updatedBy='".. mysql:escape_string(updatedWho(client, online)) .."', charges='" .. mysql:escape_string(charges) .. "', cell='" .. mysql:escape_string(cell) .. "' WHERE charactername='".. mysql:escape_string(returnWhat(name, online)).."'")
		if query then
			local result = mysql:query( "SELECT * FROM jailed WHERE charactername='"..mysql:escape_string(returnWhat(name, online)).."'")
			local row = mysql:fetch_assoc( result )
			if row then
                local row1 = getRow(removeid)
				table.remove(t, row1)
				table.insert(t, { row.id, row.charid, row.charactername, row.jail_time, row.convictionDate, row.updatedBy, row.charges, row.cell, row.fine, row.jail_time_online })
				triggerClientEvent(client, "PrisonGUI:Refresh", client, t)
				exports.logs:dbLog(client, 35, returnWhat(name, online), "Updated prisoner data. New data: "..row.cell.." character: "..row.charactername.." JailStamp: "..row.jail_time.." OnlineTime: ".. row.jail_time_online .." Charges: "..row.charges.." Fine: "..row.fine)

				if online then
					outputChatBox("Your prisoner details has been updated.", name, 0, 255, 0)
					activateJail(row.charid, name)
				end
			else
				outputChatBox("Error, PS#02. Report on Mantis: bugs.owlgaming.net", client, 255, 0, 0)
			end
			mysql:free_result(result)
		else
			outputChatBox("No character found with that name.", client, 255, 0, 0)
		end
	end
)

function returnWhat(name, online)
	if online then
		return getPlayerName(name)
	else
		return string.gsub(name, " ", "_")
	end
end

function activateJail(id, target)
	if not id then return end
	for key, value in ipairs(t) do
		if value[2] == id then
			setElementData(target, "jailed", 1)
			setElementData(target, "jail_time", value[4])
			setElementData(target, "jail:id", value[1])
			setElementData(target, "jail:cell", value[8])
            setElementData(target, "jail_time_online", value[10])
            local timer = setTimer(timerCheck, 60000, 0, target)
            setElementData(target, "jail:timer", timer, false)

			local cell = cells[value[8]]
			setElementPosition(target, cell[1], cell[2], cell[3])
    		setElementDimension(target, cell[5])
    		setElementInterior(target, cell[4])

    		assignSkin(target) -- Assign Prisoner Skins
    	end
    end
end

function assignSkin(source)
	skin, skinID = nil, nil
	if getElementData(source, "jailed") then
	-- I put all the id's in g_prison for you.
		local race = getElementData(source, "race")
    	if getElementData(source, "gender") == 1 then
    		-- Female
	    	if race == 0 then
				-- Black Female
				skin = bFemale
				skinID = bFemaleID
			elseif race == 1 then
				-- White Female
				skin = wFemale
				skinID = wFemaleID
			else
				-- Asian Female
				skin = aFemale
				skinID = aFemaleID
			end
		else
			-- Male
			if race == 0 then
				-- Black Male
				skin = bMale
				skinID = bMaleID
			elseif race == 1 then
				-- White Male
				skin = wMale
				skinID = wMaleID
			else
				-- Asian Male
				skin = aMale
				skinID = aMaleID
			end
		end
	else
		local items = exports['item-system']:getItems( source ) -- [] [1] = itemID [2] = itemValue
		for itemSlot, itemCheck in ipairs(items) do
			if itemCheck[1] == 16 then
				local skinData = split(tostring(itemCheck[2]), ':')
				skin = tonumber(skinData[1])
				skinID = tonumber(skinData[2])
			end
		end
	end

	if skin then
		setElementModel(source, skin)
		setElementData(source, "clothing:id", skinID or nil)
		mysql:query_free( "UPDATE characters SET skin = '" .. exports.mysql:escape_string(skin) .. "', clothingid = '" .. exports.mysql:escape_string(skinID or 0) .. "' WHERE id = '" .. exports.mysql:escape_string(getElementData( source, "dbid" )).."'" )
	end
end

function duplicateCheck(name)
	if not name then return end
	for key, value in ipairs(t) do
		if value[3] == name then
			return true
		end
		return false
	end
end

function checkForRelease(client, firstLogin)
	local found = false
	for key, value in ipairs(t) do
		if tonumber(value[2]) == tonumber(getElementData(client, "dbid")) then
			local found = true
			local days, hours, remainingtime = cleanMath(value[4])
            local onlineMinutes = value[10]
    		if remainingtime<=0 and tonumber(onlineMinutes)<=0 then
			removePrisonRecord(value[1])
                if not getElementData(client, "adminjailed") then
                    local cell = value[8]
                    local rel = releaseLocations[cells[cell].location]
                    setElementPosition(client, rel[1], rel[2], rel[3])
                    setElementDimension(client, rel[5])
                    setElementInterior(client, rel[4])
                end
    			if getElementData(client, "jailed") then
                    if not firstLogin then
                        killTimer(getElementData(client, "jail:timer"))
                    end
					removeElementData(client, "jailed")
					removeElementData(client, "jail_time")
					removeElementData(client, "jail:id")
                    removeElementData(client, "jail_time_online")
                    removeElementData(client, "jail:cell")
                    removeElementData(client, "jail:timer")
				end
    			assignSkin(client)
				outputChatBox("Your time has been served!", client, 0, 255, 0)
				return
			else
				setElementData(client, "jailed", 1)
				setElementData(client, "jail_time", value[4])
				setElementData(client, "jail:id", value[1])
				setElementData(client, "jail:cell", value[8])
                setElementData(client, "jail_time_online", value[10])
				local cell = cells[value[8]]
				if isPedDead(client) then
					spawnPlayer(client, cell[1], cell[2], cell[3], 0, getElementModel(client))
					setCameraTarget(client)
				else
					setElementPosition(client, cell[1], cell[2], cell[3])
				end
                if firstLogin then
                    outputChatBox("You are currently in PD jail. /jailtime to review your sentence.", client, 255, 0, 0)
                    local timer = setTimer(timerCheck, 60000, 0, client)
                    setElementData(client, "jail:timer", timer, false)
                end
				assignSkin(client)
    			setElementDimension(client, cell[5])
    			setElementInterior(client, cell[4])
    		return end
    	end
    end
    if not found then
    	local charID = getElementData(client, "dbid")
    	local query = mysql:query_free("UPDATE characters SET pdjail=0 WHERE id="..mysql:escape_string(charID))
        if not getElementData(client, "adminjailed") then
            local cell = getElementData(client, "jail:cell")
            local rel = releaseLocations[cells[cell].location]
            setElementPosition(client, rel[1], rel[2], rel[3])
            setElementDimension(client, rel[5])
            setElementInterior(client, rel[4])
        end
        if getElementData(client, "jailed") then
            removeElementData(client, "jailed")
            removeElementData(client, "jail_time")
            removeElementData(client, "jail:id")
            removeElementData(client, "jail_time_online")
            removeElementData(client, "jail:cell")
            removeElementData(client, "jail:timer")
	    end
	    assignSkin(client)
	end
end

local told = {}
function timerCheck(thePlayer)
    if not thePlayer or not isElement(thePlayer) then return end

    local onlineMinutes = tonumber(getElementData(thePlayer, "jail_time_online"))
    if onlineMinutes and onlineMinutes > 0 then
        if getPlayerIdleTime(thePlayer) <=  600000 then
            setElementData(thePlayer, "jail_time_online", onlineMinutes-1)
            for k,v in ipairs(t) do
                if tonumber(v[2]) == tonumber(getElementData(thePlayer, "dbid")) then
                    t[k][10] = onlineMinutes-1
                end
            end

            if told[thePlayer] then
                told[thePlayer] = nil
            end
        elseif not told[thePlayer] then
            outputChatBox("You have been flagged as away from keyboard, your online timer is not being reduced.", thePlayer, 255, 0, 0)
            told[thePlayer] = true
        end
    elseif onlineMinutes and onlineMinutes == 0 then
        local days, hours, remainingtime = cleanMath(getElementData(thePlayer, "jail_time"))
        if remainingtime <= 0 then
            checkForRelease(thePlayer)
            return
        elseif not tonumber(days) then -- No double time for life sentence
            return
        end

        local remainingMinutes = (remainingtime / 60)-2 -- Reduce by 2 minutes instead of 1
        local currenttime = getRealTime().timestamp
        local timefull = (remainingMinutes * 60) + currenttime
        setElementData(thePlayer, "jail_time", timefull)
        for k,v in ipairs(t) do
            if tonumber(v[2]) == tonumber(getElementData(thePlayer, "dbid")) then
                t[k][4] = timefull
            end
        end
    end
end

function playerQuit()
    local timer = getElementData(source, "jail:timer")
    if timer then
        killTimer(timer)
    end
    if getElementData(source, "jailed") then
        dbExec(exports.mysql:getConn("mta"), "UPDATE jailed SET jail_time=?, jail_time_online=? WHERE charid=?", getElementData(source, "jail_time"), getElementData(source, "jail_time_online"), getElementData(source, "dbid"))
    end
end
addEventHandler ( "onPlayerQuit", getRootElement(), playerQuit, true, "high" )

function playerChangeAlts()
    local timer = getElementData(source, "jail:timer")
    if timer then
        killTimer(timer)
    end
    if getElementData(source, "jailed") then
        dbExec(exports.mysql:getConn("mta"), "UPDATE jailed SET jail_time=?, jail_time_online=? WHERE charid=?", getElementData(source, "jail_time"), getElementData(source, "jail_time_online"), getElementData(source, "dbid"))
    end
    removeElementData(source, "jailed")
    removeElementData(source, "jail_time")
    removeElementData(source, "jail:id")
    removeElementData(source, "jail_time_online")
    removeElementData(source, "jail:cell")
    removeElementData(source, "jail:timer")
end
addEventHandler("accounts:characters:change", getRootElement(), playerChangeAlts, true, "high")

addCommandHandler("jailtime", function(thePlayer)
		local days, hours, remainingtime = cleanMath(getElementData(thePlayer, "jail_time"))
        local onlineMinutes = getElementData(thePlayer, "jail_time_online")
		if not remainingtime or not onlineMinutes then
			outputChatBox("You are not serving a jail sentence.", thePlayer, 255, 0, 0)
		elseif remainingtime<=0 and tonumber(onlineMinutes)<=0 then
			for key, value in ipairs(t) do
				if tonumber(value[2]) == tonumber(getElementData(thePlayer, "dbid")) then
				    removePrisonRecord(value[1])
                    if not getElementData(thePlayer, "adminjailed") then
                        local cell = getElementData(thePlayer, "jail:cell")
                        local rel = releaseLocations[cells[cell].location]
                        setElementPosition(thePlayer, rel[1], rel[2], rel[3])
                        setElementDimension(thePlayer, rel[5])
                        setElementInterior(thePlayer, rel[4])
                    end
                    local timer = getElementData(thePlayer, "jail:timer")
                    if isTimer(timer) then
                        killTimer(timer)
                    end
    			    if getElementData(thePlayer, "jailed") then -- If called from /jailtime
                        removeElementData(thePlayer, "jailed")
    					removeElementData(thePlayer, "jail_time")
    					removeElementData(thePlayer, "jail:id")
                        removeElementData(thePlayer, "jail_time_online")
                        removeElementData(thePlayer, "jail:cell")
                        removeElementData(thePlayer, "jail:timer")
				    end
				    assignSkin(thePlayer)
				    outputChatBox("Your time has been served!", thePlayer, 0, 255, 0)
				end
			end
		else
			if tonumber(hours) and tonumber(days) and tonumber(onlineMinutes) then
				if cells[getElementData(thePlayer, "jail:cell")].type == 0 then
					-- Online time doesn't exist for this cell type.
					if tonumber(hours) < 1 and tonumber(days) <= 0 then
						local minutes = ("%.1f"):format(remainingtime/60)
						outputChatBox("You currently have ".. minutes .. " minutes remaining in your sentence. You are prisoner ID "..getElementData(thePlayer, "jail:id")..", in cell "..getElementData(thePlayer, "jail:cell"), thePlayer, 255, 255, 0)
					else
						outputChatBox("You currently have ".. days .. " days and " .. hours .. " hours remaining in your sentence. You are prisoner ID ".. getElementData(thePlayer, "jail:id")..", in cell "..getElementData(thePlayer, "jail:cell"), thePlayer, 255, 255, 0)
					end
				else
					-- Show a mixture of online and offline time.
					if tonumber(hours) < 1 and tonumber(days) <= 0 then
						local minutes = ("%.1f"):format(remainingtime/60)
						outputChatBox("You currently have ".. minutes .. " offline minutes and ".. onlineMinutes .." online minutes remaining in your sentence. You are prisoner ID "..getElementData(thePlayer, "jail:id")..", in cell "..getElementData(thePlayer, "jail:cell"), thePlayer, 255, 255, 0)
					else
						outputChatBox("You currently have ".. days .. " offline days, " .. hours .. " offline hours and ".. onlineMinutes .." online minutes remaining in your sentence. You are prisoner ID ".. getElementData(thePlayer, "jail:id")..", in cell "..getElementData(thePlayer, "jail:cell"), thePlayer, 255, 255, 0)
					end
					if tonumber(onlineMinutes) <= 0 then
						outputChatBox("Your offline time is going down by double because your online minutes are already served!", thePlayer, 255, 255, 0)
					end
				end
			elseif tostring(days) ~= "Awaiting" then
				outputChatBox("You are currently serving a life sentence. You are prisoner ID "..getElementData(thePlayer, "jail:id")..", in cell "..getElementData(thePlayer, "jail:cell"), thePlayer, 255, 255, 0)
            elseif tostring(hours) == "Online Time" then
                outputChatBox("You currently have ".. onlineMinutes .." online minutes remaining in your sentence. You are prisoner ID "..getElementData(thePlayer, "jail:id")..", in cell "..getElementData(thePlayer, "jail:cell"), thePlayer, 255, 255, 0)
            end
		end
end )

function timeReleaseCheck(initialize)
	local players = exports.pool:getPoolElementsByType("player")
	for key, value in ipairs(players) do
		if getElementData(value, "loggedin")==1 then
		    for _,res in ipairs(t) do
			    if tonumber(res[2]) == tonumber(getElementData(value, "dbid")) then
				    local days, hours, remainingtime = cleanMath(res[4])
                    local onlineMinutes = res[10]
    			    if remainingtime<=0 and tonumber(onlineMinutes)<=0 then
    				    outputDebugString("JAIL: Timer removed " .. string.gsub(tostring(res[3]), "_", " ") .. " from jail.")
    				    outputChatBox("Your time has been served!", value, 0, 255, 0)
                        removePrisonRecord(res[1])
                        local timer = getElementData(value, "jail:timer")
                        if timer then
                            killTimer(timer)
                        end
                        if not getElementData(value, "adminjailed") then
                            local cell = getElementData(value, "jail:cell")
                            local rel = releaseLocations[cells[cell].location]
                            setElementPosition(value, rel[1], rel[2], rel[3])
                            setElementDimension(value, rel[5])
                            setElementInterior(value, rel[4])
                        end
        			    if getElementData(value, "jailed") then
                            removeElementData(value, "jailed")
        					removeElementData(value, "jail_time")
        					removeElementData(value, "jail:id")
                            removeElementData(value, "jail_time_online")
                            removeElementData(value, "jail:cell")
                            removeElementData(value, "jail:timer")
    				    end
    				    assignSkin(value)
				    else
					    local minutes = ("%.1f"):format(remainingtime/60)
					    outputDebugString("JAIL: Player remaining in jail ".. string.gsub(tostring(res[3]), "_", " ") .." Minutes/OnlineMinutes: ".. tostring(minutes) .. "/".. tostring(onlineMinutes) ..".")
					    --[[outputChatBox("You are currently in PD jail. /jailtime to review your sentence.", value, 255, 0, 0)]]
                        if initialize then
                            setElementData(value, "jailed", 1)
					        setElementData(value, "jail_time", res[4])
                            setElementData(value, "jail_time_online", res[10])
					        setElementData(value, "jail:id", res[1])
					        setElementData(value, "jail:cell", res[8])

                            local timer = setTimer(timerCheck, 60000, 0, value)
                            setElementData(value, "jail:timer", timer, false)
                        end
    			    end
    		    end
    	    end
        end
    end
end

function sendPrisonMsg(string)
    local string = string.gsub(string, "_", " ")
    for _, v in ipairs(exports.pool:getPoolElementsByType("player")) do
        local team = getPlayerTeam( v )
        if exports.factions:isPlayerInFaction(v, 1) or exports.factions:isPlayerInFaction(v, 54) or exports.factions:isPlayerInFaction(v, 81) then
        	outputChatBox(string, v, 255, 0, 0)
        end
    end
end

function updatedWho(client, online)
	if online then
 		return getElementData(client, "account:username")
	else
 		return getPlayerName(client)
 	end
end

-- Speaker through all interiors/dimensions of the prison.
function processSpeakerMessage(thePlayer, commandName, ...)
	if not (...) then
		outputChatBox("SYNTAX: /"..commandName.." [message] - Sends a speaker-like message through the prison.", thePlayer)
		outputChatBox("You must be in the prison or in the courtyard. SASD usage only.", thePlayer)
	else
		local px, py, pz = getElementPosition(thePlayer)
		if (getElementInterior(thePlayer) == speakerInt and speakerDimensions[getElementDimension(thePlayer)] and (exports.factions:isPlayerInFaction(thePlayer, 1))) or (getDistanceBetweenPoints3D( px, py, pz, speakerOutX, speakerOutY, speakerOutZ ) < 100 and exports.factions:isPlayerInFaction(thePlayer, 1)) then
			for k, v in ipairs(exports.pool:getPoolElementsByType("player")) do
				local arrayInt = getElementInterior(v)
				local arrayDim = getElementDimension(v)
				local aX, aY, aZ = getElementPosition(v) -- used for the courtyard message

				local message = table.concat({...}, " ")
				if arrayInt == speakerInt and speakerDimensions[arrayDim] then -- speakerInt and speakerDimensions are set in g_ config file
					if exports.factions:isPlayerInFaction(v, 1) then
						outputChatBox("PRISON INTERCOM ("..string.gsub(getPlayerName(thePlayer), "_", " ")..") o< "..message, v, 218, 165, 32)
					else
						outputChatBox("PRISON INTERCOM o< "..message, v, 218, 165, 32)
					end
				elseif getDistanceBetweenPoints3D( aX, aY, aZ, speakerOutX, speakerOutY, speakerOutZ ) < 100 then -- 100 meters from center of courtyard = you can hear it speakers
					if exports.factions:isPlayerInFaction(v, 1) then
						outputChatBox("PRISON INTERCOM ("..string.gsub(getPlayerName(thePlayer), "_", " ")..") o< "..message, v, 218, 165, 32)
					else
						outputChatBox("PRISON INTERCOM o< "..message, v, 218, 165, 32)
					end
				end
			end
		end
	end
end
addCommandHandler("intercom", processSpeakerMessage)
