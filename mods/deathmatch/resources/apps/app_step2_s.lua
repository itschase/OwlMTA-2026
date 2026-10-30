--MAXIME
local selectedQuests2 = setmetatable({}, { __mode = "k" })
local flowTicks = setmetatable({}, { __mode = "k" })
local CHALLENGE_TTL_MS = 30 * 60 * 1000

local function elapsedMilliseconds(now, previous)
	return (now - previous) % 4294967296
end

local function resolveApplicantActor(proposedPlayer, action, expectedState, cooldown)
	local actor = proposedPlayer
	if client then
		if source ~= client then
			outputDebugString("[APPS][FLOW] outcome=rejected action=" .. action .. " reason=source_mismatch", 2)
			return false
		end
		actor = client
	end
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

	local now = getTickCount()
	local actorTicks = flowTicks[actor]
	local lastTick = actorTicks and actorTicks[action]
	if lastTick and elapsedMilliseconds(now, lastTick) < cooldown then
		outputDebugString("[APPS][FLOW] outcome=rejected action=" .. action .. " reason=rate_limited", 2)
		return false
	end
	if not actorTicks then
		actorTicks = {}
		flowTicks[actor] = actorTicks
	end
	actorTicks[action] = now

	local accountRow = exports.mysql:query_fetch_assoc("SELECT `appstate` FROM `account_details`"
		.. " WHERE `account_id`='" .. accountID .. "' LIMIT 1")
	if not accountRow then
		outputDebugString("[APPS][FLOW] outcome=rejected action=" .. action .. " reason=state_lookup_failed", 1)
		return false
	end
	local appState = accountRow and tonumber(accountRow.appstate)
	if appState ~= expectedState then
		outputDebugString("[APPS][FLOW] outcome=rejected action=" .. action .. " reason=invalid_state", 2)
		return false
	end
	return actor, accountID
end

local function sendSubmissionResult(actor, succeeded, message)
	if isElement(actor) then
		triggerClientEvent(actor, "apps:processPart2:result", actor, succeeded == true, message)
	end
end

local function selectQuestions(questions, count)
	for index = #questions, 2, -1 do
		local other = math.random(1, index)
		questions[index], questions[other] = questions[other], questions[index]
	end
	local selected = {}
	for index = 1, count do
		selected[index] = questions[index]
	end
	return selected
end

function startStep2(retest)
	local actor, accountID = resolveApplicantActor(source, "step2_start", 1, 1000)
	if not actor then
		local responseActor = client or source
		if isElement(responseActor) and getElementType(responseActor) == "player" then
			sendSubmissionResult(responseActor, false, "Your application stage could not be opened. Please reconnect and try again.")
		end
		return false
	end

	local query = exports.mysql:query("SELECT `question` FROM `applications_questions` WHERE `part`='2'")
	if not query then
		outputDebugString("[APPS][FLOW] outcome=rejected action=step2_start reason=question_query_failed", 1)
		sendSubmissionResult(actor, false, "The application questions are temporarily unavailable. Please try again shortly.")
		return false
	end

	local questions = {}
	while true do
		local row = exports.mysql:fetch_assoc(query)
		if not row then
			break
		end
		local question = type(row.question) == "string" and row.question or nil
		if question and #question >= 2 and #question <= 500 then
			table.insert(questions, question)
		end
	end
	exports.mysql:free_result(query)
	if #questions < 4 then
		outputDebugString("[APPS][FLOW] outcome=rejected action=step2_start reason=question_bank_underfilled", 1)
		sendSubmissionResult(actor, false, "The application question bank is incomplete. Please contact server staff.")
		return false
	end

	local selected = selectQuestions(questions, 4)
	selectedQuests2[actor] = {
		accountID = accountID,
		issuedAt = getTickCount(),
		questions = selected,
	}
	triggerClientEvent(actor, "apps:startStep2", actor, selected, retest)
	return true
end
addEvent("apps:startStep2", true)
addEventHandler("apps:startStep2", root, startStep2)

local function normalizeAnswers(answers)
	if type(answers) ~= "table" or answers[5] ~= nil then
		return false
	end
	local normalized = {}
	for index = 1, 4 do
		local answer = answers[index]
		if type(answer) ~= "string" then
			return false
		end
		answer = answer:gsub("^%s+", ""):gsub("%s+$", "")
		if #answer < 2 or #answer > 500 then
			return false
		end
		normalized[index] = answer
	end
	return normalized
end

local function compensateInsertedApplication(applicationID, accountID, reason)
	local compensated = exports.mysql:query_free("DELETE FROM `applications` WHERE `id`='"
		.. applicationID .. "' AND `applicant`='" .. accountID .. "' AND `state`='0'")
	outputDebugString("[APPS][FLOW] outcome=rejected action=part2_submit reason=" .. reason
		.. " compensation=" .. (compensated and "complete" or "failed"), compensated and 2 or 1)
