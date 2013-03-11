//=============================================================================
// SPG_HealthPickup
//
// Simple health pick up.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_HealthPickup extends DroppedPickup
	placeable;

// Static mesh used by the pick up
var(HealthPickup) const StaticMeshComponent Mesh;
// Sound to play when the pick up is picked up by a pawn
var(HealthPickup) const SoundCue PickupSound;
// How much health to give to the pawn when picked up
var(HealthPickup) const int HealthToGive;

/**
 * Called when this pick up should be given to a pawn
 *
 * @param	P		Pawn to give to
 * @network			Server
 */
function GiveTo(Pawn P)
{
	// Play sound
	if (PickupSound != None)
	{
		PlaySound(PickupSound);		
	}

	// Add health to the player, but clamp it to the pawn's maximum health
	P.Health = Min(P.Health + HealthToGive, P.HealthMax);
	// Handle the rest of pick up
	PickedUpBy(P);
}

auto state Pickup
{
	/*
	 * Validate touch (if valid return true to let other pick me up and trigger event).
	 *
	 * @param	Other		Pawn to validate
	 * @network				Server
	 */
	function bool ValidTouch(Pawn Other)
	{
		// make sure its a live player
		if (Other == None || !Other.bCanPickupInventory || (Other.DrivenVehicle == None && Other.Controller == None))
		{
			return false;
		}

		// make sure thrower doesn't run over own weapon
		if (Physics == PHYS_Falling && Other == Instigator && Velocity.Z > 0)
		{
			return false;
		}

		return true;
	}
}

defaultproperties
{
	// Remove the sprite component
	Components.Remove(Sprite);

	// Add the static mesh component
	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
	End Object
	Mesh=MyStaticMeshComponent
	Components.Add(MyStaticMeshComponent);
}