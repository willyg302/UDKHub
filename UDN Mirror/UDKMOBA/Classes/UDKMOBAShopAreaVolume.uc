//=============================================================================
// UDKMOBAShopAreaVolume
//
// Shop area volume where team members can purchase items.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAShopAreaVolume extends PhysicsVolume;

// Team num that this shop area belongs to
var() byte TeamNum;
// Upper left corner
var() Vector UpperLeftCorner;
// Lower right corner
var() Vector LowerRightCorner;

/**
 * Returns the team that this shop volume is for
 *
 * @return		Returns the team num that the level designer has set
 * @network		All
 */
simulated function byte GetTeamNum()
{
	return TeamNum;
}

// Default properties block
defaultproperties
{
	BrushColor=(R=255,G=127,B=0,A=255)
	bColored=true
}