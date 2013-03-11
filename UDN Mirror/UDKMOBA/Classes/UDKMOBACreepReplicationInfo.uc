class UDKMOBACreepReplicationInfo extends UDKMOBAPawnReplicationInfo;

/**
 */
simulated function bool ShouldBroadCastWelcomeMessage(optional bool bExiting)
{
	// Never broadcast welcome message
	return false;
}

defaultproperties
{
}