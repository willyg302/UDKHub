//=============================================================================
// SPG_PlayerController
//
// Pawn which represents the player. Handles visual components and driving
// the aim offset.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_PlayerController extends PlayerController;

// The desired rotation that we want the pawn to be facing
var Rotator DesiredRotation;

/**
 * Updates the rotation of the controller and the pawn. Called once per tick
 *
 * @param	DeltaTime	Time since the last tick was executed.
 * @network				Server and client
 */
function UpdateRotation(float DeltaTime)
{
	local Rotator DeltaRot;

	// Set the delta rotation to that of the desired rotation, as the desired rotation represents
	// the rotation derived from the acceleration of the pawn
	DeltaRot = DesiredRotation;
	// Set the delta pitch to read from the look up input
	DeltaRot.Pitch = PlayerInput.aLookUp;
	// Never need to roll the delta rotation
	DeltaRot.Roll = 0;

	// Shake the camera if necessary
	ViewShake(DeltaTime);

	// If we have a pawn, update its facing rotation
	if (Pawn != None)
	{
		Pawn.FaceRotation(DeltaRot, DeltaTime);
	}
}

// Default state that pawn is walking
state PlayerWalking
{
	/**
	 * Handle player moving. Called once per tick
	 *
	 * @param	DeltaTime	Time since the last tick
	 * @network				Server and client
	 */
	function PlayerMove(float DeltaTime)
	{
		local Vector X, Y, Z, NewAccel, CameraLocation;
		local Rotator OldRotation, CameraRotation;
		local bool bSaveJump;

		// If we don't have a pawn to control, then we should go to the dead state
		if (Pawn == None)
		{
			GotoState('Dead');
		}
		else
		{
			// Grab the camera view point as we want to have movement aligned to the camera
			PlayerCamera.GetCameraViewPoint(CameraLocation, CameraRotation);
			// Get the individual axes of the rotation
			GetAxes(CameraRotation, X, Y, Z);

			// Update acceleration
			NewAccel = PlayerInput.aStrafe * Y;
			NewAccel.Z = 0;
			NewAccel = Pawn.AccelRate * Normal(NewAccel);

			// Set the desired rotation
			DesiredRotation = Rotator(NewAccel);

			// Update rotation
			OldRotation = Rotation;
			UpdateRotation(DeltaTime);

			// Update crouch
			Pawn.ShouldCrouch(bool(bDuck));

			// Handle jumping
			if (bPressedJump && Pawn.CannotJumpNow())
			{
				bSaveJump = true;
				bPressedJump = false;
			}
			else
			{
				bSaveJump = false;
			}

			// Update the movement, either replicate it or process it
			if (Role < ROLE_Authority)
			{
				ReplicateMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
			}
			else
			{
				ProcessMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
			}

			bPressedJump = bSaveJump;
		}
	}
}

/**
 * Exec function called when the crouch button is pressed
 */
simulated exec function Duck()
{
	bDuck = 1;
}

/**
 * Exec function called when the crouch button is released
 */
simulated exec function UnDuck()
{
	bDuck = 0;
}

defaultproperties
{
	CameraClass=class'SPG_Camera'
}