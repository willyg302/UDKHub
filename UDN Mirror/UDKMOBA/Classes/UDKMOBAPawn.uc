//=============================================================================
// UDKMOBAPawn
//
// MOBA base pawn to create hero/creep pawn archetypes used by the game. Has 
// a lot of base functionality that are common to creeps/heroes.
//
// * Has weapon properties, UDKMOBA doesn't need to use the weapon system
//   which comes with UE3 as a simpler method will suffice.
// * Has mana properties which are used for spells and so forth.
// * Has effects which happen when moving through water and other physical
//   material effects.
// * Has teleport properties which are used when spawning.
// * Handles a lot of base stats used in most MOBA style games.
// * Handles creation of the screen space bounding box.
// * Handles the occlusion mesh effect when the pawn is hidden from view on the
//   PC.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPawn extends Pawn
	Abstract
	HideCategories(Movement, Camera, Debug, Attachment, Physics, Advanced, Object)
	Implements(UDKMOBAMinimapInterface, UDKMOBATouchInterface, UDKMOBAAttackInterface, UDKMOBAStatsInterface, UDKMOBACommandInterface)
	Placeable;

// Armor type definition
enum EArmorType
{
	ART_Light,
	ART_Medium,
	ART_Heavy,
	ART_Fortified,
	ART_Hero,
	ART_Unarmored,
};

// Attack type definition
enum EAttackType
{
	ATT_Chaos,
	ATT_Hero,
	ATT_Normal,
	ATT_Pierce,
	ATT_Siege,
	ATT_Spells,
};

// Light environment used by the mesh
var(Pawn) const DynamicLightEnvironmentComponent LightEnvironment;
// How much mana this pawn has
var(Pawn) float Mana;
// How much health this pawn has - sync'd with 'Pawn.Health'
var(Pawn) float HealthFloat;
// How long an attack takes to do (in seconds) - doesn't change, but does combine with Attack Speed stat.
var(Pawn) const float BaseAttackTime;

// Flash symbol name to use on the minimap
var(GFx) const string MinimapMovieClipSymbolName;

// Weapon third person mesh
var(Weapon) const SkeletalMeshComponent WeaponSkeletalMesh;
// Weapon attachment socket
var(Weapon) const Name WeaponAttachmentSocketName;
// Weapon fire mode
var(Weapon) const editinline instanced UDKMOBAWeaponFireMode WeaponFireMode;
// Weapon firing socket name, the socket is stored within WeaponSkeletalMesh
var(Weapon) const Name WeaponFiringSocketName;
// The type of damage this pawn deals when auto-attacking
var(Weapon) const class<DamageType> PawnDamageType<DisplayName=DamageType>;
// How much damage this unit does at level 1 (minus main stat contributions, upgrades/items)
var(Weapon) const float BaseDamage;

// Water splash effects
var(Effects) const ParticleSystem WaterSplashParticleSystem;
// Water splash sockets, 0 == Left, 1 == Right
var(Effects) const Name FootSocketNames[2];

// Teleport particle effect to play
var(Teleport) const ParticleSystem TeleportParticleTemplate;
// Teleport sound effect to play
var(Teleport) const SoundCue TeleportSoundCue;

// How many hit points this unit has at level 1 (minus strength hitpoints)
var(Stats) const float BaseHealth;
// How fast this unit regenerates hit points at level 1 (minus stregnth hit points regen)
var(Stats) const float BaseHealthRegen;
// How much mana this unit has at level 1 (minus intelligence mana)
var(Stats) const float BaseMana;
// How fast this unit regenerates mana at level 1 (minus intelligence mana regen)
var(Stats) const float BaseManaRegen;
// How much strength this unit has at level 1
var(Stats) const float BaseStrength;
// How much strength this unit gains with each level
var(Stats) const float LevelStrength;
// How much agility this unit has at level 1
var(Stats) const float BaseAgility;
// How much agility this unit gains with each level
var(Stats) const float LevelAgility;
// How much intelligence this unit has at level 1
var(Stats) const float BaseIntelligence;
// How much intelligence this unit gains with each level
var(Stats) const float LevelIntelligence;
// How much armor this unit has at level 1 (minus agility contributions, upgrades/items)
var(Stats) const float BaseArmor;
// How often this unit will evade an attack without upgrades/items
var(Stats) const float BaseEvasion;
// How often this unit will miss an attack without upgrades/items
var(Stats) const float BaseBlind;
// How much magic resistance this unit has without upgrades/items
var(Stats) const float BaseMagicResistance;
// How often this unit will evade a magic attack without upgrades/items
var(Stats) const float BaseMagicEvasion;
// How much to multiply magic damage from this unit without upgrades/items
var(Stats) const float BaseMagicAmp;
// Whether this unit cannot take damage from magic without upgrades/items
var(Stats) const bool BaseMagicImmunity;
// How often this unit will miss a magic attack without upgrades/items
var(Stats) const float BaseUnpracticed;
// Attack speed multiplier for this unit without upgrades/items
var(Stats) const float BaseAttackSpeed;
// How far this unit can see during the day without upgrades/items
var(Stats) const float BaseSight;
// How far this unit can see during the night without upgrades/items
var(Stats) const float BaseSightNight;
// How far away this unit can attack enemies without upgrades/items
var(Stats) const float BaseRange;
// How fast this unit can run without upgrades/items
var(Stats) const float BaseSpeed;
// Whether this unit can be seen by others without upgrades/items
var(Stats) const bool BaseVisibility;
// Whether this unit can see invisible characters without upgrades/items
var(Stats) const bool BaseTrueSight;
// Whether this unit can run through other heros without upgrades/items
var(Stats) const bool BaseColliding;
// Whether this unit can cast spells/abilities without upgrades/items
var(Stats) const bool BaseCanCast;
// The type of armor this unit has (changes how damage is reduced)
var(Stats) const EArmorType ArmorType;
// The (default) type of attack this unit uses (changes how damage is reduced)
var(Stats) const EAttackType AttackType;

