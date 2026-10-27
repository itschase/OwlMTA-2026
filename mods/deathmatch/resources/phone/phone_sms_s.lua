--MAXIME
local messageLimit = 20
local threadLimit = 100
local function getRequester()
    local player = client or source
    if client and client ~= source then return nil end
    if not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "loggedin") ~= 1 then return nil end
    return player
end

local function ownsPhone(player, phone)
    phone = tonumber(phone)
    return isElement(player) and getElementType(player) == "player"
        and getElementData(player, "loggedin") == 1 and phone
        and exports.global:hasItem(player, 2, phone) and phone or nil
end
function getOneSMSThread(fromPhone, threadIndex)
    local thread = {}
    local query = mysql:query("SELECT *, TIME_TO_SEC(TIMEDIFF(NOW(), `date`)) AS `secdiff` FROM `phone_sms` WHERE (`from`='"..fromPhone.."' AND `to`='"..threadIndex.."') OR (`from`='"..threadIndex.."' AND `to`='"..fromPhone.."') ORDER BY `date` DESC LIMIT "..messageLimit)
    while true do
        local row = mysql:fetch_assoc(query)
        if not row then break end
        table.insert(thread, row)
    end
    return thread
end

function fetchSMS(fromPhone, forceUpdate, forceUpdateContactList1)
    local player = getRequester()
    if not player then return end
    fromPhone = ownsPhone(player, fromPhone)
    fromPhone = tonumber(fromPhone)
    local SMSs = {}
    if fromPhone then
        if forceUpdateContactList1 then
            forceUpdateContactList(player, fromPhone)
        end

        local query = mysql:query("SELECT *, TO_SECONDS(`date`) AS `datesec` FROM `phone_sms` WHERE `from`='"..fromPhone.."' OR `to`='"..fromPhone.."' ORDER BY `date` DESC ")
        while true do
            local row = mysql:fetch_assoc(query)
            if not row then break end
            table.insert(SMSs, row)
        end
    end

    triggerClientEvent(player, "phone:receiveSMSFromServer", player, fromPhone, SMSs, forceUpdate)
end
addEvent("phone:fetchSMS", true)
addEventHandler("phone:fetchSMS", root, fetchSMS)

local function fetchOneSMSThreadForPlayer(player, fetchForPhone, messageSentTo, outGoing, forceUpdateContactList1, limit)
    fetchForPhone = ownsPhone(player, fetchForPhone)
    messageSentTo = tonumber(messageSentTo)
    local SMSs = {}
    if fetchForPhone and messageSentTo then
        if forceUpdateContactList1 then
            forceUpdateContactList(player, fetchForPhone)
        end
        
        limit = math.min(math.max(tonumber(limit) or 10, 1), 100)
        limit = "LIMIT "..limit
        local query = mysql:query("SELECT *, TO_SECONDS(`date`) AS `datesec` FROM `phone_sms` WHERE (`from`='"..fetchForPhone.."' AND `to`='"..messageSentTo.."') OR (`from`='"..messageSentTo.."' AND `to`='"..fetchForPhone.."') ORDER BY `date` DESC "..limit)
        while query do
            local row = mysql:fetch_assoc(query)
            if not row then break end
            table.insert(SMSs, row)
        end
    end
    --outputDebugString("fetchOneSMSThread / "..getPlayerName(source))
    triggerClientEvent(player, "phone:receiveOneSMSThreadFromServer", player, fetchForPhone, messageSentTo, SMSs, outGoing)
end

function fetchOneSMSThread(fetchForPhone, messageSentTo, outGoing, forceUpdateContactList1, limit)
    local player = getRequester()
    if not player then return end
    fetchOneSMSThreadForPlayer(player, fetchForPhone, messageSentTo, outGoing, forceUpdateContactList1, limit)
end
addEvent("phone:fetchOneSMSThread", true)
addEventHandler("phone:fetchOneSMSThread", root, fetchOneSMSThread)

