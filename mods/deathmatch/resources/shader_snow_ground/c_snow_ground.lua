--
-- c_snow_ground.lua
--

--[[
local helpMessage = "F7 to turn off ground snow"
local helpMessageTime = 4000
local helpMessageY = 0.2]]

local bEffectEnabled
local snowShader
local treeShader
local naughtyTreeShader
local sNoiseTexture
local vehTimer
local doneVehTexRemove = {}
local lastveh, lastid
local checkCurrentVehicle, removeVehTexturesSoon, removeVehTextures

----------------------------------------------------------------
----------------------------------------------------------------
-- Effect switching on and off
----------------------------------------------------------------
----------------------------------------------------------------

--------------------------------
-- onClientResourceStart
--		Auto switch on at start
--------------------------------
addEventHandler( "onClientResourceStart", resourceRoot,
	function()
		triggerEvent( "switchGoundSnow", resourceRoot, true )
	end
)

--------------------------------
-- Command handler
--		Toggle via command
--------------------------------
function toggleGoundSnow()
	triggerEvent( "switchGoundSnow", resourceRoot, not bEffectEnabled )
end
addCommandHandler('groundsnow',toggleGoundSnow)
--addCommandHandler('Toggle ground snow',toggleGoundSnow)
--bindKey("F7","down","Toggle ground snow")


--------------------------------
-- Switch effect on or off
--------------------------------
local checkInteriorAgainTimer
function switchGoundSnow( bOn )
	--outputDebugString("switchGoundSnow("..tostring(bOn)..")")
	if checkInteriorAgainTimer then
		if isTimer(checkInteriorAgainTimer) then
			killTimer(checkInteriorAgainTimer)
		end
		checkInteriorAgainTimer = nil
	end
	if bOn then
		local userSetting = getElementData(localPlayer, "groundsnow")
		if not userSetting or userSetting ~= "0" then
			local interior = getElementInterior(localPlayer)
			if interior == 0 then
				enableGoundSnow()
			else
				--outputDebugString("bypass: interior")
				checkInteriorAgainTimer = setTimer(checkInteriorAgain, 5000, 1)
			end
		else
			--outputDebugString("bypass: setting")
		end
	else
		disableGoundSnow()
	end
end
addEvent( "switchGoundSnow", true )
addEventHandler( "switchGoundSnow", getRootElement(), switchGoundSnow )

function checkInteriorAgain()
	local interior = getElementInterior(localPlayer)
	if interior == 0 then
		local userSetting = getElementData(localPlayer, "groundsnow")
		if not userSetting or userSetting ~= "0" then
			enableGoundSnow()
		else
			--outputDebugString("bypass: setting")
		end
	else
		--outputDebugString("bypass: interior")
	end
	if isTimer(checkInteriorAgainTimer) then
		killTimer(checkInteriorAgainTimer)
	end
	checkInteriorAgainTimer = nil
end

----------------------------------------------------------------
----------------------------------------------------------------
-- Effect clever stuff
----------------------------------------------------------------
----------------------------------------------------------------
local maxEffectDistance = 250		-- To speed up the shader, don't use it for objects further away than this

-- List of world texture name matches
-- (The ones later in the list will take priority) 
local snowApplyList = {
						"*",				-- Everything!
				}

-- List of world textures to exclude from this effect
local snowRemoveList = {
						"",	"unnamed",									-- unnamed

						"vehicle*", "?emap*", "?hite*",					-- vehicles
						"*92*", "*wheel*", "*interior*",				-- vehicles
						"*handle*", "*body*", "*decal*",				-- vehicles
						"*8bit*", "*logos*", "*badge*",					-- vehicles
						"*plate*", "*sign*",							-- vehicles
						"headlight", "headlight1",						-- vehicles

						"shad*",										-- shadows
						"coronastar",									-- coronas
						"tx*",											-- grass effect
						"lod*",											-- lod models
						"cj_w_grad",									-- checkpoint texture
						"*cloud*",										-- clouds
						"*smoke*",										-- smoke
						"sphere_cj",									-- nitro heat haze mask
						"particle*",									-- particle skid and maybe others
						"*water*", "sw_sand", "coral",					-- sea
						"radardisc", "radar*",
						"blugrad32", "greengrad32", "lyellow32", "redgrad32", "skull", --pickups
					}

