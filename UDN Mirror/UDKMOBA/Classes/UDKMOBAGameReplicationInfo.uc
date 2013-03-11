//=============================================================================
// UDKMOBAGameReplicationInfo
// 
// Game replication info used by UDK MOBA
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGameReplicationInfo extends GameReplicationInfo;

// The time passed in the game, to be replicated to clients
var float ServerGameTime;
// Whether or not ServerGameTime is changing - if true, ServerGameTime is replicated
var bool bGameTimeChanging;

// Replication block
replication
{
	if (bGameTimeChanging)
		ServerGameTime;
}

// Default properties block
defaultproperties
{
}