//=============================================================================
// UDKMOBASpell_DemoGuy_MissileBarrage
//
// This is the missile barrage ability for the DemoGuy hero. This ability 
// launches missiles into the air which then rain down on the targeted area.
// Affects creeps, heros and objectives.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBASpell_DemoGuy_MissileBarrage extends UDKMOBASpell;

// Archetype to use for the missile projectile
var(MissileBarrage) const UDKMOBAProjectile_MissileBarrage_Missile MissileProjectileArchetype;
// How many missiles to launch per level
var(MissileBarrage) const array<int> MissileAmount;

// Counter of how many missiles have been launched
var ProtectedWrite int MissilesLaunched;
// Current target location for the missiles
var ProtectedWrite Vector MissionTargetLocation;

/**
 * Launches the missiles
 *
 * @network		Server and client
 */
protected simulated function PerformCast()
{
	// Only launch the missiles on the server
	if (Role == Role_Authority && !IsTimerActive(NameOf(LaunchMissileTimer)))
	{
		MissilesLaunched = 0;
		MissionTargetLocation = TargetLocation;
		SetTimer(0.05f, true, NameOf(LaunchMissileTimer));
	}
}

/**
 * Returns how many missiles should be launched
 *
 * @return		Returns how many missiles should be launched
 */
simulated function int GetMissileCount()
{
	if (MissileAmount.Length == 0)
	{
		return 1;
	}

	if (Level < 0)
	{
		return 0;
	}

	if (MissileAmount.Length <= Level)
	{
		// undefined - return best estimate
		return MissileAmount[MissileAmount.Length - 1];
	}

	return MissileAmount[Level];
}

/**
 * Launches the missiles which is usually called via a timer
 */
function LaunchMissileTimer()
{
	local UDKMOBAProjectile_MissileBarrage_Missile UDKMOBAProjectile_MissileBarrage_Missile;

	// Spawn the missile
	UDKMOBAProjectile_MissileBarrage_Missile = PawnOwner.Spawn(MissileProjectileArchetype.Class,,, PawnOwner.Location,, MissileProjectileArchetype);
	if (UDKMOBAProjectile_MissileBarrage_Missile != None)
	{
		// Set the spell owner
		UDKMOBAProjectile_MissileBarrage_Missile.SpellOwner = Self;
		// Set the attack owner
		UDKMOBAProjectile_MissileBarrage_Missile.OwnerAttackInterface = UDKMOBAAttackInterface(PawnOwner);
		// Set the target location
		UDKMOBAProjectile_MissileBarrage_Missile.TargetLocation = MissionTargetLocation + Vect(1.f, 0.f, 0.f) * RandRange(0.f, 256.f) + Vect(0.f, 1.f, 0.f) * RandRange(0.f, 256.f);
		// Send the projectile flying
		UDKMOBAProjectile_MissileBarrage_Missile.Init(VRandCone(Vect(0.f, 0.f, 1.f), Pi * 0.25f));
	}

	// Count how many missiles have been launched
	MissilesLaunched++;
	// Clear the timer if the amount of missiles have been launched
	if (MissilesLaunched >= GetMissileCount())
	{
		ClearTimer(NameOf(LaunchMissileTimer));
	}
}

// Default properties block
defaultproperties
{
	MissileAmount(0)=3
	MissileAmount(1)=5
	MissileAmount(2)=7
	MissileAmount(3)=10
}