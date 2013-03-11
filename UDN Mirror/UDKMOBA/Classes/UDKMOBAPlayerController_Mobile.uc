//=============================================================================
// UDKMOBAPlayerController_Mobile
//
// Mobile specific version of the MOBA player controller which handles the 
// touch input from the touch screen.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPlayerController_Mobile extends UDKMOBAPlayerController;

// Struct which contains touch event data
struct STouchEvent
{
	// Touch handle
	var int Handle;
	// Screen space location of the touch
	var Vector2D ScreenLocation;
	// True if this touch has already been processed or not
	var bool HasBeenProcessed;
};

// Array of all touch events
var array<STouchEvent> TouchEvents;

/**
 * Initializes the input system
 *
 * @network		Client
 */
event InitInputSystem()
{
	local MobilePlayerInput MobilePlayerInput;

	Super.InitInputSystem();

	// Assign the touch delegate
	MobilePlayerInput = MobilePlayerInput(PlayerInput);
	if (MobilePlayerInput != None)
	{
		MobilePlayerInput.OnInputTouch = InternalOnInputTouch;
	}
}

/**
 * Called when the player controller is destroyed
 *
 * @network		Server and client
 */
event Destroyed()
{
	local MobilePlayerInput MobilePlayerInput;

	Super.Destroyed();

	// Clear the touch delegate
	MobilePlayerInput = MobilePlayerInput(PlayerInput);
	if (MobilePlayerInput != None)
	{
		MobilePlayerInput.OnInputTouch = None;
	}
}

/**
 * Called when the game receives a touch event from the touch pad
 *
 * @param		Handle					Touch handle
 * @param		Type					Touch type
 * @param		TouchLocation			Screen space coordinates where the touch occured on the touch pad
 * @param		DeviceTimestamp			When the touch event occured according to the device
 * @param		TouchpadIndex			Which touch pad was touched
 * @network								Local client
 */
function InternalOnInputTouch(int Handle, ETouchType Type, Vector2D TouchLocation, float DeviceTimestamp, int TouchpadIndex);

/**
 * This state handles when the player commanding the hero pawn
 *
 * @network		Server and client
 */
state PlayerCommanding
{
	/**
	 * Called when the game receives a touch event from the touch pad
	 *
	 * @param		Handle					Touch handle
	 * @param		Type					Touch type
	 * @param		TouchLocation			Screen space coordinates where the touch occured on the touch pad
	 * @param		DeviceTimestamp			When the touch event occured according to the device
	 * @param		TouchpadIndex			Which touch pad was touched
	 * @network								Local client
	 */
	function InternalOnInputTouch(int Handle, ETouchType Type, Vector2D TouchLocation, float DeviceTimestamp, int TouchpadIndex)
	{
		local STouchEvent TouchEvent;
		local int Index;

		// Handle new touch events
		if (Type == Touch_Began)
		{
			// Ensure that this is a new touch event
			if (TouchEvents.Find('Handle', Handle) != INDEX_NONE)
			{
				return;
			}

			// Setup the touch event
			TouchEvent.Handle = Handle;
			TouchEvent.ScreenLocation = TouchLocation;
			TouchEvent.HasBeenProcessed = false;

			// Add the touch event to the TouchEvents array
			TouchEvents.AddItem(TouchEvent);
		}
		else if (Type == Touch_Moved)
		{
			Index = TouchEvents.Find('Handle', Handle);
			if (Index == INDEX_NONE)
			{
				return;
			}

			// Update the screen location
			TouchEvents[Index].ScreenLocation = TouchLocation;
			TouchEvents[Index].HasBeenProcessed = false;
		}
		// Handle existing touch events
		else if (Type == Touch_Ended || Type == Touch_Cancelled)
		{			
			Index = TouchEvents.Find('Handle', Handle);
			if (Index == INDEX_NONE)
			{
				return;
			}

			// Remove the touch event from the TouchEvents array
			TouchEvents.Remove(Index, 1);
		}
	}
}

/**
 * This state handles when the player is aiming a spell
 *
 * @network		Server and client
 */
state PlayerAimingSpell
{
	/**
	 * Called when the game receives a touch event from the touch pad
	 *
	 * @param		Handle					Touch handle
	 * @param		Type					Touch type
	 * @param		TouchLocation			Screen space coordinates where the touch occured on the touch pad
	 * @param		DeviceTimestamp			When the touch event occured according to the device
	 * @param		TouchpadIndex			Which touch pad was touched
	 * @network								Local client
	 */
	function InternalOnInputTouch(int Handle, ETouchType Type, Vector2D TouchLocation, float DeviceTimestamp, int TouchpadIndex)
	{
		local STouchEvent TouchEvent;
		local int Index;

		// Handle new touch events
		if (Type == Touch_Began)
		{
			// Ensure that this is a new touch event
			if (TouchEvents.Find('Handle', Handle) != INDEX_NONE)
			{
				return;
			}

			// Setup the touch event
			TouchEvent.Handle = Handle;
			TouchEvent.ScreenLocation = TouchLocation;
			TouchEvent.HasBeenProcessed = false;

			// Add the touch event to the TouchEvents array
			TouchEvents.AddItem(TouchEvent);
		}
		// Handle existing touch events
		else if (Type == Touch_Ended || Type == Touch_Cancelled)
		{			
			Index = TouchEvents.Find('Handle', Handle);
			if (Index == INDEX_NONE)
			{
				return;
			}

			// Remove the touch event from the TouchEvents array
			TouchEvents.Remove(Index, 1);
		}
	}

	/**
	 * Handle pending right click commands
	 *
	 * @param		HUD					HUD reference in case any functions or variables are required. Canvas is also valid
	 * @param		ScreenLocation		Screen location to convert to a world location
	 * @network							Local client
	 */
	function HandlePendingRightClickCommand(HUD HUD, Vector2D ScreenLocation)
	{
		local Vector WorldOrigin, WorldDirection;

		if (AimingSpell == None)
		{
			return;
		}

		// Get the deprojection coordinates from the screen location
		HUD.Canvas.Deproject(ScreenLocation, WorldOrigin, WorldDirection);
		CastAimSpell(AimingSpell.OrderIndex, WorldOrigin, WorldDirection);

		AimingSpell = None;
		GotoState('PlayerCommanding');
	}

	/**
	 * Called when the state ends
	 *
	 * @param		NextStateName		Name of the next state that the controller will go to next
	 * @network							Server and client
	 */
	event EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);
		
		// Clear the touch array
		TouchEvents.Remove(0, TouchEvents.Length);
	}
}

// Default properties block
defaultproperties
{
	CameraClass=class'UDKMOBACamera_Mobile'
	Properties=UDKMOBAPlayerProperties_Mobile'UDKMOBA_Game_Resources_Mobile.Properties.PlayerProperties'
}