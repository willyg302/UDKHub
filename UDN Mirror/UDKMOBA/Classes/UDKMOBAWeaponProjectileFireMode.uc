//=============================================================================
// UDKMOBAWeaponProjectileFireMode
//
// Weapon fire mode which launches a projectile.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAWeaponProjectileFireMode extends UDKMOBAWeaponFireMode;

// Archetype of the projectile to use
var(FireMode) const UDKMOBAProjectile ProjectileArchetype;

/**
 * Fires the weapon.
 *
 * @param		FireLocation		Where in the world the weapon should fire from
 * @param		FireRotation		Direction the weapon should fire in
 * @param		Enemy				Enemy to shoot at
 * @network							Server
 */
protected function BeginFire(Vector FireLocation, Rotator FireRotation, Actor Enemy)
{
	local UDKMOBAProjectile SpawnedProjectile;
	local UDKMOBAPawn UDKMOBAPawn;

	// Only spawn the projectile on the server
	if (WeaponOwner.GetActor().Role == ROLE_Authority)
	{
		// Spawn projectile
		SpawnedProjectile = WeaponOwner.GetActor().Spawn(ProjectileArchetype.Class,,, FireLocation, FireRotation, ProjectileArchetype);
		if (SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe)
		{
			// Set the weapon owner
			SpawnedProjectile.OwnerAttackInterface = WeaponOwner;
			// Set the enemy
			SpawnedProjectile.Enemy = Enemy;
			// Initialize the projectile
			SpawnedProjectile.Init(Vector(FireRotation));

			SpawnedProjectile.Damage = WeaponOwner.GetDamage();
			SpawnedProjectile.DamageType = WeaponOwner.GetDamageType();

			UDKMOBAPawn = UDKMOBAPawn(WeaponOwner);
			if (UDKMOBAPawn != None)
			{
				UDKMOBAPawn.SendAttack(SpawnedProjectile.Damage, SpawnedProjectile.DamageType);
			}
		}
	}
}

// Default properties block
defaultproperties
{
}