local treeApplyList = {
						"sm_des_bush*", "*tree*", "*ivy*", "*pine*",	-- trees and shrubs
						"veg_*", "*largefur*", "hazelbr*", "weeelm",
						"*branch*", "cypress*",
						"*bark*", "gen_log", "trunk5",
						"bchamae", "vegaspalm01_128",

	}

local naughtyTreeApplyList = {
						"planta256", "sm_josh_leaf", "kbtree4_test", "trunk3",					-- naughty trees and shrubs
						"newtreeleaves128", "ashbrnch", "pinelo128", "tree19mi",
						"lod_largefurs07", "veg_largefurs05","veg_largefurs06",
						"fuzzyplant256", "foliage256", "cypress1", "cypress2",
	}

--------------------------------
-- Switch effect on
--------------------------------
function enableGoundSnow()
	if bEffectEnabled then return end
	-- Version check
	if getVersion ().sortable < "1.1.1-9.03285" then
		outputChatBox( "Resource is not compatible with this client." )
		return
	end

	-- Keep allocations local until the full shader set is ready. A failed DX
	-- allocation or uniform update must not strand earlier elements.
	local created = {}
	local function createShader(path, priority, distance)
		local shader = dxCreateShader(path, priority, distance)
		if shader then
			table.insert(created, shader)
		else
			outputDebugString("[shader_snow_ground] Failed to create shader: " .. path, 2)
		end
		return shader
	end
	local function createTexture(path)
		local texture = dxCreateTexture(path)
		if texture then
			table.insert(created, texture)
		else
			outputDebugString("[shader_snow_ground] Failed to create texture: " .. path, 2)
		end
		return texture
	end
	local function releaseCreated()
		for _, element in ipairs(created) do
			if isElement(element) then
				destroyElement(element)
			end
		end
	end

	local newSnowShader = createShader("snow_ground.fx", 0, maxEffectDistance)
	local newTreeShader = createShader("snow_trees.fx")
	local newNaughtyTreeShader = createShader("snow_naughty_trees.fx")
	local newNoiseTexture = createTexture("smallnoise3d.dds")
	if not newSnowShader or not newTreeShader or not newNaughtyTreeShader or not newNoiseTexture then
		releaseCreated()
		return false
	end

	local uniforms = {
		{ newTreeShader, "sNoiseTexture", newNoiseTexture },
		{ newNaughtyTreeShader, "sNoiseTexture", newNoiseTexture },
		{ newSnowShader, "sNoiseTexture", newNoiseTexture },
		{ newSnowShader, "sFadeEnd", maxEffectDistance },
		{ newSnowShader, "sFadeStart", maxEffectDistance / 2 },
	}
	for _, uniform in ipairs(uniforms) do
		if not dxSetShaderValue(uniform[1], uniform[2], uniform[3]) then
			outputDebugString("[shader_snow_ground] Failed to set shader value: " .. uniform[2], 2)
			releaseCreated()
			return false
		end
	end

	snowShader = newSnowShader
	treeShader = newTreeShader
	naughtyTreeShader = newNaughtyTreeShader
	sNoiseTexture = newNoiseTexture

	local function applyPatterns(shader, patterns, label)
		local failedPatterns = {}
		for _, pattern in ipairs(patterns) do
			if not engineApplyShaderToWorldTexture(shader, pattern) then
				table.insert(failedPatterns, pattern)
			end
		end
		if #failedPatterns > 0 then
			outputDebugString("[shader_snow_ground] Failed to apply " .. label .. " to texture pattern(s): " .. table.concat(failedPatterns, ", "), 2)
		end
	end

	-- Process snow apply list
	applyPatterns(snowShader, snowApplyList, "ground shader")

	-- Process snow remove list
	for _,removeMatch in ipairs(snowRemoveList) do
		engineRemoveShaderFromWorldTexture ( snowShader, removeMatch )
	end

	-- Process tree apply list
	applyPatterns(treeShader, treeApplyList, "tree shader")

	-- Process naughty tree apply list
	applyPatterns(naughtyTreeShader, naughtyTreeApplyList, "alternate tree shader")

	-- Init vehicle checker
	doneVehTexRemove = {}
	vehTimer = setTimer( checkCurrentVehicle, 100, 0 )
	if not vehTimer then
		outputDebugString("[shader_snow_ground] Failed to start vehicle texture cleanup timer", 2)
		disableGoundSnow()
		return false
	end
	removeVehTextures()

	-- Flag effect as running
	bEffectEnabled = true

	--showHelp()
