//=============================================================================
// UDKMOBACamera_PC
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
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACamera_PC extends UDKMOBACamera;

// Camera properties
var const UDKMOBACameraProperties_PC CameraProperties;

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
	local Vector CameraDirectionX, CameraDirectionY, CameraDirectionZ, CameraMoveDirection, CameraIntersectionPoint;
	local LocalPlayer LocalPlayer;
	local Vector2D MousePosition;

	// Return the default update camera target
	if (CameraProperties == None)
	{
		Super.UpdateViewTarget(OutVT, DeltaTime);
		return;
	}

	if (PCOwner != None)
	{
		// Grab the mouse coordinates and check if they are on the egde of the screen
		if (PCOwner.MyHUD != None)
		{
			LocalPlayer = LocalPlayer(PCOwner.Player);
			if (LocalPlayer != None && LocalPlayer.ViewportClient != None)
			{
				MousePosition = LocalPlayer.ViewportClient.GetMousePosition();
				// Left
				if (MousePosition.X >= 0 && MousePosition.X < 8)
				{
					CameraMoveDirection.X = -1.f;
				}
				// Right
				else if (MousePosition.X > PCOwner.MyHUD.SizeX - 8 && MousePosition.X <= PCOwner.MyHUD.SizeX)
				{
					CameraMoveDirection.X = 1.f;
				}
				else
				{
					CameraMoveDirection.X = 0.f;
				}

				// Top
				if (MousePosition.Y >= 0 && MousePosition.Y < 8)
				{
					CameraMoveDirection.Y = -1.f;
				}
				// Bottom
				else if (MousePosition.Y > PCOwner.MyHUD.SizeY - 8 && MousePosition.Y <= PCOwner.MyHUD.SizeY)
				{
					CameraMoveDirection.Y = 1.f;
				}
				else
				{
					CameraMoveDirection.Y = 0.f;
				}
			}
		}

		// Normalize the camera move direction based on the player input
		CameraMoveDirection.X += PCOwner.PlayerInput.RawJoyRight;
		CameraMoveDirection.Y += (PCOwner.PlayerInput.RawJoyUp * -1.f);
		CameraMoveDirection = Normal(CameraMoveDirection);

		// Turn off hero tracking as soon as the player attempts to adjust the camera
		if (!IsZero(CameraMoveDirection) && IsTrackingHeroPawn)
		{
			IsTrackingHeroPawn = false;
		}

		if (IsTrackingHeroPawn)
		{
			UDKMOBAPlayerController = UDKMOBAPlayerController(PCOwner);
			if (UDKMOBAPlayerController != None && UDKMOBAPlayerController.HeroPawn != None)
			{
				DesiredCameraLocation = UDKMOBAPlayerController.HeroPawn.Location;
			}
		}
		else
		{
			// Grab the camera rotation axes
			GetAxes(CameraProperties.Rotation, CameraDirectionX, CameraDirectionY, CameraDirectionZ);

			DesiredCameraLocation += Vector(Rotator(CameraDirectionY) + Rot(0, 16384, 0)) * CameraMoveDirection.Y * PCOwner.PlayerInput.MoveForwardSpeed * DeltaTime;
			DesiredCameraLocation += CameraDirectionY * CameraMoveDirection.X * PCOwner.PlayerInput.MoveStrafeSpeed * DeltaTime;
		}

		// Find the point on the camera movement plane where the camera should be. This ensures that the camera stays at a constant height
		class'UDKMOBAObject'.static.LinePlaneIntersection(DesiredCameraLocation, DesiredCameraLocation - Vector(CameraProperties.Rotation) * 16384.f, CameraProperties.MovementPlane, CameraProperties.MovementPlaneNormal, CameraIntersectionPoint);

		// Linearly interpolate to the desired camera location
		OutVT.POV.Location = VLerp(OutVT.POV.Location, CameraIntersectionPoint, CameraProperties.BlendSpeed * DeltaTime);
	}

	// Set the camera rotation
	OutVT.POV.Rotation = CameraProperties.Rotation;
}

// Default properties block
defaultproperties
{
	CameraProperties=UDKMOBACameraProperties_PC'UDKMOBA_Game_Resources_PC.Properties.CameraProperties'
}