// Screen bounding box 
var ProtectedWrite Box ScreenBoundingBox;
// Water volumes within the world
var ProtectedWrite array<UTWaterVolume> WaterVolumes;
// Hidden geometry skeletal mesh component
var ProtectedWrite SkeletalMeshComponent OcclusionSkeletalMeshComponent;
// Stats modifier
var ProtectedWrite UDKMOBAStatsModifier StatsModifier;
// Weapon detection trigger
var ProtectedWrite UDKMOBATrigger WeaponRangeTrigger;

// All DoT's that have been given to this pawn, and are still active.
var array<UDKMOBADoT> ActiveDoTs;

// Replication block
replication
{
	// Replicate only if the values are dirty, this replication info is owned by the player and from server to client
	if (bNetDirty)
		Mana;
}

/**
 * Called when the pawn is initialized
 *
 * @network		Server and client
 */
simulated event PostBeginPlay()
{
	local int i;
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	Super.PostBeginPlay();

	// Only the server needs to spawn the AIController which is used for pathing
	if (Role == Role_Authority)
	{
		SpawnDefaultController();
	}

	// Set the fire modes weapon owner
	if (WeaponFireMode != None)
	{
		WeaponFireMode.SetOwner(Self);

		// Create the weapon detection trigger
		WeaponRangeTrigger = Spawn(class'UDKMOBATrigger',,, Location);
		if (WeaponRangeTrigger != None)
		{
			// Attach the weapon range trigger to the pawn
			WeaponRangeTrigger.SetBase(Self);

			UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
			// Set the cylinder component size
			if (WeaponRangeTrigger.CollisionCylinderComponent != None && UDKMOBAPawnReplicationInfo != None)
			{
				WeaponRangeTrigger.CollisionCylinderComponent.SetCylinderSize(BaseRange - GetCollisionRadius(), 64.f);
			}
		}
	}

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		// Attach the weapon skeletal mesh component if one exists
		if (WeaponSkeletalMesh != None && Mesh.GetSocketByName(WeaponAttachmentSocketName) != None)
		{
			Mesh.AttachComponentToSocket(WeaponSkeletalMesh, WeaponAttachmentSocketName);
		}

		// If this is on a PC then initialize the hidden geometry skeletal mesh component
		if (!WorldInfo.IsConsoleBuild())
		{
			// Set the skeletal mesh
			OcclusionSkeletalMeshComponent.SetSkeletalMesh(OcclusionSkeletalMeshComponent.ParentAnimComponent.SkeletalMesh);
			// Create material instances for all elements
			for (i = 0; i < OcclusionSkeletalMeshComponent.GetNumElements(); ++i)
			{
				OcclusionSkeletalMeshComponent.CreateAndSetMaterialInstanceConstant(i);
			}

			// Attach the component
			AttachComponent(OcclusionSkeletalMeshComponent);
		}
	}

	// On the server
	if (Role == Role_Authority)
	{
		// Create the stats modifier
		StatsModifier = new class'UDKMOBAStatsModifier'();
		if (StatsModifier != None)
		{
			StatsModifier.AddStatChange(STATNAME_Strength, BaseStrength, MODTYPE_Addition, 0.f, true);
			StatsModifier.AddStatChange(STATNAME_Agility, BaseAgility, MODTYPE_Addition, 0.f, true);
			StatsModifier.AddStatChange(STATNAME_Intelligence, BaseIntelligence, MODTYPE_Addition, 0.f, true);
		}
	}

	PlayerController = GetALocalPlayerController();
	if (PlayerController != None)
	{
		// Add myself to the local player controller's HUD
		UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
		if (UDKMOBAHUD != None)
		{
			UDKMOBAHUD.AddTouchInterface(Self);
			if (UDKMOBAHUD.HUDMovie != None)
			{
				UDKMOBAHUD.HUDMovie.AddMinimapInterface(Self);
			}
		}

		SetOcclusionColor(PlayerController.GetTeamNum());
	}

	// Set the health float, which is maintained during the game
	HealthFloat = float(Health);
}

/**
 * Called when the local player has changed teams
 *
 * @network			Server and client
 */
simulated function NotifyLocalPlayerTeamReceived()
{
	local PlayerController PlayerController;

	PlayerController = GetALocalPlayerController();
	if (PlayerController != None)
	{
		SetOcclusionColor(PlayerController.GetTeamNum());
	}
}

