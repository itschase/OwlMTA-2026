--MAXIME / 2015.1.8

function canPlayerAccessStaffManager(player)
	-- Donator status does not grant access to staff tools.
	return exports.integration:isPlayerTrialAdmin(player)
		or exports.integration:isPlayerVCTMember(player)
		or exports.integration:isPlayerLeadScripter(player)
		or exports.integration:isPlayerMappingTeamLeader(player)
		or exports.integration:isPlayerFMTLeader(player)
end

