--[[
* ***********************************************************************************************************************
* Copyright (c) 2016 OwlGaming Community - All Rights Reserved
* All rights reserved. This program and the accompanying materials are private property belongs to OwlGaming Community
* Unauthorized copying of this file, via any medium is strictly prohibited
* Proprietary and confidential
* ***********************************************************************************************************************
]]

settings = {
	client_file = 'map.xml',
	map_content_max_length = 1000000,
	external_map_max_objects = 1000,
	external_map_max_concurrent_requests = 1,
}

function getReqStatus( v )
	if v.approved == 0 then
		return 'Pending', 255, 255, 255, 200
	elseif v.approved == 2 then
		return 'Declined', 255, 0, 0, 255
	else
		if v.enabled == 1 then 
			return 'Accepted & Implemented', 0, 255, 0, 255
		else
			return 'Accepted & Disabled', 255, 0, 0, 200
		end
	end
end

function getCurrentTimeString()
	local time = getRealTime()
	return "["..time.monthday.."/"..(time.month+1).."/"..(time.year+1900).."]"
end

function canAdminMaps( player )
	return exports.integration:isPlayerScripter( player, true ) or exports.integration:isPlayerMappingTeamMember( player, true ) or exports.integration:isPlayerHeadAdmin( player, true )
end

function canAccessMgmtTab( player )
	return exports.integration:isPlayerSupporter( player, true ) or exports.integration:isPlayerTrialAdmin( player, true ) or exports.integration:isPlayerScripter( player, true ) or exports.integration:isPlayerMappingTeamMember( player, true )
end

function canEditMap( player, map, tab_id )
	local isOwner = tonumber(map.uploader) == tonumber(getElementData(player, 'account:id'))
	local isPending = not exports.map_load:isMapLoaded(map.id) and tonumber(map.approved) == 0 and tonumber(map.enabled) == 0
	if tab_id == 1 then
		return isOwner and isPending
	elseif tab_id == 3 then
		return isPending and canAdminMaps(player)
	end
	return false
end

function canDeleteMap( player, map, tab_id )
	local isOwner = tonumber(map.uploader) == tonumber(getElementData(player, 'account:id'))
	local canDelete = tonumber(map.enabled) == 0 and not exports.map_load:isMapLoaded(map.id)
	if tab_id == 1 then
		return isOwner and tonumber(map.approved) == 0 and canDelete
	elseif tab_id == 3 then
		return canDelete and canAdminMaps(player)
	end
	return false
end

function canAcceptMap( player, map, tab_id )
	return tonumber(map.approved) == 0 and tonumber(map.enabled) == 0 and canAdminMaps(player)
end

function canDeclineMap( player, map, tab_id )
	return tonumber(map.approved) == 0 and tonumber(map.enabled) == 0 and canAdminMaps(player)
end

function canImplementMap( player, map, tab_id ) 
	return tonumber(map.approved) == 1 and tonumber(map.enabled) == 0 and canAdminMaps(player)
end

function canDisableMap( player, map, tab_id )
	return tonumber(map.approved) == 1 and tonumber(map.enabled) == 1 and canAdminMaps(player)
end

local function finiteNumber(value)
	local number = tonumber(value)
	return number and number == number and number ~= math.huge and number ~= -math.huge and number or false
end

local function integerInRange(value, minimum, maximum)
	local number = finiteNumber(value)
	return number and number == math.floor(number) and number >= minimum and (not maximum or number <= maximum)
end

local function optionalNumber(value, minimum, maximum, integer)
	if value == nil then
		return true
	end
	local number = finiteNumber(value)
	return number and (not minimum or number >= minimum) and (not maximum or number <= maximum)
		and (not integer or number == math.floor(number))
end

