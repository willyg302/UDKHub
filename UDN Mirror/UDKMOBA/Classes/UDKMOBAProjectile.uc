//=============================================================================
// UDKMOBAProjectile
//
// Base Projectile class to use for UDKMOBA. Projectiles uses a particle 
// system to represent them flying around, they also spawn a particle system
// when they explode. There is also an option to spawn a decal when the
// projectile explodes. Projectiles are homing by default and will home in
// at the target. Projectiles also only attack the enemy they have been set and
// will be destroyed if the enemy is dead.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAProjectile extends Projectile
	HideCategories(Movement, Display, Attachment, Physics, Advanced, Debug, Object, Projectile);

// Flight particle system to use
var(MOBAProjectile) const ParticleSystemComponent FlightParticleSystem;
// Impact particle template to use
var(MOBAProjectile) const ParticleSystem ImpactTemplate;
// Impact material instance time varying to use for decals. This assumes the linear scalar data is setup for fading away
var(MOBAProjectile) const MaterialInstanceTimeVarying ImpactDecalMaterialInstanceTimeVarying;
// Impact opacity scalar parameter name
var(MOBAProjectile) const Name ImpactDecalOpacityScalarParameterName;
// Impact decal life time
var(MOBAProjectile) const float ImpactDecalLifeSpan;
// Impact decal minimum size
var(MOBAProjectile) const Vector2D ImpactDecalMinSize;
// Impact decal maximum size
var(MOBAProjectile) const Vector2D ImpactDecalMaxSize;
// If true, then the size of the decal is always uniform
var(MOBAProjectile) const bool AlwaysUniformlySized;
// These 4 variables are here because we need to hide the 'Projectile' category, because Damage and
// DamageType aren't inherent in MOBA's - they come from the firing entity. But we need to be able
// to set _some_ of the 'Projectile' vars...
// Initial speed of projectile.
var(MOBAProjectile)	float MOBASpeed<DisplayName=Speed>;
// Limit on speed of projectile (0 means no limit).
var(MOBAProjectile)	float MOBAMaxSpeed<DisplayName=MaxSpeed>;
// Sound made when projectile is spawned.
var(MOBAProjectile)	SoundCue MOBASpawnSound<DisplayName=SpawnSound>;
// Sound made when projectile hits something.
var(MOBAProjectile)	SoundCue MOBAImpactSound<DisplayName=ImpactSound>;

// Who owns this projectile
var UDKMOBAAttackInterface OwnerAttackInterface;
// The enemy that this projectile homes in on and attacks
var RepNotify Actor Enemy;
// The type of damage this projectile does
var class<DamageType> DamageType;
// The attack type this projectile inherits
var UDKMOBAPawn.EAttackType AttackType;
// If true, then the explosion effects have been triggered
var ProtectedWrite bool HasExploded;

// Replication block
replication
{
	if (bNetInitial)
		Enemy;
}

/**
 * Called when this projectile is initialized
 *
 * @network		Server and client
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	Speed = MOBASpeed;
	MaxSpeed = MOBAMaxSpeed;
	SpawnSound = MOBASpawnSound;
	ImpactSound = MOBAImpactSound;

	// Play the spawn sound if there is one
	if (SpawnSound != None)
	{
		PlaySound(SpawnSound, true);
	}
}

/**
 * Called when the projectile is destroyed
 *
 * @network		All
 */
simulated event Destroyed()
{
	Super.Destroyed();

	SpawnExplosionEffects(Location, Vect(0.f, 0.f, 1.f));
}

/**
 * Called when a variable that has been flagged with RepNotify has finished replicating
 *
 * @param		VarName		Name of the variable that was replicated
 * @network					Client
 */