/**
 * Called every time the pawn is updated
 *
 * @param		DeltaTime		Time since the last time the pawn was updated
 * @network						Server and client
 */
simulated function Tick(float DeltaTime)
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	Super.Tick(DeltaTime);

	if (Role == Role_Authority)
	{
		// Update the health and mana
		UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
		if (UDKMOBAPawnReplicationInfo != None)
		{
			HealthFloat = FMin(float(HealthMax), HealthFloat + (UDKMOBAPawnReplicationInfo.HealthRegenerationAmount * DeltaTime));
			Mana = FMin(UDKMOBAPawnReplicationInfo.ManaMax, Mana + (UDKMOBAPawnReplicationInfo.ManaRegenerationAmount * DeltaTime));
		}

		// Sync the health with the float
		Health = int(HealthFloat);
		
		// Recalculates the pawn stats
		RecalculateStats();
	}
}

/**
 * Recalculate the pawn stat
 *
 * @network		Server
 */
function RecalculateStats()
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;
	local bool JustSpawned;
	local float OldRange;

	if (StatsModifier == None)
	{
		return;
	}

	// Check if this pawn has just spawned
	JustSpawned = (Abs(WorldInfo.TimeSeconds - SpawnTime) < 0.05f);
	HealthMax = int(StatsModifier.CalculateStat(STATNAME_HPMax, BaseHealth));

	// If just spawned, then set Health to HealthMax
	if (JustSpawned)
	{
		HealthFloat = HealthMax;
		Health = HealthMax;
	}

	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None)
	{
		// MUST calc attributes first
		UDKMOBAPawnReplicationInfo.Strength = StatsModifier.CalculateStat(STATNAME_Strength);
		UDKMOBAPawnReplicationInfo.Agility = StatsModifier.CalculateStat(STATNAME_Agility);
		UDKMOBAPawnReplicationInfo.Intelligence = StatsModifier.CalculateStat(STATNAME_Intelligence);

		// Now can go through the rest
		UDKMOBAPawnReplicationInfo.ManaMax = StatsModifier.CalculateStat(STATNAME_ManaMax, BaseMana);

		// If just spawned, then set Mana to Mana Max
		if (JustSpawned)
		{
			Mana = UDKMOBAPawnReplicationInfo.ManaMax;
		}

		UDKMOBAPawnReplicationInfo.ManaRegenerationAmount = StatsModifier.CalculateStat(STATNAME_ManaRegen, BaseManaRegen);
		UDKMOBAPawnReplicationInfo.HealthRegenerationAmount = StatsModifier.CalculateStat(STATNAME_HPRegen, BaseHealthRegen);

		// Now calc all the rest of the stats
		UDKMOBAPawnReplicationInfo.Damage = StatsModifier.CalculateStat(STATNAME_Damage, BaseDamage);
		UDKMOBAPawnReplicationInfo.Armor = StatsModifier.CalculateStat(STATNAME_Armor, BaseArmor);
		UDKMOBAPawnReplicationInfo.MagicResistance = StatsModifier.CalculateStat(STATNAME_MagicResistance, BaseMagicResistance);
		UDKMOBAPawnReplicationInfo.MagicImmunity = (StatsModifier.CalculateStat(STATNAME_MagicImmunity, BaseMagicImmunity) > 0.5f) ? true : false;
		UDKMOBAPawnReplicationInfo.AttackSpeed = StatsModifier.CalculateStat(STATNAME_AttackSpeed, BaseAttackSpeed);
		UDKMOBAPawnReplicationInfo.Sight = StatsModifier.CalculateStat(STATNAME_Sight, BaseSight);
		UDKMOBAPawnReplicationInfo.SightNight = StatsModifier.CalculateStat(STATNAME_SightNight, BaseSightNight);
		OldRange = UDKMOBAPawnReplicationInfo.Range;
		UDKMOBAPawnReplicationInfo.Range = StatsModifier.CalculateStat(STATNAME_Range, BaseRange);
		if (UDKMOBAPawnReplicationInfo.Range != OldRange && WeaponRangeTrigger.CollisionCylinderComponent != None)
		{
			WeaponRangeTrigger.CollisionCylinderComponent.SetCylinderSize(UDKMOBAPawnReplicationInfo.Range - GetCollisionRadius(), 64.f);
		}
		UDKMOBAPawnReplicationInfo.Speed = StatsModifier.CalculateStat(STATNAME_Speed, BaseSpeed);
		GroundSpeed = UDKMOBAPawnReplicationInfo.Speed;
		UDKMOBAPawnReplicationInfo.Visibility = (StatsModifier.CalculateStat(STATNAME_Visibility, BaseVisibility) > 0.5f) ? true : false;
		UDKMOBAPawnReplicationInfo.TrueSight = (StatsModifier.CalculateStat(STATNAME_TrueSight, BaseTrueSight) > 0.5f) ? true : false;
		UDKMOBAPawnReplicationInfo.Colliding = (StatsModifier.CalculateStat(STATNAME_Colliding, BaseColliding) > 0.5f) ? true : false;
		UDKMOBAPawnReplicationInfo.CanCast = (StatsModifier.CalculateStat(STATNAME_CanCast, BaseCanCast) > 0.5f) ? true : false;
		UDKMOBAPawnReplicationInfo.Evasion = StatsModifier.CalculateStat(STATNAME_Evasion, BaseEvasion);
		UDKMOBAPawnReplicationInfo.Blind = StatsModifier.CalculateStat(STATNAME_Blind, BaseBlind);
		UDKMOBAPawnReplicationInfo.MagicEvasion = StatsModifier.CalculateStat(STATNAME_MagicEvasion, BaseMagicEvasion);
		UDKMOBAPawnReplicationInfo.MagicAmp = StatsModifier.CalculateStat(STATNAME_MagicAmp, BaseMagicAmp);
		UDKMOBAPawnReplicationInfo.Unpracticed = StatsModifier.CalculateStat(STATNAME_Unpracticed, BaseUnpracticed);
	}
}

