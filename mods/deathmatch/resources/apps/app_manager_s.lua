--MAXIME
appOpened = {}
function openAppsWindow(thePlayer, cmd)
	local actor = appsResolveManagerActor(thePlayer)
	if not actor or not appsAuthorizeManager(actor, "applications.review.list", "applications.review") then
		return false
	end

	local apps = {}
	local quests = {}
	local preparedQ = ""
	local mQuery = nil

	preparedQ = "SELECT `a`.`id` AS `id`, `a`.`applicant` AS `username`, `dateposted`, `state`, `datereviewed`, `a`.`reviewer` AS `reviewer` FROM `applications` `a` ORDER BY `dateposted` DESC LIMIT 75"
	mQuery = exports.mysql:query(preparedQ)
	while true do
		local row = exports.mysql:fetch_assoc(mQuery)
		if not row then break end
		row.username = exports.cache:getUsernameFromId(row.username)
		row.reviewer = exports.cache:getUsernameFromId(row.reviewer)
		table.insert(apps, row )
	end
	exports.mysql:free_result(mQuery)

	preparedQ = "SELECT `id`, `part`, `question`, `createDate`, `applications_questions`.`createdBy` AS 'createdBy', `updateDate`, `applications_questions`.`updatedBy` AS 'updatedBy' FROM `applications_questions` ORDER BY `updateDate` DESC "
	mQuery = exports.mysql:query(preparedQ)
	while true do
		local row = exports.mysql:fetch_assoc(mQuery)
		if not row then break end
		row.createdBy = exports.cache:getUsernameFromId(row.createdBy)
		row.updatedBy = exports.cache:getUsernameFromId(row.updatedBy)
		table.insert(quests, row)
		--outputDebugString(row["question"])
	end
	exports.mysql:free_result(mQuery)



	triggerClientEvent(actor, "apps:openAppsWindow", actor, apps, quests)
	return true
end
addEvent("apps:openAppsWindow", true)
addEventHandler("apps:openAppsWindow", root, openAppsWindow)

function updateNumber()
	local mQuery = nil

	preparedQ = "SELECT COUNT(*) AS 'apps' FROM `applications` WHERE `state`=0"
	mQuery = exports.mysql:query_fetch_assoc(preparedQ)
	local apps = tonumber(mQuery["apps"])
	exports.mysql:free_result(mQuery)

	setElementData(getResourceRootElement(), "apps:number", apps)
end
addEvent("apps:requestApps", false)
addEventHandler("onResourceStart", getResourceRootElement(), updateNumber)
addEventHandler("apps:requestApps", getResourceRootElement(), updateNumber)


function openQuestionDetail(id, part)
	local actor = appsResolveManagerActor()
	if not actor or not appsAuthorizeManager(actor, "applications.question_bank.read", "applications.question_bank.manage") then
		return false
	end
	id = tonumber(id)
	part = tonumber(part)
	if not id or id < 1 or id ~= math.floor(id) or (part ~= 1 and part ~= 2) then
		outputDebugString("[APPS][QUESTION_BANK] outcome=rejected reason=invalid_detail_request", 2)
		return false
	end
	local mysqlResult = exports.mysql:query_fetch_assoc("SELECT * FROM `applications_questions` WHERE `id`='"..(id) .."' LIMIT 1")
	triggerClientEvent(actor, "apps:openQuestionDetail", actor, part, false, true, mysqlResult)
end
addEvent("apps:openQuestionDetail", true)
addEventHandler("apps:openQuestionDetail", root, openQuestionDetail)

