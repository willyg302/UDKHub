//=============================================================================
// UDKMOBAPlayerController_PC
//
// PC/Mac player controller which uses the mouse and keyboard to interact with 
// the game.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPlayerController_PC extends UDKMOBAPlayerController;

// Aiming decal component
var ProtectedWrite UDKMOBADecalActorSpawnable AimingDecalActor;
// If true, then track the mouse when the left mouse button is depressed
var ProtectedWrite bool TrackMouseWhileLeftMouseButtonIsHeld;

/**
 * Returns true if the HUD is currently capturing the mouse input or not
 *
 * @return		Returns true if the HUD is currently capturing the mouse input or not
 * @network		Server and client
 */
function bool IsHUDCapturingMouseInput()
{
	local UDKMOBAHUD UDKMOBAHUD;
	
	UDKMOBAHUD = UDKMOBAHUD(MyHUD);
	if (UDKMOBAHUD == None || UDKMOBAHUD.HUDMovie == None)
	{
		return false;
	}

	return UDKMOBAHUD.HUDMovie.bCapturingMouseInput;
}

/**
 * Propagated from HUD::PostRender().
 *
 * @network		Server and client
 */
function PostRender();

/**
 * This state handles when the player commanding the hero pawn
 *
 * @network		Server and client
 */
state PlayerCommanding
{
	/**
	 * Propagated from HUD::PostRender().
	 *
	 * @network		Server and client
	 */
	function PostRender()
	{
		local Vector HitLocation, HitNormal;
		local UDKMOBAHUD UDKMOBAHUD;
		local Color PlayerColor;
		local Vector2D MinimapLocation;

		if (TrackMouseWhileLeftMouseButtonIsHeld)
		{
			UDKMOBAHUD = UDKMOBAHUD(MyHUD);
			if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None && UDKMOBAHUD.HUDMovie.DrawOnMinimap && UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC != None && class'UDKMOBAObject'.static.MouseToWorldCoordinates(MyHUD, HitLocation, HitNormal) && class'UDKMOBAObject'.static.GetPlayerColor(UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo), PlayerColor))
			{
				class'UDKMOBAMapInfo'.static.WorldToMinimap(HitLocation, MinimapLocation);
				UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.DrawUsingScreenSpaceCoordinates(MinimapLocation.X * UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.HalfWidth, MinimapLocation.Y * UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.HalfHeight, PlayerColor, class'UDKMOBAGFxHUD'.default.Properties.DrawingTimeInterval);
			}
		}
	}

	/**
	 * Player wants to fire his / her weapon.
	 *
	 * @param		FireModeNum			Fire mode index
	 * @network							Local client
	 */
	exec function StartFire(optional byte FireModeNum)
	{
		local UDKMOBAHUD_PC UDKMOBAHUD_PC;

		// Don't call the super if the HUD is capturing input
		if (!IsHUDCapturingMouseInput())
		{
			Global.StartFire(FireModeNum);
		}

		// StartFire(0) is normally bound to Left Mouse Click
		if (FireModeNum == 0)
		{
			// Set the pending left click command on ths HUD
			UDKMOBAHUD_PC = UDKMOBAHUD_PC(MyHUD);
			if (UDKMOBAHUD_PC != None)
			{
				UDKMOBAHUD_PC.PendingLeftClickCommand = true;
			}
		}
		// StartFire(1) is normally bound to Right Mouse Click
		else if (FireModeNum == 1)
		{
			// Set the pending right click command on the HUD
			UDKMOBAHUD_PC = UDKMOBAHUD_PC(MyHUD);
			if (UDKMOBAHUD_PC != None)
			{
				UDKMOBAHUD_PC.PendingRightClickCommand = true;
			}
		}
	}

	/**
	 * Player wants to stop firing his / her weapon.
	 *
	 * @param		FireModeNum		Fire mode index
	 * @network						Local client
	 */
	exec function StopFire(optional byte FireModeNum)
	{
		if (FireModeNum == 0 && TrackMouseWhileLeftMouseButtonIsHeld)
		{
			TrackMouseWhileLeftMouseButtonIsHeld = false;
		}
	}

	/**
	 * Handle pending left click commands
	 *
	 * @param		HUD					HUD reference in case any functions or variables are required. Canvas is also valid
	 * @param		ScreenLocation		Screen location to convert to a world location
	 * @network							Local client
	 */
	function HandlePendingLeftClickCommand(HUD HUD, Vector2D ScreenLocation)
	{
		local Vector HitLocation, HitNormal;
		local UDKMOBAHUD UDKMOBAHUD;
		local Vector2D MinimapLocation;

		// Ping on the mini by converting the world coordinates to mini map coordinates
		if (PingOnMinimap)
		{
			UDKMOBAHUD = UDKMOBAHUD(MyHUD);
			if (UDKMOBAHUD != None && class'UDKMOBAObject'.static.ScreenSpaceCoordinatesToWorldCoordinates(HUD, ScreenLocation, HitLocation, HitNormal))
			{				
				UDKMOBAHUD.HUDMovie.PerformPingUsingWorldSpaceCoordinates(HitLocation);
			}
		}
		else
		{
			// Otherwise check if we should be drawing on the mini map
			UDKMOBAHUD = UDKMOBAHUD(MyHUD);
			if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None && UDKMOBAHUD.HUDMovie.DrawOnMinimap && UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC != None && class'UDKMOBAObject'.static.MouseToWorldCoordinates(MyHUD, HitLocation, HitNormal))
			{
				class'UDKMOBAMapInfo'.static.WorldToMinimap(HitLocation, MinimapLocation);
				UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.LastMousePosition.X = MinimapLocation.X * UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.HalfWidth;
				UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.LastMousePosition.Y = MinimapLocation.Y * UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.HalfHeight;
				TrackMouseWhileLeftMouseButtonIsHeld = true;
			}
		}
	}
}

