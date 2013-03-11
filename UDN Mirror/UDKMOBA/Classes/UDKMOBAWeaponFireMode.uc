//=============================================================================
// UDKMOBAWeaponConeFireMode
//
// Weapon fire mode which uses a cone detection to deal damage to enemies.
// Cone detection is done by using a VisibleCollidingActors iterator and then
// compare the dot product between the direction of the weapon owner to the
// iterated actor and the direction of the weapon owner.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAWeaponFireMode extends Object
	Abstract
	EditInlineNew
	HideCategories(Object);

// The actor who owns this weapon
var ProtectedWrite UDKMOBAAttackInterface WeaponOwner;

/**
 * Sets the owner of the weapon
 *
 * @param		NewWeaponOwner		New weapon owners
 * @network							Server
 */
function SetOwner(UDKMOBAAttackInterface NewWeaponOwner)
{
	// Do not allow the weapon owner to be set to none
	if (NewWeaponOwner == None)
	{
		return;
	}

	WeaponOwner = NewWeaponOwner;
}

/**
 * Returns the attacking angle of the fire mode
 *
 * @return		Returns the angle range of the fire mode. If this is closer to 1.f then the weapon owner needs to be a lot more accurate
 * @network		Server
 */
function float GetAttackingAngle()
{
	return 0.95f;
}

/**
 * Called when this weapon fire mode is going to be destroyed. Since this is an object, it is here that object/actor references are cleared and removed
 *
 * @network		Server
 */
function Destroy()
{
	// Stop firing
	StopFire();

	// Clear the weapon owner
	WeaponOwner = None;
}

/**
 * Start firing the weapon
 *
 * @network		Server
 */
function StartFire()
{
	local float FiringRate;
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;
	local UDKMOBAPawn UDKMOBAPawn;

	if (WeaponOwner != None)
	{
		// Fire the weapon
		Fire();

		UDKMOBAPawn = UDKMOBAPawn(WeaponOwner);
		if (UDKMOBAPawn != None)
		{
			FiringRate = UDKMOBAPawn.BaseAttackTime;

			UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(UDKMOBAPawn.PlayerReplicationInfo);
			if (UDKMOBAPawnReplicationInfo != None && UDKMOBAPawnReplicationInfo.AttackSpeed > -1.f)
			{
				FiringRate /= (1.f + UDKMOBAPawnReplicationInfo.AttackSpeed);
			}

			// Set a timer for the next time firing should occur
			WeaponOwner.GetActor().SetTimer(FiringRate, true, NameOf(Fire), Self);
		}
	}
}

/**
 * Stop firing the weapon
 *
 * @network		Server
 */
function StopFire()
{
	if (WeaponOwner != None)
	{
		WeaponOwner.GetActor().ClearTimer(NameOf(Fire), Self);
	}
}

/**
 * Returns true if the weapon is firing or not
 *
 * @return		Returns true if the weapon is firing or not
 * @network		Server
 */
function bool IsFiring()
{
	if (WeaponOwner != None)
	{
		return WeaponOwner.GetActor().IsTimerActive(NameOf(Fire), Self);
	}

	return false;
}

/**
 * Begins firing the weapon. Finalized as sub classes should not be sub classing this function
 *
 * @network		Server
 */
final function Fire()
{
	local Vector FireLocation;
	local Rotator FireRotation;	
	local Actor CurrentEnemy;

	// Abort if WeaponOwner is none
	if (WeaponOwner == None)
	{
		return;
	}

	// Ensure that there is a current enemy set
	CurrentEnemy = WeaponOwner.GetEnemy();
	if (CurrentEnemy == None)
	{
		StopFire();
		return;
	}

	// Grab the weapon firing location and rotation
	WeaponOwner.GetWeaponFiringLocationAndRotation(FireLocation, FireRotation);

	// Call begin fire to start the actual firing
	BeginFire(FireLocation, Rotator(CurrentEnemy.Location - FireLocation), CurrentEnemy);
}

/**
 * Fires the weapon. Sub classes should sub class this function
 *
 * @param		FireLocation		Where in the world the weapon should fire from
 * @param		FireRotation		Direction the weapon should fire in
 * @param		Enemy				Enemy to shoot at
 * @network							Server
 */
protected function BeginFire(Vector FireLocation, Rotator FireRotation, Actor Enemy);

// Default properties block
defaultproperties
{
}