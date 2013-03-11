//=============================================================================
// UDKMOBAPlayerReplicationInfo
//
// Player replication info which handles all of player data which needs to be 
// transferred between the server and client. Information such as the player's
// color, money and so forth.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPlayerReplicationInfo extends PlayerReplicationInfo;

// Link to the pawn replication info
var RepNotify UDKMOBAPawnReplicationInfo PawnReplicationInfo;
// Current hero that this player has selected
var ProtectedWrite RepNotify UDKMOBAHeroPawn HeroArchetype;
// How much money this player has 
var ProtectedWrite RepNotify int Money;
// How many times this player assisted with a teammates' kill
var RepNotify int Assists;
// How many times this player got the last (killing) hit on an enemy creep
var RepNotify int LastHits;
// How many times this player got the last (killing) hit on a friendly creep
var RepNotify int Denies;
// The color this player has been given - unique in the game
var ProtectedWrite RepNotify Name PlayerColor;
// Next time the player will respawn
var float NextRespawnTime;

// Replication block
replication
{
	// Replicate only if the values are dirty, this replication info is owned by the player and from server to client
	if (bNetDirty && bNetOwner)
		 Money, Assists, LastHits, Denies;

	// Replicate only if the values are dirty and from server to client
	if (bNetDirty)
		HeroArchetype, PlayerColor, PawnReplicationInfo;
}

/**
 * Called when a variable flagged as RepNotify has been replicated
 *
 * @param		VarName			Name of the variable that was replicated
 * @network						Client
 */
simulated event ReplicatedEvent(name VarName)
{
	// Money was replicated
	if (VarName == NameOf(Money))
	{
		MoneyUpdated();
	}
	// PlayerColor was replicated
	else if (VarName == NameOf(PlayerColor))
	{
		NotifyPlayerColorChanged();
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Sets the player color based on the name
 *
 * @param		NewPlayerColor		Name of the player color to use
 * @network							Server
 */
function SetPlayerColor(Name NewPlayerColor)
{
	if (NewPlayerColor != '' && NewPlayerColor != 'None')
	{
		PlayerColor = NewPlayerColor;

		// Notify that the player color has changed
		NotifyPlayerColorChanged();
	}
}

/**
 * Notification of when the player color has changed
 *
 * @network		Server and client
 */
simulated function NotifyPlayerColorChanged()
{
	local UDKMOBAHeroPawn UDKMOBAHeroPawn;

	// Early exit if this on the dedicated server
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// Notify owned hero pawn
	ForEach WorldInfo.AllPawns(class'UDKMOBAHeroPawn', UDKMOBAHeroPawn)
	{
		if (UDKMOBAHeroPawn.PlayerReplicationInfo == PawnReplicationInfo)
		{
			if (IsTimerActive(NameOf(NotifyPlayerColorChanged)))
			{
				ClearTimer(NameOf(NotifyPlayerColorChanged));
			}

			UDKMOBAHeroPawn.NotifyPlayerColorChanged();
			return;
		}
	}

	// Set up a timer in case this failed
	if (!IsTimerActive(NameOf(NotifyPlayerColorChanged)))
	{
		SetTimer(0.05f, true, NameOf(NotifyPlayerColorChanged));
	}
}

/**
 * This sets the hero archetype and automatically sets up any RPC calls that need to be made between the client and the server
 *
 * @param		NewHeroArchetype		New hero archetype to set the player to
 * @network								Server and client
 */
simulated function SetHeroArchetype(UDKMOBAHeroPawn NewHeroArchetype)
{
	// Return if NewHeroArchetype is none
	// Return if the hero has already been set
	if (NewHeroArchetype == None || HeroArchetype != None)
	{
		return;
	}

	// Sync with the server if this is the client
	if (Role < Role_Authority)
	{
		ServerSetHeroArchetype(NewHeroArchetype);
	}

	// Simulate setting the hero archetype on the client for instant response, or actually set the hero archetype on the server
	AssignHeroArchetype(NewHeroArchetype);
}

/**
 * This is called from the client, when the client wants to select a hero
 *
 * @param		NewHeroArchetype		New hero archetype to set the player to
 * @network								Server
 */
reliable server function ServerSetHeroArchetype(UDKMOBAHeroPawn NewHeroArchetype)
{
	// Never run on this function on the client
	// Return if NewHeroArchetype is none
	// Return if the hero has already been set
	if (Role < Role_Authority || NewHeroArchetype == None || HeroArchetype != None)
	{
		return;
	}

	// Actually set the hero archetype on the server
	AssignHeroArchetype(NewHeroArchetype);
}

/**
 * This is call on both the server and the client to set the hero for the player
 *
 * @param		NewHeroArchetype		New hero archetype to set the player to
 * @network								Server and client
 */
simulated function AssignHeroArchetype(UDKMOBAHeroPawn NewHeroArchetype)
{
	local UDKMOBAGameInfo UDKMOBAGameInfo;

	// Return if NewHeroArchetype is none
	// Return if the hero has already been set
	if (NewHeroArchetype == None || HeroArchetype != None)
	{
		return;
	}

	HeroArchetype = NewHeroArchetype;

	if (Role == Role_Authority)
	{
		// Notify the game info that a player has picked his/her hero
		UDKMOBAGameInfo = UDKMOBAGameInfo(WorldInfo.Game);
		if (UDKMOBAGameInfo != None)
		{
			UDKMOBAGameInfo.NotifyHeroPick();
		}
	}
}

/**
 * Modifies the amount of money, ensure that it never goes below zero
 *
 * @param		Amount		Amount of money to give, or take away if negative
 * @network					Server and client
 */
simulated function ModifyMoney(int Amount)
{
	Money = Max(Money + Amount, 0);
	MoneyUpdated();
}

/**
 * Notifies the HUD when money has been updated
 *
 * @network			All
 */
simulated function MoneyUpdated()
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	foreach WorldInfo.AllControllers(class'PlayerController', PlayerController)
	{
		UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
		if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
		{
			UDKMOBAHUD.HUDMovie.NotifyMoneyUpdated(Money);
		}
	}
}

// Default properties block
defaultproperties
{
}