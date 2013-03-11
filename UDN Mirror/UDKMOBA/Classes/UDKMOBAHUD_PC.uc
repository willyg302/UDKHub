//=============================================================================
// UDKMOBAHUD_PC
//
// PC/Mac specific version of the MOBA HUD. Mostly handles pending left and
// right mouse clicks.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAHUD_PC extends UDKMOBAHUD;

// HUD PC Properties
var ProtectedWrite UDKMOBAHUD_PCProperties CachedPCHUDProperties;
// Pending left click command
var bool PendingLeftClickCommand;
// Pending right click command
var bool PendingRightClickCommand;

// Portrait material instance constant instance
var ProtectedWrite MaterialInstanceConstant PortraitMaterialInstanceConstant;
// Create the render target for the portrait
var ProtectedWrite TextureRenderTarget2D PortraitRenderTarget;
// Create the portrait skeletal mesh
var ProtectedWrite UDKMOBAPortraitSkeletalMeshActor PortraitSkeletalMeshActor;
// Create the portrait scene capture component
var ProtectedWrite SceneCapture2DComponent PortraitSceneCapture2DComponent;

/**
 * Called when the HUD is first instanced 
 *
 * @network		Client
 */
event PostBeginPlay()
{
	Super.PostBeginPlay();

	// Check that the HUD properties
	if (HUDProperties != None)
	{
		CachedPCHUDProperties = UDKMOBAHUD_PCProperties(HUDProperties);
		if (CachedPCHUDProperties != None)
		{
			// Create the render target
			PortraitRenderTarget = class'TextureRenderTarget2D'.static.Create(256, 256, PF_A8R8G8B8, MakeLinearColor(1.f, 0.f, 1.f, 1.f), false);
			if (PortraitRenderTarget != None)
			{
				// Create the portrait skeletal mesh actor
				PortraitSkeletalMeshActor = Spawn(class'UDKMOBAPortraitSkeletalMeshActor',,, Vect(-32768.f, -32768.f, -32768.f), CachedPCHUDProperties.PortraitSkeletalMeshActorRotation);
				// Create the scene capture component
				PortraitSceneCapture2DComponent = new () class'SceneCapture2DComponent';
				if (PortraitSceneCapture2DComponent != None)
				{
					AttachComponent(PortraitSceneCapture2DComponent);
					PortraitSceneCapture2DComponent.bUpdateMatrices = false;
					PortraitSceneCapture2DComponent.ViewMode = SceneCapView_Lit;
					PortraitSceneCapture2DComponent.SetCaptureParameters(PortraitRenderTarget, 90.f, 1.f, 1024.f);
					PortraitSceneCapture2DComponent.SetView(PortraitSkeletalMeshActor.Location + CachedPCHUDProperties.PortraitCameraOffset, Rot(0, 0, 0));
				}
			}
		}
	}
}

/**
 * Precalculate most common values, to avoid doing 1200 times the same operations
 *
 * @network		Client
 */
function PreCalcValues()
{
	Super.PreCalcValues();

	// Abort if no HUD properties
	if (CachedPCHUDProperties == None)
	{
		return;
	}
}

/**
 * Called when the HUD should handle rendering
 *
 * @network		Client
 */
event PostRender()
{
	local UDKMOBAPlayerController_PC UDKMOBAPlayerController_PC;
	local LocalPlayer LocalPlayer;

	Super.PostRender();

	if (PlayerOwner != None)
	{
		// Ensure that the hardware cursor is always visible
		LocalPlayer = LocalPlayer(PlayerOwner.Player);
		if (LocalPlayer != None && LocalPlayer.ViewportClient != None && !LocalPlayer.ViewportClient.bDisplayHardwareMouseCursor)
		{
			LocalPlayer.ViewportClient.SetHardwareMouseCursorVisibility(true);
		}

		// Setup the portrait skeletal mesh actor
		UDKMOBAPlayerController_PC = UDKMOBAPlayerController_PC(PlayerOwner);
		if (UDKMOBAPlayerController_PC != None)
		{
			if (PortraitSkeletalMeshActor != None && PortraitSkeletalMeshActor.SkeletalMesh.SkeletalMesh == None && UDKMOBAPlayerController_PC != None && UDKMOBAPlayerController_PC.HeroPawn != None)
			{
				PortraitSkeletalMeshActor.SkeletalMesh.SetSkeletalMesh(UDKMOBAPlayerController_PC.HeroPawn.Mesh.SkeletalMesh);

				if (HUDMovie != None)
				{
					HUDMovie.SetHeroPortrait(PortraitRenderTarget);
				}
			}

			// Forward the post render call to the player controller
			UDKMOBAPlayerController_PC.PostRender();

			// If the player is in the aiming state, then handle placing the decal component
			if (UDKMOBAPlayerController_PC.IsInState('PlayerAimingSpell'))
			{
				UDKMOBAPlayerController_PC.UpdateWorldCursor(Self);
			}
		}
	}

	// Process all commands
	ProcessCommands();	
}

/**
 * Handle all pending commands
 *
 * @network		Client
 */
protected function ProcessCommands()
{
	local LocalPlayer LocalPlayer;
	local UDKMOBAPlayerController_PC UDKMOBAPlayerController_PC;

	if (HUDMovie.bCapturingMouseInput)
	{
		if (PendingLeftClickCommand)
		{
			HUDMovie.HandlePendingLeftClickCommand();
			PendingLeftClickCommand = false;
		}

		if (PendingRightClickCommand)
		{
			HUDMovie.HandlePendingRightClickCommand();
			PendingRightClickCommand = false;
		}
	}
	// Handle a pending move command
	else if (PlayerOwner != None)
	{
		UDKMOBAPlayerController_PC = UDKMOBAPlayerController_PC(PlayerOwner);
		if (UDKMOBAPlayerController_PC != None)
		{
			// Grab the local player, abort if no local player or the local player has no viewport
			LocalPlayer = LocalPlayer(PlayerOwner.Player);
			if (LocalPlayer == None || LocalPlayer.ViewportClient == None)
			{
				return;
			}

			// Send the mouse position to process a left click command
			if (PendingLeftClickCommand)
			{
				UDKMOBAPlayerController_PC.HandlePendingLeftClickCommand(Self, LocalPlayer.ViewportClient.GetMousePosition());
				PendingLeftClickCommand = false;
			}

			// Send the mouse position to process a right click command
			if (PendingRightClickCommand)
			{
				UDKMOBAPlayerController_PC.HandlePendingRightClickCommand(Self, LocalPlayer.ViewportClient.GetMousePosition());
				PendingRightClickCommand = false;
			}
		}
	}
}

// Default properties block
defaultproperties
{
	HUDProperties=UDKMOBAHUD_PCProperties'UDKMOBA_HUD_PC_Resources.Archetypes.HUDProperties'
}