/**
 * Updates the world cursor, which is usually represented as a decal component that can move around
 *
 * @param		HUD			HUD reference
 * @network					Server and local client
 */
function UpdateWorldCursor(HUD HUD);

/**
 * This state handles when the player is aiming a spell
 *
 * @network		Server and client
 */
state PlayerAimingSpell
{
	/**
	 * Player wants to fire his / her weapon.
	 *
	 * @param		FireModeNum			Fire mode index
	 * @network							Local client
	 */
	exec function StartFire(optional byte FireModeNum)
	{
		local UDKMOBAHUD_PC UDKMOBAHUD_PC;

		// Don't call the super if the HUD is capturing input
		if (!IsHUDCapturingMouseInput())
		{
			Global.StartFire(FireModeNum);
		}

		// StartFire(0) is normally bound to Left Mouse Click
		if (FireModeNum == 0)
		{
			// Set the pending left click command on ths HUD
			UDKMOBAHUD_PC = UDKMOBAHUD_PC(MyHUD);
			if (UDKMOBAHUD_PC != None)
			{
				UDKMOBAHUD_PC.PendingLeftClickCommand = true;
			}
		}
		// StartFire(1) is normally bound to Right Mouse Click
		else if (FireModeNum == 1)
		{
			// Set the pending right click command on the HUD
			UDKMOBAHUD_PC = UDKMOBAHUD_PC(MyHUD);
			if (UDKMOBAHUD_PC != None)
			{
				UDKMOBAHUD_PC.PendingRightClickCommand = true;
			}
		}
	}

	/**
	 * Called when the controller first goes into this state
	 *
	 * @param		PreviousStateName		Name of the state that this actor was in previously
	 * @network								Server and client
	 */
	event BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		// Create the aiming decal actor if it doesn't exist
		if (AimingDecalActor == None)
		{
			AimingDecalActor = Spawn(class'UDKMOBADecalActorSpawnable',,,, Rot(-16384, 0, 0));
			if (AimingDecalActor != None)
			{
				AimingDecalActor.SetHidden(true);
			}
		}

		// Set the aiming decal material and size
		if (AimingDecalActor != None && AimingSpell != None)
		{
			AimingDecalActor.SetDecalMaterial(AimingSpell.DecalMaterial);
			AimingDecalActor.SetDecalSize(AimingSpell.DecalSize);
		}
	}

	/**
	 * Called when the controller leaves this state
	 *
	 * @param		NextStateName		Name of the state that this actor will go into next
	 * @network							Server and client
	 */
	event EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);

		// Hide the aiming decal actor
		if (AimingDecalActor != None)
		{
			AimingDecalActor.SetHidden(true);
		}
	}

	/**
	 * Handle pending left click commands
	 *
	 * @param		HUD					HUD reference in case any functions or variables are required. Canvas is also valid
	 * @param		ScreenLocation		Screen location to convert to a world location
	 * @network							Local client
	 */
	function HandlePendingLeftClickCommand(HUD HUD, Vector2D ScreenLocation)
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
	 * Handle pending right click commands. Cancel the spell that the player is currently aiming
	 *
	 * @param		HUD					HUD reference in case any functions or variables are required. Canvas is also valid
	 * @param		ScreenLocation		Screen location to convert to a world location
	 * @network							Local client
	 */
	function HandlePendingRightClickCommand(HUD HUD, Vector2D ScreenLocation)
	{
		AimingSpell = None;
		GotoState('PlayerCommanding');
	}

	/**
	 * Updates the world cursor, which is usually represented as a decal component that can move around
	 *
	 * @param		HUD			HUD reference
	 * @network					Server and local client
	 */
	function UpdateWorldCursor(HUD HUD)
	{
		local Vector HitLocation, HitNormal;

		if (AimingSpell == None || HUD == None || AimingDecalActor == None)
		{
			return;
		}

		if (AimingSpell.AimingType == EAT_World && class'UDKMOBAObject'.static.MouseToWorldCoordinates(HUD, HitLocation, HitNormal))
		{
			AimingDecalActor.SetLocation(HitLocation + Vect(0.f, 0.f, 256.f));

			if (AimingDecalActor.bHidden)
			{
				AimingDecalActor.SetHidden(false);
			}
		}
	}
}

// Default properties block
defaultproperties
{
	CameraClass=class'UDKMOBACamera_PC'
	Properties=UDKMOBAPlayerProperties_PC'UDKMOBA_Game_Resources_PC.Properties.PlayerProperties'
}