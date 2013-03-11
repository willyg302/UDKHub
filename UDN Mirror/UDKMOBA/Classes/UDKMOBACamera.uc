//=============================================================================
// UDKMOBACamera
//
// Camera class which handles the camera position. The camera has two modes
// depending on the platform that the game is running on. The camera uses a 
// interpolating method; so that movement of the camera is always fluid.
//
// On PC it uses a fixed height birds eye view. The player is able to move
// the camera by using the arrow keys and when the mouse is on the edge of the 
// screen. The player can also go straight back to their hero by using a 
// console command, and lock onto their hero by double tapping the console
// command. 
// 
// On Mobile it uses a fixed birds eye view. The camera is locked onto the 
// players hero and does not have much freedom in moving the camera around.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACamera extends Camera
	DependsOn(UDKMOBAGameInfo);

// Desired camera location
var ProtectedWrite Vector DesiredCameraLocation;
// If true, then the camera should track the hero pawn until the player attempts to adjust the camera location
var bool IsTrackingHeroPawn;

/**
 * Sets the desired location for the camera
 *
 * @param		NewDesiredCameraLocation		New desired location of the camera
 * @network										Client
 */
function SetDesiredCameraLocation(Vector NewDesiredCameraLocation)
{
	DesiredCameraLocation = NewDesiredCameraLocation;
}

// Default properties block
defaultproperties
{
}