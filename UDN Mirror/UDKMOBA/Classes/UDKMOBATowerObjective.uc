//=============================================================================
// UDKMOBATowerObjective
//
// Subclass of the UDKMOBAObjective class used for towers.
//
// * Towers will attack enemies within range in an organised way
// * Towers are invulnerable until a previous tower is destroyed
// * Towers give money when destroyed
// * Towers will create a dynamic obstacle to prevent pawns from walking
//   through them
// * Towers will regenerate health
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBATowerObjective extends UDKMOBAObjective
	HideCategories(Effects, Teleport, AI);

// Ring static mesh used to highlight the tower
var(Tower) const StaticMeshComponent RingStaticMesh;
// Point light used to light the area around the tower
var(Tower) const LightComponent Light;
// Particle system used by the tower
var(Tower) const ParticleSystemComponent ParticleSystem;
// Tower detection radius
var(Tower) const float DetectionRadius;
// Relative offset to the tower location to specify where the projectile should spawn
var(Tower) const Vector SpawnProjectileOffset;
// How much damage this tower deals per hit
var(Tower) const float Damage;
// The type of damage this tower does
var(Tower) const class<DamageType> TowerDamageType<DisplayName=DamageType>;
// Towers that must be destroyed before this one can be damaged
var(Tower) const array<UDKMOBATowerObjective> TowerProtectors;
// Explosion sound cue to play when destroyed
var(Tower) const SoundCue ExplosionSoundCue;
// Explosion particle effect to spawn when destroyed
var(Tower) const ParticleSystem ExplosionTemplate;
// How much to gold to give to enemy players when destroyed
var(Tower) const float GoldToGiveWhenDestroyed;

// Current attacking target
var ProtectedWrite UDKMOBAAttackInterface CurrentEnemy;
// Dynamic obstacle
var ProtectedWrite UDKMOBADynamicObstacle DynamicObstacle;
// Array of enemies that have attacked allied heroes
var ProtectedWrite array<UDKMOBAAttackInterface> EnemyAttackedHeroesList;
// Array of enemies that have attacked me
var ProtectedWrite array<UDKMOBAAttackInterface> EnemyAttackedMeList;
// Detection point
var ProtectedWrite UDKMOBATrigger DetectionTrigger;
// Detected attack interfaces
var ProtectedWrite array<UDKMOBAAttackInterface> DetectedAttackInterfaces;

/**
 * Called when the actor is first initialized
 *
 * @network			Server and client
 */
simulated event PostBeginPlay()
{
	Super(UDKMOBAPawn).PostBeginPlay();

	// Initialize the fire mode
	if (WeaponFireMode != None)
	{
		WeaponFireMode.SetOwner(Self);
	}

	// Create the dynamic obstacle
	if (CylinderComponent != None && CylinderComponent.CollisionRadius > 0.f)
	{
		DynamicObstacle = Spawn(class'UDKMOBADynamicObstacle',,, Location, Rotation,, true);
		if (DynamicObstacle != None)
		{
			DynamicObstacle.SetAsSquare(CylinderComponent.CollisionRadius);
			DynamicObstacle.RegisterObstacle();
		}
	}

	// Create the detection point
	DetectionTrigger = Spawn(class'UDKMOBATrigger',,, Location);
	if (DetectionTrigger != None)
	{
		// Set the detection radius
		if (DetectionTrigger.CollisionCylinderComponent != None)
		{
			DetectionTrigger.CollisionCylinderComponent.SetCylinderSize(DetectionRadius, 64.f);
		}
		
		// Set the delegates
		DetectionTrigger.OnTouch = InternalOnTouch;
		DetectionTrigger.OnUnTouch = InternalOnUnTouch;
	}
}

/**
 * Called when the tower has been destroyed
 *
 * @network			Server and client
 */
simulated event Destroyed()
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	Super.Destroyed();

	// Destroy the dynamic obstacle
	if (DynamicObstacle != None)
	{
		DynamicObstacle.UnregisterObstacle();
		DynamicObstacle.Destroy();
	}

	// Destroy the detection trigger
	if (DetectionTrigger != None)
	{
		DetectionTrigger.OnTouch = None;
		DetectionTrigger.OnUnTouch = None;
		DetectionTrigger.Destroy();
	}

	// Remove myself from the local players touch interfaces array
	PlayerController = GetALocalPlayerController();
	if (PlayerController != None)
	{
		UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
		if (UDKMOBAHUD != None)
		{
			UDKMOBAHUD.RemoveTouchInterface(Self);
		}
	}
}