end

--------------------------------
-- Switch effect off
--------------------------------
function disableGoundSnow()
	if not bEffectEnabled and not snowShader and not treeShader and not naughtyTreeShader and not sNoiseTexture then return end

	-- Remove world associations before destroying the DX elements. This also
	-- makes cleanup safe if initialization was interrupted after allocation.
	if snowShader then
		for _, match in ipairs(snowApplyList) do
			engineRemoveShaderFromWorldTexture(snowShader, match)
		end
	end
	if treeShader then
		for _, match in ipairs(treeApplyList) do
			engineRemoveShaderFromWorldTexture(treeShader, match)
		end
	end
	if naughtyTreeShader then
		for _, match in ipairs(naughtyTreeApplyList) do
			engineRemoveShaderFromWorldTexture(naughtyTreeShader, match)
		end
	end

	-- Destroy all elements
	if sNoiseTexture and isElement(sNoiseTexture) then destroyElement(sNoiseTexture) end
	if treeShader and isElement(treeShader) then destroyElement(treeShader) end
	if naughtyTreeShader and isElement(naughtyTreeShader) then destroyElement(naughtyTreeShader) end
	if snowShader and isElement(snowShader) then destroyElement(snowShader) end
	if isTimer(vehTimer) then
		killTimer(vehTimer)
	end
	sNoiseTexture, treeShader, naughtyTreeShader, snowShader = nil, nil, nil, nil
	vehTimer = nil
	doneVehTexRemove = {}
	lastveh, lastid = nil, nil

	-- Flag effect as stopped
	bEffectEnabled = false
end


----------------------------------------------------------------
-- removeVehTextures
--		Keep effect off vehicles
----------------------------------------------------------------
local nextCheckTime = 0
local bHasFastRemove = getVersion().sortable > "1.1.1-9.03285"

addEventHandler( "onClientPlayerVehicleEnter", root,
	function()
		removeVehTexturesSoon ()
	end
)

-- Called every 100ms
checkCurrentVehicle = function ()
	local veh = getPedOccupiedVehicle(localPlayer)
	local id = veh and getElementModel(veh)
	if lastveh ~= veh or lastid ~= id then
		lastveh = veh
		lastid = id
		removeVehTexturesSoon()
	end
	if nextCheckTime < getTickCount() then
		nextCheckTime = getTickCount() + 5000
		removeVehTextures()
	end
end

-- Called the players current vehicle need processing
removeVehTexturesSoon = function ()
	nextCheckTime = getTickCount() + 200
end

-- Remove textures from players vehicle from effect
removeVehTextures = function ()
	if not bHasFastRemove then return end
	if not snowShader then return end

	local veh = getPedOccupiedVehicle(localPlayer)
	if veh then
		local id = getElementModel(veh)
		local vis = engineGetVisibleTextureNames("*",id)
		-- For each texture
		if vis then	
			for _,removeMatch in pairs(vis) do
				-- Remove for each shader
				if not doneVehTexRemove[removeMatch] then
					doneVehTexRemove[removeMatch] = true
					engineRemoveShaderFromWorldTexture ( snowShader, removeMatch )
				end
			end
		end
	end
end


