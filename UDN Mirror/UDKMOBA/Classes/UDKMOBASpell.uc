//=============================================================================
// UDKMOBASpell: Base spell class which is used by all spells.
//
// Mostly a utility class to handle aspects such as cool down, a generic
// interface to use the spells and to store data about the spells. Note that we
// 'activate' a spell, which causes animations to start. After an 'activation
// time', we then 'cast' the spell, which actually deals damage/spawns a
// projectile/whatever. There can then be return animations, although once the
// 'cast' is made, other commands can be queued.
//
// * player decides to use a spell
// * player optionally aims the spell
// * the spell activates, effects spawn, animations start
// * an activation time passes. If the spell is channeling, this is 0 seconds
// * the spell casts, damage is deal, particles are spawned, reverse animations
// * a cast time passes. If the spell is channeling, this can be interrupted
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBASpell extends ReplicationInfo
	HideCategories(Display, Attachment, Physics, Advanced, Debug, Object)
	abstract;

// The different ways a spell can be aimed
enum EAimType
{
	EAT_World<DisplayName=World>, // we trace against the level only
	EAT_Actor<DisplayName=Actor>, // will trace against any actor
	EAT_None<DisplayName=No Aiming> // no aim, just fire
};

// Name of the texture to use for the spell icon in the UI
var(Spell) const String IconName;
// The maximum level that the spell can be upgraded to
var(Spell) const int MaxLevel;
// Mana cost to use the active ability of this spell - by level
var(Spell) const array<float> ManaCost;
// Whether this spell has an active ability at all.
var(Spell) bool HasActive;
// Whether this spell needs the user to choose where to fire it
var(Spell) const EAimType AimingType;

// Decal material to use, only on PC
var(Spell, Aim) const MaterialInterface DecalMaterial;
// Decal material size
var(Spell, Aim) const Vector2D DecalSize;

// Sound to play when activating the spell
var(Spell, Active) const SoundCue ActivatingSoundCue;
// Particle effect to create when activating the spell
var(Spell, Active) const ParticleSystem ActivatingParticleTemplate;
// Sound to play when casting the spell
var(Spell, Active) const SoundCue CastingSoundCue;
// Particle effect to create when casting the spell
var(Spell, Active) const ParticleSystem CastingParticleTemplate;
// Cooldown time. Time it takes for this spell to refresh after it has been cast - by level
var(Spell, Active) const array<float> CooldownTime;
// How long (in seconds) from triggering the ability before damage/etc is actually dealt
var(Spell, Active) const array<float> ActivationTime;
// What sort of attack type a projectile or damage given uses
var(Spell, Active) const UDKMOBAPawn.EAttackType AttackType;

// Used if AimingType == EAT_World to say where the spell is going
var Vector TargetLocation;
// Used if AimingType == EAT_Actor to say where the spell is going
var Actor TargetActor;
// Index within the Spells array. This is because the ordering of the Spells arrays are important!
var RepNotify int OrderIndex;
// Current upgrade level of the spell
var RepNotify int Level;
// Player replication info that owns this spell.
var RepNotify UDKMOBAPawnReplicationInfo OwnerReplicationInfo;
// Whether this spell is channeling right now
var ProtectedWrite RepNotify bool IsChanneling;
// When this spell was (last) triggered
var ProtectedWrite float ActivatedAt;
// Pawn that currently owns this spell
var ProtectedWrite Pawn PawnOwner;
// Activation count which increases when the spell is activated. If the activation count gets reset back to zero, then it is considered to be refreshed
var ProtectedWrite RepNotify int ActivationCount;
// Cast count which increases when the spell is cast. If the cast count gets reset back to zero, then it is considered to be refreshed
var ProtectedWrite RepNotify int CastCount;

// Replication block
replication
{
	// Replicate if the variables are dirty and from the server to the client
	if (bNetDirty)
		IsChanneling, OwnerReplicationInfo, ActivationCount, CastCount, Level;

	// Replicate if the variable is dirty, spell is owned by the player and from the server to the client
	if (bNetDirty && bNetOwner)
		OrderIndex;
}

