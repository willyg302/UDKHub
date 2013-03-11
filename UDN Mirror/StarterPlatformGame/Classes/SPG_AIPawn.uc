//=============================================================================
// SPG_AIPawn
//
// Simple AI pawn which is placeable in the level. 
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_AIPawn extends Pawn
	placeable;

// Dynamic light environment component to help speed up lighting calculations for the pawn
var(Pawn) const DynamicLightEnvironmentComponent LightEnvironment;
// Ground speed of the pawn, display as Ground Speed in the editor
var(Pawn) const float UserGroundSpeed<DisplayName=Ground Speed>;
// Explosion particle system to play when blowing up
var(Pawn) const ParticleSystem ExplosionParticleTemplate;
// Explosion sound to play
var(Pawn) const SoundCue ExplosionSoundCue;
// Explosion damage amount 
var(Pawn) const int ExplosionDamage;
// Archetyped pick up to drop
var(Pawn) const archetype DroppedPickup ArchetypedPickup;
// Percentage chance to drop pickups
var(Pawn) const float ChanceToDropPickup;

// Current enemy
var Actor Enemy;

/**
 * Called when the pawn is first initialized
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	SpawnDefaultController();
}

/**
 * Called every frame
 *
 * @param	DeltaTime		Time since the last tick event was called
 */
simulated function Tick(float DeltaTime)
{
	local PlayerController PlayerController;
	local Vector Direction;
	local Rotator NewRotation;

	Super.Tick(DeltaTime);

	// If we don't have an enemy yet...
	if (Enemy == None)
	{
		// Find the player controller in the world
		PlayerController = GetALocalPlayerController();
		if (PlayerController != None && PlayerController.Pawn != None)
		{
			// Set the enemy to the player controller's pawn
			Enemy = PlayerController.Pawn;
		}
	}
	else if (Physics == PHYS_Walking)
	{
		// Find the direction in order for me to look at my enemy
		Direction = Enemy.Location - Location;
		// Only need to use the yaw from the direction
		NewRotation = Rotator(Direction);
		NewRotation.Pitch = 0;
		NewRotation.Roll = 0;
		// Set the rotation so that I look at the enemy
		SetRotation(NewRotation);
		// Set my velocity, so I move towards the enemy
		Velocity = Normal(Enemy.Location - Location) * UserGroundSpeed;
		// Set my acceleration, so I move towards the enemy
		Acceleration = Velocity;
	}
}

/**
 * Sets the Rigid Body channels when the pawn is in ragdoll or not
 *
 * @network				Server and client
 */
simulated function SetPawnRBChannels(bool bRagdollMode)
{
	Mesh.SetRBChannel((bRagdollMode) ? RBCC_Pawn : RBCC_Untitled3);
	Mesh.SetRBCollidesWithChannel(RBCC_Default, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Pawn, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Vehicle, bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_Untitled3, !bRagdollMode);
	Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, bRagdollMode);
}

/**
 * Called when the pawn has died. This make the pawn turn into a ragdoll
 *
 * @param		DamageType		Damage type which killed the pawn
 * @param		HitLoc			Last hit location made when the pawn died
 * @network						Server and client
 */
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	local DroppedPickup DroppedPickup;

	Mesh.MinDistFactorForKinematicUpdate = 0.0;
	Mesh.ForceSkelUpdate();
	Mesh.SetTickGroup(TG_PostAsyncWork);
	CollisionComponent = Mesh;
	CylinderComponent.SetActorCollision(false, false);
	Mesh.SetActorCollision(true, false);
	Mesh.SetTraceBlocking(true, true);
	SetPawnRBChannels(true);
	SetPhysics(PHYS_RigidBody);
	Mesh.PhysicsWeight = 1.f;

	if (Mesh.bNotUpdatingKinematicDueToDistance)
	{
		Mesh.UpdateRBBonesFromSpaceBases(true, true);
	}

	Mesh.PhysicsAssetInstance.SetAllBodiesFixed(false);
	Mesh.bUpdateKinematicBonesFromAnimation = false;
	Mesh.WakeRigidBody();

	// Set the actor to automatically destroy in ten seconds.
	LifeSpan = 10.f;

	// Chance to drop a pick up
	if (ArchetypedPickup != None && FRand() <= ChanceToDropPickup)
	{
		// Spawn a dropped pickup
		DroppedPickup = Spawn(ArchetypedPickup.Class,,, Location,, ArchetypedPickup);
		if (DroppedPickup != None)
		{
			// Set the dropped pick up to falling
			DroppedPickup.SetPhysics(PHYS_Falling);
			// Set the velocity of the dropped pickup to the toss velocity
			DroppedPickup.Velocity.X = 0;
			DroppedPickup.Velocity.Y = 0;
			DroppedPickup.Velocity.Z = RandRange(200.f, 250.f);
		}
	}
}

event Bump(Actor Other, PrimitiveComponent OtherComp, Vector HitNormal)
{
	Super.Bump(Other, OtherComp, HitNormal);

	if (SPG_PlayerPawn(Other) != None)
	{
		// Apply damage to the bumped pawn
		Other.TakeDamage(ExplosionDamage, None, Location, Vect(0, 0, 0), class'DamageType');

		// Play the particle effect
		if (ExplosionParticleTemplate != None)
		{
			WorldInfo.MyEmitterPool.SpawnEmitter(ExplosionParticleTemplate, Location);
		}

		// Play the explosion sound
		if (ExplosionSoundCue != None)
		{
			PlaySound(ExplosionSoundCue);
		}

		// Destroy the pawn
		Destroy();
	}
}

defaultproperties
{
	// Ground speed of the pawn
	UserGroundSpeed=150.f
	// Set physics to falling
	Physics=PHYS_Falling

	// Remove the sprite component as it is not needed
	Components.Remove(Sprite)

	// Create a light environment for the pawn
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=true
		bIsCharacterLightEnvironment=true
		bUseBooleanEnvironmentShadowing=false
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	// Create a skeletal mesh component for the pawn
	Begin Object Class=SkeletalMeshComponent Name=MySkeletalMeshComponent
		bCacheAnimSequenceNodes=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CastShadow=true
		BlockRigidBody=true
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true)
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=false
		bHasPhysicsAssetInstance=true
		TickGroup=TG_PreAsyncWork
		MinDistFactorForKinematicUpdate=0.2f
		bChartDistanceFactor=true
		RBDominanceGroup=20
		Scale=1.f
		bAllowAmbientOcclusion=false
		bUseOnePassLightingOnTranslucency=true
		bPerBoneMotionBlur=true
	End Object
	Mesh=MySkeletalMeshComponent
	Components.Add(MySkeletalMeshComponent)
}