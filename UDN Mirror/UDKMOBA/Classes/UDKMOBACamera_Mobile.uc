//=============================================================================
// UDKMOBACamera_Mobile
//
// Camera class which handles the camera position. The camera has two modes
// depending on the platform that the game is running on. The camera uses a 
// interpolating method; so that movement of the camera is always fluid.
//
// On Mobile it uses a fixed birds eye view. The camera is locked onto the 
// players hero and does not have much freedom in moving the camera around.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACamera_Mobile extends UDKMOBACamera;

// Camera properties
var const UDKMOBACameraProperties_Mobile CameraProperties;
// Secondary desired camera location
var Vector SecondaryDesiredCameraLocation;

/**
 * Sets the desired location for the camera
 *
 * @param		NewDesiredCameraLocation		New desired location of the camera
 * @network										Client
 */
function SetDesiredCameraLocation(Vector NewDesiredCameraLocation)
{
	SecondaryDesiredCameraLocation = NewDesiredCameraLocation;
}

/**
 * Query ViewTarget and outputs Point Of View.
 *
 * @param		OutVT			ViewTarget to use.
 * @param		DeltaTime		Delta Time since last camera update (in seconds).
 * @network						Client
 */
function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAHUD UDKMOBAHUD;
	local Vector TargetLocation;

	// Return the default update camera target
	if (CameraProperties == None)
	{
		Super.UpdateViewTarget(OutVT, DeltaTime);
		return;
	}

	UDKMOBAPlayerController = UDKMOBAPlayerController(PCOwner);
	if (UDKMOBAPlayerController != None && UDKMOBAPlayerController.HeroPawn != None)
	{
		// Check if the mini map wants control of the target location
		UDKMOBAHUD = UDKMOBAHUD(UDKMOBAPlayerController.MyHUD);
		if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None && UDKMOBAHUD.HUDMovie.MinimapButtonPressed && !UDKMOBAHUD.HUDMovie.DrawOnMinimap && !UDKMOBAHUD.HUDMovie.MoveUsingMinimap)
		{
			TargetLocation = SecondaryDesiredCameraLocation;
		}
		else
		{
			// Calculate the camera as the target location plus the vertical hover distance
			TargetLocation = UDKMOBAPlayerController.HeroPawn.Location;
		}
	}
	else
	{
		TargetLocation = OutVT.Target.Location;
	}

	// Calculate the camera as the target location plus the vertical hover distance
	DesiredCameraLocation = TargetLocation - Vector(CameraProperties.Rotation) * CameraProperties.HoverDistance;

	// Linearly interpolate to the desired camera location
	OutVT.POV.Location = VLerp(OutVT.POV.Location, DesiredCameraLocation, CameraProperties.BlendSpeed * DeltaTime);

	// Set the camera rotation
	OutVT.POV.Rotation = CameraProperties.Rotation;
}

// Default properties block
defaultproperties
{
	CameraProperties=UDKMOBACameraProperties_Mobile'UDKMOBA_Game_Resources_Mobile.Properties.CameraProperties'
}