/**
 * Recalculate the pawn stat
 *
 * @network		Server and client
 */
simulated function RecalculateStats()
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	// Only handle this on the server
	if (Role == Role_Authority)
	{
		if (StatsModifier == None)
		{
			return;
		}

		// Only a few things need to be updated based on stats
		UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
		if (UDKMOBAPawnReplicationInfo != None)
		{
			UDKMOBAPawnReplicationInfo.HealthRegenerationAmount = StatsModifier.CalculateStat(STATNAME_HPRegen, BaseHealthRegen);
			UDKMOBAPawnReplicationInfo.Damage = StatsModifier.CalculateStat(STATNAME_Damage, BaseDamage);
			UDKMOBAPawnReplicationInfo.Armor = StatsModifier.CalculateStat(STATNAME_Armor, BaseArmor);
			UDKMOBAPawnReplicationInfo.MagicResistance = StatsModifier.CalculateStat(STATNAME_MagicResistance, BaseMagicResistance);
			UDKMOBAPawnReplicationInfo.MagicImmunity = (StatsModifier.CalculateStat(STATNAME_MagicImmunity, BaseMagicImmunity) > 0.5f) ? true : false;
		}
	}
}

/**
 * Stubbed out as we don't need to handle momentum for immovable towers
 *
 * @param		Momentum		Unused
 * @param		HitLocation		Unused
 * @param		DamageType		Unused
 * @param		HitInfo			Unused
 * @network						Server
 */
function HandleMomentum(vector Momentum, Vector HitLocation, class<DamageType> DamageType, optional TraceHitInfo HitInfo);

/**
 * Stubbed out as we don't need to handle momentum for immovable towers
 *
 * @param		NewVelocity		Unused
 * @param		HitLocation		Unused
 * @param		DamageType		Unused
 * @param		HitInfo			Unused
 * @network						Server
 */
function AddVelocity(vector NewVelocity, vector HitLocation, class<DamageType> DamageType, optional TraceHitInfo HitInfo);

/**
 * Called when the detection trigger has been touched
 *
 * @param		Caller			Always a reference to this actor
 * @param		Other			Actor that was touched
 * @param		OtherComp		Actor's primitive component that was touched
 * @param		HitLocation		World location where the touch occured
 * @param		HitNormal		Surface normal calculated when the touch occured
 * @network						Server and client
 */
simulated function InternalOnTouch(Actor Caller, Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local UDKMOBAAttackInterface UDKMOBAAttackInterface;

	// Ensure that the caller is the detection trigger
	if (Caller == DetectionTrigger)
	{
		// Ensure the other actor implements the attack interface
		UDKMOBAAttackInterface = UDKMOBAAttackInterface(Other);
		if (UDKMOBAAttackInterface != None && DetectedAttackInterfaces.Find(UDKMOBAAttackInterface) == INDEX_NONE)
		{
			DetectedAttackInterfaces.AddItem(UDKMOBAAttackInterface);
		}
	}
}

/**
 * Called when the detection trigger untouches an actor within the world (that is to say, an actor that was touched but no longer is)
 *
 * @param		Caller			Always a reference to this actor
 * @param		Other			Actor that was untouched
 * @network						Server and client
 */
simulated function InternalOnUnTouch(Actor Caller, Actor Other)
{
	local UDKMOBAAttackInterface UDKMOBAAttackInterface;

	// Ensure that the caller is the detection trigger
	if (Caller == DetectionTrigger)
	{
		// Ensure the other actor implements the attack interface
		UDKMOBAAttackInterface = UDKMOBAAttackInterface(Other);
		if (UDKMOBAAttackInterface != None)
		{
			DetectedAttackInterfaces.RemoveItem(UDKMOBAAttackInterface);
		}	
	}
}

/**
 * Called everytime the actor is updated
 *
 * @param		DeltaTime		Time since the last update
 * @network						Server and client
 */
