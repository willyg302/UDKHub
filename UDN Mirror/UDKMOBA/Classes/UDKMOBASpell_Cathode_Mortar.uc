//=============================================================================
// UDKMOBASpell_Cathode_Mortar
//
// This is the mortar ability for the Cathode hero. This causes cathode to
// lobb a projectile which then explodes on the ground causing knock back,
// damage and a stun.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBASpell_Cathode_Mortar extends UDKMOBASpell;

// Archetype to use for the missile projectile
var(MissileBarrage) const UDKMOBAProjectile_Mortar_Shell MortarProjectileArchetype;

/**
 * Launches the mortar
 *
 * @network		Server and client
 */
protected simulated function PerformCast()
{
	// Only launch the mortar on the server
	if (Role == Role_Authority)
	{
	}
}

// Default properties block
defaultproperties
{
}