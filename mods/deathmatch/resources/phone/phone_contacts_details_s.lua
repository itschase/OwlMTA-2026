--MAXIME
local function getOwnedContact(id)
	if client and client ~= source then return nil end
	local player = client or source
	id = tonumber(id)
	if not id or not isElement(player) or getElementType(player) ~= "player" or getElementData(player, "loggedin") ~= 1 then return nil end
	local contact = mysql:query_fetch_assoc("SELECT `id`, `phone` FROM `phone_contacts` WHERE `id`='"..mysql:escape_string(tostring(id)).."' LIMIT 1")
	if contact and exports.global:hasItem(player, 2, tonumber(contact.phone)) then return player, contact end
	return nil
end

function updateContactDetails(id, name, number, email, address, favo)
	local player, contact = getOwnedContact(id)
	if not player or type(name) ~= "string" or type(number) ~= "string" or type(email) ~= "string" or type(address) ~= "string"
		or not tonumber(number) or string.len(name) < 1 or string.len(name) > 50 or string.len(number) < 1 or string.len(number) > 50
		or string.len(email) > 60 or string.len(address) > 100 then
		return false
	end
	if mysql:query_free("UPDATE `phone_contacts` SET `entryName`='"..exports.global:toSQL(name).."', `entryNumber`='"..exports.global:toSQL(number).."', `entryEmail`='"..exports.global:toSQL(email or "").."', `entryAddress`='"..exports.global:toSQL(address or "").."', `entryFavorited`='"..(tonumber(favo) == 1 and 1 or 0).."' WHERE `id`='"..contact.id.."' AND `phone`='"..mysql:escape_string(tostring(contact.phone)).."' ") then
		triggerClientEvent(player, "phone:contacts:details:update:response", player, id, name, number, email, address, favo)
		return true
	end
	if player then triggerClientEvent(player, "phone:contacts:details:update:response", player, false) end
	return false
end
addEvent("phone:contacts:details:update", true)
addEventHandler("phone:contacts:details:update", root, updateContactDetails)

function deleteContact(id)
	local player, contact = getOwnedContact(id)
	if not player then return false end
	if mysql:query_free("DELETE FROM `phone_contacts` WHERE `id`='"..contact.id.."' AND `phone`='"..mysql:escape_string(tostring(contact.phone)).."' ") then
		triggerClientEvent(player, "phone:contacts:details:delete:response", player, id)
		return true
	end
	triggerClientEvent(player, "phone:contacts:details:delete:response", player, false)
	return false
end
addEvent("phone:contacts:details:delete", true)
addEventHandler("phone:contacts:details:delete", root, deleteContact)
