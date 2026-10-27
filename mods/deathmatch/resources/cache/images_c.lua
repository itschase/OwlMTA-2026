--[[
 * ***********************************************************************************************************************
 * Copyright (c) 2015 OwlGaming Community - All Rights Reserved
 * All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * ***********************************************************************************************************************
 ]]

local images = {}
local searched = {}
local cooldown = 10 --seconds.
local refresh_rate = 0 -- hours, 0 = never recache.
local MAX_IMAGE_BYTES = 2 * 1024 * 1024

local function validId(id)
	local number = tonumber(id)
	return number and number == math.floor(number) and number ~= 0 and math.abs(number) <= 2147483647 and number
end

local function validImageData(data)
	if type(data) ~= 'string' or #data == 0 or #data > MAX_IMAGE_BYTES then
		return false
	end
	return data:sub(1, 3) == '\255\216\255' or data:sub(1, 8) == '\137PNG\r\n\26\n'
end

local function getPath(url)
	return '@images_cache/' .. md5(tostring(url)) .. '.tex'
end

-- Use do not use triggerClientEvent or triggerEvent on this function. 
-- If you intend to cache a new image from URL from client, call the function directly or use triggerServerEvent instead.
function addImage(id, data)
	local url = nil
	id = validId(id)
	if not id then return false end

	if source then -- Triggered from server.
		if not validImageData(data) then
			--outputDebugString("[CACHE] Images / Client / addImage / id and data are required parameters.")
			return
		end
		
		--Check and clear this image data if it is already been cached in client's file system.
		local filename = removeImage(id)

		--Now create a file in client's file system too, so next time they can load it quickly.
		local file = fileCreate(filename)
		if not file then return false end
		local size = fileWrite(file, data)
		fileClose(file)

		if size == #data then
			--outputDebugString("[CACHE] Images / Client / addImage / Received "..exports.global:formatMoney(math.floor(size/1000)).."KB of data from server. Cached image in client's file system as '"..filename.."' - "..id)
			images[id] = getImage(id)
			searched[id] = getTickCount()
		else
			fileDelete(filename)
			--outputDebugString("[CACHE] Images / Client / addImage / Couln't cache image - "..id.." in client's file system.")
		end
		
	else -- Caching new image from client. 
		if id and id > 0 then
			local ply = false
			if tonumber(getElementData(localPlayer, "account:id")) == id then
				ply = localPlayer
			else
				for _, player in pairs(exports.pool:getPoolElementsByType("player")) do
					if tonumber(getElementData(player, "account:id")) == id then
						ply = player
						break
					end
				end
			end
			if ply and getElementData(ply, "account:email") and getElementData(ply, "avatar") == 1  then
				url = 'https://www.gravatar.com/avatar/'..string.lower(md5(getElementData(ply,"account:email"))).."?d=404"
			end
		else
			url = 'https://owlgaming.net/assets/interiors/'..-id..'.jpg'
		end

		if url then
			triggerServerEvent("cache:addImage", localPlayer, id, url)
		else
			--outputDebugString("[CACHE] Images / Client / addImage / Url is required parameters.")
			return 
		end
	end
end
addEvent("cache:addImage", true)
addEventHandler("cache:addImage", root, addImage)

function getImage(id)
	local url = nil
	id = validId(id)
	if not id then return false end

	if not images[id] then
		-- Check file system
		local filename = getPath(id)
		if fileExists ( filename ) then -- if yes cache to client RAM
			local file = fileOpen(filename, true)
			if file then
				local size = fileGetSize(file)
				if tonumber(size) > 0 and size <= MAX_IMAGE_BYTES then
					local content = fileRead(file, size)
					if validImageData(content) then
						images[id] = { data = content, tex = dxCreateTexture(filename)}
					else
						fileClose(file)
						fileDelete(filename)
						file = nil
					end
					-- Check if the image from client is up to date with server's.
					if file then triggerServerEvent("cache:verifyClientImageFile", localPlayer, id, size) end
					--outputDebugString("[CACHE] images / client / getImage / Verify image : "..id)
				end
				if file then fileClose(file) end
			end
		end
	end

	if id and id > 0 then
		local ply = false
		if tonumber(getElementData(localPlayer, "account:id")) == id then
			ply = localPlayer
		else
			for _, player in pairs(exports.pool:getPoolElementsByType("player")) do
				if isElement(player) and tonumber(getElementData(player, "account:id")) == id then
					ply = player
					break
				end
			end
		end
		if ply and getElementData(ply, "account:email") and getElementData(ply, "avatar") == 1  then
			url = 'https://www.gravatar.com/avatar/'..string.lower(md5(getElementData(ply,"account:email"))).."?d=404"
		end
	else
		url = 'https://owlgaming.net/assets/interiors/'..-id..'.jpg'
	end

	if images[id] then -- if image is found somewhere client side.
		if not searched[id] then searched[id] = getTickCount() end
		if refresh_rate > 0 and getTickCount() - searched[id] > 1000*60*60*refresh_rate then
			searched[id] = getTickCount()
			--outputDebugString("[CACHE] images / client / getImage / cache refreshing and requested new image from server: "..id)
			triggerServerEvent("cache:addImage", localPlayer, id, url)
		end
	else -- if image is NOT found anywhere client side.
		if url and (not searched[id] or searched[id] and getTickCount() - searched[id] > 1000*cooldown) then
			searched[id] = getTickCount()
			--outputDebugString("[CACHE] images / client / getImage / requesting image from server: "..url)
			triggerServerEvent("cache:getImage", localPlayer, id, url)
		end
	end
	return images[id]
end

function removeImage(id, remove_from_server_too)
	images[id] = nil
	--Check if this image data is already been cached in client's file system.
	local filename = getPath(id)
	if fileExists ( filename ) then -- if yes, clear it.
		fileDelete(filename) 
	end
	if remove_from_server_too then
		triggerServerEvent("cache:removeImage", localPlayer, id)
	end
	--outputDebugString("[CACHE] / Images / Client / removeImage / Done for "..id)
	return filename
end
addEvent("cache:removeImage", true)
addEventHandler("cache:removeImage", root, removeImage)

