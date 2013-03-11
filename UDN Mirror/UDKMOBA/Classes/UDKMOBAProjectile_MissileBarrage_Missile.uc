//=============================================================================
// UDKMOBAProjectile_MissileBarrage_Missile
//
// These are spawned from the Missile Barrage spell. They fly straight up into 
// the air for a short time and then home in towards their target.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAProjectile_MissileBarrage_Missile extends UDKMOBAProjectile;

// Minimum time to fly up for
var(Missile) const float FlyUpTimeMin;
// Maximum time to fly up for
var(Missile) const float FlyUpTimeMax;
// Damage per level
var(Missile) const array<float> DamageLevel;
// Radius per level
var(Missile) const array<float> RadiusLevel;

// Replicated time to start homing
var RepNotify float HomingInTime;
// Desired target location
var RepNotify Vector TargetLocation;
// Spell that launched this projectile
var UDKMOBASpell SpellOwner;

// Replication block
replication
{
	if (bNetInitial)
		HomingInTime, TargetLocation;
}

/**
 * Called when the missile is first initialized
 *
 * @network		Server and client
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (Role == Role_Authority)
	{
		// Play the spawn sound
		if (SpawnSound != None)
		{
			PlaySound(SpawnSound, true);
		}

		HomingInTime = RandRange(FlyUpTimeMin, FlyUpTimeMax);
		SetTimer(HomingInTime, false, NameOf(StartHomingTimer));
	}
}

/**
 * Called when a variable flagged with a RepNotify has finished replicated
 *
 * @network		Client
 */
simulated event ReplicatedEvent(Name VarName)
{
	// Homing in time was replicated, start the timer
	if (VarName == NameOf(HomingInTime))
	{
		SetTimer(HomingInTime, false, NameOf(StartHomingTimer));
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

/**
 * Called the Projectile version of Init only
 *
 * @param		Direction		Direction to set the velocity of the projectile
 * @network						Server and client
 */
simulated function Init(Vector Direction)
{
	Super(Projectile).Init(Direction);
}

/**
 * Starts the homing timer
 *
 * @network		Server and client
 */
simulated function StartHomingTimer()
{
	SetTimer(0.05f, true, NameOf(HomingInTimer));
}

/**
 * Called via timer, which blends the rotation of the missile so that the missile eventually turns towards the homing target
 *
 * @network		Server and client
 */
simulated function HomingInTimer()
{
	local Rotator DesiredRotation;

	if (VSizeSq(Location - TargetLocation) < 4096.f)
	{
		Explode(Location, Vect(0.f, 0.f, 1.f));
		ClearTimer(NameOf(HomingInTimer));
	}
	else
	{
		DesiredRotation = Rotator(TargetLocation - Location);
		SetRotation(RLerp(Rotation, DesiredRotation, 0.75f, true));
		Init(Vector(Rotation));
	}
}

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @param		Other			Unused
 * @param		OtherComp		Unused
 * @param		HitLocation		Unused
 * @param		HitNormal		Unused
 * @network						Server and client
 */
simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal);

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @param		Other			Unused
 * @param		HitLocation		Unused
 * @param		HitNormal		Unused
 * @network						Server and client
 */
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal);

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @param		HitNormal		Unused
 * @param		Wall			Unused
 * @param		WallComp		Unused
 * @network						Server and client
 */
simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp);

/**
 * Stubbed as this functionality is not required for the missile
 *
 * @network						Server and client
 */
simulated function DealEnemyDamage();

/**
 * Explodes the projectile
 *
 * @param		HitLocation		World location where the touch occurred
 * @param		HitNormal		Surface normal of the touch
 * @network						Server and client
 */
simulated function Explode(vector HitLocation, vector HitNormal)
{
	local Controller AttackingController;
	local int DamageDone;
	local UDKMOBAPawn UDKMOBAPawn;
	local UDKMOBASpell_DemoGuy_MissileBarrage UDKMOBASpell_DemoGuy_MissileBarrage;

	if (Role == Role_Authority && OwnerAttackInterface != None)
	{
		UDKMOBASpell_DemoGuy_MissileBarrage = UDKMOBASpell_DemoGuy_MissileBarrage(SpellOwner);
		if (UDKMOBASpell_DemoGuy_MissileBarrage != None)
		{
			UDKMOBAPawn = UDKMOBAPawn(OwnerAttackInterface);
			if (UDKMOBAPawn != None)
			{
				AttackingController = UDKMOBAPawn.Controller;
				if (AttackingController != None)
				{
					ForEach CollidingActors(class'UDKMOBAPawn', UDKMOBAPawn, RadiusLevel[UDKMOBASpell_DemoGuy_MissileBarrage.Level], HitLocation, true)
					{
						if (UDKMOBAPawn.GetTeamNum() != OwnerAttackInterface.GetTeamNum())
						{
							DamageDone = DamageLevel[UDKMOBASpell_DemoGuy_MissileBarrage.Level] * UDKMOBAPawn.GetArmorTypeMultiplier(AttackType);
							UDKMOBAPawn.TakeDamage(DamageDone, AttackingController, UDKMOBAPawn.Location, Vect(0.f, 0.f, 0.f), class'DamageType',, Self);
						}
					}
				}
			}
		}
	}

	Super.Explode(HitLocation, HitNormal);
}

// Default properties block
defaultproperties
{
	FlyUpTimeMin=0.35f
	FlyUpTimeMax=0.45f
	bRotationFollowsVelocity=true
	Speed=1250.f
	bCollideActors=false
	bNetTemporary=false
	RadiusLevel(0)=96.f
	RadiusLevel(1)=128.f
	RadiusLevel(2)=160.f
	RadiusLevel(3)=224.f
	DamageLevel(0)=20.f
	DamageLevel(1)=30.f
	DamageLevel(2)=40.f
	DamageLevel(3)=60.f
}