function saveQuestion(part, id, question, key, answer1, answer2, answer3)
	local actor = appsResolveManagerActor()
	if not actor or not appsAuthorizeManager(actor, "applications.question_bank.write", "applications.question_bank.manage") then
		return false
	end
	local client = actor
	part = tonumber(part)
	local numericID = id and tonumber(id)
	if (part ~= 1 and part ~= 2) or type(question) ~= "string" or question == ""
		or (id and (not numericID or numericID < 1 or numericID ~= math.floor(numericID)))
		or (part == 1 and (tonumber(key) == nil or tonumber(key) < 1 or tonumber(key) > 3
			or type(answer1) ~= "string" or type(answer2) ~= "string" or type(answer3) ~= "string")) then
		outputDebugString("[APPS][QUESTION_BANK] outcome=rejected reason=invalid_save_request", 2)
		return false
	end
	id = numericID
	if part == 1 then
		if id and tonumber(id) then
			local mQuery1 = exports.mysql:query_free("UPDATE `applications_questions` SET `question`='"..toSQL(question).."', `key`='"..toSQL(key or 1).."', `answer1`='"..toSQL(answer1 or "").."', `answer2`='"..toSQL(answer2 or "").."', `answer3`='"..toSQL(answer3 or "").."', `part`='"..toSQL(part).."', `updatedBy`='"..toSQL(getElementData(client, "account:id")).."', `updateDate`=NOW() WHERE `id`='"..toSQL(id).."' ")
			if not mQuery1 then
				outputDebugString("APPLICATION MANAGER / DATABASE ERROR")
				outputChatBox("[APPLICATION MANAGER] Update question #"..id.." failed.", client, 255,0,0)
				return false
			end

			outputChatBox("[APPLICATION MANAGER] You have updated question #"..id.." successfully.", client, 0,255,0)
			exports.global:sendMessageToAdmins("[APPLICATION-MANAGER]: "..getElementData(client, "account:username").." has updated question #"..id.." (Part "..part..", Question: '"..question.."')")
			openAppsWindow(client)
			return true
		else
			local mQuery1 = exports.mysql:query_insert_free("INSERT INTO `applications_questions` SET `question`='"..toSQL(question).."', `key`='"..toSQL(key or "").."', `answer1`='"..toSQL(answer1 or "").."', `answer2`='"..toSQL(answer2 or "").."', `answer3`='"..toSQL(answer3 or "").."', `part`='"..toSQL(part).."', `updatedby`='"..toSQL(getElementData(client, "account:id")).."', `updateDate`=NOW(), `createdBy`='"..toSQL(getElementData(client, "account:id")).."', `createDate`=NOW() ")
			if not mQuery1 then
				outputDebugString("APPLICATION MANAGER / DATABASE ERROR")
				outputChatBox("[APPLICATION MANAGER] Failed to create question.", client, 255,0,0)
				return false
			end

			outputChatBox("[APPLICATION MANAGER] You have created question #"..mQuery1.." successfully.", client, 0,255,0)
			exports.global:sendMessageToAdmins("[APPLICATION-MANAGER]: "..getElementData(client, "account:username").." has created question #"..mQuery1.." (Part "..part..", Question: '"..question.."')")
			openAppsWindow(client)
			return true
		end
	else
		if id and tonumber(id) then
			local mQuery1 = exports.mysql:query_free("UPDATE `applications_questions` SET `question`='"..toSQL(question).."', `part`='"..toSQL(part).."', `updatedBy`='"..toSQL(getElementData(client, "account:id")).."', `updateDate`=NOW() WHERE `id`='"..toSQL(id).."' ")
			if not mQuery1 then
				outputDebugString("APPLICATION MANAGER / DATABASE ERROR")
				outputChatBox("[APPLICATION MANAGER] Update question #"..id.." failed.", client, 255,0,0)
				return false
			end

			outputChatBox("[APPLICATION MANAGER] You have updated question #"..id.." successfully.", client, 0,255,0)
			exports.global:sendMessageToAdmins("[APPLICATION-MANAGER]: "..getElementData(client, "account:username").." has updated question #"..id.." (Part "..part..", Question: '"..question.."')")
			openAppsWindow(client)
			return true
		else
			local mQuery1 = exports.mysql:query_insert_free("INSERT INTO `applications_questions` SET `question`='"..toSQL(question).."', `part`='"..toSQL(part).."', `updatedby`='"..toSQL(getElementData(client, "account:id")).."', `updateDate`=NOW(), `createdBy`='"..toSQL(getElementData(client, "account:id")).."', `createDate`=NOW() ")
			if not mQuery1 then
				outputDebugString("APPLICATION MANAGER / DATABASE ERROR")
				outputChatBox("[APPLICATION MANAGER] Failed to create question.", client, 255,0,0)
				return false
			end

			outputChatBox("[APPLICATION MANAGER] You have created question #"..mQuery1.." successfully.", client, 0,255,0)
			exports.global:sendMessageToAdmins("[APPLICATION-MANAGER]: "..getElementData(client, "account:username").." has created question #"..mQuery1.." (Part "..part..", Question: '"..question.."')")
			openAppsWindow(client)
			return true
		end
	end
	return false
