//=============================================================================
// SPG_InventoryManager
//
// Inventory manager which is capable of creating inventory from archetypes.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_InventoryManager extends InventoryManager;

/**
 * Creates an inventory for the manager based on an archetype
 *
 * @param	NewInventoryItemArchetype		Archetype of the inventory to give to the player
 * @param	bDoNotActivate					Do not activate the inventory
 * @return									Returns the inventory that was created
 * @network									Server and client
 */
simulated function Inventory CreateInventoryArchetype(Inventory NewInventoryItemArchetype, optional bool bDoNotActivate)
{
	local Inventory	Inv;
	
	// Ensure the inventory archetype is valid
	if (NewInventoryItemArchetype != None)
	{
		// Spawn the inventory archetype
		Inv = Spawn(NewInventoryItemArchetype.Class, Owner,,,, NewInventoryItemArchetype);
		
		// Spawned the inventory, and add the inventory
		if (Inv != None && !AddInventory(Inv, bDoNotActivate))
		{
			// Unable to add the inventory, so destroy the spawned inventory
			Inv.Destroy();
			Inv = None;
		}
	}

	// Return the spawned inventory
	return Inv;
}

defaultproperties
{
	// Create the pending fire array
	PendingFire(0)=0
	PendingFire(1)=0
}