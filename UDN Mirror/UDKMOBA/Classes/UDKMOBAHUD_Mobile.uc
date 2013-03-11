//=============================================================================
// UDKMOBAHUD_Mobile
//
// This HUD is the mobile specific version of the MOBA HUD. This is primarily
// used for handling the touch events.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAHUD_Mobile extends UDKMOBAHUD;

// If true, then the hero portrait has been set
var ProtectedWrite bool HasSetHeroPortrait;

/**
 * Called when the HUD should handle rendering and touch events
 *
 * @network		Client
 */
event PostRender()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	Super.PostRender();

	if (!HasSetHeroPortrait && HUDMovie != None)
	{
		if (PlayerOwner != None)
		{
			UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerOwner.PlayerReplicationInfo);
			if (UDKMOBAPlayerReplicationInfo != None && UDKMOBAPlayerReplicationInfo.HeroArchetype != None && UDKMOBAPlayerReplicationInfo.HeroArchetype.HeroPortrait != None)
			{				
				HasSetHeroPortrait = true;
				HUDMovie.SetHeroPortrait(UDKMOBAPlayerReplicationInfo.HeroArchetype.HeroPortrait);
			}
		}
	}

	// Process touch events
	ProcessTouchEvents();
}

/**
 * Called when the HUD should process touch events
 *
 * @network		Client
 */
function ProcessTouchEvents()
{
	local UDKMOBAPlayerController_Mobile UDKMOBAPlayerController_Mobile;
	local int i;
	
	// Ensure that we have access to the Mobile player controller
	UDKMOBAPlayerController_Mobile = UDKMOBAPlayerController_Mobile(PlayerOwner);
	if (UDKMOBAPlayerController_Mobile == None || UDKMOBAPlayerController_Mobile.TouchEvents.Length <= 0)
	{
		return;
	}

	// Iterate through the touch events and process them if they have not been processed
	for (i = 0; i < UDKMOBAPlayerController_Mobile.TouchEvents.Length; ++i)
	{
		if (!UDKMOBAPlayerController_Mobile.TouchEvents[i].HasBeenProcessed)
		{
			// Set flag to true so it won't be processed again
			UDKMOBAPlayerController_Mobile.TouchEvents[i].HasBeenProcessed = true;

			// Check if this touch event was not on the mini map
			if (!HUDMovie.MinimapButtonPressed)
			{
				// Send the touch location to process a right click command
				UDKMOBAPlayerController_Mobile.HandlePendingRightClickCommand(Self, UDKMOBAPlayerController_Mobile.TouchEvents[i].ScreenLocation);			
			}
		}
	}
}

// Default properties block
defaultproperties
{
	HUDProperties=UDKMOBAHUD_MobileProperties'UDKMOBA_HUD_Mobile_Resources.Archetypes.HUDProperties'
}