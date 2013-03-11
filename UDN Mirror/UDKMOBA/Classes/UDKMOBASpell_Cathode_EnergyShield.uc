//=============================================================================
// UDKMOBASpell_Cathode_EnergyShield
//
// This is the energy shield ability used by the Cathode hero. It adjusts 
// incomimg damages depending if the hero has any mana left. if there is no
// more mana, then the spell toggles off.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBASpell_Cathode_EnergyShield extends UDKMOBASpell;

// Packed damage direction
struct SAdjustDamageDirection
{
	var byte FlashCount;
	var byte CompressedYaw;
	var byte CompressedPitch;
	var byte CompressedRoll;
};

// Energy shield particle effect
var(EnergyShield) const ParticleSystemComponent ShieldParticleComponent;
// How much mana it costs to reduce damage
var(EnergyShield) const float DamageReductionManaCost[4];
// Maximum amount of damage that is reduced
var(EnergyShield) const float DamageReduction[4];
// Sound to play when the shield reduces damage
var(EnergyShield) const SoundCue DamageReductionSoundCue;
// Particle effect to spawn when the shield reduces damage
var(EnergyShield) const ParticleSystem DamageReductionParticleTemplate;

// How long to wait till the spell can be retriggered again. This prevents players from toggling on and off too quickly
var(Spell, Toggle) const float ReTriggerDelay;

// True if the spell is currently active
var RepNotify ProtectedWrite bool IsActive;
// Replicated compressed damage direction
var RepNotify SAdjustDamageDirection AdjustDamageDirection;
// Next valid time this spell is able to be reiggered again
var ProtectedWrite float NextValidTriggerTime;

// Replication block
replication
{
	if (bNetDirty)
		AdjustDamageDirection, IsActive;
}

/**
 * Initializes the spell
 *
 * @network			Server and client
 */
simulated function Initialize()
{
	Super.Initialize();

	// Attach the particle component to the pawn
	if (PawnOwner != None && ShieldParticleComponent != None)
	{
		ShieldParticleComponent.DeactivateSystem();
		PawnOwner.AttachComponent(ShieldParticleComponent);
	}
}

/**
 * Called when a variable that has been flagged as RepNotify has finished replicating
 *
 * @param		VarName		Name of the variable that was replicated
 * @network					Client
 */
simulated event ReplicatedEvent(Name VarName)
{
	local Rotator UncompressedDirection;

	// Adjust damage direction has been replicated
	if (VarName == NameOf(AdjustDamageDirection))
	{
		// Uncompress the direction
		UncompressedDirection.Yaw = AdjustDamageDirection.CompressedYaw << 8;
		UncompressedDirection.Pitch = AdjustDamageDirection.CompressedPitch << 8;
		UncompressedDirection.Roll = AdjustDamageDirection.CompressedRoll << 8;

		// Play the effects
		PlayShieldEffects(UncompressedDirection);
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

/**
 * Begins activating the spell - override to ensure toggle is taken care of
 *
 * @network		Server and client
 */
simulated function Activate()
{
	// If time hasn't passed to allow the next valid trigger time, abort
	if (WorldInfo.TimeSeconds < NextValidTriggerTime)
	{
		return;
	}

	// Toggle IsActive boolean
	IsActive = !IsActive;

	// Toggle the shield particle system component
	if (WorldInfo.NetMode != NM_DedicatedServer && ShieldParticleComponent != None)
	{
		if (IsActive)
		{
			ShieldParticleComponent.ActivateSystem();
		}
		else
		{
			ShieldParticleComponent.DeactivateSystem();
		}
	}

	// Set the next time it is valid to trigger this toggle again
	NextValidTriggerTime = WorldInfo.TimeSeconds + ReTriggerDelay;

	Super.Activate();
}

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
function AdjustDamage(out float InDamage, out vector Momentum, Controller InstigatedBy, vector HitLocation, class<DamageType> DamageType, TraceHitInfo HitInfo, Actor DamageCauser)
{
	local UDKMOBAPawn UDKMOBAPawn;
	local Rotator Direction;

	// If the spell is not active, then exit early
	if (!IsActive)
	{
		return;
	}

	// Early exit if UDKMOBAPawn is invalid or has no more mana
	UDKMOBAPawn = UDKMOBAPawn(PawnOwner);
	if (UDKMOBAPawn == None || int(UDKMOBAPawn.Mana) <= 0)
	{
		return;
	}

	// Reduce damage based on how much mana is available
	// Pawn has enough mana to do 100% damage reduction
	if (UDKMOBAPawn.Mana >= DamageReductionManaCost[Level])
	{
		InDamage *= 1.f - DamageReduction[Level];
		UDKMOBAPawn.Mana -= DamageReductionManaCost[Level];
	}
	// Pawn has some mana, but not enough to do 100% damage reduction
	else
	{
		InDamage *= 1.f - (UDKMOBAPawn.Mana / DamageReductionManaCost[Level] * DamageReduction[Level]);
		UDKMOBAPawn.Mana = 0;
	}
	
	// Update effects for the client
	// Calculate the direction that the shield block in
	Direction = Rotator(HitLocation - PawnOwner.Location);
	AdjustDamageDirection.FlashCount++;
	AdjustDamageDirection.CompressedYaw = Direction.Yaw >> 8;
	AdjustDamageDirection.CompressedPitch = Direction.Pitch >> 8;
	AdjustDamageDirection.CompressedRoll = Direction.Roll >> 8;

	// Play the shield effects locally
	PlayShieldEffects(Direction);
}

/**
 * Plays the shield effects
 *
 * @param		ShieldEffectRotation		Shield effect rotation
 * @network									Server and client
 */
simulated function PlayShieldEffects(Rotator ShieldEffectRotation)
{
	// Abort if on the dedicated server
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// Play the damage reduction sound cue
	if (DamageReductionSoundCue != None)
	{
		PawnOwner.PlaySound(DamageReductionSoundCue, true);
	}

	// Spawn the particle effect
	if (WorldInfo.MyEmitterPool != None && DamageReductionParticleTemplate != None)
	{
		WorldInfo.MyEmitterPool.SpawnEmitter(DamageReductionParticleTemplate, PawnOwner.Location, ShieldEffectRotation, PawnOwner, PawnOwner);
	}
}

// Default properties block
defaultproperties
{
	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent
	End Object
	ShieldParticleComponent=MyParticleSystemComponent

	DamageReductionManaCost(0)=30
	DamageReductionManaCost(1)=25
	DamageReductionManaCost(2)=20
	DamageReductionManaCost(3)=10
	DamageReduction(0)=0.03f
	DamageReduction(1)=0.06f
	DamageReduction(2)=0.09f
	DamageReduction(3)=0.15f
	IsActive=false
	ReTriggerDelay=0.1f
}