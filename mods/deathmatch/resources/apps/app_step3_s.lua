--MAXIME
local step3Ticks = setmetatable({}, { __mode = "k" })
local notifiedApplications = {}

local function elapsedMilliseconds(now, previous)
	return (now - previous) % 4294967296
end

local function getAuthenticatedApplicant(actor, expectedState, action)
	if not isElement(actor) or getElementType(actor) ~= "player"
		or getElementData(actor, "account:loggedin") ~= true then
		outputDebugString("[APPS][FLOW] outcome=rejected action=" .. action .. " reason=invalid_session", 2)
		return false
	end
	local accountID = tonumber(getElementData(actor, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID) then
		outputDebugString("[APPS][FLOW] outcome=rejected action=" .. action .. " reason=invalid_account", 2)
		return false
	end
	local row = exports.mysql:query_fetch_assoc("SELECT `a`.`id` FROM `account_details` `d`"
		.. " INNER JOIN `applications` `a` ON `a`.`applicant`=`d`.`account_id` AND `a`.`state`='0'"
		.. " WHERE `d`.`account_id`='" .. accountID .. "' AND `d`.`appstate`='" .. expectedState .. "'"
		.. " ORDER BY `a`.`id` DESC LIMIT 1")
	local applicationID = row and tonumber(row.id)
	if not applicationID or applicationID < 1 or applicationID ~= math.floor(applicationID) then
		outputDebugString("[APPS][FLOW] outcome=rejected action=" .. action .. " reason=missing_pending_application", 2)
		return false
	end
	return accountID, applicationID
end

local function notifyReviewers(applicantName)
	local count = 0
	for _, player in ipairs(getElementsByType("player")) do
		if getElementData(player, "loggedin") == 1 and exports.global:isAdminOnDuty(player) then
			local message = "[APPLICATION] Player '" .. applicantName
				.. "' submitted an application and is awaiting review. Press F7 to open the queue."
			local delivered = false
			if getElementData(player, "report_panel_mod") == "2"
				or getElementData(player, "report_panel_mod") == "3" then
				delivered = pcall(function()
					exports.report:showToAdminPanel(message, player, 255, 0, 0)
				end)
			elseif getElementData(player, "wrn:style") == 1 then
				delivered = triggerClientEvent(player, "sendWrnMessage", player, message) == true
			else
				delivered = outputChatBox(message, player, 255, 0, 0) == true
			end
			if delivered then
				count = count + 1
			else
				outputDebugString("[APPS][FLOW] outcome=committed action=step3_notify followup=reviewer_delivery_failed", 2)
			end
		end
	end
	return count
end

function appsShowStep3(actor, notifyStaff)
	local _, applicationID = getAuthenticatedApplicant(actor, 2, "step3_show")
	if not applicationID then
		return false
	end

	local message
	if notifyStaff == true and not notifiedApplications[applicationID] then
		local applicantName = getElementData(actor, "account:username")
		if type(applicantName) ~= "string" or applicantName == "" then
			applicantName = "Applicant"
		end
		local count = notifyReviewers(applicantName)
		notifiedApplications[applicationID] = true
		if not triggerEvent("apps:requestApps", resourceRoot) then
			outputDebugString("[APPS][FLOW] outcome=committed action=step3_notify followup=count_refresh_failed", 2)
		end
		if count > 0 then
			message = "Your application was submitted successfully. " .. count
				.. " on-duty administrator(s) were notified and can review it."
		else
			message = "Your application was submitted successfully. No reviewing administrators are currently on duty; you may disconnect and return later."
		end
	end

	local delivered = triggerClientEvent(actor, "apps:startStep3", actor, message)
	if not delivered then
		outputDebugString("[APPS][FLOW] outcome=committed action=step3_show followup=applicant_delivery_failed", 1)
		return false
	end
	outputDebugString("[APPS][FLOW] outcome=presented action=step3_show", 3)
	return true
end

function startStep3()
	if not client or source ~= client then
		outputDebugString("[APPS][FLOW] outcome=rejected action=step3_open reason=invalid_caller", 2)
		return false
	end
	local now = getTickCount()
	local previous = step3Ticks[client]
	if previous and elapsedMilliseconds(now, previous) < 3000 then
		outputDebugString("[APPS][FLOW] outcome=rejected action=step3_open reason=rate_limited", 2)
		return false
	end
	step3Ticks[client] = now
	return appsShowStep3(client, false)
end
addEvent("apps:startStep3", true)
addEventHandler("apps:startStep3", root, startStep3)

function retakeApplicationPart2()
	local actor = source
	if client then
		if source ~= client then
			outputDebugString("[APPS][FLOW] outcome=rejected action=part2_retake reason=source_mismatch", 2)
			return false
		end
		actor = client
	end
	if not isElement(actor) or getElementType(actor) ~= "player"
		or getElementData(actor, "account:loggedin") ~= true then
		outputDebugString("[APPS][FLOW] outcome=rejected action=part2_retake reason=invalid_session", 2)
		return false
	end
	triggerEvent("apps:startStep2", actor, true)
	return true
end
addEvent("apps:retakeApplicationPart2", true)
addEventHandler("apps:retakeApplicationPart2", root, retakeApplicationPart2)

addEventHandler("onPlayerQuit", root, function()
	step3Ticks[source] = nil
end)