end
addEvent("apps:saveQuestion", true)
addEventHandler("apps:saveQuestion", root, saveQuestion)

function deleteQuestion(id, part)
	local actor = appsResolveManagerActor()
	if not actor or not appsAuthorizeManager(actor, "applications.question_bank.delete", "applications.question_bank.manage") then
		return false
	end
	local client = actor
	id = tonumber(id)
	part = tonumber(part)
	if id and id >= 1 and id == math.floor(id) and (part == 1 or part == 2) then
		local sumQuests = exports.mysql:query_fetch_assoc("SELECT COUNT(*) AS 'num' FROM `applications_questions` WHERE `part`='"..part.."' ")
		local limit = 6
		if tonumber(part) == 2 then
			limit = 4
		end
		if not sumQuests or not tonumber(sumQuests["num"]) or tonumber(sumQuests["num"]) <= limit then
			outputChatBox("[APPLICATION MANAGER] At least "..limit.." questions must be in part "..part.."'s bank, please add more questions to be able to delete.", client, 255,0,0)
			return false
		end
		local mQuery1 = exports.mysql:query_free("DELETE FROM `applications_questions` WHERE `id`='"..toSQL(id).."' ")
		if not mQuery1 then
			outputDebugString("APPLICATION MANAGER / DATABASE ERROR")
			outputChatBox("[APPLICATION MANAGER] Delete question #"..id.." failed.", client, 255,0,0)
			return false
		end

		outputChatBox("[APPLICATION MANAGER] You have deleted question #"..id.." successfully.", client, 0,255,0)
		exports.global:sendMessageToAdmins("[APPLICATION-MANAGER]: "..getElementData(client, "account:username").." has deleted question #"..id..".")
		openAppsWindow(client)
		return true
	else
		outputDebugString("[APPS][QUESTION_BANK] outcome=rejected reason=invalid_delete_request", 2)
		outputChatBox("[APPLICATION MANAGER] Invalid question delete request.", client, 255,0,0)
		return false
	end
end
addEvent("apps:deleteQuestion", true)
addEventHandler("apps:deleteQuestion", root, deleteQuestion)

function openAppDetail(id, readOnly)
	local actor = appsResolveManagerActor()
	if not actor or not appsAuthorizeManager(actor, "applications.review.read", "applications.review") then
		return false
	end
	local client = actor
	id = tonumber(id)
	if id and id >= 1 and id == math.floor(id) then
		if appOpened[id] and isElement(appOpened[id]) and getElementType(appOpened[id]) == "player" and not readOnly then
			if client ~= appOpened[id] then
				outputChatBox("[APPLICATION MANAGER] This application is currently being reviewed by "..exports.global:getAdminTitle1(appOpened[id])..".", client, 255,0,0)
			end
			return false
		end
		local appData = exports.mysql:query_fetch_assoc("SELECT `a`.`id` AS `id`, `a`.`applicant` AS `username`, `question1`, `question2`, `question3`, `question4`, `answer1`, `answer2`, `answer3`, `answer4`, `dateposted`, `state`, `reviewer`, `note`, `datereviewed`, `applicant` FROM `applications` `a` WHERE `a`.`id`='"..id.."' ")

		if appData and appData.id then
			readOnly = readOnly == true or tonumber(appData.state) ~= 0
			appData.reviewer = exports.cache:getUsernameFromId(appData.reviewer)
			appData.username = exports.cache:getUsernameFromId(appData.username)
			if not readOnly then
				local staffName = exports.global:getAdminTitle1(client)
				if not exports.mysql:query_free("UPDATE `applications` SET `reviewer`='"..getElementData(client, "account:id").."', `datereviewed`=NOW() WHERE `id`='"..id.."' AND `state`='0'") then
					outputDebugString("[APPS][REVIEW] outcome=rejected reason=lock_persistence_failed", 1)
					return false
				end
				appOpened[id] = client
				sendMsgToStaff(staffName.." has opened and reviewing "..appData.username.."'s application ID#"..id..".")
				sendMsgToApplicant(appData.applicant, staffName.." has opened and is currently reviewing your application.\nPlease stand by..")
			end
			triggerClientEvent(client, "apps:openAppDetail",client, appData, readOnly)
		end
	end