local function sendSMSForPlayer(player, from, to, content, showChatNotification)
    from = ownsPhone(player, from)
    to = tonumber(to)
    local powerOn, isSecret
    if from then
        local ringtone
        powerOn, ringtone, isSecret = getPhoneSettings(from, true)
    end
    private = tonumber(isSecret) == 1 and 1 or 0
    if not from or not to or not content or type(content) ~= "string" or string.len(content) < 1 or string.len(content) > 120 then
        return false
    end
    if not powerOn or powerOn == 0 then return false end

    mysql:query_insert_free("INSERT INTO `phone_sms` SET `from`='"..from.."', `to`='"..to.."', `content`='"..exports.global:toSQL(content).."', private="..private)
    local loggedElements = {player, "ph"..tostring(from), "ph"..tostring(to) }

    if showChatNotification then
        outputChatBox("SMS to #" .. to .. ": " .. content, player, 120, 255, 80)
    end

    local alertUser = true
    if not isNumberAHotline(to) then
        local t_powerOn, t_ringtone, t_isSecret, t_isInPhonebook, t_boughtBy = getPhoneSettings(to, true)
        if not t_powerOn then --not existed
            local notExisted = "Delivery has failed to these recipients: #"..to..". Number does not exist."
            mysql:query_insert_free("INSERT INTO `phone_sms` SET `from`='"..to.."', `to`='"..from.."', `content`='"..exports.global:toSQL(notExisted).."' ")
            fetchOneSMSThreadForPlayer(player, from, to, true)

            exports['logs']:dbLog(player, 30, loggedElements, content)
            return false
        end

        if t_powerOn == 0 then 
            alertUser = false
        end
    end

    local found, target = searchForPhone(to)
    if found and target then
        fetchOneSMSThreadForPlayer(target, to, from)
        table.insert(loggedElements, target)
        if alertUser then
            triggerClientEvent(target, "newSMSReceived", resourceRoot, from, to, content)
        end
    end
    fetchOneSMSThreadForPlayer(player, from, to, true)

    exports['logs']:dbLog(player, 30, loggedElements, content)
end

function sendSMS(from, to, content, private, showChatNotification)
    local player = getRequester()
    if not player then return false end
    -- The client-supplied privacy flag is intentionally ignored; the owned phone's setting is authoritative.
    return sendSMSForPlayer(player, from, to, content, showChatNotification)
end
addEvent("phone:sendSMS", true)
addEventHandler("phone:sendSMS", root, sendSMS)

for i = 1, 20 do
    addCommandHandler( "sms" .. tostring( i == 1 and "" or i ), function(thePlayer, theCommand, to, ...)
        if getElementData(thePlayer, "loggedin") ~= 1 then return end

        -- find the item with the matching id
        -- /sms is the first phone, /sms2 the second phone etc.
        to = tonumber(to)
        if to and ... then
            local count = 0
            local items = exports['item-system']:getItems(thePlayer)
            for _, v in ipairs(items) do
                if v[1] == 2 then -- it's a phone
                    count = count + 1
                    if count == i then
                        local from = v[2]
                        local message = table.concat({...}, " ")
                        local power = getPhoneSettings(from,  true)
                        if power and power ~= 0 then 
                            sendSMSForPlayer(thePlayer, from, to, message, true)
                            return
                        else
                            outputChatBox("Your phone needs to be powered on to be able to SMS.", thePlayer, 255, 0, 0)
                        end
                    end
                end
            end
        else
            outputChatBox("SYNTAX: /" .. theCommand .. " [Phone Number] [Message]", thePlayer, 255, 194, 14)
        end
    end)
end

function startRingingSMS(fromPhone, smsTone, volume)
    local player = getRequester()
    if not player then return false end
    fromPhone = ownsPhone(player, fromPhone)
    if not fromPhone then return false end
    local phoneSettings = {getPhoneSettings(fromPhone, true)}
    local turnedOn = phoneSettings[1]
    smsTone = phoneSettings[8]
    volume = phoneSettings[9]

    if turnedOn and turnedOn ~= 0 then
        for _,nearbyPlayer in ipairs(exports.global:getNearbyElements(player, "player"), 10) do
            triggerClientEvent(nearbyPlayer, "startRinging", player, 2, smsTone, volume)
        end
        if smsTone > 1 then
            triggerEvent('sendAme', player, "'s cellphone starts to ring.")
        end
        outputChatBox("Your phone #"..fromPhone.." has received a new text message.", player)
    end
end
addEvent("phone:startRingingSMS", true)
addEventHandler("phone:startRingingSMS", root, startRingingSMS)

function updateSMSViewedState(fromPhone, threadIndex)
    local player = getRequester()
    fromPhone = player and ownsPhone(player, fromPhone)
    threadIndex = tonumber(threadIndex)
    if fromPhone and threadIndex and mysql:query_free("UPDATE `phone_sms` SET `viewed`=1 WHERE `from`='"..threadIndex.."' AND `to`='"..fromPhone.."' ") then
        fetchOneSMSThreadForPlayer(player, fromPhone, threadIndex)
    end
end
addEvent("phone:updateSMSViewedState", true)
addEventHandler("phone:updateSMSViewedState", root, updateSMSViewedState)


function cleanUpOldSMS()
    mysql:query_free("DELETE FROM `phone_sms` WHERE DATEDIFF(NOW(),`date`) > 7  ")
end
addEventHandler("onResourceStart", resourceRoot, cleanUpOldSMS)
