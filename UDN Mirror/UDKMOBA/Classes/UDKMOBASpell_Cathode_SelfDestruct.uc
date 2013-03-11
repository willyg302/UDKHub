//=============================================================================
// UDKMOBASpell_Cathode_SelfDestruct
//
// This is the self destruct ability for the Cathode hero. It causes the hero
// to explode and damage everyone around him.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBASpell_Cathode_SelfDestruct extends UDKMOBASpell;

// Explosion particle system to spawn when self destructing
var(SelfDestruct) const ParticleSystem ExplosionParticleTemplate;
// Explosion sound to play when self destructing
var(SelfDestruct) const SoundCue ExplosionSoundCue;
// Self destruct delay time
var(SelfDestruct) const float ExplosionDelayTime[4];
// Explosion radius to find victims
var(SelfDestruct) const float ExplosionRadius[4];
// Amount of health to multiply by to find the damage
var(SelfDestruct) const float DamageMultiplier[4];
// Explosion damage type to use when dealing damage to victims
var(SelfDestruct) const class<DamageType> ExplosionDamageType<AllowAbstract>;
// Explosion momentum to transfer when dealing damage to victims
var(SelfDestruct) const float ExplosionMomentumTransfer;

/**
 * Begins casting the spell
 *
 * @network		Server and client
 */
protected simulated function PerformCast()
{
	// Set up explosion timer, if the ExplosionDelayTime is above zero
	if (ExplosionDelayTime[Level] > 0.f)
	{
		SetTimer(ExplosionDelayTime[Level], false, NameOf(ExplosionDelayTimer));
	}
	// Otherwise, just call ExplosionDelayTimer() directly
	else
	{
		ExplosionDelayTimer();
	}
}

/**
 * Called via a timer which explodes the pawn and hurts everyone around
 *
 * @network		Server and client
 */
simulated function ExplosionDelayTimer()
{
	local Controller AttackingController;
	local int DamageDone;
	local UDKMOBAPawn UDKMOBAPawn;
	local int ExplosionDamageAmount;

	// Calculate how much damage to deal
	ExplosionDamageAmount = PawnOwner.Health * DamageMultiplier[Level];

	// Explode and deal damage
	if (Role == Role_Authority)
	{
		UDKMOBAPawn = UDKMOBAPawn(PawnOwner);
		if (UDKMOBAPawn != None)
		{
			AttackingController = UDKMOBAPawn.Controller;
			if (AttackingController != None)
			{
				ForEach CollidingActors(class'UDKMOBAPawn', UDKMOBAPawn, ExplosionRadius[Level], PawnOwner.Location, true)
				{
					if (UDKMOBAPawn.GetTeamNum() != AttackingController.GetTeamNum())
					{
						DamageDone = ExplosionDamageAmount * UDKMOBAPawn.GetArmorTypeMultiplier(AttackType);
						UDKMOBAPawn.TakeDamage(DamageDone, AttackingController, UDKMOBAPawn.Location, Vect(0.f, 0.f, 0.f), class'DamageType',, Self);
					}
				}
			}
		}
	}

	// Play the self destructing explosion particle effect
	if (ExplosionParticleTemplate != None && WorldInfo.MyEmitterPool != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionParticleTemplate, PawnOwner.Location, PawnOwner.Rotation, PawnOwner, PawnOwner);
	}

	// Play the self destructing explosion sound
	if (ExplosionSoundCue != None)
	{
		PawnOwner.PlaySound(ExplosionSoundCue, true);
	}

	// Destroy the pawn
	PawnOwner.TakeDamage(65536, PawnOwner.Controller, PawnOwner.Location, Vect(0.f, 0.f, 0.f), class'DamageType');
}

// Default properties block
defaultproperties
{
	ExplosionDelayTime(0)=2.f
	ExplosionDelayTime(1)=2.2f
	ExplosionDelayTime(2)=2.4f
	ExplosionDelayTime(3)=2.8f
	ExplosionRadius(0)=192.f
	ExplosionRadius(1)=256.f
	ExplosionRadius(2)=320.f
	ExplosionRadius(3)=448.f
	DamageMultiplier(0)=0.25f
	DamageMultiplier(1)=0.3f
	DamageMultiplier(2)=0.35f
	DamageMultiplier(3)=0.45f
	ExplosionDamageType=class'DamageType'
	ExplosionMomentumTransfer=5000.f
}