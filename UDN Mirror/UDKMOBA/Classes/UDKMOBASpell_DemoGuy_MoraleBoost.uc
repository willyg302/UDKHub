//=============================================================================
// UDKMOBASpell_DemoGuy_MoraleBoost
//
// This is the morale boost passive ability for the DemoGuy hero. This ability
// adds a buff to creeps and heroes by making their armor, damage and speed
// a little faster.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBASpell_DemoGuy_MoraleBoost extends UDKMOBASpell;

// Dynamic decal component; only used on the PC platform
var(MoraleBoost) const DecalComponent DecalComponent;

/**
 * Initializes the spell
 *
 * @network			Server and client
 */
simulated function Initialize()
{
	Super.Initialize();

	// Abort if the pawn owner is none
	if (PawnOwner == None)
	{
		return;
	}

	// Attach the decal to the pawn on the PC platform
	if (class'UDKMOBAGameInfo'.static.GetPlatform() == P_PC)
	{
		if (DecalComponent != None)
		{
			PawnOwner.AttachComponent(DecalComponent);
		}
	}
}

defaultproperties
{
	Begin Object Class=DecalComponent Name=MyDecalComponent
		DecalTransform=DecalTransform_OwnerRelative
		bMovableDecal=true
	End Object
	DecalComponent=MyDecalComponent
}