end
addEvent("apps:openAppDetail", true)
addEventHandler("apps:openAppDetail", root, openAppDetail)

function cleanUpOpenedApps()
	for i, openedApp in pairs(appOpened) do
		if openedApp == source then
			openedApp = nil
			appOpened[i] = nil
		end
	end
end
addEventHandler ( "onPlayerQuit", getRootElement(), cleanUpOpenedApps )
addEventHandler ( "accounts:characters:change", getRootElement(), cleanUpOpenedApps )

local app_fail_attempts = {}
function updateAppState(id, state, reason)
	local actor = appsResolveManagerActor()
	if not actor or not appsAuthorizeManager(actor, "applications.review.decide", "applications.review") then
		return false
	end
	local client = actor
	id = tonumber(id)
	state = tonumber(state)
	if type(reason) == "string" then
		reason = reason:match("^%s*(.-)%s*$")
	end
	if not id or id < 1 or id ~= math.floor(id) or (state ~= 1 and state ~= 2)
		or type(reason) ~= "string" or #reason < 2 or #reason > 500 then
		outputDebugString("[APPS][REVIEW] outcome=rejected reason=invalid_decision", 2)
		return false
	end
	if appOpened[id] ~= actor then
		outputDebugString("[APPS][REVIEW] outcome=rejected reason=lock_not_owned", 2)
		return false
	end

	local storedApplication = exports.mysql:query_fetch_assoc("SELECT `applicant`, `state`"
		.. " FROM `applications` WHERE `id`='" .. id .. "' LIMIT 1")
	local applicantID = storedApplication and tonumber(storedApplication.applicant)
	if not applicantID or applicantID < 1 or applicantID ~= math.floor(applicantID)
		or tonumber(storedApplication.state) ~= 0 then
		outputDebugString("[APPS][REVIEW] outcome=rejected reason=stale_or_missing_application", 2)
		return false
	end
	local applicationName = exports.cache:getUsernameFromId(applicantID) or ("account #" .. applicantID)

	do
		local reviewer = getElementData(client, "account:id")
		local appData = exports.mysql:query_free("UPDATE `applications` SET `reviewer`='"..reviewer.."', `datereviewed`=NOW(), `state`='"..state.."', `note`='"..toSQL(reason).."' WHERE `id`='"..id.."' AND `state`='0' ")
		if not appData then
			outputDebugString("[APPS][REVIEW] outcome=rejected reason=decision_persistence_failed", 1)
			return false
		end
		local auditSucceeded = pcall(function()
			exports.logs:dbLog(client, 4, "ac" .. applicantID,
				"APPLICATION DECISION id=" .. id .. " state=" .. state)
		end)
		if not auditSucceeded then
			outputDebugString("[APPS][REVIEW] outcome=audit_unavailable", 1)
		end
		openAppsWindow(client)
		do
			local staffName = exports.global:getAdminTitle1(client)
			sendMsgToStaff(staffName.." has "..(state == 1 and "accepted" or "declined").." "..applicationName.."'s application ID#"..id..". Reason: "..reason)
			if state == 1 then -- accepted
				app_fail_attempts[applicantID] = nil
				sendMsgToApplicant(applicantID, "Congratulations! Your application has been reviewed and accepted by "..staffName..".\nReason: "..reason.."\nJoining the game...")
				exports.mysql:query_free("UPDATE `account_details` SET `appstate`='3' WHERE `account_id`='"..applicantID.."' ")
				setTimer(movePlayerToSelectionScreen, 10000, 1, applicantID)
				exports['report']:updateStaffReportCount(client)
			elseif state == 2 then
				if not app_fail_attempts[applicantID] then
					app_fail_attempts[applicantID] = 1
				end
				if app_fail_attempts[applicantID] >= 3 then
					exports.mysql:query_free("DELETE FROM `force_apps` WHERE `account`='" .. applicantID .. "' ")
					exports.mysql:query_free("INSERT INTO `force_apps` SET `account`='" .. applicantID .. "' ")
					exports.mysql:query_free("UPDATE `account_details` SET `appstate`='0' WHERE `account_id`='" .. applicantID .. "' ")
					for i, player in pairs(getElementsByType("player")) do
						if getElementData(player, "account:id") == tonumber(applicantID) and (getElementData(player, "loggedin") ~= 1) then
							redirectPlayer ( player, "" , 0 )
							break
						end
					end
					app_fail_attempts[applicantID] = nil
					sendMsgToStaff(applicationName.." has been 24 hours banned from retaking application as it has been declined 3 times in a row.")
					exports['report']:updateStaffReportCount(client)
					updateNumber()
					return true
				else
					sendMsgToApplicant(applicantID, "Unfortunately, your application has been declined by "..staffName..".\nReason: "..reason.."\nReturning to application section 2..\n\nYou have "..tostring(3-app_fail_attempts[applicantID]).." chance(s) left to re-submit another application.")
					app_fail_attempts[applicantID] = app_fail_attempts[applicantID] + 1
					exports.mysql:query_free("UPDATE `account_details` SET `appstate`='1' WHERE `account_id`='"..applicantID.."' ")
					setTimer(movePlayerBackToStep2, 10000, 1, applicantID)
				end
				exports['report']:updateStaffReportCount(client)
			end
			updateNumber()
			triggerEvent("apps:closeAppDetail",client, id)
		end
	end