simulated event ReplicatedEvent(Name VarName)
{
	// Set the enemy
	if (VarName == NameOf(Enemy))
	{
		if (Enemy != None)
		{
			Init(Normal(Enemy.Location - Location));
		}
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Set the velocity of the projectile based on the direction
 *
 * @param		Direction		Direction to set the velocity of the projectile
 * @network						Server and client
 */
simulated function Init(Vector Direction)
{
	Super.Init(Direction);

	// Start the homing timer if it hasn't been started
	if (!IsTimerActive(NameOf(HomingTimer)) && Enemy != None)
	{
		SetTimer(0.1f, true, NameOf(HomingTimer));
	}
}

/**
 * Called usually with a timer, turns towards the enemy in question. If the enemy is no longer valid, then the projectile is destroyed
 *
 * @network		Server and client
 */
simulated function HomingTimer()
{
	local UDKMOBAAttackInterface UDKMOBAAttackInterface;

	// Destroy the projectile if enemy is None
	if (Enemy == None)
	{
		// Spawn the impact particle effect if there is one
		if (ImpactTemplate != None && WorldInfo.MyEmitterPool != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(ImpactTemplate, Location);
		}

		Destroy();
	}

	// Check if the enemy is still valid to attack
	UDKMOBAAttackInterface = UDKMOBAAttackInterface(Enemy);
	if (UDKMOBAAttackInterface != None && !UDKMOBAAttackInterface.IsValidToAttack())
	{
		// Spawn the impact particle effect if there is one
		if (ImpactTemplate != None && WorldInfo.MyEmitterPool != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(ImpactTemplate, Location);
		}

		Destroy();
	}

	// Always home towards the enemy
	Init(Normal(Enemy.Location - Location));
}

/**
 * Called when the projectile has touched another actor
 *
 * @param		Other			Actor that this projectile touched
 * @param		OtherComp		Actor's primitive component that touched the projectile
 * @param		HitLocation		World location where the touch occurred
 * @param		HitNormal		Surface normal of the touch
 * @network						Server and client
 */
simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	// Projectiles only ever hit their targetted enemy
	if (Other == Enemy)
	{
		Super.Touch(Other, OtherComp, HitLocation, HitNormal);
	}
}

/**
 * Process the touch event
 *
 * @param		Other			Actor that this projectile touched
 * @param		HitLocation		World location where the touch occurred
 * @param		HitNormal		Surface normal of the touch
 * @network						Server and client
 */
simulated function ProcessTouch(Actor Other, Vector HitLocation, Vector HitNormal)
{
	// Projectiles only ever hit their targetted enemy
	if (Other == Enemy)
	{
		DealEnemyDamage();
		Explode(HitLocation, HitNormal);
	}
}

/**
 * Called when the projectile touchs an actor that is defined as a wall
 *
 * @param		HitNormal		Surface normal of the wall
 * @param		Wall			Actor which represents the wall
 * @param		WallComp		Actor's primitive component that is the wall
 * @network						Server and client
 */
simulated singular event HitWall(vector HitNormal, actor Wall, PrimitiveComponent WallComp)
{
	// Abort if I did not touch the enemy
	if (Wall == Enemy)
	{
		DealEnemyDamage();
		Explode(Location, HitNormal);
	}
}

/**
 * Deals damage to the enemy
 * 
 * @network		Server and client
 */
simulated function DealEnemyDamage()
{
	local Controller AttackingController;
	local int DamageDone;
	local UDKMOBAPawn UDKMOBAPawn;

	// Only deal damage on the server
	if (Role == ROLE_Authority && OwnerAttackInterface != None)
	{
		DamageDone = Damage;
		AttackingController = None;
		if (UDKMOBAPawn(OwnerAttackInterface) != None)
		{
			AttackingController = UDKMOBAPawn(OwnerAttackInterface).Controller;
			UDKMOBAPawn = UDKMOBAPawn(Enemy);
			if (UDKMOBAPawn != None)
			{
				DamageDone *= UDKMOBAPawn.GetArmorTypeMultiplier(AttackType);
			}
		}

		Enemy.TakeDamage(DamageDone, AttackingController, Enemy.Location, Velocity, DamageType, , Self);
	}
}

/**
 * Explodes the projectile
 *
 * @param		HitLocation		World location where the touch occurred
 * @param		HitNormal		Surface normal of the touch
 * @network						Server and client
 */
simulated function Explode(vector HitLocation, vector HitNormal)
{
	// Create the explosion effects
	SpawnExplosionEffects(HitLocation, HitNormal);

	// Destroy the projectile
	Destroy();
}

/**
 * Create the explosion effects
 *
 * @param		HitLocation		World location where the touch occurred
 * @param		HitNormal		Surface normal of the touch
 * @network						Server and client
 */
simulated function SpawnExplosionEffects(vector HitLocation, vector HitNormal)
{
	local MaterialInstanceTimeVarying MaterialInstanceTimeVarying;
	local float Width, Height;
	local Vector TraceHitLocation, TraceHitNormal;
	local Actor HitActor;

	if (HasExploded)
	{
		return;
	}

	HasExploded = true;	

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		// Play the impact sound if there is one
		if (ImpactSound != None)
		{
			PlaySound(ImpactSound, true);
		}
	
		// Spawn the impact particle effect if there is one
		if (ImpactTemplate != None && WorldInfo.MyEmitterPool != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(ImpactTemplate, HitLocation, Rotator(HitNormal));
		}
	
		// Spawn the impact decal effect if there is one
		if (ImpactDecalMaterialInstanceTimeVarying != None && WorldInfo.MyDecalManager != None)
		{
			HitNormal = Normal(HitNormal);
			HitActor = Trace(TraceHitLocation, TraceHitNormal, HitLocation - HitNormal * 256.f, HitLocation + HitNormal * 256.f);		
			if (HitActor != None && HitActor.bWorldGeometry)
			{
				MaterialInstanceTimeVarying = new () class'MaterialInstanceTimeVarying';
				if (MaterialInstanceTimeVarying != None)
				{
					// Figure out the decal width and height
					Width = RandRange(ImpactDecalMinSize.X, ImpactDecalMaxSize.X);
					Height = (AlwaysUniformlySized) ? Width : RandRange(ImpactDecalMinSize.Y, ImpactDecalMaxSize.Y);
			
					// Set up the MaterialInstanceTimeVarying
					MaterialInstanceTimeVarying.SetParent(ImpactDecalMaterialInstanceTimeVarying);
			
					// Spawn the decal
					WorldInfo.MyDecalManager.SpawnDecal(MaterialInstanceTimeVarying, TraceHitLocation + TraceHitNormal * 8.f, Rotator(-TraceHitNormal), Width, Height, 32.f, false);
			
					// Set the scalar start time; so that the decal doesn't start fading away immediately
					MaterialInstanceTimeVarying.SetScalarStartTime(ImpactDecalOpacityScalarParameterName, ImpactDecalLifeSpan);
				}
			}
		}
	}
}

// Default properties block
defaultproperties
{
	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent
	End Object
	Components.Add(MyParticleSystemComponent)
	FlightParticleSystem=MyParticleSystemComponent

	bCollideWorld=false
	bCollideActors=true
	ImpactDecalLifeSpan=24.f
	ImpactDecalOpacityScalarParameterName="DissolveAmount"
	ImpactDecalMinSize=(X=192.f,Y=192.f)
	ImpactDecalMaxSize=(X=256.f,Y=256.f)
	AlwaysUniformlySized=true
	bNetTemporary=false
	bAlwaysRelevant=true

	MOBAMaxSpeed=+02000.000000
	MOBASpeed=+02000.000000
	AttackType=ATT_Spells
}