/**
 * Called when a variable flagged as RepNotify has been replicated
 *
 * @param		VarName			Name of the variable that was replicated
 * @network						Server and client
 */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == NameOf(OwnerReplicationInfo) || VarName == NameOf(OrderIndex))
	{		
		if (OwnerReplicationInfo != None)
		{
			// When both OwnerReplicationInfo and OrderIndex are not valid, add it
			if (OrderIndex != INDEX_NONE)
			{
				OwnerReplicationInfo.AddSpell(Self, OrderIndex);
			}

			// Initialize when at least the OwnerReplicationInfo is valid
			Initialize();
		}
	}
	else if (VarName == NameOf(ActivationCount))
	{
		ActivateEffects(true);
	}
	else if (VarName == NameOf(CastCount))
	{
		CastEffects(true);
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Sets the owner on the client side
 * 
 * @param		NewOwner		New owner to set for the spell
 * @network						Local Client
 */
reliable client function ClientSetOwner(Actor NewOwner)
{
	SetOwner(NewOwner);
}

/**
 * Initializes the spell
 *
 * @network			Server and client
 */
simulated function Initialize()
{
	local Pawn Pawn;

	// Abort if the owner replication info is none
	if (OwnerReplicationInfo == None)
	{
		return;
	}

	// Grab the pawn with the matching owner replication info
	ForEach WorldInfo.AllPawns(class'Pawn', Pawn)
	{
		if (Pawn.PlayerReplicationInfo == OwnerReplicationInfo)
		{
			PawnOwner = Pawn;
			break;
		}
	}
}

/**
 * Sends the player a message
 *
 * @param		Message		Message to display on the HUD
 * @network					Server and client
 */
simulated function SendPlayerMessage(string Message)
{
	local UDKMOBAHeroAIController UDKMOBAHeroAIController;
	local UDKMOBAHUD UDKMOBAHUD;

	// Ensure we have a pawn
	if (PawnOwner == None)
	{
		return;
	}

	// Ensure we have a hero AI controller
	UDKMOBAHeroAIController = UDKMOBAHeroAIController(PawnOwner.Controller);
	if (UDKMOBAHeroAIController == None || UDKMOBAHeroAIController.UDKMOBAPlayerController == None)
	{
		return;
	}

	UDKMOBAHUD = UDKMOBAHUD(UDKMOBAHeroAIController.UDKMOBAPlayerController.MyHUD);
	if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
	{
		UDKMOBAHUD.HUDMovie.AddCenteredMessage(Message);
	}
}

/**
 * Returns true if the spell has an active ability that can be cast
 *
 * @return		Returns true if the spell can be cast
 * @network		Server and client
 */
simulated function bool CanCast()
{
	local UDKMOBAPawn UDKMOBAPawn;

	// Check if the spell even has an active ability or not
	if (!HasActive)
	{
		return false;
	}

	// Check if the spell has any levels
	if (Level < 0)
	{
		SendPlayerMessage(Localize("HUD", "SpellNotAvailable", "UDKMOBA"));
		return false;
	}

	// Check if the spell is cooling down
	if (IsTimerActive(NameOf(CooldownTimer)))
	{
		SendPlayerMessage(Localize("HUD", "SpellNotReady", "UDKMOBA"));
		return false;
	}

	// Check if the pawn has enough mana
	UDKMOBAPawn = UDKMOBAPawn(PawnOwner);
	if (UDKMOBAPawn != None && UDKMOBAPawn.Mana < GetManaCost())
	{
		SendPlayerMessage(Localize("HUD", "NotEnoughMana", "UDKMOBA"));
		return false;
	}

	return true;
}

/**
 * Returns the current cost to use this spell
 *
 * @return		Returns the current cost to use this spell
 * @network		Server and client
 */
simulated function float GetManaCost()
{
	if (ManaCost.Length == 0)
	{
		return 1.f;
	}

	if (Level < 0)
	{
		return 0.f;
	}

	if (ManaCost.Length <= Level)
	{
		// undefined - return best estimate
		return ManaCost[ManaCost.Length - 1];
	}

	return ManaCost[Level];
}

/**
 * Returns the current activation time for this spell. Sometimes called 'cast time'
 *
 * @return		Returns the current activation time when using this spell
 * @network		Server and client
 */
simulated function float GetActivationTime()
{
	if (ActivationTime.Length == 0)
	{
		return 0.1f;
	}

	if (Level < 0)
	{
		return 0.f;
	}

	if (ActivationTime.Length <= Level)
	{
		// undefined - return best estimate
		return ActivationTime[ActivationTime.Length - 1];
	}

	return ActivationTime[Level];
}

/**
 * Returns the current cooldown time for this spell
 *
 * @return		Returns the current cooldown time for this spell
 * @network		Server and client
 */
simulated function float GetCooldownTime()
{
	if (CooldownTime.Length == 0)
	{
		return 1.f;
	}

	if (Level < 0)
	{
		return 60.f;
	}

	if (CooldownTime.Length <= Level)
	{
		// undefined - return best estimate
		return CooldownTime[CooldownTime.Length - 1];
	}

	return CooldownTime[Level];
}

/**
 * Begins activating the spell
 *
 * @network		Server and client
 */
simulated function Activate()
{
	// Immediately perform the spell effects
	ActivateEffects(false);

	if (GetActivationTime() == 0.f)
	{
		// Immediately perform action
		Cast();
	}
	else
	{
		// Perform action after cast time
		SetTimer(GetActivationTime(), false, NameOf(Cast));
	}

	if (Role == Role_Authority)
	{
		// Start the cooldown timer
		SetTimer(GetCooldownTime(), false, NameOf(CooldownTimer));
	}
}

/**
 * Sets up the target based on how this aim
 *
 * @param		AimLocation			World space location the player is aiming from
 * @param		AimDirection		World space direction the player is aiming in
 * @return							True if a valid target has been chosen, false otherwise.
 * @network							Server and client
 */
simulated function bool SetTargetsFromAim(Vector AimLocation, Vector AimDirection)
{
	local Actor Actor;
	local vector HitLocation, HitNormal;

	if (AimingType == EAT_World)
	{
		// Perform a trace to find either UDKMOBAGroundBlockingVolume or the WorldInfo [BSP] 
		ForEach TraceActors(class'Actor', Actor, HitLocation, HitNormal, AimLocation + AimDirection * 16384.f, AimLocation)
		{
			if (UDKMOBAGroundBlockingVolume(Actor) != None || WorldInfo(Actor) != None)
			{
				TargetLocation = HitLocation;
				break;
			}
		}

		return true;
	}

	return false;
}

/**
 * Called when the spell has been activated
 *
 * @param		ViaReplication		True if this was called via replication
 * @network							Server and client
 */
simulated function ActivateEffects(bool ViaReplication)
{
	local PlayerController PlayerController;

	// Client side effects only
	PlayerController = PlayerController(Owner);
	if (PlayerController != None && LocalPlayer(PlayerController.Player) != None)
	{
		// Play the activating sound
		if (!ViaReplication && ActivatingSoundCue != None && WorldInfo.NetMode != NM_DedicatedServer)
		{
			PawnOwner.PlaySound(ActivatingSoundCue, true);
		}

		// This was a replicated call, so begin the cooldown since it is known that the server was able to perform the spell
		if (ViaReplication)
		{
			SetTimer(GetCooldownTime(), false, NameOf(CooldownTimer));
		}
	}

	// Create the activating particle template that everyone can see
	if (((bNetOwner && !ViaReplication) || !bNetOwner) && ActivatingParticleTemplate != None && WorldInfo.NetMode != NM_DedicatedServer && WorldInfo.MyEmitterPool != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(ActivatingParticleTemplate, PawnOwner.Location, PawnOwner.Rotation, PawnOwner, PawnOwner);
	}

	// Increment the flash count, so that clients can see the effect
	if (Role == Role_Authority)
	{
		// Ensure that activation count never goes back to zero as that would be a refresh
		if (ActivationCount == 255)
		{
			ActivationCount = 1;
		}
		else
		{
			ActivationCount++;
		}
	}
}

/**
 * Called after the spell has been activated and ActivationTime has passed
 *
 * @network		Server and client
 */
final simulated function Cast()
{
	local UDKMOBAPawn UDKMOBAPawn;

	// Consume mana
	UDKMOBAPawn = UDKMOBAPawn(PawnOwner);
	if (UDKMOBAPawn != None)
	{
		UDKMOBAPawn.Mana = Max(UDKMOBAPawn.Mana - GetManaCost(), 0);
	}

	// Spawn in cast effects
	CastEffects(false);

	// Perform the actual cast
	PerformCast();
}

/**
 * Actually does the damage, creates the projectile, or otherwise does the spell itself
 *
 * @network		Server and client
 */
protected simulated function PerformCast();

/**
 * Called when the spell has been cast
 *
 * @param		ViaReplication		True if this was called via replication
 * @network							Server and client
 */
simulated function CastEffects(bool ViaReplication)
{
	local PlayerController PlayerController;

	// Client side effects only
	PlayerController = PlayerController(Owner);
	if (PlayerController != None && LocalPlayer(PlayerController.Player) != None)
	{
		// Play the casting sound
		if (!ViaReplication && CastingSoundCue != None && WorldInfo.NetMode != NM_DedicatedServer)
		{
			PlaySound(CastingSoundCue, true,,, (PlayerController.Pawn != None) ? PlayerController.Pawn.Location : PlayerController.Location);
		}
	}

	// Create the casting particle template that everyone can see
	if (((bNetOwner && !ViaReplication) || !bNetOwner) && CastingParticleTemplate != None && WorldInfo.NetMode != NM_DedicatedServer && WorldInfo.MyEmitterPool != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(CastingParticleTemplate, PawnOwner.Location, PawnOwner.Rotation, PawnOwner, PawnOwner);
	}

	// Increment the flash count, so that clients can see the effect
	if (Role == Role_Authority)
	{
		// Ensure that activation count never goes back to zero as that would be a refresh
		if (CastCount == 255)
		{
			CastCount = 1;
		}
		else
		{
			CastCount++;
		}
	}
}

/**
 * Called when the cooldown timer has expired
 *
 * @network		Server and client
 */
simulated function CooldownTimer();

/**
 * Adjusts the damage before applying it to the pawn owner. This iterates over all of the spells and items to allow them to adjust damage
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
function AdjustDamage(out float InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser);

// Default properties block
defaultproperties
{
	ManaCost(0)=10.f
	ManaCost(1)=20.f
	ManaCost(2)=30.f
	ManaCost(3)=40.f
	OrderIndex=INDEX_NONE
	Level=-1
	MaxLevel=4
	HasActive=true
	TickGroup=TG_DuringAsyncWork
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	NetUpdateFrequency=1
	DecalSize=(X=256.f,Y=256.f)
	AttackType=ATT_Spells
}