simulated event Tick(float DeltaTime)
{
	local UDKMOBAAttackInterface HighestPriorityAttackInterface;
	local array<UDKMOBAAttackInterface> PotentialAttackInterfaces;
	local int i, AttackPriority, HighestAttackPriority;

	Super.Tick(DeltaTime);

	if (Role == Role_Authority)
	{
		// If this tower has a current target, then evaluate if it should continue to be the target
		if (CurrentEnemy != None)
		{
			// Current target is no longer valid to attack, set current target as none
			// Current target changed teams, and is now on the same team as the tower, set current target as none
			// Current target is no longer being detected
			if (!CurrentEnemy.IsValidToAttack() || CurrentEnemy.GetTeamNum() == GetTeamNum() || DetectedAttackInterfaces.Find(CurrentEnemy) == INDEX_NONE)
			{
				CurrentEnemy = None;
			}
		}

		// If this tower doesn't have any targets right now, evaluate if it should have a current target or not
		if (CurrentEnemy == None)
		{
			// Scan the enemies who have attacked me and validate for them
			if (EnemyAttackedMeList.Length > 0)
			{
				for (i = 0; i < EnemyAttackedMeList.Length; ++i)
				{
					if (EnemyAttackedMeList[i] == None || EnemyAttackedMeList[i].GetTeamNum() == GetTeamNum() || !EnemyAttackedMeList[i].IsValidToAttack() || DetectedAttackInterfaces.Find(EnemyAttackedMeList[i]) == INDEX_NONE)
					{
						EnemyAttackedMeList.Remove(i, 1);
						--i;
					}
					else
					{
						CurrentEnemy = EnemyAttackedMeList[i];
						break;
					}
				}
			}
			// Scan around for something attack with the lowest health
			else
			{
				for (i = 0; i < DetectedAttackInterfaces.Length; ++i)
				{
					// Continue if the actor is on the same team as the tower
					// Continue if the actor is not valid to attack
					if (DetectedAttackInterfaces[i].GetTeamNum() == GetTeamNum() || !DetectedAttackInterfaces[i].IsValidToAttack())
					{
						continue;
					}

					// Add to the potential list of actors to attack
					PotentialAttackInterfaces.AddItem(DetectedAttackInterfaces[i]);		
				}

				// If we have some potential attack interfaces, then find out which one to attack
				if (PotentialAttackInterfaces.Length > 0)
				{
					for (i = 0; i < PotentialAttackInterfaces.Length; ++i)
					{
						// Get the attack priority from the actor itself
						AttackPriority = 1.f - PotentialAttackInterfaces[i].GetHealthPercentage();

						// Check to see if this is the highest priority interface or not
						if (HighestPriorityAttackInterface == None || AttackPriority > HighestAttackPriority)
						{
							HighestPriorityAttackInterface = PotentialAttackInterfaces[i];
							HighestAttackPriority = AttackPriority;
						}
					}
				}

				// Set the current target if we have a valid highest priority attack interface
				if (HighestPriorityAttackInterface != None)
				{
					CurrentEnemy = HighestPriorityAttackInterface;
				}
			}
		}

		// Attack the current target if there is one
		if (WeaponFireMode != None)
		{
			if (CurrentEnemy != None)
			{
				if (!WeaponFireMode.IsFiring())
				{
					WeaponFireMode.StartFire();
				}
			}
			else
			{
				if (WeaponFireMode.IsFiring())
				{
					WeaponFireMode.StopFire();
				}
			}
		}
	}
}

/** 
 * Apply some amount of damage to this actor
 *
 * @param		DamageAmount		The base damage to apply
 * @param		EventInstigator		The Controller responsible for the damage
 * @param		HitLocation			World location where the hit occurred
 * @param		Momentum			Force caused by this hit
 * @param		DamageType			Class describing the damage that was done
 * @param		HitInfo				Additional info about where the hit occurred
 * @param		DamageCauser		The Actor that directly caused the damage (i.e. the Projectile that exploded, the Weapon that fired, etc)
 * @network							Server 
 */
event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local UDKMOBAAttackInterface UDKMOBAAttackInterface;

	Super.TakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

	// Append the damage causer to the list of actors who have attacked me
	UDKMOBAAttackInterface = UDKMOBAAttackInterface(DamageCauser);
	if (UDKMOBAAttackInterface != None && EnemyAttackedMeList.Find(DamageCauser) == INDEX_NONE)
	{
		EnemyAttackedMeList.AddItem(DamageCauser);
	}
}

