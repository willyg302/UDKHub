//=============================================================================
// UDKMOBACreepFactory
//
// Editor placeable actor which indicates where pawns should be spawned, how
// quickly pawns should be spawned, which route they are following, what team
// the creeps belong to. The factory also keeps track of all of the pawns that
// have spawned and died to ensure that there is a maximum amount of them at
// any given time.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACreepFactory extends Actor	
	ClassGroup(MOBA)
	HideCategories(Attachment, Collision, Physics, Debug, Object)
	Placeable;

// Pawn archetype to spawn
var(CreepFactory) const UDKMOBACreepPawn PawnArchetype;
// Time between each spawn
var(CreepFactory) const float SpawnInterval;
// Route for the creeps that belong to this factory
var(CreepFactory) const Route Route;
// Maximum amount of creeps that this factory can own
var(CreepFactory) const int MaximumCreepCount;
// Team that this factory owns
var(CreepFactory) const byte TeamIndex;

// Current amount of creeps that this factory owns
var ProtectedWrite int CurrentCreepCount;

/**
 * Called when this actor is initialized in the world. Here the factory is setup with a timer to spawn creeps
 *
 * @network		Server
 */
function PostBeginPlay()
{
	local UDKMOBAMapInfo UDKMOBAMapInfo;

	Super.PostBeginPlay();

	if (PawnArchetype != None)
	{
		// Check if the map info wants to disable us
		UDKMOBAMapInfo = UDKMOBAMapInfo(WorldInfo.GetMapInfo());
		if (UDKMOBAMapInfo != None && UDKMOBAMapInfo.bDisableCreepSpawners)
		{
			return;
		}

		// Spawn the first creep
		SpawnCreepTimer();

		// Set up the spawn interval
		if (SpawnInterval > 0.f)
		{
			SetTimer(SpawnInterval, true, NameOf(SpawnCreepTimer));
		}
	}
}

/**
 * Called by the creep when it has died so that the factory can keep track of how many pawns it has spawned is still alive
 *
 * @network		Server
 */
function CreepDied()
{
	CurrentCreepCount = Max(CurrentCreepCount - 1, 0);
}

/**
 * Called by a timer to spawn the pawn if possible
 *
 * @network		Server
 */
function SpawnCreepTimer()
{
	local UDKMOBACreepPawn SpawnedPawn;
	local UDKMOBACreepAIController UDKMOBACreepAIController;

	// If the current creep count is above or equal to the maximum creep count, then abort
	if (CurrentCreepCount >= MaximumCreepCount)
	{
		return;
	}

	// Spawn the pawn using the pawn archetype
	SpawnedPawn = Spawn(PawnArchetype.Class, Self,, Location, Rotation, PawnArchetype);
	if (SpawnedPawn != None)
	{
		// Increase the creep count
		CurrentCreepCount++;
		// Play the teleport effects
		SpawnedPawn.PlayTeleportEffect(true, true);
		// Restart the creep
		UDKMOBACreepAIController = UDKMOBACreepAIController(SpawnedPawn.Controller);
		if (UDKMOBACreepAIController != None)
		{
			UDKMOBACreepAIController.Initialize();
		}
	}
}

// Defaut properties block
defaultproperties
{
	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.Ambientcreatures'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=false
		AlwaysLoadOnServer=false
		SpriteCategoryName="Pawns"
	End Object
	Components.Add(Sprite)

	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=50.f
		CollisionHeight=50.f
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	bEdShouldSnap=true
	bStatic=false
	bNoDelete=true
	bCollideWhenPlacing=true
	MaximumCreepCount=10
}