end

function processPart2(answers)
	local actor, accountID = resolveApplicantActor(source, "part2_submit", 1, 3000)
	if not actor then
		if client and isElement(client) and getElementType(client) == "player" then
			sendSubmissionResult(client, false, "Your application session is no longer valid. Please reopen it and try again.")
		end
		return false
	end

	local challenge = selectedQuests2[actor]
	if not challenge or challenge.accountID ~= accountID
		or elapsedMilliseconds(getTickCount(), challenge.issuedAt) > CHALLENGE_TTL_MS then
		selectedQuests2[actor] = nil
		outputDebugString("[APPS][FLOW] outcome=rejected action=part2_submit reason=missing_or_expired_challenge", 2)
		sendSubmissionResult(actor, false, "Your application session expired. Please reopen this section and try again.")
		return false
	end

	local normalizedAnswers = normalizeAnswers(answers)
	if not normalizedAnswers then
		outputDebugString("[APPS][FLOW] outcome=rejected action=part2_submit reason=invalid_answers", 2)
		sendSubmissionResult(actor, false, "Each answer must contain between 2 and 500 characters.")
		return false
	end

	local questions = challenge.questions
	local applicationID = tonumber(exports.mysql:query_insert_free("INSERT INTO `applications` SET"
		.. " `applicant`='" .. accountID .. "',"
		.. " `question1`='" .. toSQL(questions[1]) .. "', `question2`='" .. toSQL(questions[2]) .. "',"
		.. " `question3`='" .. toSQL(questions[3]) .. "', `question4`='" .. toSQL(questions[4]) .. "',"
		.. " `answer1`='" .. toSQL(normalizedAnswers[1]) .. "', `answer2`='" .. toSQL(normalizedAnswers[2]) .. "',"
		.. " `answer3`='" .. toSQL(normalizedAnswers[3]) .. "', `answer4`='" .. toSQL(normalizedAnswers[4]) .. "'"))
	if not applicationID or applicationID < 1 or applicationID ~= math.floor(applicationID) then
		outputDebugString("[APPS][FLOW] outcome=rejected action=part2_submit reason=insert_failed", 1)
		sendSubmissionResult(actor, false, "Your application could not be saved. Please try again.")
		return false
	end

	local transitionExecuted = exports.mysql:query_free("UPDATE `account_details` SET `appstate`='2'"
		.. " WHERE `account_id`='" .. accountID .. "' AND `appstate`='1'")
	if not transitionExecuted then
		compensateInsertedApplication(applicationID, accountID, "state_transition_failed")
		sendSubmissionResult(actor, false, "Your application state could not be saved. Please try again.")
		return false
	end

	local affectedRow = exports.mysql:query_fetch_assoc("SELECT ROW_COUNT() AS `affected_rows`")
	local affectedRows = affectedRow and tonumber(affectedRow.affected_rows)
	if not affectedRows then
		outputDebugString("[APPS][FLOW] outcome=indeterminate action=part2_submit reason=affected_row_check_failed", 1)
		sendSubmissionResult(actor, false, "Your application state could not be confirmed. Please reconnect before retrying.")
		return false
	elseif affectedRows < 1 then
		compensateInsertedApplication(applicationID, accountID, "stale_state_transition")
		sendSubmissionResult(actor, false, "Your application stage changed before submission. Please reopen it and try again.")
		return false
	end

	local cleanupSucceeded = exports.mysql:query_free("DELETE FROM `applications` WHERE `applicant`='"
		.. accountID .. "' AND `state`='0' AND `id`<>'" .. applicationID .. "'")
	if not cleanupSucceeded then
		outputDebugString("[APPS][FLOW] outcome=committed action=part2_submit followup=stale_row_cleanup_failed", 1)
	end

	local stateSyncSucceeded = pcall(function()
		exports.anticheat:setEld(actor, "appstate", 2)
	end)
	if not stateSyncSucceeded or tonumber(getElementData(actor, "appstate")) ~= 2 then
		outputDebugString("[APPS][FLOW] outcome=committed action=part2_submit followup=session_state_sync_failed", 1)
	end
	local auditSucceeded = pcall(function()
		exports.logs:dbLog(actor, 4, "ac" .. accountID, "APPLICATION SUBMITTED id=" .. applicationID)
	end)
	if not auditSucceeded then
		outputDebugString("[APPS][FLOW] outcome=committed action=part2_submit followup=audit_unavailable", 1)
	end

	selectedQuests2[actor] = nil
	sendSubmissionResult(actor, true)
	triggerEvent("apps:startStep3", actor, true)
	return true
end
addEvent("apps:processPart2", true)
addEventHandler("apps:processPart2", root, processPart2)

addEventHandler("onPlayerQuit", root, function()
	selectedQuests2[source] = nil
	flowTicks[source] = nil
end)
