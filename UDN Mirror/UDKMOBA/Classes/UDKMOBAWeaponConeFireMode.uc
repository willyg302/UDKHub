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
class UDKMOBAWeaponConeFireMode extends UDKMOBAWeaponFireMode;

// Hit actors
struct SHitActor
{
	var float Rating;
	var Actor Actor;
};

// Range of the weapon
var(FireMode) const float Range;
// Extent trace of the weapon
var(FireMode) const Vector Extent;
// Dot angle that the hit actor has to be within to count as a hit
var(FireMode) const float DotAngle;
// Maximum count of actors to hit
var(FireMode) const int HitCount;
// Momentum to transfer to the hit actor
var(FireMode) const float MomentumTransfer;

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
	local Actor HitActor;
	local Vector FireDirection, PawnToActorDirection;
	local array<SHitActor> HitActors;
	local float PawnToActorDotAngle, ActualDamage;
	local SHitActor NewSHitActor;
	local int i;
	local UDKMOBAPawn OwnerUDKMOBAPawn, HitUDKMOBAPawn;

	// Only spawn the projectile on the server
	if (WeaponOwner.GetActor().Role == ROLE_Authority)
	{
		FireDirection = Vector(FireRotation);
		foreach WeaponOwner.GetActor().VisibleCollidingActors(class'Actor', HitActor, Range, WeaponOwner.GetActor().Location, true, Extent, true)
		{
			PawnToActorDirection = Normal(HitActor.Location - WeaponOwner.GetActor().Location);
			PawnToActorDotAngle = FireDirection dot PawnToActorDirection;
			if (PawnToActorDotAngle >= DotAngle)
			{
				// Calculate the rating
				NewSHitActor.Rating = PawnToActorDotAngle / VSize(HitActor.Location - WeaponOwner.GetActor().Location);
				// Calculate the actor
				NewSHitActor.Actor = HitActor;
				// Append to the hit actors
				HitActors.AddItem(NewSHitActor);
			}
		}

		ActualDamage = WeaponOwner.GetDamage();
		OwnerUDKMOBAPawn = UDKMOBAPawn(WeaponOwner);
		if (OwnerUDKMOBAPawn != None)
		{	
			// Modify damage based on the owner's stats
			OwnerUDKMOBAPawn.SendAttack(ActualDamage, WeaponOwner.GetDamageType());

			if (HitCount <= 0)
			{
				// Damage all of them
				for (i = 0; i < HitActors.Length; ++i)
				{
					HitUDKMOBAPawn = UDKMOBAPawn(HitActors[i].Actor);
					if (HitUDKMOBAPawn != None)
					{
						ActualDamage *= HitUDKMOBAPawn.GetArmorTypeMultiplier(OwnerUDKMOBAPawn.AttackType);	
					}

					HitActors[i].Actor.TakeDamage(ActualDamage, OwnerUDKMOBAPawn.Controller, HitActors[i].Actor.Location, MomentumTransfer * Vector(FireRotation), WeaponOwner.GetDamageType(),, OwnerUDKMOBAPawn);
				}
			}
			else
			{
				// Sort based on rating
				HitActors.Sort(CompareHitActors);
				for (i = 0; i < HitCount; ++i)
				{
					HitUDKMOBAPawn = UDKMOBAPawn(HitActors[i].Actor);
					if (HitUDKMOBAPawn != None)
					{
						ActualDamage *= HitUDKMOBAPawn.GetArmorTypeMultiplier(OwnerUDKMOBAPawn.AttackType);	
					}

					HitActors[i].Actor.TakeDamage(ActualDamage, OwnerUDKMOBAPawn.Controller, HitActors[i].Actor.Location, MomentumTransfer * Vector(FireRotation), WeaponOwner.GetDamageType(),, OwnerUDKMOBAPawn);
				}
			}
		}
	}
}

/**
 * Handle sorting of an array of SHitActors.
 *
 * @param		A		First instance to compare
 * @param		B		Second instance to compare
 * @return				Returns 0 if A has a higher rating than B, otherwise return -1
 * @network				Server
 */
function int CompareHitActors(SHitActor A, SHitActor B)
{
	return (A.Rating > B.Rating) ? 0 : -1;
}

// Default properties block
defaultproperties
{
	Range=1024.f
	DotAngle=0.5f
	HitCount=0
}