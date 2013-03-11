//=============================================================================
// UDKMOBACheatManager
//
// Cheat manager which handles all of the cheats in the game.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACheatManager extends CheatManager;

/**
 * God console command which makes the players hero invulnerable to all damage
 *
 * @network			Standalone
 */
exec function God()
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	Super.God();

	// Grab the UDKMOBAPlayerController, abort if the player controller, hero pawn or the hero pawn's is none
	UDKMOBAPlayerController = UDKMOBAPlayerController(Outer);
	if (UDKMOBAPlayerController == None || UDKMOBAPlayerController.HeroPawn == None || UDKMOBAPlayerController.HeroPawn.Controller == None)
	{
		return;
	}

	// Forward the bGodMode value
	UDKMOBAPlayerController.HeroPawn.Controller.bGodMode = bGodMode;
}

/**
 * Cheat code to give XP to the player controller. This is synchronized with the server
 *
 * @param		XPGain		How much experience to give to the player
 * @network					Server and local client
 */
exec function GiveXP(int XPGain)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	// Grab the UDKMOBAPlayerController
	UDKMOBAPlayerController = UDKMOBAPlayerController(Outer);
	if (UDKMOBAPlayerController == None || UDKMOBAPlayerController.HeroPawn == None)
	{
		return;
	}

	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAPlayerController.HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo != None)
	{
		UDKMOBAHeroPawnReplicationInfo.GiveExperience(XPGain);
	}
}

/**
 * Cheat code to give money to the player controller. This is synchronized with the server
 *
 * @param		Amount		How much money to give to the player
 * @network					Server and local client
 */
exec function GiveMoney(int Amount)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	// Grab the UDKMOBAPlayerController
	UDKMOBAPlayerController = UDKMOBAPlayerController(Outer);
	if (UDKMOBAPlayerController == None)
	{
		return;
	}

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(UDKMOBAPlayerController.PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None)
	{
		UDKMOBAPlayerReplicationInfo.ModifyMoney(Amount);
	}
}

// Default properties block
defaultproperties
{
}