/**
 * Pawn starts firing
 *
 * @param		FireModeNum		Unused
 * @network						Server and client
 */
simulated function StartFire(byte FireModeNum)
{
	// Fire the weapon fire mode
	if (WeaponFireMode != None)
	{
		WeaponFireMode.StartFire();
	}
}


/**
 * Pawn stops firing
 * 
 * @param		FireModeNum		Unused
 * @network						Server and client
 */
simulated function StopFire(byte FireModeNum)
{
	// Stop firing the weapon fire mode
	if (WeaponFireMode != None)
	{
		WeaponFireMode.StopFire();
	}
}

/**
 * Returns true if the weapon is firing or not
 *
 * @return		Returns true if the weapon is firing
 * @network		Server and client
 */
function bool IsFiring()
{
	// Returns if the weapon fire mode is firing
	if (WeaponFireMode != None)
	{
		return WeaponFireMode.IsFiring();
	}

	return false;
}

/**
 * Sets the occlusion color based on the local player controller's team num
 *
 * @param		LocalPlayerControllerTeamNum		Local player's controller team num
 * @network											Server and client
 */
simulated function SetOcclusionColor(byte LocalPlayerControllerTeamNum)
{
	local int i;
	local MaterialInstanceConstant MaterialInstanceConstant;
	local byte TeamNum;
	local LinearColor OcclusionColor;

	if (WorldInfo.NetMode != NM_DedicatedServer && !WorldInfo.IsConsoleBuild())
	{
		// Get my team num
		TeamNum = GetTeamNum();
		if (LocalPlayerControllerTeamNum == 255)
		{
			OcclusionColor = MakeLinearColor(1.f, 0.f, 1.f, 1.f);
		}
		else
		{
			// If this pawn's team is equal to the local players team then make the occlusion green
			if (TeamNum == LocalPlayerControllerTeamNum)
			{
				OcclusionColor = MakeLinearColor(0.f, 1.f, 0.f, 1.f);
			}
			// Otherwise make it red
			else
			{
				OcclusionColor = MakeLinearColor(1.f, 0.f, 0.f, 1.f);
			}
		}

		for (i = 0; i < OcclusionSkeletalMeshComponent.GetNumElements(); ++i)
		{
			MaterialInstanceConstant = MaterialInstanceConstant(OcclusionSkeletalMeshComponent.GetMaterial(i));
			if (MaterialInstanceConstant != None)
			{
				MaterialInstanceConstant.SetVectorParameterValue('OcclusionColor', OcclusionColor);
			}
		}
	}
}

/**
 * Plays the foot step sound
 *
 * @param		FootDown		0 = Left foot, 1 = Right foot
 * @network						Server and client
 */
simulated event PlayFootStepSound(int FootDown)
{
	local int i;
	local Vector FootLocation, SocketLocation;
	local Rotator SocketRotation;

	// Calculate the foot location
	FootLocation = Location - (Vect(0.f, 0.f, 1.f) * GetCollisionHeight());

	// See if the pawn is standing in water
	if (WaterVolumes.Length > 0 && WaterSplashParticleSystem != None && (FootDown == 0 || FootDown == 1))
	{
		for (i = 0; i < WaterVolumes.Length; ++i)
		{
			if (WaterVolumes[i].EncompassesPoint(FootLocation) && WorldInfo.MyEmitterPool != None)
			{				
				Mesh.GetSocketWorldLocationAndRotation(FootSocketNames[FootDown], SocketLocation, SocketRotation);
				WorldInfo.MyEmitterPool.SpawnEmitter(WaterSplashParticleSystem, SocketLocation);
				return;
			}			
		}
	}
}

/**
 * Called when the pawn is spawned
 *
 * @param		bOut		Unused
 * @param		bSound		If true, play a teleport sound
 * @network					Server and client
 */
simulated function PlayTeleportEffect(bool bOut, bool bSound)
{
	Super.PlayTeleportEffect(bOut, bSound);

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		// Spawn the particle effect
		if (TeleportParticleTemplate != None && WorldInfo.MyEmitterPool != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(TeleportParticleTemplate, Location, Rotation);
		}

		// Play the sound effect
		if (bSound && TeleportSoundCue != None)
		{
			PlaySound(TeleportSoundCue);
		}
	}
}

