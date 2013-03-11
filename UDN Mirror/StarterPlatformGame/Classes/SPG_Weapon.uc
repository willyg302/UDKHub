//=============================================================================
// SPG_Weapon
//
// Simple weapon that can shoot projectiles.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_Weapon extends Weapon;

// Name of the socket which represents the muzzle socket
var(Weapon) const Name MuzzleSocketName;
// Particle system representing the muzzle flash
var(Weapon) const ParticleSystemComponent MuzzleFlash;
// Projectile classes that this weapon fires. DisplayName lets the editor show this as WeaponProjectiles
var(Weapon) const array< class<Projectile> > Projectiles<DisplayName=Weapon Projectiles>;
// Sounds to play back when the weapon is fired
var(Weapon) const array<SoundCue> WeaponFireSounds;

/**
 * Constructor called when the weapon is spawned into the world
 *
 * @network					Server and client
 */
simulated event PostBeginPlay()
{
	local SkeletalMeshComponent SkeletalMeshComponent;

	Super.PostBeginPlay();

	if (MuzzleFlash != None)
	{
		SkeletalMeshComponent = SkeletalMeshComponent(Mesh);
		if (SkeletalMeshComponent != None && SkeletalMeshComponent.GetSocketByName(MuzzleSocketName) != None)
		{
			SkeletalMeshComponent.AttachComponentToSocket(MuzzleFlash, MuzzleSocketName);
		}
	}
}

/**
 * Called when the weapon has been given to a pawn
 *
 * @param	NewOwner		Pawn that this weapon has been given to
 * @param	bDoNoActivate	Flag to indicate that this weapon should not be activated
 * @network					Client
 */
reliable client function ClientGivenTo(Pawn NewOwner, bool bDoNotActivate)
{
	local SPG_PlayerPawn SPG_PlayerPawn;

	Super.ClientGivenTo(NewOwner, bDoNotActivate);

	// Check that we have a new owner and the new owner has a mesh
	if (NewOwner != None && NewOwner.Mesh != None)
	{
		// Cast the new owner into a SPG_PlayerPawn as we need the weapon socket name
		// If the cast succeeds, we check that the new owner's mesh has a socket by that name
		SPG_PlayerPawn = SPG_PlayerPawn(NewOwner);
		if (SPG_PlayerPawn != None && NewOwner.Mesh.GetSocketByName(SPG_PlayerPawn.WeaponSocketName) != None)
		{
			// Set the shadow parent of the weapon mesh to the new owner's skeletal mesh. This prevents doubling up
			// of shadows and also allows improves rendering performance
			Mesh.SetShadowParent(NewOwner.Mesh);
			// Set the light environment of the weapon mesh to the new owner's light environment. This improves
			// rendering performance
			Mesh.SetLightEnvironment(SPG_PlayerPawn.LightEnvironment);
			// Attach the weapon mesh to the new owner's skeletal meshes socket
			NewOwner.Mesh.AttachComponentToSocket(Mesh, SPG_PlayerPawn.WeaponSocketName);
		}
	}
}

/**
 * Returns the projectile class based on the current fire mode
 *
 * @return			Returns the class of the projectile indexed within the Projectiles array
 * @network			Server
 */
function class<Projectile> GetProjectileClass()
{
	return (CurrentFireMode < Projectiles.length) ? Projectiles[CurrentFireMode] : None;
}

/**
 * Plays all firing effects
 *
 * @param	FireModeNum		Fire mode
 * @param	HitLocation		Where in the world the trace hit
 * @network					Server and client
 */
simulated function PlayFireEffects(byte FireModeNum, optional vector HitLocation)
{
	if (MuzzleFlash != None)
	{
		// Activate the muzzle flash
		MuzzleFlash.ActivateSystem();
	}

	// Play back weapon fire sound if FireModeNum is within the array bounds and if the 
	// weapon fire sound in that array index is not none
	if (FireModeNum < WeaponFireSounds.Length && WeaponFireSounds[FireModeNum] != None && Instigator != None)
	{
		Instigator.PlaySound(WeaponFireSounds[FireModeNum]);
	}
}

/**
 * Stops all firing effects
 *
 * @param	FireModeNum		Fire mode
 * @network					Server and client
 */
simulated function StopFireEffects(byte FireModeNum)
{
	if (MuzzleFlash != None)
	{
		// Deactivate the muzzle flash
		MuzzleFlash.DeactivateSystem();
	}
}

/**
 * Fires a projectile.
 * Spawns the projectile, but also increment the flash count for remote client effects.
 * Network: Local Player and Server
 */

simulated function Projectile ProjectileFire()
{
	local Vector SpawnLocation;
	local Rotator SpawnRotation;
	local class<Projectile> ProjectileClass;
	local Projectile SpawnedProjectile;

	// tell remote clients that we fired, to trigger effects
	IncrementFlashCount();

	// Only allow servers to spawn projectiles
	if (Role == ROLE_Authority)
	{
		// This is where we would spawn the projectile
		SpawnLocation = Instigator.GetWeaponStartTraceLocation();
		// This is the rotation we should spawn the projectile
		SpawnRotation = GetAdjustedAim(SpawnLocation);

		// Get the projectile class
		ProjectileClass = GetProjectileClass();
		if (ProjectileClass != None)
		{
			// Spawn the projectile setting the projectile's owner to myself
			SpawnedProjectile = Spawn(ProjectileClass, Self,, SpawnLocation, SpawnRotation);

			// Check if we've spawned the projectile, and that it isn't going to be deleted
			if (SpawnedProjectile != None && !SpawnedProjectile.bDeleteMe)
			{
				// Initialize the projectile
				SpawnedProjectile.Init(Vector(SpawnRotation));
			}
		}
		
		// Return it up the line
		return SpawnedProjectile;
	}

	return None;
}
defaultproperties
{
	// Create the skeletal mesh component for the weapon
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

	// Create the particle system component for the weapon's muzzle flash
	Begin Object Class=ParticleSystemComponent Name=MyParticleSystemComponent		
	End Object
	MuzzleFlash=MyParticleSystemComponent
	Components.Add(MyParticleSystemComponent);

	// Set the weapon firing states
	FiringStatesArray(0)="WeaponFiring"
	FiringStatesArray(1)="WeaponFiring"

	// Set the weapon to fire projectiles by default
	WeaponFireTypes(0)=EWFT_Projectile
	WeaponFireTypes(1)=EWFT_Projectile
}