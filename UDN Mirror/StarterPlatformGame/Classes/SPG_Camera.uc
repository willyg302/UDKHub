//=============================================================================
// SPG_Camera
//
// Camera which simply adds an offset to the target's location and aims
// the camera at the target.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_Camera extends Camera;

var const archetype SPG_CameraProperties CameraProperties;

/**
 * Updates the camera's view target. Called once per tick
 *
 * @param	OutVT		Outputted camera view target
 * @param	DeltaTime	Time since the last tick was executed
 */
function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	// Early exit if:
	// - We have a pending view target
	// - OutVT currently equals ViewTarget
	// - Blending parameter is lock out going
	if (PendingViewTarget.Target != None && OutVT == ViewTarget && BlendParams.bLockOutgoing)
	{
		return;
	}

	// Add the camera offset to the target's location to get the location of the camera
	OutVT.POV.Location = OutVT.Target.Location + CameraProperties.CameraOffset;
	// Make the camera point towards the target's location
	OutVT.POV.Rotation = Rotator(OutVT.Target.Location - OutVT.POV.Location);
}

defaultproperties
{
	CameraProperties=SPG_CameraProperties'StarterPlatformGameContent.Archetypes.CameraProperties'
}