/**
 * This pawn has died
 *
 * @param	Killer			Who killed this pawn
 * @param	DamageType		What killed it
 * @param	HitLocation		Where did the hit occur
 * @return					Returns true if the pawn died
 */
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	// Destroy the weapon fire
	if (WeaponFireMode != None)
	{
		WeaponFireMode.Destroy();
	}
	
	// Destroy the weapon range trigger
	if (WeaponRangeTrigger != None)
	{
		WeaponRangeTrigger.Destroy();
		WeaponRangeTrigger = None;
	}

	// Remove it from the touch interfaces array in the local HUD
	PlayerController = GetALocalPlayerController();
	if (PlayerController != None)
	{
		UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
		if (UDKMOBAHUD != None)
		{
			UDKMOBAHUD.RemoveTouchInterface(Self);
			if (UDKMOBAHUD.HUDMovie != None)
			{
				UDKMOBAHUD.HUDMovie.RemoveMinimapInterface(Self);
			}
		}
	}

	return Super.Died(Killer, DamageType, HitLocation);
}

// ======================================
// UDKMOBAMinimapInterface implementation
// ======================================
/**
 * Returns what layer this actor should have it's movie clip in Scaleform
 *
 * @return		Returns the layer enum
 * @network		Server and client
 */
simulated function EMinimapLayer GetMinimapLayer()
{
	return EML_None;
}

/**
 * Returns whether or not this actor is still valid to be rendered on the mini map
 *
 * @return		Returns true if the mini map should render this actor or not
 * @network		Server and client
 */
simulated function bool IsVisibleOnMinimap()
{
	return (Health > 0);
}

/**
 * Returns the name of the movie clip symbol to instance on the minimap
 *
 * @return		Returns the name of the movie clip symbol to instance on the minimap
 * @network		Server and client
 */
simulated function String GetMinimapMovieClipSymbolName()
{
	return MinimapMovieClipSymbolName;
}

/**
 * Updates the minimap icon
 *
 * @param		MinimapIcon		GFxObject which represents the minimap icon
 * @network						Server and client
 */
simulated function UpdateMinimapIcon(UDKMOBAGFxMinimapIconObject MinimapIcon);

// ====================================
// UDKMOBATouchInterface implementation
// ====================================
/**
 * Invalidates the touch bounding box for this actor
 *
 * @network		Server and client
 */
simulated function InvalidateTouchBoundingBox()
{
	if (ScreenBoundingBox.Min.X != -1 || ScreenBoundingBox.Min.Y != -1)
	{
		ScreenBoundingBox.Min.X = -1.f;
		ScreenBoundingBox.Min.Y = -1.f;
		ScreenBoundingBox.Max.X = -1.f;
		ScreenBoundingBox.Max.Y = -1.f;
	}
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
	if (WorldInfo.TimeSeconds - LastRenderTime < 0.3f)
	{
		GetComponentsBoundingBox(ComponentsBoundingBox);
		if (class'UDKMOBAObject'.static.GetPrimitiveComponentScreenBoundingBox(HUD, ComponentsBoundingBox, ScreenBoundingBox))
		{
			return;
		}
	}

	// Otherwise reset the screen bounding box to something invalid
	InvalidateTouchBoundingBox();
}

/**
 * Returns true if the point is within the screen bounding box
 *
 * @param		Point		Point to test
 * @return					Returns true if the point is within the screen bounding box
 * @network					Server and client
 */
simulated function bool IsPointInTouchBoundingBox(Vector2D Point)
{
	return class'UDKMOBAObject'.static.IsPointInTouchBoundingBox(Point, ScreenBoundingBox);
}

/**
 * Returns the touch priority to allow other touch interfaces to be more (or less) important than others
 *
 * @return		Returns the touch priority to allow sorting of multiple touch priorities
 * @network		Server and client
 */
simulated function int GetTouchPriority()
{
	return -1;
}

/**
 * Returns the touch bounding box for this actor
 *
 * @return		Returns the touch bounding box
 * @network		Server and client
 */
simulated function Box GetTouchBoundingBox()
{
	return ScreenBoundingBox;
}

// =====================================
// UDKMOBAAttackInterface implementation
// =====================================
/**
 * Returns the weapon firing location and rotation
 *
 * @param		FireLocation		Fire location to output
 * @param		FireRotation		Fire rotation to output
 * @network							Server and client
 */
simulated function GetWeaponFiringLocationAndRotation(out Vector FireLocation, out Rotator FireRotation)
{
	local Actor CurrentEnemy;

	// Grab the skeletal mesh component, abort if it doesn't exist
	if (WeaponSkeletalMesh == None || WeaponSkeletalMesh.SkeletalMesh == None)
	{
		return;
	}

	// Check that FiringSocketName is a valid name of a socket
	if (WeaponSkeletalMesh.GetSocketByName(WeaponFiringSocketName) == None)
	{
		return;
	}

	// Get the current enemy, abort if there is no current enemy
	CurrentEnemy = GetEnemy();
	if (CurrentEnemy == None)
	{
		return;
	}

	// Grab the world socket location and rotation and forward this to begin fire
	WeaponSkeletalMesh.GetSocketWorldLocationAndRotation(WeaponFiringSocketName, FireLocation, FireRotation);
}

/**
 * Returns the enemy
 *
 * @return		Returns the enemy
 * @network		Server and client
 */