----------------------------------------------------------------
-- Help message
----------------------------------------------------------------
--[[
function showHelp()
	if bShowHelp ~= nil then return end
	bShowHelp = true
	helpStartTime = getTickCount()
	setTimer( function() bShowHelp=false end, helpMessageTime, 1 )
end

addEventHandler( "onClientRender", root,
	function ()
		if bShowHelp then
			local age = getTickCount() - helpStartTime
			if ( age > helpMessageTime - 256 ) then
				age = helpMessageTime - age
			end
			age = math.min(math.max(0,age),255)
			local sx, sy = guiGetScreenSize()
			dxDrawText(helpMessage, sx/2-3, sy*helpMessageY, sx/2+2, 0, tocolor(0, 0, 0, age), 3, 'default', 'center' )
			dxDrawText(helpMessage, sx/2+3, sy*helpMessageY, sx/2+2, 0, tocolor(0, 0, 0, age), 3, 'default', 'center' )
			dxDrawText(helpMessage, sx/2, sy*helpMessageY, sx/2, 0, tocolor(255, 255, 0, age), 3, 'default', 'center' )
		end
	end
)
]]

----------------------------------------------------------------
-- Unhealthy hacks
----------------------------------------------------------------
_dxCreateShader = dxCreateShader
function dxCreateShader( filepath, priority, maxDistance, bDebug )
	priority = priority or 0
	maxDistance = maxDistance or 0
	bDebug = bDebug or false

	-- Slight hack - maxEffectDistance doesn't work properly before build 3236 if fullscreen
	local build = getVersion ().sortable:sub(9)
	local fullscreen = not dxGetStatus ().SettingWindowed
	if build < "03236" and fullscreen then
		maxDistance = 0
	end

	return _dxCreateShader ( filepath, priority, maxDistance, bDebug )
end

----------------------------------------------------------------
-- SLIPPERY ROADS / SNOW TIRES
----------------------------------------------------------------
local snowTireID = 212

function applySlippery(vehicle, hasSnowTire)
	local thisVehicle = getPedOccupiedVehicle(localPlayer)
	if(vehicle ~= thisVehicle) then return end
	if not hasSnowTire then
		local model = getElementModel(vehicle)
		if model == 598 or model == 596 or model == 597 or model == 599 or model == 490 then -- Police cars
			setGravity ( 0.0070 )
		elseif model == 554 or model == 572 or model == 579 or model == 400 or model == 404 or model == 489 or model == 505 or model == 470 then
			setGravity ( 0.0050 )
		elseif model == 429 or model == 541 or model == 415 or model == 480 or model == 562 or model == 565 or model == 434 or model == 494 or model == 502 or model == 503 or model == 401 or model == 559 or model == 561 or model == 560 or model == 506 or model == 451 or model == 558 or model == 555 or model == 477 then
			setGravity ( 0.004 )
		else
			setGravity ( 0.0045 )
		end
	end
	
	local vType = getVehicleType(vehicle) 
	local editingMode = getElementData(vehicle, "isTestDriveCar")
	local jobVeh = getElementData(vehicle, "job") or 0 
	
	if hasSnowTire or vType == "Plane" or vType == "Helicopter" or vType == "Boat" or vType == "Train" or editingMode or jobVeh > 0 then
		setGravity( 0.008 )
	end
end
addEvent("shader_snow_ground:applySlippery", true)
addEventHandler("shader_snow_ground:applySlippery", root, applySlippery)

addEventHandler("onClientVehicleExit", root,
	function(thePlayer, seat)
		if thePlayer == getLocalPlayer() then
			setGravity ( 0.008 )
		end
	end
)
function resetGravity()
	if not getPedOccupiedVehicle(getLocalPlayer()) then --or exports.global:hasItem(getPedOccupiedVehicle(localPlayer), snowTireID) then
		setGravity( 0.008 )
	end
end
setTimer(resetGravity, 4000, 0)

function resetGravityOnResourceStop(res)
	setGravity( 0.008 )
end
addEventHandler("onClientResourceStop", resourceRoot, resetGravityOnResourceStop)