function validateSubmittedMap(map, maxObjects)
	if type(map) ~= 'table' or not integerInRange(maxObjects, 1) then
		return false, 'Invalid map object collection.'
	end

	local objectCount = 0
	for index in pairs(map) do
		if type(index) ~= 'number' or index < 1 or index ~= math.floor(index) then
			return false, 'Map objects must use a contiguous numeric list.'
		end
		objectCount = objectCount + 1
		if objectCount > maxObjects then
			return false, 'Map exceeds the maximum object count.'
		end
	end
	if objectCount < 1 then
		return false, 'Map must contain at least one object.'
	end

	local submittedInterior, submittedDimension
	for index = 1, objectCount do
		local object = map[index]
		if type(object) ~= 'table'
			or (object.id ~= nil and (type(object.id) ~= 'string' or #object.id > 65535))
			or not integerInRange(object.interior, 0, 2147483647)
			or not optionalNumber(object.dimension, 0, 2147483647, true)
			or not optionalNumber(object.collisions, 0, 1, true)
			or not optionalNumber(object.breakable, 0, 1, true)
			or not optionalNumber(object.radius, 0)
			or not integerInRange(object.model, 1, 4294967295)
			or not optionalNumber(object.lodModel, 0, 4294967295, true)
			or not finiteNumber(object.posX) or not finiteNumber(object.posY) or not finiteNumber(object.posZ)
			or not finiteNumber(object.rotX) or not finiteNumber(object.rotY) or not finiteNumber(object.rotZ)
			or not optionalNumber(object.doublesided, 0, 1, true)
			or not optionalNumber(object.scale, 0)
			or not optionalNumber(object.alpha, 0, 255, true) then
			return false, 'Map object #'..index..' contains invalid persisted fields.'
		end

		local objectInterior = tonumber(object.interior)
		local objectDimension = tonumber(object.dimension) or 0
		if not submittedInterior then
			submittedInterior, submittedDimension = objectInterior, objectDimension
		elseif objectInterior ~= submittedInterior or objectDimension ~= submittedDimension then
			return false, 'All map objects must use the same interior and dimension.'
		end
	end

	return true
end

function processMapContent( content, max_objects, content_is_filepath )
	local map = content_is_filepath or fileCreate( settings.client_file )                -- attempt to create a new file
	result, message = false, 'Errors occurred while processing map content. Code 341'
	if map then   
		if not content_is_filepath then                                
	    	fileWrite(map, content)      
	    	fileClose(map)
	    end
	    local root = xmlLoadFile ( content_is_filepath and content or settings.client_file )
	    if root then
	    	local objects = xmlNodeGetChildren( root )
	    	if objects then
			if #objects < 1 or #objects > max_objects then
	    			result, message = false, "Your map ("..#objects.." objs) must contain at least one object and at most "..max_objects.." objects (including world object removals)."
	    		else
	    			local submit_objects = {}
	    			local int, dim
		    		for index, object in ipairs( objects ) do
		    			local submit_one_object = {}
		    			for name, value in pairs ( xmlNodeGetAttributes ( object ) ) do
					        submit_one_object[ name ] = tonumber(value) or value
					        if submit_one_object[ name ] == 'true' then
					        	submit_one_object[ name ] = 1
					        elseif submit_one_object[ name ] == 'false' then
					        	submit_one_object[ name ] = 0
					        end
					        -- validating
					        if name == 'interior' and value then
					        	if not int then
					        		int = value
					        	else
					        		if int ~= value then
					        			xmlUnloadFile( root )
					        			if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
		    							return false, 'All objects within one mapping must be in the same interior.'
		    						end
		    					end
		    				elseif name == 'dimension' and value then
		    					if not dim then
		    						dim = value
		    					else
		    						if dim ~= value then
		    							xmlUnloadFile( root )
		    							if not content_is_filepath then
		    								fileDelete( settings.client_file )
		    							end
		    							return false, 'All objects within one mapping must be in the same dimension.'
		    						end
		    					end
		    				end
					    end
					    table.insert( submit_objects, submit_one_object )
		    		end
		    		xmlUnloadFile( root )
		    		if not content_is_filepath then
		    			fileDelete( settings.client_file )
		    		end
		    		return submit_objects
		    	end
	    	else
	    		result, message = false, 'Error occurred while processing map content. Code 136.'
	    	end
	    	xmlUnloadFile( root )
	    else
	    	result, message = false, 'Error occurred while processing map content. Code 133.'
	    end
	    if not content_is_filepath then
	    	fileDelete( settings.client_file )
	    end
	end
	return result, message
end
