local images = { }
local searched = {}
local refresh_rate = 0 --hours , 0 = never recache.
local default_avatar_size = 0
local MAX_IMAGE_BYTES = 2 * 1024 * 1024
local MAX_CACHE_BYTES = 32 * 1024 * 1024
local MAX_CACHE_ENTRIES = 512
local MAX_PENDING_FETCHES = 32
local MAX_PENDING_FETCHES_PER_PLAYER = 4
local pending_fetches = {}
local pending_fetch_count = 0
local pending_fetches_by_player = {}
local cache_sizes = {}
local cache_entry_count = 0
local cache_total_bytes = 0
local cache_index_path = 'images_cache/index.txt'

local function validId(id)
	local number = tonumber(id)
	return number and number == math.floor(number) and number ~= 0 and math.abs(number) <= 2147483647 and number
end

local function validImageUrl(id, url)
	if type(url) ~= 'string' or #url > 256 then
		return false
	end

	if id > 0 then
		local hash = url:match('^https://www%.gravatar%.com/avatar/([0-9a-fA-F]+)%?d=404$')
		return hash and #hash == 32
	end

	local interiorId = url:match('^https://owlgaming%.net/assets/interiors/(%d+)%.jpg$')
	return interiorId and tonumber(interiorId) == -id
end

-- The client call sites establish these URL formats, but they do not provide a
-- server-verifiable account-to-Gravatar mapping for offline accounts. Numeric IDs
-- and host/path validation bound the input; URL ownership remains unresolved.

local function validImageData(data)
	if type(data) ~= 'string' or #data == 0 or #data > MAX_IMAGE_BYTES then
		return false
	end

	-- The active callers request JPEGs and Gravatar images. This resource's legacy
	-- fetchRemote form does not return headers, cap bytes while downloading, or let
	-- this call constrain redirects, so validate the received payload before cache.
	return data:sub(1, 3) == '\255\216\255' or data:sub(1, 8) == '\137PNG\r\n\26\n'
end

local function saveCacheIndex()
	local file = fileCreate(cache_index_path)
	if not file then return false end
	for id, size in pairs(cache_sizes) do
		fileWrite(file, tostring(id), '\t', tostring(size), '\n')
	end
	fileClose(file)
	return true
end

local function loadCacheIndex()
	-- Legacy cache files without an index are accounted for when their IDs are read.
	-- MTA's resource file API has no directory enumeration for a one-time migration.
	if not fileExists(cache_index_path) then return end
	local file = fileOpen(cache_index_path, true)
	if not file then return end
	local size = fileGetSize(file)
	local contents = size and size > 0 and fileRead(file, size) or ''
	fileClose(file)
	for line in tostring(contents):gmatch('[^\r\n]+') do
		local id, bytes = line:match('^(-?%d+)\t(%d+)$')
		id, bytes = tonumber(id), tonumber(bytes)
		if id and id ~= 0 and bytes and bytes > 0 and bytes <= MAX_IMAGE_BYTES
			and cache_entry_count < MAX_CACHE_ENTRIES and cache_total_bytes + bytes <= MAX_CACHE_BYTES then
			cache_sizes[id] = bytes
			cache_entry_count = cache_entry_count + 1
			cache_total_bytes = cache_total_bytes + bytes
		end
	end
end

loadCacheIndex()

local function trackExistingFile(id, size)
	if cache_sizes[id] then return true end
	if not size or size <= 0 or size > MAX_IMAGE_BYTES or cache_entry_count >= MAX_CACHE_ENTRIES
		or cache_total_bytes + size > MAX_CACHE_BYTES then
		return false
	end
	cache_sizes[id] = size
	cache_entry_count = cache_entry_count + 1
	cache_total_bytes = cache_total_bytes + size
	saveCacheIndex()
	return true
end

local function untrackFile(id)
	local oldSize = cache_sizes[id]
	if not oldSize then return end
	cache_sizes[id] = nil
	cache_entry_count = math.max(0, cache_entry_count - 1)
	cache_total_bytes = math.max(0, cache_total_bytes - oldSize)
	saveCacheIndex()
end

local function addPendingClient(request, player)
	if not player then return true end
	if request.clients[player] then return true end
	local count = pending_fetches_by_player[player] or 0
	if count >= MAX_PENDING_FETCHES_PER_PLAYER then return false end
	request.clients[player] = true
	pending_fetches_by_player[player] = count + 1
	return true
end

local function releasePendingClients(request)
	if not request then return end
	for player in pairs(request.clients) do
		local count = (pending_fetches_by_player[player] or 1) - 1
		pending_fetches_by_player[player] = count > 0 and count or nil
	end
end

