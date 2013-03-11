//=============================================================================
// UDKMOBAHeroPawnReplicationInfo
//
// Replication info which handles all single hero specific data which needs to 
// be transferred between the server and client. Information such as the hero's 
// experience, death timer, and so forth.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAHeroPawnReplicationInfo extends UDKMOBAPawnReplicationInfo;

// The level of the abilities applied to the hero - if you get a level by don't 'use' it, then this lags Level by 1
var ProtectedWrite RepNotify int AppliedLevel;
// How much experience this hero has
var ProtectedWrite RepNotify int Experience;
// How long (in seconds) the hero will remain dead after a death before reviving.
var ProtectedWrite float ReviveTime;

// Replication block
replication
{
	// Replicate only if the values are dirty, this replication info is owned by the player and from server to client
	if (bNetDirty && bNetOwner)
		Experience, AppliedLevel;

	// Replicate only if the values are dirty and from server to client
	if (bNetDirty)
		ReviveTime;
}

/**
 * Returns how far through to the next level we are - 0.f is not at all (just leveled up), 1.f is have all the needed experience.
 *
 * @network		Server and client
 */
simulated function float ProgressToNextLevel()
{
	return ProgressToLevel(Level + 1);
}

/**
 * Needed to test how far you are towards the next (not necessarily 'applied') level. So if you have the experience for level 4, you can test how far to level 3 you are (1.f).
 *
 * @param		NextLevel		What level you want to test
 * @network						Server and client
 */
simulated function float ProgressToLevel(int NextLevel)
{
	local int LowerLevelXP, NextLevelXP;

	// Level 'n' requires (((the n'th triangle number) - 1) * 100) XP
	LowerLevelXP = (TriangleNumber(NextLevel - 1) - 1) * 100;
	NextLevelXP = (TriangleNumber(NextLevel) - 1) * 100;

	if (Experience < LowerLevelXP)
	{
		return 0.f;
	}
	else if (Experience > NextLevelXP)
	{
		return 1.f;
	}
	else
	{
		return (Float(Experience - LowerLevelXP) / Float(NextLevelXP - LowerLevelXP));
	}
}

/**
 * Returns the N'th Triangle Number (sum of integers from 1 to N).
 *
 * @param		N		Nth integer to use
 * @return				Returns the Nth triangle number
 * @network				Server and client
 */
simulated function int TriangleNumber(int N)
{
	return ((N * (N + 1)) / 2);
}

/**
 * Gives this hero some experience
 *
 * @param	Amount		How much hero to give to the hero
 * @network				Server and client
 */
simulated function GiveExperience(int Amount)
{
	Experience = Max(Experience + Amount, 0);

	while (ProgressToNextLevel() >= 1.f)
	{
		GainLevel();
	}
}

/**
 * Called when a hero has their level 'applied' by choosing something to upgrade.
 *
 * @network		Server and client
 */
simulated function ApplyLevel()
{
	AppliedLevel++;
}

// Default properties block
defaultproperties
{
	Level=1
	AppliedLevel=0
	ReviveTime=0.f
	ManaMax=100
}