simulated function Actor GetEnemy()
{
	local UDKMOBAAIController UDKMOBAAIController;

	UDKMOBAAIController = UDKMOBAAIController(Controller);
	if (UDKMOBAAIController != None)
	{
		return UDKMOBAAIController.CurrentEnemy;
	}

	return None;
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
	return Controller != None && Health > 0;
}

/**
 * Returns the amount of damage that this actor does for an attack. NOT used for spells.
 *
 * @return		The amount of damage done, with Blind taken account of.
 * @network		Server and client
 */
simulated function float GetDamage()
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None)
	{
		return UDKMOBAPawnReplicationInfo.Damage;
	}

	return 0.f;
}

/**
 * Returns the amount of damage that this actor does for an attack.
 *
 * @return		The type of damage this actor does for auto-attacks.
 * @network		Server and client
 */
simulated function class<DamageType> GetDamageType()
{
	return PawnDamageType;
}

/**
 */
simulated function bool IsInvulnerable()
{
	return false;
}

// ====================================
// UDKMOBAStatsInterface implementation
// ====================================
/**
 * Returns the health of this actor
 *
 * @return		Returns the health of this actor
 * @network		Server and client
 */
simulated function int GetHealth()
{
	return Health;
}

/**
 * Returns the health as a percentage value
 *
 * @return		The health as a percentage value
 * @network		Server and client
 */
simulated function float GetHealthPercentage()
{
	return float(Health) / float(HealthMax);
}

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
 * @return		The mana as a percentage value
 * @network		Server and client
 */
simulated function float GetManaPercentage()
{
	return 0.f;
}

/**
 * Returns what to multiply damage by, based on our ArmorType and the attackers DamageType. This
 * is just a big 5x5 matrix of magic numbers, these values match DotA. So call on the defender.
 *
 * @param		IncomingAttackType	The AttackType of the other pawn
 */
function float GetArmorTypeMultiplier(EAttackType IncomingAttackType)
{
	local int Counter;
	local UDKMOBAGameInfo UDKMOBAGameInfo;

	UDKMOBAGameInfo = UDKMOBAGameInfo(WorldInfo.Game);
	if (UDKMOBAGameInfo != None)
	{
		for (Counter = 0; Counter < UDKMOBAGameInfo.default.Properties.ArmorAttackMatrix.Length; Counter++)
		{
			if (UDKMOBAGameInfo.default.Properties.ArmorAttackMatrix[Counter].AttackType == IncomingAttackType && UDKMOBAGameInfo.default.Properties.ArmorAttackMatrix[Counter].ArmorType == ArmorType)
			{
				return UDKMOBAGameInfo.default.Properties.ArmorAttackMatrix[Counter].Multiplier;
			}
		}
	}
	return 1.f;
}

/**
 * Adjusts the damage before applying it to the pawn. This iterates over all of the spells and
 * items to allow them to adjust damage. It also takes armor into account - but not Armor Type.
 *
 * @param		InDamage			Output damage
 * @param		Momentum			Output momentum
 * @param		InstigatedBy		Controller that instigated the damage
 * @param		HitLocation			World location where the damage occured
 * @param		DamageType			Damage type used to apply the damage
 * @param		HitInfo				Struct which contains parameters on the hit
 * @param		DamageCauser		Actor that caused damage to this pawn
 * @network							Server
 */
function AdjustDamage(out int InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	local float OutDamage;
	local int i;
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	OutDamage = InDamage;
	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None)
	{
		// First, check for evasion
		if (DamageType == class'UDKMOBADamageTypePhysical')
		{
			if (FRand() < UDKMOBAPawnReplicationInfo.Evasion)
			{
				// missed!
				InDamage = 0;
				return;
			}
		}
		// And magic evasion...
		else if (DamageType == class'UDKMOBADamageTypeMagical')
		{
			if (UDKMOBAPawnReplicationInfo.MagicImmunity || FRand() < UDKMOBAPawnReplicationInfo.MagicEvasion)
			{
				// immune/missed!
				InDamage = 0;
				return;
			}
			else
			{
				OutDamage *= UDKMOBAPawnReplicationInfo.MagicResistance;
			}
		}

		// Iterate through spells, and allow them to adjust damage
		for (i = 0; i < UDKMOBAPawnReplicationInfo.Spells.Length; ++i)
		{
			if (UDKMOBAPawnReplicationInfo.Spells[i] != None)
			{
				UDKMOBAPawnReplicationInfo.Spells[i].AdjustDamage(OutDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);
			}
		}

		// Iterate through items, and allow them to adjust damage
		for (i = 0; i < UDKMOBAPawnReplicationInfo.Items.Length; ++i)
		{
			if (UDKMOBAPawnReplicationInfo.Items[i] != None)
			{
				UDKMOBAPawnReplicationInfo.Items[i].AdjustDamage(OutDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);
			}
		}

		// Now handle armor - these formulas taken from DotA
		if (UDKMOBAPawnReplicationInfo.Armor > 0.f)
		{
			OutDamage *= 1.f - ((0.06f * UDKMOBAPawnReplicationInfo.Armor) / (1.06f * UDKMOBAPawnReplicationInfo.Armor));
		}
		else if (UDKMOBAPawnReplicationInfo.Armor < 0.f)
		{
			OutDamage *= 2.f - (0.94f ** Abs(UDKMOBAPawnReplicationInfo.Armor));
		}
	}

	InDamage = Int(OutDamage);

	Super.AdjustDamage(InDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);
}

