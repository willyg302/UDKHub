//=============================================================================
// SPG_GameInfo
//
// Game info which spawns the player controller, pawn and HUD for the player.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_GameInfo extends SimpleGame;

// Variable which references the default pawn archetype stored within a package
var() const archetype Pawn DefaultPawnArchetype;
// Variable which references the default weapon archetype stored within a package
var() const archetype Weapon DefaultWeaponArchetype;

/**
 * Spawns the default pawn for a controller at a given start spot
 *
 * @param	NewPlayer	Controller to spawn the pawn for
 * @param	StartSpot	Where to spawn the pawn
 * @return	Pawn		Returns the pawn that was spawned
 * @network				Server
 */
function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{
	local Rotator StartRotation;
	local Pawn SpawnedPawn;

	// Quick exit if NewPlayer is none or if StartSpot is none
	if (NewPlayer == None || StartSpot == None)
	{
		return None;
	}

	// Only the start spot's yaw from its rotation is required
	StartRotation = Rot(0, 0, 0);
	StartRotation.Yaw = StartSpot.Rotation.Yaw;

	// Spawn the default pawn archetype at the start spot's location and the start rotation defined above
	// Set SpawnedPawn to the spawned
	SpawnedPawn = Spawn(DefaultPawnArchetype.Class,,, StartSpot.Location, StartRotation, DefaultPawnArchetype);

	// Return the value of SpawnedPawn
	return SpawnedPawn;
}

/**
 * Adds the default inventory to the pawn
 *
 * @param		P	Pawn to give default inventory to
 * @network			Server
 */
event AddDefaultInventory(Pawn P)
{
	local SPG_InventoryManager SPG_InventoryManager;

	Super.AddDefaultInventory(P);

	// Ensure that we have a valid default weapon archetype
	if (DefaultWeaponArchetype != None)
	{
		// Get the inventory manager
		SPG_InventoryManager = SPG_InventoryManager(P.InvManager);
		if (SPG_InventoryManager != None)
		{
			// Create the inventory from the archetype
			SPG_InventoryManager.CreateInventoryArchetype(DefaultWeaponArchetype, false);
		}
	}
}

defaultproperties
{
	// What player controller class to create for the player
	PlayerControllerClass=class'SPG_PlayerController'
	// What default pawn archetype to spawn for the player
	DefaultPawnArchetype=SPG_PlayerPawn'StarterPlatformGameContent.Archetypes.PlayerPawn'
	// What default weapon archetype to spawn for the player
	DefaultWeaponArchetype=SPG_Weapon'StarterPlatformGameContent.Archetypes.LinkGunWeapon'
	// What HUD class to create for the player
	HUDType=class'SPG_HUD'
}