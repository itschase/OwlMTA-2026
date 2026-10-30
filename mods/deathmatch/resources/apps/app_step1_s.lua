--MAXIME
local selectedQuests = setmetatable({}, { __mode = "k" })
local flowTicks = setmetatable({}, { __mode = "k" })
local CHALLENGE_TTL_MS = 30 * 60 * 1000
local COOLDOWN_SECONDS = 24 * 60 * 60

local function elapsedMilliseconds(now, previous)
	return (now - previous) % 4294967296
end

local function resolveApplicantActor(proposedPlayer, action, expectedState, cooldown)
	local actor = proposedPlayer
	if client then
		if source ~= client then
			outputDebugString("[APPS][QUIZ] outcome=rejected action=" .. action .. " reason=source_mismatch", 2)
			return false
		end
		actor = client
	end
	if not isElement(actor) or getElementType(actor) ~= "player"
		or getElementData(actor, "account:loggedin") ~= true then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=" .. action .. " reason=invalid_session", 2)
		return false
	end

	local accountID = tonumber(getElementData(actor, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID) then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=" .. action .. " reason=invalid_account", 2)
		return false
	end

	local now = getTickCount()
	local actorTicks = flowTicks[actor]
	local lastTick = actorTicks and actorTicks[action]
	if lastTick and elapsedMilliseconds(now, lastTick) < cooldown then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=" .. action .. " reason=rate_limited", 2)
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
		outputDebugString("[APPS][QUIZ] outcome=rejected action=" .. action .. " reason=state_lookup_failed", 1)
		return false
	end
	if tonumber(accountRow.appstate) ~= expectedState then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=" .. action .. " reason=invalid_state", 2)
		return false
	end
	return actor, accountID
end

local function sendQuizResult(actor, succeeded, message, resetRequired)
	if isElement(actor) then
		triggerClientEvent(actor, "apps:finishStep1:result", actor, succeeded == true, message, resetRequired == true)
	end
end

local function getRemainingCooldown(accountID)
	local row = exports.mysql:query_fetch_assoc("SELECT UNIX_TIMESTAMP(NOW())"
		.. "-MAX(UNIX_TIMESTAMP(`forceapp_date`)) AS `secdiff` FROM `force_apps`"
		.. " WHERE `account`='" .. accountID .. "'")
	if not row then
		return false, "lookup_failed"
	end
	local secondsSince = tonumber(row.secdiff)
	if not secondsSince then
		return 0
	end
	local remaining = COOLDOWN_SECONDS - math.max(0, secondsSince)
	if remaining <= 0 then
		if not exports.mysql:query_free("DELETE FROM `force_apps` WHERE `account`='" .. accountID .. "'") then
			outputDebugString("[APPS][QUIZ] outcome=allowed followup=expired_cooldown_cleanup_failed", 1)
		end
		return 0
	end
	return math.ceil(remaining)
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

function startStep11(retest)
	local actor, accountID = resolveApplicantActor(source, "step1_start", 0, 1000)
	if not actor then
		local responseActor = client or source
		if isElement(responseActor) and getElementType(responseActor) == "player" then
			sendQuizResult(responseActor, false, "Your application stage could not be opened. Please reconnect and try again.")
		end
		return false
	end

	local remaining, cooldownError = getRemainingCooldown(accountID)
	if remaining == false then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_start reason=" .. cooldownError, 1)
		sendQuizResult(actor, false, "Your application cooldown could not be checked. Please try again shortly.")
		return false
	end

	local query = exports.mysql:query("SELECT `question`, `answer1`, `answer2`, `answer3`, `key`"
		.. " FROM `applications_questions` WHERE `part`='1'")
	if not query then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_start reason=question_query_failed", 1)
		sendQuizResult(actor, false, "The quiz questions are temporarily unavailable. Please try again shortly.")
		return false
	end

	local questions = {}
	while true do
		local row = exports.mysql:fetch_assoc(query)
		if not row then
			break
		end
		local key = tonumber(row.key)
		if type(row.question) == "string" and #row.question >= 2 and #row.question <= 500
			and type(row.answer1) == "string" and #row.answer1 >= 1 and #row.answer1 <= 500
			and type(row.answer2) == "string" and #row.answer2 >= 1 and #row.answer2 <= 500
			and type(row.answer3) == "string" and #row.answer3 >= 1 and #row.answer3 <= 500
			and key and key >= 1 and key <= 3 and key == math.floor(key) then
			table.insert(questions, {
				question = row.question,
				answer1 = row.answer1,
				answer2 = row.answer2,
				answer3 = row.answer3,
				key = key,
			})
		end
	end
	exports.mysql:free_result(query)
	if #questions < 6 then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_start reason=question_bank_underfilled", 1)
		sendQuizResult(actor, false, "The quiz question bank is incomplete. Please contact server staff.")
		return false
	end

	local selected = selectQuestions(questions, 6)
	local presentation, answerKeys = {}, {}
	for index = 1, 6 do
		presentation[index] = {
			question = selected[index].question,
			answer1 = selected[index].answer1,
			answer2 = selected[index].answer2,
			answer3 = selected[index].answer3,
		}
		answerKeys[index] = selected[index].key
	end
	selectedQuests[actor] = {
		accountID = accountID,
		issuedAt = getTickCount(),
		answerKeys = answerKeys,
	}

	local remainHours, remainMinutes, remainSeconds
	if remaining > 0 then
		remainHours = math.floor(remaining / 3600)
		if remainHours < 1 then
			remainHours = nil
			remainMinutes = math.floor(remaining / 60)
			if remainMinutes < 1 then
				remainMinutes = nil
				remainSeconds = remaining
			end
		end
	end
	triggerClientEvent(actor, "apps:step11", actor, presentation, retest,
		remainHours, remainMinutes, remainSeconds)
	return true
end
addEvent("apps:startStep11", true)
addEventHandler("apps:startStep11", root, startStep11)

local function normalizeAnswers(answers)
	if type(answers) ~= "table" or answers[7] ~= nil then
		return false
	end
	local normalized = {}
	for index = 1, 6 do
		local answer = tonumber(answers[index])
		if not answer or answer < 1 or answer > 3 or answer ~= math.floor(answer) then
			return false
		end
		normalized[index] = answer
	end
	return normalized
end

function finishStep1(answers)
	local actor, accountID = resolveApplicantActor(source, "step1_submit", 0, 3000)
	if not actor then
		if client and isElement(client) and getElementType(client) == "player" then
			sendQuizResult(client, false, "Your quiz session is no longer valid. Please reopen it and try again.", true)
		end
		return false
	end

	local remaining, cooldownError = getRemainingCooldown(accountID)
	if remaining == false then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_submit reason=" .. cooldownError, 1)
		sendQuizResult(actor, false, "Your application cooldown could not be checked. Please try again shortly.")
		return false
	elseif remaining > 0 then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_submit reason=cooldown_active", 2)
		sendQuizResult(actor, false, "You must wait for the application cooldown to expire before submitting the quiz.")
		return false
	end

	local challenge = selectedQuests[actor]
	if not challenge or challenge.accountID ~= accountID
		or elapsedMilliseconds(getTickCount(), challenge.issuedAt) > CHALLENGE_TTL_MS then
		selectedQuests[actor] = nil
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_submit reason=missing_or_expired_challenge", 2)
		sendQuizResult(actor, false, "Your quiz session expired. Please reopen this section and try again.", true)
		return false
	end

	local normalizedAnswers = normalizeAnswers(answers)
	if not normalizedAnswers then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_submit reason=invalid_answers", 2)
		sendQuizResult(actor, false, "Select one answer for every quiz question.")
		return false
	end

	local correct = 0
	for index = 1, 6 do
		if normalizedAnswers[index] == challenge.answerKeys[index] then
			correct = correct + 1
		end
	end
	local incorrect = 6 - correct
	if incorrect > 0 then
		selectedQuests[actor] = nil
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_submit reason=incorrect_answers", 3)
		sendQuizResult(actor, false, "Some answers were incorrect. Review the rules and start a new quiz.", true)
		return false
	end

	local transitionExecuted = exports.mysql:query_free("UPDATE `account_details` SET `appstate`='1'"
		.. " WHERE `account_id`='" .. accountID .. "' AND `appstate`='0'")
	if not transitionExecuted then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_submit reason=state_transition_failed", 1)
		sendQuizResult(actor, false, "Your quiz result could not be saved. Please try again.")
		return false
	end
	local affectedRow = exports.mysql:query_fetch_assoc("SELECT ROW_COUNT() AS `affected_rows`")
	local affectedRows = affectedRow and tonumber(affectedRow.affected_rows)
	if not affectedRows then
		outputDebugString("[APPS][QUIZ] outcome=indeterminate action=step1_submit reason=affected_row_check_failed", 1)
		sendQuizResult(actor, false, "Your quiz result could not be confirmed. Please reconnect before retrying.")
		return false
	elseif affectedRows < 1 then
		outputDebugString("[APPS][QUIZ] outcome=rejected action=step1_submit reason=stale_state_transition", 2)
		sendQuizResult(actor, false, "Your application stage changed before submission. Please reopen it.")
		return false
	end

	local stateSyncSucceeded = pcall(function()
		exports.anticheat:setEld(actor, "appstate", 1)
	end)
	if not stateSyncSucceeded or tonumber(getElementData(actor, "appstate")) ~= 1 then
		outputDebugString("[APPS][QUIZ] outcome=committed action=step1_submit followup=session_state_sync_failed", 1)
	end
	local auditSucceeded = pcall(function()
		exports.logs:dbLog(actor, 4, "ac" .. accountID, "APPLICATION QUIZ PASSED")
	end)
	if not auditSucceeded then
		outputDebugString("[APPS][QUIZ] outcome=committed action=step1_submit followup=audit_unavailable", 1)
	end

	selectedQuests[actor] = nil
	sendQuizResult(actor, true, "Quiz passed. Opening the written application.")
	triggerEvent("apps:startStep2", actor)
	return true
end
addEvent("apps:finishStep1", true)
addEventHandler("apps:finishStep1", root, finishStep1)

addEventHandler("onPlayerQuit", root, function()
	selectedQuests[source] = nil
	flowTicks[source] = nil
end)