/**
 * Overridden to handle our HealthFloat value. Handles damage dealt to the pawn
 *
 * @param		Damage				How much damage to deal to the pawn
 * @param		InstigatedBy		Controller that instigated this damage event
 * @param		HitLocation			World location where damage was applied
 * @param		Momentum			Momentum to push the pawn
 * @param		DamageType			Damage type to affect the pawn
 * @param		HitInfo				Struct which contains parameters on the hit
 * @param		DamageCauser		Actor that caused damage to this pawn
 * @network							Server
 */
event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local int ActualDamage;
	local Controller Killer;

	if (Role < ROLE_Authority || Health <= 0 || IsInvulnerable())
	{
		return;
	}

	if (DamageType == None)
	{
		DamageType = class'DamageType';
	}

	Damage = Max(Damage, 0);

	if (Physics == PHYS_None && DrivenVehicle == None)
	{
		SetMovementPhysics();
	}

	if (Physics == PHYS_Walking && DamageType.default.bExtraMomentumZ)
	{
		Momentum.Z = FMax(Momentum.Z, 0.4f * VSize(Momentum));
	}

	Momentum = Momentum / Mass;

	if (DrivenVehicle != None)
	{
		DrivenVehicle.AdjustDriverDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
	}

	ActualDamage = Damage;
	WorldInfo.Game.ReduceDamage(ActualDamage, Self, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
	AdjustDamage(ActualDamage, Momentum, InstigatedBy, HitLocation, DamageType, HitInfo, DamageCauser);

	// call Actor's version to handle any SeqEvent_TakeDamage for scripting
	Super(Actor).TakeDamage(ActualDamage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);

	HealthFloat -= ActualDamage;
	Health = int(HealthFloat);

	if (IsZero(HitLocation))
	{
		HitLocation = Location;
	}

	if (Health <= 0)
	{
		// pawn died
		Killer = SetKillInstigator(InstigatedBy, DamageType);
		TearOffMomentum = Momentum;
		Died(Killer, DamageType, HitLocation);
	}
	else
	{
		HandleMomentum(Momentum, HitLocation, DamageType, HitInfo);
		NotifyTakeHit(InstigatedBy, HitLocation, ActualDamage, DamageType, Momentum, DamageCauser);

		if (DrivenVehicle != None)
		{
			DrivenVehicle.NotifyDriverTakeHit(InstigatedBy, HitLocation, ActualDamage, DamageType, Momentum);
		}

		if (InstigatedBy != None && InstigatedBy != Controller)
		{
			LastHitBy = InstigatedBy;
		}
	}

	PlayHit(ActualDamage, InstigatedBy, HitLocation, DamageType, Momentum, HitInfo);
	MakeNoise(1.f);
}

/**
 * Called before sending any sort of attack, so that Blind, Unpracticed, and Magic Amp can be taken
 * account of. Called on the attacker.
 *
 * @param	Damage		The amount of base damage the unit/spell wants to do
 * @param	DamageType	The class of damage being dealt
 */
function SendAttack(out float Damage, class<DamageType> DamageType)
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None)
	{
		if (DamageType == class'UDKMOBADamageTypePhysical')
		{
			if (FRand() < UDKMOBAPawnReplicationInfo.Blind)
			{
				// missed!
				Damage = 0.f;
			}
		}
		else if (DamageType == class'UDKMOBADamageTypeMagical')
		{
			if (FRand() < UDKMOBAPawnReplicationInfo.Unpracticed)
			{
				// missed!
				Damage = 0.f;
			}
			else
			{
				Damage *= UDKMOBAPawnReplicationInfo.MagicAmp;
			}
		}
	}
}

/**
 * Called when this actor is torn off from the network
 *
 * @network		Server and client
 */
simulated event TornOff()
{
	Health = -100;
	HealthFloat = -100.f;
	BeginRagdoll();
	LifeSpan = 5.f;
}

/**
 * Begins ragdolling the pawn
 *
 * @network		All
 */
simulated function BeginRagdoll()
{
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// Turn off collision
	SetCollision(false, false, false);
	CollisionComponent = Mesh;
	// Always perform kinematic update regardless of distance
	Mesh.MinDistFactorForKinematicUpdate = 0.f;
	// Force an update on the skeletal mesh
	Mesh.ForceSkelUpdate();
	Mesh.UpdateRBBonesFromSpaceBases(true, true);
	// Turn on physics assets
	Mesh.PhysicsWeight = 1.f;
	// Set the physics simulation
	SetPhysics(PHYS_RigidBody);
	// Unfix all of the bodies on the physics asset instance
	Mesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
	// Set the rigid body channels
	Mesh.SetRBChannel(RBCC_Pawn);
	Mesh.SetRBCollidesWithChannel(RBCC_Default, true);
	Mesh.SetRBCollidesWithChannel(RBCC_Pawn, true);
	Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, true);
	Mesh.SetRBCollidesWithChannel(RBCC_Untitled3, false);
	Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, true);
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
	return (RequestingPlayerReplicationInfo != None && RequestingPlayerReplicationInfo.Team != None && RequestingPlayerReplicationInfo.Team.TeamIndex == GetTeamNum());
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

