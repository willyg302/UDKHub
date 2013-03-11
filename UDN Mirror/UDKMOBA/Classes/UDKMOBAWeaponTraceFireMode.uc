//=============================================================================
// UDKMOBAWeaponTraceFireMode
//
// Weapon fire mode which uses a trace to detect enemies to damage.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAWeaponTraceFireMode extends UDKMOBAWeaponFireMode;

// Range of the weapon
var(FireMode) const float TraceRange;
// Box extent to use for the trace
var(FireMode) const Vector TraceExtent;
// Momentum amount to transfer to hit actor
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
	local Vector HitLocation, HitNormal, TraceStart, TraceEnd;
	local UDKMOBAPawn OwnerUDKMOBAPawn, HitUDKMOBAPawn;
	local float ActualDamage;

	// Only spawn the projectile on the server
	if (WeaponOwner.GetActor().Role == ROLE_Authority)
	{
		TraceStart = FireLocation;
		TraceEnd = TraceStart + Vector(FireRotation) * TraceRange;

		HitActor = WeaponOwner.GetActor().Trace(HitLocation, HitNormal, TraceEnd, TraceStart, true, TraceExtent);
		if (HitActor != None)
		{
			ActualDamage = WeaponOwner.GetDamage();

			OwnerUDKMOBAPawn = UDKMOBAPawn(WeaponOwner);
			if (OwnerUDKMOBAPawn != None)
			{	
				// Modify damage based on the owner's stats
				OwnerUDKMOBAPawn.SendAttack(ActualDamage, WeaponOwner.GetDamageType());

				// Modify damage based on the hit pawn's stats
				HitUDKMOBAPawn = UDKMOBAPawn(HitActor);
				if (HitUDKMOBAPawn != None)
				{
					ActualDamage *= HitUDKMOBAPawn.GetArmorTypeMultiplier(OwnerUDKMOBAPawn.AttackType);					
				}
			}

			// Deal the damage
			HitActor.TakeDamage(ActualDamage, OwnerUDKMOBAPawn.Controller, HitLocation, MomentumTransfer * Vector(FireRotation), WeaponOwner.GetDamageType(),, OwnerUDKMOBAPawn);
		}
	}
}

// Default properties block
defaultproperties
{
	TraceRange=16384.f
}