local function getPath(url)
	return 'images_cache/' .. md5(tostring(url)) .. '.tex'
end

local function queueImageFetch(id, url, requester)
	if not validImageUrl(id, url) then return false end
	if requester and (not isElement(requester) or getElementType(requester) ~= 'player') then return false end

	local request = pending_fetches[id]
	if request then
		if request.url ~= url then return false end
		return addPendingClient(request, requester)
	end
	if pending_fetch_count >= MAX_PENDING_FETCHES then return false end

	request = { url = url, clients = {} }
	if not addPendingClient(request, requester) then return false end
	pending_fetch_count = pending_fetch_count + 1
	pending_fetches[id] = request
	local requestHandle = fetchRemote(url, "cache/images", 1, addImageAsync, "", true, url, id)
	if not requestHandle then
		pending_fetches[id] = nil
		pending_fetch_count = math.max(0, pending_fetch_count - 1)
		releasePendingClients(request)
		return false
	end
	return true
end

-- Leave 'data' parameter empty if you intend to add a new image from URL.
-- Maxime / 2015.6.28
function addImage(id, url, data)
	id = validId(id)
	if not id then
		return
	end
	if client and (not isElement(client) or getElementType(client) ~= 'player' or source ~= client or data ~= nil) then
		return
	end

	if data then
		if not validImageData(data) then return end
		local filename = getPath(id)
		local oldSize = cache_sizes[id]
		local isTracked = oldSize ~= nil
		if not oldSize and fileExists(filename) then
			local oldFile = fileOpen(filename, true)
			if oldFile then
				oldSize = fileGetSize(oldFile)
				fileClose(oldFile)
			end
			if oldSize and not trackExistingFile(id, oldSize) then
				fileDelete(filename)
				oldSize = nil
			end
			isTracked = oldSize ~= nil
		end
		oldSize = oldSize or 0
		if not isTracked and (cache_entry_count >= MAX_CACHE_ENTRIES or cache_total_bytes + #data > MAX_CACHE_BYTES) then
			return
		elseif cache_total_bytes - oldSize + #data > MAX_CACHE_BYTES then
			return
		end
		-- Replace the existing file while keeping the cache quota accounting intact.
		if fileExists(filename) then fileDelete(filename) end

		local file = fileCreate(filename)
		if not file then
			images[id] = nil
			untrackFile(id)
			return false
		end
		local size = fileWrite(file, data)
		fileClose(file)
		if size == #data then
			images[id] = data
			cache_sizes[id] = size
			if not isTracked then cache_entry_count = cache_entry_count + 1 end
			cache_total_bytes = cache_total_bytes - oldSize + size
			saveCacheIndex()
			outputDebugString("[CACHE] Images / Server / addImage / Cached image - "..id.." in server's file system as '"..filename.."'.Total: "..exports.global:formatMoney(math.floor(size/1000)).."KB")
			return true
		else
			fileDelete(filename)
			images[id] = nil
			untrackFile(id)
			outputDebugString("[CACHE] Images / Server / addImage / Couln't cache image - "..id.." in server's file system.")
			return false
		end
	else
		return queueImageFetch(id, url, client)
	end
end
addEvent("cache:addImage", true)
addEventHandler("cache:addImage", root, addImage)

local function sendImageToClient(client_to_sync, id, data)
	-- would be a disater of source is nil, it would send to all clients, we don't want that.
	if client_to_sync and isElement(client_to_sync) and getElementType(client_to_sync) == 'player' then
		if triggerLatentClientEvent(client_to_sync, "cache:addImage", 50000, false, client_to_sync, id, data) then
			--outputDebugString("[CACHE] Images / Server / sendImageToClient / Sending image data to "..getPlayerName(client_to_sync).." limited at 50KB/s - "..tostring(id))
			return true
		end
	end
end

function addImageAsync(data, errno, url, id)
	local request = pending_fetches[id]
	pending_fetches[id] = nil
	pending_fetch_count = math.max(0, pending_fetch_count - 1)
	releasePendingClients(request)
	if errno == 0 then
		if validImageUrl(id, url) and validImageData(data) then
			local cached = addImage(id, url, data)
			if cached and request then
				for client_to_sync in pairs(request.clients) do
					sendImageToClient(client_to_sync, id, data)
				end
			end
			if cached then searched[id] = getTickCount() end
		end
	else
		--outputDebugString("[CACHE] Images / Server / addImageAsync / Couldn't fetch image - "..tostring(id)..". Error Code: "..errno)
	end
end

function getImage(id, url)
	id = validId(id)
	if not id or (client and (not isElement(client) or getElementType(client) ~= 'player' or source ~= client)) then
		return false
	end
	local requester = client
	if not requester and source and isElement(source) and getElementType(source) == 'player' then
		-- A server-originated event may deliberately target a player source. Remote
		-- requests always use the authenticated MTA client validated above instead.
		requester = source
	end
	if not images[id] then
		-- Check file system
		local filename = getPath(id)
		if fileExists ( filename ) then
			local file = fileOpen(filename, true)
			if file then
				local size = fileGetSize(file)
				if tonumber(size) > 0 and size <= MAX_IMAGE_BYTES and trackExistingFile(id, size) then
					local data = fileRead(file, size)
					if validImageData(data) then
						images[id] = data
					else
						fileClose(file)
						file = nil
						fileDelete(filename)
						untrackFile(id)
					end
					-- Check if the image from server is up to date with id's.
					if file then verifyServerImageFile(id, url, size) end
				else
					fileClose(file)
					file = nil
					fileDelete(filename)
					untrackFile(id)
				end
				if file then fileClose(file) end
			end
		end
	end

	-- if image is found somewhere on server .
	if images[id] then
		-- if image is older than refresh_rate, fetch it from id again to recache.
		local recached = false
		if searched[id] and refresh_rate > 0 and getTickCount() - searched[id] > 1000*60*60*refresh_rate then
			--outputDebugString("[CACHE] images / Server / getImage / cache refreshing and requested new image from server: "..id)
			-- Recache on server and also sent the file to client to recache client side for the player that requested for it.
			recached = queueImageFetch(id, url, requester)
		end
		-- Send the current image to client who requested for this.
		if not recached then
			sendImageToClient(requester, id, images[id])
		end
	else -- if image is NOT found anywhere on server, fetch it from URL again then send to client who requested it.
		--outputDebugString("[CACHE] images / Server / getImage / fetching image from URL: "..url)
		queueImageFetch(id, url, requester)
	end
	return images[id]
end
addEvent("cache:getImage", true)
addEventHandler("cache:getImage", root, getImage)

function verifyClientImageFile(id, size)
	id = validId(id)
	size = tonumber(size)
	if not id or not size or size ~= math.floor(size) or size < 0 or size > MAX_IMAGE_BYTES
		or not client or not isElement(client) or getElementType(client) ~= 'player' or source ~= client then
		return false
	end
	local filename = getPath(id)
	if fileExists ( filename ) then
		local file = fileOpen(filename, true)
		if file then
			local sizeServer = fileGetSize(file)
			if not sizeServer or sizeServer <= 0 or sizeServer > MAX_IMAGE_BYTES then
				fileClose(file)
				images[id] = nil
				fileDelete(filename)
				untrackFile(id)
				triggerClientEvent(source, "cache:removeImage", source, id)
				return false
			else
				if not images[id] then
					local data = fileRead(file, sizeServer)
					if validImageData(data) then images[id] = data end
				end
				if not images[id] then
					fileClose(file)
					fileDelete(filename)
					untrackFile(id)
					triggerClientEvent(source, "cache:removeImage", source, id)
					return false
				elseif size ~= sizeServer then
					sendImageToClient(source, id, images[id])
				end
				--outputDebugString("[CACHE] Images / Server / verifyClientImageFile / Sending new image data to "..getPlayerName(source))
			end
			fileClose(file)
		end
	else -- if file doesn't exist on server, it shouldn't be on client.
		images[id] = nil
		triggerClientEvent(source, "cache:removeImage", source, id)
	end
end
addEvent("cache:verifyClientImageFile", true)
addEventHandler("cache:verifyClientImageFile", root, verifyClientImageFile)

function verifyServerImageFile(id, url, size)
	id = validId(id)
	if not id or not validImageUrl(id, url) then return false end
	-- There will be no URL sent to the server if the user is offline so keep the cached image
	if url then
		addImage(id, url)
	end
end

function removeImage(id, remove_from_client_too)
	id = validId(id)
	if not id then return false end
	if client and (not isElement(client) or getElementType(client) ~= 'player' or source ~= client) then return false end
	if client and tonumber(getElementData(client, 'account:id')) ~= id then return false end
	images[id] = nil
	--Check if this image data is already been cached in server's file system.
	local filename = getPath(id)
	if fileExists ( filename ) then -- if yes, clear it.
		fileDelete(filename)
	end
	untrackFile(id)
	if remove_from_client_too and source and getElementType(source) == 'player' then
		triggerClientEvent(source, "cache:removeImage", source, id)
	end
	--outputDebugString("[CACHE] / images / server / removeImage / Requested by "..(source and getPlayerName(source) or "SYSTEM")..", Done for "..id)
	return filename
end
addEvent("cache:removeImage", true)
addEventHandler("cache:removeImage", root, removeImage)