end
addEvent("apps:updateAppState", true)
addEventHandler("apps:updateAppState", root, updateAppState)

function closeAppDetail(id)
	local actor = appsResolveManagerActor(source)
	if not actor or not appsAuthorizeManager(actor, "applications.review.close", "applications.review") then
		return false
	end
	if id and tonumber(id) then
		id = tonumber(id)
		if appOpened[id] and appOpened[id] ~= actor then
			outputDebugString("[APPS][REVIEW] outcome=rejected reason=lock_not_owned", 2)
			return false
		end
		appOpened[id] = nil
		--exports.mysql:query_free("UPDATE `applications` SET `reviewer`='0' WHERE `id`='"..id.."'")
		triggerClientEvent(actor, "apps:closeAppDetail", actor)
		return true
	end
	return false
end
addEvent("apps:closeAppDetail", true)
addEventHandler("apps:closeAppDetail", root, closeAppDetail)

function movePlayerToSelectionScreen(id)
	if id and tonumber(id) then
		id = tonumber(id)
		local players = getElementsByType("player")
		for i, player in pairs(players) do
			if getElementData(player, "account:id") == id then
				triggerEvent("accounts:playerFinishApps", player)
				return true
			end
		end
	end
end

function movePlayerBackToStep2(id)
	if id and tonumber(id) then
		id = tonumber(id)
		local players = getElementsByType("player")
		for i, player in pairs(players) do
			if getElementData(player, "account:id") == id then
				triggerClientEvent (player,"apps:destroyGUIPart3",player)
				triggerEvent("apps:retakeApplicationPart2", player)
				return true
			end
		end
	end
end

function toSQL(stuff)
	return exports.mysql:escape_string(stuff)
end

function sendMsgToStaff(msg)
	if msg then
		exports.global:sendWrnToStaffOnDuty(msg, "APPLICATION", 255, 0, 0)
	end
end

function sendMsgToApplicant(applicant, msg)
	local players = getElementsByType("player")
	for i, player in pairs(players) do
		if getElementData(player, "account:id") == tonumber(applicant) and (getElementData(player, "loggedin") ~= 1) then
			triggerClientEvent(player, "apps:startStep3", player, msg)
		end
	end
end