/**
 * This pawn has died.
 *
 * @param	Killer			Who killed this pawn
 * @param	DamageType		What killed it
 * @param	HitLocation		Where did the hit occur
 * @return					Returns true if allowed to die
 * @network					Server
 */
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local int MoneyAmount, i;
	local float TeamSize;
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local array<UDKMOBAPlayerReplicationInfo> UDKMOBAPlayerReplicationInfos;

	if (Super.Died(Killer, DamageType, HitLocation))
	{
		// If the killer was on the same team, then it is a deny, otherwise, distribute money to everyone
		if (Killer.GetTeamNum() != GetTeamNum())
		{
			TeamSize = 0.f;
			foreach WorldInfo.AllControllers(class'UDKMOBAPlayerController', UDKMOBAPlayerController)
			{
				UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(UDKMOBAPlayerController.PlayerReplicationInfo);
				if (UDKMOBAPlayerReplicationInfo != None)
				{
					UDKMOBAPlayerReplicationInfos.AddItem(UDKMOBAPlayerReplicationInfo);

					if (UDKMOBAPlayerController.GetTeamNum() != GetTeamNum())
					{
						TeamSize += 1.f;
					}
				}
			}

			MoneyAmount = FCeil(GoldToGiveWhenDestroyed / TeamSize);

			for (i = 0; i < UDKMOBAPlayerReplicationInfos.Length; ++i)
			{
				if (UDKMOBAPlayerReplicationInfos[i] != None)
				{
					UDKMOBAPlayerReplicationInfos[i].ModifyMoney(MoneyAmount);
				}
			}			
		}

		return true;
	}

	return false;
}

/**
 * Plays the dying sound
 *
 * @network		Server and client
 */
simulated function PlayDyingSound()
{
	Super.PlayDyingSound();

	if (ExplosionSoundCue != None)
	{
		PlaySound(ExplosionSoundCue, true);
	}
}

/**
 * Performs any client side stuff to represent that this tower is dying
 *
 * @param		DamageType		Damage type that killed this tower
 * @param		HitLoc			Hit location of the hit that killed this tower
 * @network						Server and client
 */
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	Super.PlayDying(DamageType, HitLoc);

	if (ExplosionTemplate != None && WorldInfo.MyEmitterPool != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionTemplate, Location);
	}

	SetHidden(true);
}

// =====================================
// UDKMOBAAttackInterface implementation
// =====================================
/**
 * Returns the weapon firing location and rotation
 *
 * @param		FireLocation		Output the firing location
 * @param		FireRotation		Output the firing rotation
 * @network							Server and client
 */
simulated function GetWeaponFiringLocationAndRotation(out Vector FireLocation, out Rotator FireRotation)
{
	FireLocation = Location + SpawnProjectileOffset;
	FireRotation = Rotator(CurrentEnemy.GetActor().Location - FireLocation);
}

/**
 * Returns the enemy
 *
 * @return		Returns the current enemy
 * @network		Server and client
 */
simulated function Actor GetEnemy()
{
	return CurrentEnemy.GetActor();
}

/**
 * Returns the attack priority of this actor
 *
 * @param		Attacker		Actor that wants to attack this UDKMOBAAttackInterface
 * @return						Returns the attacking priority that this implementing actor belongs to
 * @network						Server and client
 */
simulated function int GetAttackPriority(Actor Attacker)
{
	return 10;
}

/**
 * Returns the actor that implements this interface
 *
 * @return		Returns the actor that implements this interface
 * @network		Server and client
 */
simulated function Actor GetActor()
{
	return Self;
}

/**
 * Returns true if the actor is still valid to attack
 *
 * @return		Returns true if the actor is still valid to attack
 * @network		Server and client
 */
simulated function bool IsValidToAttack()
{
	return Health > 0;
}

/**
 * Returns the amount of damage that this actor does for an attack. NOT used for spells.
 *
 * @return		The amount of damage done, with Blind taken account of.
 * @network		Server and client
 */
simulated function float GetDamage()
{
	return Damage;
}

/**
 * Returns the amount of damage that this actor does for an attack.
 *
 * @return		The type of damage this actor does for auto-attacks.
 * @network		Server and client
 */