/**
 * Add a new DoT to effect this pawn.
 *
 * @param		NewDoT		New DoT object
 * @network					Server
 */
function AddDoT(UDKMOBADoT NewDoT)
{
	NewDoT.Target = Self;
	NewDoT.ExpiryTime = WorldInfo.TimeSeconds + NewDoT.Duration;
	ActiveDoTs.AddItem(NewDoT);
	SetTimer(NewDot.Period, true, 'DamageCalled', NewDoT);
}

/**
 * Called by the Tick to ensure DoT's are removed once expired.
 *
 * @network		Server
 */
function RemoveOldDoTs()
{
	local int i;

	for (i = 0; i < ActiveDoTs.Length; ++i)
	{
		if (ActiveDoTs[i].ExpiryTime < WorldInfo.TimeSeconds)
		{
			ClearTimer('DamageCalled', ActiveDoTs[i]);
			ActiveDoTs.Remove(i, 1);
			--i;
		}
	}
}

/**
 * A DoT has proc'd, do its effects
 *
 * @param		NewDoT		DoT object
 * @network					Server
 */
function ProcDoT(UDKMOBADoT TheDoT)
{
	local float DamageDone;

	DamageDone = TheDoT.DamageAmount * GetArmorTypeMultiplier(TheDoT.AttackType);
	TakeDamage(DamageDone, TheDoT.Instigator, Location, Velocity, TheDoT.DamageType);
}

// Default properties block
defaultproperties
{
	Components.Remove(Sprite)

 	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=true
		bUseBooleanEnvironmentShadowing=false
		ModShadowFadeoutTime=0.75f
		bIsCharacterLightEnvironment=true
		bAllowDynamicShadowsOnTranslucency=true
 	End Object
 	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

 	Begin Object Class=SkeletalMeshComponent Name=MySkeletalMeshComponent
		CollideActors=true
		BlockRigidBody=true
		bHasPhysicsAssetInstance=true
		bUpdateKinematicBonesFromAnimation=false
		MinDistFactorForKinematicUpdate=0.f
		LightEnvironment=MyLightEnvironment
 	End Object
 	Mesh=MySkeletalMeshComponent
 	Components.Add(MySkeletalMeshComponent)

	Begin Object Class=SkeletalMeshComponent Name=MyWeaponSkeletalMeshComponent
		CollideActors=false
		BlockRigidBody=false
		bHasPhysicsAssetInstance=false
		bUpdateKinematicBonesFromAnimation=false
		MinDistFactorForKinematicUpdate=0.f
		LightEnvironment=MyLightEnvironment
	End Object
	WeaponSkeletalMesh=MyWeaponSkeletalMeshComponent
	Components.Add(MyWeaponSkeletalMeshComponent)

	Begin Object Class=SkeletalMeshComponent Name=MyOcclusionSkeletalMeshComponent
		CollideActors=false
		BlockRigidBody=false
		bHasPhysicsAssetInstance=false
		bUpdateKinematicBonesFromAnimation=false
		MinDistFactorForKinematicUpdate=0.f
		ParentAnimComponent=MySkeletalMeshComponent
		bUseBoundsFromParentAnimComponent=true
		DepthPriorityGroup=SDPG_Foreground
		Materials(0)=Material'UDKMOBA_Game_Resources_PC.OcclusionMaterial'
		Materials(1)=Material'UDKMOBA_Game_Resources_PC.OcclusionMaterial'
	End Object
	OcclusionSkeletalMeshComponent=MyOcclusionSkeletalMeshComponent

	MinimapMovieClipSymbolName="minimapcircleicon"
	RotationRate=(Yaw=0,Pitch=0,Roll=0)	
	Mana=10
	BaseAttackTime=2.f
	Health=100
	HealthMax=100
	Physics=PHYS_Falling
	WalkingPhysics=PHYS_Walking
	bAlwaysRelevant=true
	bReplicateHealthToAll=true
	BaseHealth=10.f
	BaseHealthRegen=0.f
	BaseMana=0.f
	BaseManaRegen=0.f
	BaseStrength=1.f
	LevelStrength=1.f
	BaseAgility=1.f
	LevelAgility=1.f
	BaseIntelligence=1.f
	LevelIntelligence=1.f
	BaseDamage=5.f
	BaseArmor=1.f
	BaseEvasion=0.f
	BaseBlind=0.f
	BaseMagicResistance=1.f
	BaseMagicAmp=1.f
	BaseMagicImmunity=false
	BaseUnpracticed=0.f
	BaseAttackSpeed=1.f
	BaseSight=512.f
	BaseSightNight=384.f
	BaseRange=256.f
	BaseSpeed=500.f
	BaseVisibility=true
	BaseTrueSight=false
	BaseColliding=true
	BaseCanCast=true
	PawnDamageType=class'DamageType'
	ArmorType=ART_Unarmored
	AttackType=ATT_Normal
}