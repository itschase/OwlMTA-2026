local function getAuthenticatedAccountID(player)
	if not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "account:loggedin") ~= true then
		return false
	end

	local accountID = tonumber(getElementData(player, "account:id"))
	if not accountID or accountID < 1 or accountID ~= math.floor(accountID) then
		return false
	end

	return accountID
end

local function isValidEmail(email)
	if type(email) ~= "string" or #email == 0 or #email > 254 or email:find("%s") then
		return false
	end

	local at = email:find("@", 1, true)
	if not at or at == 1 or at == #email or email:find("@", at + 1, true) then
		return false
	end

	local domain = email:sub(at + 1)
	return domain:find(".", 1, true) ~= nil and domain:sub(1, 1) ~= "." and domain:sub(-1) ~= "."
end

local function respond(player, success, message)
	if isElement(player) then
		triggerClientEvent(player, "requestEmail:saveEmailResult", resourceRoot, success, message)
	end
end

local function saveEmail(email)
	local player = client
	if not isElement(player) or getElementType(player) ~= "player" then
		outputDebugString("[ACCOUNT][EMAIL] rejected request reason=invalid_remote_client", 2)
		return false
	end

	local accountID = getAuthenticatedAccountID(player)
	if not accountID then
		outputDebugString("[ACCOUNT][EMAIL] rejected request account=unknown reason=not_authenticated", 2)
		respond(player, false, "Log in before changing your account email.")
		return false
	end

	if not isValidEmail(email) then
		outputDebugString("[ACCOUNT][EMAIL] rejected request account=" .. tostring(accountID) .. " reason=invalid_email", 2)
		respond(player, false, "Enter a valid email address (maximum 254 characters).")
		return false
	end

	if not dbExec(exports.mysql:getConn("core"), "UPDATE accounts SET email=? WHERE id=?", email, accountID) then
		outputDebugString("[ACCOUNT][EMAIL] update failed account=" .. tostring(accountID) .. " reason=database_error_or_duplicate_email", 1)
		respond(player, false, "Unable to save that email. Check whether it is already in use and try again.")
		return false
	end

	setElementDataEx(player, "account:email", email, true)
	outputDebugString("[ACCOUNT][EMAIL] update succeeded account=" .. tostring(accountID), 3)
	respond(player, true, "Email saved successfully.")
	return true
end

addEvent("requestEmail:saveEmail", true)
addEventHandler("requestEmail:saveEmail", getRootElement(), saveEmail)