simulated function class<DamageType> GetDamageType()
{
	return TowerDamageType;
}

/**
 * Returns true if the actor is currently invulnerable
 *
 * @return		Returns true if the actor is invulnerable
 * @network		Server and client
 */
simulated function bool IsInvulnerable()
{
	local int i;

	if (TowerProtectors.Length > 0)
	{
		for (i = 0; i < TowerProtectors.Length; ++i)
		{
			if (TowerProtectors[i] != None && TowerProtectors[i].Health > 0)
			{
				return true;
			}
		}
	}

	return false;
}

// ====================================
// UDKMOBATouchInterface implementation
// ====================================
/**
 * Returns the touch priority to allow other touch interfaces to be more (or less) important than others
 *
 * @return		Returns the touch priority to allow sorting of multiple touch priorities
 * @network		Server and client
 */
simulated function int GetTouchPriority()
{
	return 15;
}

/**
 * Updates the touch bounding box for this actor
 *
 * @param		HUD			HUD to use if Canvas is required
 * @network					Server and client
 */
simulated function UpdateTouchBoundingBox(HUD HUD)
{
	local Box ComponentsBoundingBox;

	// Check if the actor has been rendered within the last few frames or so
	if (WorldInfo.TimeSeconds - LastRenderTime < 0.3f && CollisionComponent != None)
	{
		ComponentsBoundingBox.Min = CollisionComponent.Bounds.Origin - CollisionComponent.Bounds.BoxExtent;
		ComponentsBoundingBox.Max = CollisionComponent.Bounds.Origin + CollisionComponent.Bounds.BoxExtent;
		if (class'UDKMOBAObject'.static.GetPrimitiveComponentScreenBoundingBox(HUD, ComponentsBoundingBox, ScreenBoundingBox))
		{
			return;
		}
	}

	// Otherwise reset the screen bounding box to something invalid
	InvalidateTouchBoundingBox();
}

// ======================================
// UDKMOBACommandInterface implementation
// ======================================
/**
 * Returns true if the requesting player replication info is able to follow this actor
 *
 * @param		RequestingPlayerReplicationInfo			PlayerReplicationInfo that is asking
 * @return												Returns true if the requesting player can follow this actor
 * @network												Server and client
 */
simulated function bool CanBeFollowed(PlayerReplicationInfo RequestingPlayerReplicationInfo)
{
	return false;
}

/**
 * Returns true if the requesting player replication info is able to attack this actor
 *
 * @param		RequestingPlayerReplicationInfo			PlayerReplicationInfo that is asking
 * @return												Returns true if the requesting player can attack this actor
 * @network												Server and client
 */
simulated function bool CanBeAttacked(PlayerReplicationInfo RequestingPlayerReplicationInfo)
{
	return (RequestingPlayerReplicationInfo != None && RequestingPlayerReplicationInfo.Team != None && RequestingPlayerReplicationInfo.Team.TeamIndex != GetTeamNum());
}

// ====================================
// UDKMOBAStatsInterface implementation
// ====================================
/**
 * Returns true if the actor implementing this interface can have mana
 *
 * @return		True if the actor implementing this interface can have mana
 * @network		Server and client
 */
simulated function bool HasMana()
{
	return false;
}

/**
 * Returns the mana as a percentage value
 *
 * @return		Return the mana as a percentage value
 * @network		Server and client
 */
simulated function float GetManaPercentage()
{
	return 0.f;
}

// Default properties block
defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=MyRingStaticMeshComponent
		LightEnvironment=MyLightEnvironment
	End Object
	Components.Add(MyRingStaticMeshComponent)
	RingStaticMesh=MyRingStaticMeshComponent

	Begin Object Class=PointLightComponent Name=MyLightComponent
	End Object
	Components.Add(MyLightComponent)
	Light=MyLightComponent

	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent
		SecondsBeforeInactive=1
	End Object
	Components.Add(MyParticleSystemComponent)
	ParticleSystem=MyParticleSystemComponent

	bDontPossess=true
	bEdShouldSnap=true
	HealthMax=4250
	Health=4250
	DetectionRadius=512.f
	Damage=50.f
	TowerDamageType=class'DamageType'
	GoldToGiveWhenDestroyed=1200.f
}