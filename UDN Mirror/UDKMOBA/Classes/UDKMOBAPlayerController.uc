//=============================================================================
// UDKMOBAPlayerController
//
// Base player controller which handles most of the underlying game mechanics
// such as moving the hero character, casting spells, buying inventory items.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPlayerController extends SimplePC
	abstract;

// Properties archetype used by the player controller
var const UDKMOBAPlayerProperties Properties;
// An array of all blocking volumes
var array<BlockingVolume> BlockingVolumes;
// Confirmation particle effect
var EmitterSpawnable ConfirmationEmitter;
// Current aim spell that is being aimed
var UDKMOBASpell AimingSpell;
// Last time the player snapped the camera to the hero
var float LastCameraSnapToHeroTime;
// If true, then the player wants to ping on the mini map
var ProtectedWrite bool PingOnMinimap;

// Hero that the player is controlling
var RepNotify UDKMOBAHeroPawn HeroPawn;
`if(`notdefined(FINAL_RELEASE))
var const UDKMOBAHeroPawn CathodeHeroArchetype;
var const UDKMOBAHeroPawn DemoGuyHeroArchetype;
`endif

// Replication block
replication
{
	if (bNetDirty)
		HeroPawn;
}

/**
 * Called when the player controller is initialized
 *
 * @network		Server and local client
 */
simulated function PostBeginPlay()
{
	local BlockingVolume BlockingVolume;

	Super.PostBeginPlay();

	// Find and cache all of the blocking volumes
	ForEach AllActors(class'BlockingVolume', BlockingVolume)
	{
		BlockingVolumes.AddItem(BlockingVolume);
	}	

	// Spawn the confirmation emitter
	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		ConfirmationEmitter = Spawn(class'EmitterSpawnable');
	}
}

/**
 * Transfers a stash item to the inventory
 *
 * @param		StashIndex		Index into the stash array to transfer to the inventory array
 * @network						Local client
 */
simulated function TranfersStashToInventory(int StashIndex)
{
	if (!CanTransferStashToInventory(StashIndex))
	{
		return;
	}

	if (Role < Role_Authority)
	{
		ServerTranfersStashToInventory(StashIndex);
	}

	TransferredStashToInventory(StashIndex);
}

/**
 * Transfers a stash item to the inventory
 *
 * @param		StashIndex		Index into the stash array to transfer to the inventory array
 * @network						Server
 */
reliable server function ServerTranfersStashToInventory(int StashIndex)
{
	if (CanTransferStashToInventory(StashIndex))
	{
		TransferredStashToInventory(StashIndex);
	}
}

/**
 * Transfered a stash item to the inventory
 *
 * @param		StashIndex		Index into the stash array to transfer to the inventory array
 * @network						All
 */
simulated function TransferredStashToInventory(int StashIndex)
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None)
	{
		UDKMOBAPawnReplicationInfo.TransferStashToInventory(StashIndex);
	}
}

/**
 * Returns true if an item in the stash can be trasnferred into the inventory
 *
 * @param		StashIndex		Index into the stash array to transfer to the inventory array
 * @network						All
 */
simulated function bool CanTransferStashToInventory(int StashIndex)
{
	local UDKMOBAShopAreaVolume UDKMOBAShopAreaVolume;
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	// Check if the hero pawn is within his own shop volume
	if (HeroPawn == None)
	{
		return false;
	}

	// Player must be within his/her shop volume
	UDKMOBAShopAreaVolume = UDKMOBAShopAreaVolume(HeroPawn.PhysicsVolume);
	if (UDKMOBAShopAreaVolume == None || UDKMOBAShopAreaVolume.GetTeamNum() != HeroPawn.GetTeamNum())
	{
		return false;
	}

	// Check that the inventory index is available to use
	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None && UDKMOBAPawnReplicationInfo.Stash[StashIndex] != None)
	{
		return UDKMOBAPawnReplicationInfo.CanTransferStashToInventory(StashIndex);
	}

	return true;
}

/**
 * Console command which toggles if the player want to ping on the minimap or not
 *
 * @param		EnablePingOnMinimap		If true, then enable pinging on the mini map
 * @network								All
 */
exec function TogglePingOnMinimap(bool EnablePingOnMinimap)
{
	PingOnMinimap = EnablePingOnMinimap;
}

/**
 * Console command which toggles if the player wants to draw on the minimap or not
 *
 * @param		EnableDrawOnMinimap		If true, then enable drawing on the mini map
 * @network								All
 */
exec function ToggleDrawOnMinimap(bool EnableDrawOnMinimap)
{
	local UDKMOBAHUD UDKMOBAHUD;

	UDKMOBAHUD = UDKMOBAHUD(MyHUD);
	if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
	{
		UDKMOBAHUD.HUDMovie.DrawOnMinimap = EnableDrawOnMinimap;

		// Set up a timer which clears the lines on the mini map
		if (!EnableDrawOnMinimap)
		{
			UDKMOBAHUD.HUDMovie.StartTimerToClearDrawnLines();
		}
		// Stop the timer which clears the lines on the mini map
		else
		{
			UDKMOBAHUD.HUDMovie.StopTimerToClearDrawnLines();
		}
	}
}

/**
 * Console command which toggles the on screen stats bars for creeps, heroes and objectives
 *
 * @param		ShowOnScreenStatsBars		If true, then show the screen stats bars
 * @network									Server and local client
 */
exec function ToggleOnScreenStatsBars(bool ShowOnScreenStatsBars)
{
	local UDKMOBAHUD UDKMOBAHUD;

	// Forward this to the HUD
	UDKMOBAHUD = UDKMOBAHUD(MyHUD);
	if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
	{
		UDKMOBAHUD.HUDMovie.ToggleOnScreenStatsBars(ShowOnScreenStatsBars);
	}
}

/**
 * List important PlayerController variables on canvas.  HUD will call DisplayDebug() on the current ViewTarget when the ShowDebug exec is used.
 *
 * @param		HUD				HUD with canvas to draw on
 * @param		out_YL			Height of the current font
 * @param		out_YPos		Y position on Canvas. out_YPos += out_YL, gives position to draw text for next debug line.
 * @network						Server and local client
 */
simulated function DisplayDebug(HUD HUD, out float out_YL, out float out_YPos)
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	Super.DisplayDebug(HUD, out_YL, out_YPos);

	// Show debug message of the hero selected
	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None)
	{
		HUD.Canvas.SetDrawColor(255, 0, 255);
		HUD.Canvas.DrawText("Hero:"@UDKMOBAPlayerReplicationInfo.HeroArchetype$", Team:"@UDKMOBAPlayerReplicationInfo.Team$", Team Index:"@UDKMOBAPlayerReplicationInfo.Team.TeamIndex);
		out_YPos += out_YL;
		HUD.Canvas.SetPos(4, out_YPos);
	}
}

/**
 * Console command to set the player's hero to Cathode
 *
 * @network		Server and local client
 */
exec function SelectCathodeHero()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;	

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None)
	{
		UDKMOBAPlayerReplicationInfo.SetHeroArchetype(CathodeHeroArchetype);
	}
}

/**
 * Console command to set the player's hero to DemoGuy
 *
 * @network		Server and client
 */
exec function SelectDemoGuyHero()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None)
	{
		UDKMOBAPlayerReplicationInfo.SetHeroArchetype(DemoGuyHeroArchetype);
	}
}

/**
 * Console command which snaps the camera back to the hero
 *
 * @network		Server and local client
 */
exec function SnapCameraToHero()
{
	local UDKMOBACamera UDKMOBACamera;

	UDKMOBACamera = UDKMOBACamera(PlayerCamera);
	if (UDKMOBACamera != None)
	{
		UDKMOBACamera.SetDesiredCameraLocation(HeroPawn.Location);

		// If the player snapped to the hero in quick succession then track the hero
		if (WorldInfo.TimeSeconds - LastCameraSnapToHeroTime < 0.15f)
		{
			UDKMOBACamera.IsTrackingHeroPawn = true;
		}

		// Keep track of when the player did this
		LastCameraSnapToHeroTime = WorldInfo.TimeSeconds;
	}
}

/**
 * Console command to allow the player to cast a spell
 *
 * @param		SpellIndex		Which spell to cast
 * @network						Server and local client
 */
exec function CastSpell(byte SpellIndex)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	// Check thay we have access to the player replication info
	// Check that the spell index is within range of the spell array
	// Check that the spell at the spell index is valid
	// Check that the spell is able to be casted
	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None || SpellIndex >= UDKMOBAHeroPawnReplicationInfo.Spells.Length || UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex] == None || !UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].CanCast())
	{
		return;
	}

	// If the spell does use an aiming style, then go to the player aiming spell state
	if (UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].AimingType != EAT_None)
	{
		AimingSpell = UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex];
		GotoState('PlayerAimingSpell');
	}
	// Otherwise activate the spell
	else
	{
		// If this is on the client, then sync with the server
		if (Role < Role_Authority)
		{
			ServerActivateSpell(SpellIndex);
		}

		// Begin casting the spell
		BeginActivatingSpell(SpellIndex);
	}
}

/**
 * Client replicated function to the server which begins activating the spell
 *
 * @param		SpellIndex		Which spell to cast
 * @network						Server
 */
reliable server function ServerActivateSpell(byte SpellIndex)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	// Clients can never run this
	if (Role < Role_Authority)
	{
		return;
	}

	// Check thay we have access to the player replication info
	// Check that the spell index is within range of the spell array
	// Check that the spell at the spell index is valid
	// Check that the spell is able to be casted
	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None || SpellIndex >= UDKMOBAHeroPawnReplicationInfo.Spells.Length || UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex] == None || !UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].CanCast())
	{
		return;
	}

	// Begin activating the spell
	BeginActivatingSpell(SpellIndex);
}

/**
 * Called to actually begin activating a spell that doesn't require aim
 *
 * @param		SpellIndex		Which spell to cast
 * @network						Server and local client
 */
protected simulated function BeginActivatingSpell(byte SpellIndex)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	// Check thay we have access to the player replication info
	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None)
	{
		return;
	}

	// Since the check for the spell is already done on both the client and the server, and this function is protected, SpellIndex is considered to be safe to use
	UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].Activate();
}

/**
 * Allows players to cast an aimed spell
 *
 * @param		SpellIndex		Which spell to cast
 * @param		AimLocation		World space location the user is aiming from
 * @param		AimDirection	World space direction the user is aiming in
 * @network						Server and local client
 */
simulated function CastAimSpell(byte SpellIndex, Vector AimLocation, Vector AimDirection)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	// Check thay we have access to the player replication info
	// Check that the spell index is within range of the spell array
	// Check that the spell at the spell index is valid
	// Check that the spell is able to be casted
	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None || SpellIndex >= UDKMOBAHeroPawnReplicationInfo.Spells.Length || UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex] == None || !UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].CanCast())
	{
		return;
	}

	// If this is on the client, then sync with the server
	if (Role < Role_Authority)
	{
		ServerActivateAimSpell(SpellIndex, AimLocation, AimDirection);
	}

	// Begin activating the spell
	BeginActivatingAimSpell(SpellIndex, AimLocation, AimDirection);
}

/**
 * Client replicated function to the server which begins activating the spell
 *
 * @param		SpellIndex		Which spell to cast
 * @param		AimLocation		World space location the user is aiming from
 * @param		AimDirection	World space direction the user is aiming in
 * @network						Server
 */
reliable server function ServerActivateAimSpell(byte SpellIndex, Vector AimLocation, Vector AimDirection)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	// Clients can never run this
	if (Role < Role_Authority)
	{
		return;
	}

	// Check thay we have access to the player replication info
	// Check that the spell index is within range of the spell array
	// Check that the spell at the spell index is valid
	// Check that the spell is able to be casted	
	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None || SpellIndex >= UDKMOBAHeroPawnReplicationInfo.Spells.Length || UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex] == None || !UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].CanCast())
	{
		return;
	}

	// Begin casting the spell
	BeginActivatingAimSpell(SpellIndex, AimLocation, AimDirection);
}

/**
 * Called to actually begin casting the spell
 *
 * @param		SpellIndex		Which spell to cast
 * @param		AimLocation		World space location the user is aiming from
 * @param		AimDirection	World space direction the user is aiming in
 * @network						Server and local client
 */
protected simulated function BeginActivatingAimSpell(byte SpellIndex, Vector AimLocation, Vector AimDirection)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	// Check thay we have access to the player replication info
	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None)
	{
		return;
	}

	// Since the check for the spell is already done on both the client and the server, and this function is protected, SpellIndex is considered to be safe to use
	if (UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].SetTargetsFromAim(AimLocation, AimDirection))
	{
		// Target is valid, can proceed
		UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].Activate();
	}
}

/**
 * Called when a variable flagged as RepNotify is replicated
 *
 * @param		VarName			Name of the variable that was replicated
 * @network						Local client
 */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == NameOf(HeroPawn))
	{
		if (HeroPawn != None && HeroPawn != AcknowledgedPawn)
		{
			ClientRestart(HeroPawn);
		}
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Called when the client should restart with this new pawn
 *
 * @param		NewPawn			New pawn to start with
 * @network						Local client
 */
reliable client function ClientRestart(Pawn NewPawn)
{
	local UDKMOBACamera UDKMOBACamera;

	if (NewPawn == None)
	{
		return;
	}

	// Reset all player movement input
	ResetPlayerMovementInput();
	// Clean out saved moves, since they are no longer valid
    CleanOutSavedMoves();
	// Send the acknowledgement that the pawn has been possessed
	AcknowledgePossession(NewPawn);
	// Restart the client side pawn
	NewPawn.ClientRestart();

	// If this is executed on the client, then...
	if (Role < ROLE_Authority)
	{
		// Auto focus on newly possessed pawns
		if (class'UDKMOBAGameInfo'.static.GetPlatform() == P_PC)
		{
			UDKMOBACamera = UDKMOBACamera(PlayerCamera);
			if (UDKMOBACamera != None)
			{
				UDKMOBACamera.SetDesiredCameraLocation(NewPawn.Location);
			}
		}

		// Set the view target as the pawn
		SetViewTarget(NewPawn);
		// Enter the starting state on the client
		EnterStartState();
	}
}

/**
 * Called when this controller should possess a pawn. This is handled differently compared to standard Unreal, as what is desired is that the player only sends commands to his / her pawn.
 *
 * @param		inPawn					Incoming pawn to possess
 * @param		bVehicleTransition		If true, then the player is jumping into a vehicle
 * @network								Server
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	local UDKMOBAHeroAIController UDKMOBAHeroAIController;
	local int i;
	local UDKMOBASpell Spell;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	// Attempt to assign hero pawn, if it fails then abort
	HeroPawn = UDKMOBAHeroPawn(inPawn);
	if (HeroPawn == None)
	{
		return;
	}

	// Assign the hero AI controller it's controller
	UDKMOBAHeroAIController = UDKMOBAHeroAIController(HeroPawn.Controller);
	if (UDKMOBAHeroAIController != None)
	{
		UDKMOBAHeroAIController.Controller = Self;
		UDKMOBAHeroAIController.UDKMOBAPlayerController = Self;
	}

	// Assign the hero pawn's player replication info
	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None)
	{
		// If it doesn't exist yet, create it; otherwise use the existing one
		if (UDKMOBAPlayerReplicationInfo.PawnReplicationInfo == None)
		{
			UDKMOBAHeroPawnReplicationInfo = Spawn(class'UDKMOBAHeroPawnReplicationInfo', Self);
		}
		else
		{
			UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAPlayerReplicationInfo.PawnReplicationInfo);
		}

		UDKMOBAHeroPawnReplicationInfo.Team = PlayerReplicationInfo.Team;
		UDKMOBAHeroPawnReplicationInfo.PlayerReplicationInfo = PlayerReplicationInfo;

		HeroPawn.PlayerReplicationInfo = UDKMOBAHeroPawnReplicationInfo;
		UDKMOBAPlayerReplicationInfo.PawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo;

		// Update the hero color
		HeroPawn.NotifyPlayerColorChanged();

		// Give all the spells associated with the hero
		if (UDKMOBAPlayerReplicationInfo.HeroArchetype.SpellArchetypes.Length > 0 && UDKMOBAHeroPawnReplicationInfo.Spells.Length != UDKMOBAPlayerReplicationInfo.HeroArchetype.SpellArchetypes.Length)
		{
			// Iterate through the spell archetypes
			for (i = 0; i < UDKMOBAPlayerReplicationInfo.HeroArchetype.SpellArchetypes.Length; ++i)
			{
				if (UDKMOBAPlayerReplicationInfo.HeroArchetype.SpellArchetypes[i] != None)
				{
					// Spawn the spell archetype
					Spell = Spawn(UDKMOBAPlayerReplicationInfo.HeroArchetype.SpellArchetypes[i].Class, Self,,,, UDKMOBAPlayerReplicationInfo.HeroArchetype.SpellArchetypes[i]);
					if (Spell != None)
					{
						// Set the spells owner replication info and spell index for replication to the client owner
						Spell.OwnerReplicationInfo = UDKMOBAHeroPawnReplicationInfo;
						Spell.OrderIndex = UDKMOBAHeroPawnReplicationInfo.Spells.Length;
						Spell.Initialize();
						Spell.ClientSetOwner(Self);
						// Add the spell to the spells array
						UDKMOBAHeroPawnReplicationInfo.Spells.AddItem(Spell);
					}
				}
			}
		}
	}

	// Restart the player controller
	Restart(bVehicleTransition);
}

/** 
 * Called upon possessing a new pawn, perform any specific cleanup/initialization here.
 *
 * @param		bVehicleTransition		True if this is a vehicle transition
 * @network		Server
 */
function Restart(bool bVehicleTransition)
{
	local UDKMOBACamera UDKMOBACamera;

	if (HeroPawn != None)
	{
		HeroPawn.Restart();
	}

	if (!bVehicleTransition)
	{
		Enemy = None;
		if (HeroPawn != None && HeroPawn.InvManager != None)
		{
			HeroPawn.InvManager.UpdateController();
		}
	}

	// Auto focus on newly possessed pawns
	if (class'UDKMOBAGameInfo'.static.GetPlatform() == P_PC)
	{
		UDKMOBACamera = UDKMOBACamera(PlayerCamera);
		if (UDKMOBACamera != None)
		{
			UDKMOBACamera.SetDesiredCameraLocation(HeroPawn.Location);
		}
	}

	ServerTimeStamp = 0.f;
	ResetTimeMargin();
	EnterStartState();
	ClientRestart(HeroPawn);
	SetViewTarget(HeroPawn);
	ResetCameraMode();
}

/**
 * Called when the player controller should enter the start state. Usually called by PlayerController::Restart or PlayerController::ClientRestart.
 *
 * @network		Server
 */
function EnterStartState()
{
	if (IsInState('PlayerCommanding'))
	{
		BeginState('PlayerCommanding');
	}
	else
	{
		GotoState('PlayerCommanding');
	}
}

/**
 * Handle pending left click commands
 *
 * @param		HUD					HUD reference in case any functions or variables are required. Canvas is also valid
 * @param		ScreenLocation		Screen location to convert to a world location
 * @network							Local client
 */
function HandlePendingLeftClickCommand(HUD HUD, Vector2D ScreenLocation);

/**
 * Handle pending right click commands
 *
 * @param		HUD					HUD reference in case any functions or variables are required. Canvas is also valid
 * @param		ScreenLocation		Screen location to convert to a world location
 * @network							Local client
 */
function HandlePendingRightClickCommand(HUD HUD, Vector2D ScreenLocation)
{
	local Vector WorldOrigin, WorldDirection, HitLocation, HitNormal;
	local Actor Actor;
	local UDKMOBATouchInterface UDKMOBATouchInterface, BestUDKMOBATouchInterface;
	local UDKMOBACommandInterface UDKMOBACommandInterface;
	local array<UDKMOBATouchInterface> UDKMOBATouchInterfaces;
	local int i, HighestTouchPriority, CurrentTouchPriority;
	local bool DeferredMove;
	local array<Vector> ValidPositions;
	local UDKMOBAHUD UDKMOBAHUD;

	// Abort if the HUD is invalid
	if (HUD == None || HUD.Canvas == None)
	{
		return;
	}

	UDKMOBAHUD = UDKMOBAHUD(HUD);
	if (UDKMOBAHUD == None)
	{
		return;
	}

	// Check if player right clicked on anything important, and add them into the UDKMOBATouchInterfaces array to find which has the highest priority
	for (i = 0; i < UDKMOBAHUD.TouchInterfaces.Length; ++i)
	{
		if (UDKMOBAHUD.TouchInterfaces[i] != None)
		{
			// Skip over player's own pawn
			if (UDKMOBAHUD.TouchInterfaces[i].GetActor() == Pawn || UDKMOBAHUD.TouchInterfaces[i].GetActor() == HeroPawn)
			{
				continue;
			}

			// Cast to the touch interface, and add it the touch interfaces if point is within the touch bounding box
			UDKMOBATouchInterface = UDKMOBATouchInterface(UDKMOBAHUD.TouchInterfaces[i].GetActor());
			UDKMOBACommandInterface = UDKMOBACommandInterface(UDKMOBAHUD.TouchInterfaces[i].GetActor());
			if (UDKMOBATouchInterface != None && UDKMOBACommandInterface != None && UDKMOBATouchInterface.IsPointInTouchBoundingBox(ScreenLocation))
			{
				UDKMOBATouchInterfaces.AddItem(UDKMOBAHUD.TouchInterfaces[i]);
			}
		}
	}

	if (UDKMOBATouchInterfaces.Length > 0)
	{
		// Only a single touch interface was touched, so respond to that
		if (UDKMOBATouchInterfaces.Length == 1)
		{
			BestUDKMOBATouchInterface = UDKMOBATouchInterfaces[0];
		}
		// More than one touch interface was touched, so find the one with the highest priority
		else
		{
			BestUDKMOBATouchInterface = None;
			
			// Find the highest priority touch interface
			for (i = 0; i < UDKMOBATouchInterfaces.Length; ++i)
			{
				if (UDKMOBATouchInterfaces[i] != None)
				{
					// Get the touch priority
					CurrentTouchPriority = UDKMOBATouchInterfaces[i].GetTouchPriority();

					// If there is no best touch interface, or the current touch priority is greater than the highest touch priority
					if (BestUDKMOBATouchInterface == None || CurrentTouchPriority > HighestTouchPriority)
					{
						BestUDKMOBATouchInterface = UDKMOBATouchInterfaces[i];
						HighestTouchPriority = CurrentTouchPriority;
					}
				}
			}
		}

		// Perform an action of the best UDKMOBA Touch Interface
		if (BestUDKMOBATouchInterface != None)
		{			
			// Figure out what commands can be done
			UDKMOBACommandInterface = UDKMOBACommandInterface(BestUDKMOBATouchInterface);
			if (UDKMOBACommandInterface != None)
			{
				if (UDKMOBACommandInterface.CanBeFollowed(PlayerReplicationInfo))
				{
					StartFollowCommand(BestUDKMOBATouchInterface.GetActor());
				}
				else if (UDKMOBACommandInterface.CanBeAttacked(PlayerReplicationInfo))
				{
					StartAttackCommand(BestUDKMOBATouchInterface.GetActor());
				}
			}

			return;
		}
	}

	// Touched nothing else, handle a move command in that case
	// Get the deprojection coordinates from the screen location
	HUD.Canvas.Deproject(ScreenLocation, WorldOrigin, WorldDirection);

	// Perform a trace to find either UDKMOBAGroundBlockingVolume or the WorldInfo [BSP] 
	ForEach TraceActors(class'Actor', Actor, HitLocation, HitNormal, WorldOrigin + WorldDirection * 16384.f, WorldOrigin)
	{
		if (UDKMOBAGroundBlockingVolume(Actor) != None || WorldInfo(Actor) != None)
		{
			DeferredMove = false;

			// Check if this hit location is within a blocking volume
			for (i = 0; i < BlockingVolumes.Length; ++i)
			{
				if (BlockingVolumes[i].EncompassesPoint(HitLocation) && NavigationHandle != None)
				{
					DeferredMove = true;
					break;
				}
			}

			// Attempt to find a valid position for the move
			if (!DeferredMove)
			{
				NavigationHandle.GetValidPositionsForBox(HitLocation, 512.f, HeroPawn.GetCollisionExtent(), false, ValidPositions, 1);
				if (ValidPositions.Length > 0)
				{
					for (i = 0; i < ValidPositions.Length; ++i)
					{
						// Move to the valid position
						StartMoveCommand(ValidPositions[i]);
						break;
					}
				}
				
				break;
			}
		}
	}
}

/**
 * Player wants to send his / her hero somewhere in the world
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server and local client
 */
simulated function StartMoveCommand(Vector WorldMoveLocation);

/**
 * Player wants to send his / her hero somewhere in the world
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server
 */
reliable server function ServerMoveCommand(Vector WorldMoveLocation);

/**
 * Player wants to send his / her hero somewhere in the world
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server and local client
 */
simulated function BeginMoveCommand(Vector WorldMoveLocation);

/**
 * Player wants to send his / her hero to attack something
 *
 * @param		ActorToAttack			Actor to attack
 * @network								Server and local client
 */
simulated function StartAttackCommand(Actor ActorToAttack);

/**
 * Player wants to send his / her hero to attack something
 *
 * @param		ActorToAttack			Actor to attack
 * @network								Server
 */
reliable server function ServerAttackCommand(Actor ActorToAttack);

/**
 * Player wants to send his / her hero to attack something
 *
 * @param		ActorToAttack			Actor to attack
 * @network								Server and local client
 */
simulated function BeginAttackCommand(Actor ActorToAttack);

/**
 * Player wants his / her hero to follow something
 *
 * @param		ActorToFollow			Actor to follow
 * @network								Server and local client
 */
simulated function StartFollowCommand(Actor ActorToFollow);

/**
 * Player wants his / her hero to follow something
 *
 * @param		ActorToFollow			Actor to follow
 * @network								Server
 */
reliable server function ServerFollowCommand(Actor ActorToFollow);

/**
 * Player wants his / her hero to follow something
 *
 * @param		ActorToFollow			Actor to follow
 * @network								Server and local client
 */
simulated function BeginFollowCommand(Actor ActorToFollow);

/**
 * Player wants his / her hero to cast something here
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server and local client
 */
simulated function StartCastSpellCommand(Vector WorldLocation);

/**
 * Player wants his / her hero to cast something here
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server
 */
reliable server function ServerCastSpellCommand(Vector WorldLocation);

/**
 * Player wants his / her hero to cast something here
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server and local client
 */
simulated function BeginCastSpellCommand(Vector WorldLocation);

/**
 * Player receives notification about money received from the world
 *
 * @param		Amount				Amount of money received
 * @param		WorldLocation		Where in the world money was received
 * @network							Local client
 */
reliable client function ClientReceivedMoney(int Amount, Vector WorldLocation)
{
	// Once received on the client, then just forward it to ReceivedMoney
	ReceivedMoney(Amount, WorldLocation);
}

/**
 * Player receives notification about money received from the world
 *
 * @param		Amount				Amount of money received
 * @param		WorldLocation		Where in the world money was received
 * @network							Server and local client
 */
simulated function ReceivedMoney(int Amount, Vector WorldLocation)
{
	local UDKMOBAHUD UDKMOBAHUD;

	UDKMOBAHUD = UDKMOBAHUD(MyHUD);
	if (UDKMOBAHUD != None)
	{
		UDKMOBAHUD.ReceivedMoney(Amount, WorldLocation);
	}
}

/**
 * Called when the controller's pawn has reached its destination
 *
 * @network		Server and local client
 */
function NotifyReachedDestination()
{
	// Sync with the client
	if (Role == Role_Authority)
	{
		ClientNotifyReachedDestination();
	}
	
	// Handle effects when reaching the destination
	HandleReachedDestination();
}

/**
 * Called when the controller's pawn has reached is destination on the server
 *
 * @network		Local client
 */
unreliable client function ClientNotifyReachedDestination()
{
	// Only call this on the client
	if (Role < Role_Authority)
	{
		// Handle effects when reaching the destination
		HandleReachedDestination();
	}
}

/**
 * Handle effects when the controller's pawn has reached its destination
 *
 * @network		Local client
 */
simulated function HandleReachedDestination()
{
	// Early out if this is on the dedicated server
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	// Deactivate the confirmation particle system
	if (ConfirmationEmitter != None && ConfirmationEmitter.ParticleSystemComponent != None)
	{
		ConfirmationEmitter.ParticleSystemComponent.DeactivateSystem();
	}
}

/**
 * Stubbed out as functionality is not required
 *
 * @network		Local client
 */
exec function PrevWeapon();

/**
 * Stubbed out as functionality is not required
 *
 * @network		Local client
 */
exec function NextWeapon();

/**
 * Purchases an item
 *
 * @param		ItemArchetype		Archetype of the item you want to purchase
 * @network							All
 */
simulated function PurchaseItem(UDKMOBAItem ItemArchetype)
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	if (!CanPurchaseItem(ItemArchetype))
	{
		return;
	}

	// Sync with the server
	if (Role < Role_Authority)
	{
		ServerPurchaseItem(ItemArchetype);
	}
	// Otherwise just purchase the item
	else
	{
		UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
		if (UDKMOBAPawnReplicationInfo != None)
		{
			UDKMOBAPawnReplicationInfo.PurchaseItem(ItemArchetype);
		}
	}
}

/**
 * Purchases an item
 *
 * @param		ItemArchetype		Archetype of the item you want to purchase
 * @network							Server
 */
reliable server function ServerPurchaseItem(UDKMOBAItem ItemArchetype)
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;

	if (!CanPurchaseItem(ItemArchetype))
	{
		return;
	}

	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None)
	{
		UDKMOBAPawnReplicationInfo.PurchaseItem(ItemArchetype);
	}
}

/**
 * Returns true if an item can be purchased
 *
 * @param		ItemArchetype		Archetype of the item to check
 * @return							Returns true if the item can be purchased or not
 * @network							All
 */
simulated function bool CanPurchaseItem(UDKMOBAItem ItemArchetype)
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local UDKMOBAHUD UDKMOBAHUD;
	local string S;

	if (HeroPawn == None)
	{
		return false;
	}

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo == None)
	{
		return false;
	}

	if (UDKMOBAPlayerReplicationInfo.Money < ItemArchetype.BuyCost)
	{
		UDKMOBAHUD = UDKMOBAHUD(MyHUD);
		if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
		{
			S = Localize("HUD", "NotEnoughGold", "UDKMOBA");
			S = Repl(S, "%s", ParseLocalizedPropertyPath(ItemArchetype.ItemName));
			S = Repl(S, "%i", ItemArchetype.BuyCost - UDKMOBAPlayerReplicationInfo.Money);

			UDKMOBAHUD.HUDMovie.AddCenteredMessage(S);
		}

		return false;
	}

	return true;
}

/**
 * Broadcasts a line draw to players of the same team
 *
 * @param		X1		X1 screen space position of the line
 * @param		Y1		Y1 screen space position of the line
 * @param		X2		X2 screen space position of the line
 * @param		Y2		Y2 screen space position of the line
 * @network				Server
 */
unreliable server function ServerBroadcastLineDraw(float X1, float Y1, float X2, float Y2)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None)
	{
		foreach WorldInfo.AllControllers(class'UDKMOBAPlayerController', UDKMOBAPlayerController)
		{
			if (UDKMOBAPlayerController == Self)
			{
				continue;
			}

			UDKMOBAPlayerController.ClientReceiveLineDraw(X1, Y1, X2, Y2, UDKMOBAPlayerReplicationInfo);
		}
	}
}

/**
 * Recieve a line from the server to draw on the mini map
 *
 * @param		X1									X1 screen space position of the line
 * @param		Y1									Y1 screen space position of the line
 * @param		X2									X2 screen space position of the line
 * @param		Y2									Y2 screen space position of the line
 * @param		UDKMOBAPlayerReplicationInfo		Player who sent this line
 * @network											Client
 */
unreliable client function ClientReceiveLineDraw(float X1, float Y1, float X2, float Y2, UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo)
{
	local UDKMOBAHUD UDKMOBAHUD;
	local int ColorIndex;

	UDKMOBAHUD = UDKMOBAHUD(MyHUD);
	if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None && UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC != None)
	{
		ColorIndex = class'UDKMOBAGameInfo'.default.Properties.PlayerColors.Find('ColorName', UDKMOBAPlayerReplicationInfo.PlayerColor);
		if (ColorIndex != INDEX_NONE)
		{
			UDKMOBAHUD.HUDMovie.MinimapLineDrawingMC.DrawLine(X1, Y1, X2, Y2, class'UDKMOBAGameInfo'.default.Properties.PlayerColors[ColorIndex].StoredColor.R, class'UDKMOBAGameInfo'.default.Properties.PlayerColors[ColorIndex].StoredColor.G, class'UDKMOBAGameInfo'.default.Properties.PlayerColors[ColorIndex].StoredColor.B, 255);
		}
	}
}

/**
 * Broadcasts a ping out to players of the same team
 *
 * @param		X		X screen space position of the ping 
 * @param		Y		Y screen space position of the ping
 * @network				Server
 */
unreliable server function ServerBroadcastPing(float X, float Y)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None)
	{
		foreach WorldInfo.AllControllers(class'UDKMOBAPlayerController', UDKMOBAPlayerController)
		{
			if (UDKMOBAPlayerController == Self)
			{
				continue;
			}

			if (UDKMOBAPlayerController.GetTeamNum() == GetTeamNum())
			{
				UDKMOBAPlayerController.ClientReceivePing(X, Y, UDKMOBAPlayerReplicationInfo);
			}
		}
	}
}

/**
 * Receives a ping from a player
 *
 * @param		X									X screen space position of the ping
 * @param		Y									Y screen space position of the ping
 * @param		UDKMOBAPlayerReplicationInfo		Player who sent the ping
 * @network											Local client
 */
unreliable client function ClientReceivePing(float X, float Y, UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo)
{
	local UDKMOBAHUD UDKMOBAHUD;

	UDKMOBAHUD = UDKMOBAHUD(MyHUD);
	if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
	{
		UDKMOBAHUD.HUDMovie.PerformPingUsingScreenSpaceCoordinates(X, Y, UDKMOBAPlayerReplicationInfo);
	}
}

/**
 * Called when the user has indicated they want to level up by increasing their stats
 *
 * @network		Server and client
 */
simulated function LevelUpStats()
{
	if (HeroPawn != None)
	{
		// Sync with the server
		if (Role < Role_Authority)
		{
			ServerLevelUpStats();
		}

		DoLevelUpStats();
	}
}

/**
 * Server-side call for LevelUpStats()
 *
 * @network		Server
 */
reliable server function ServerLevelUpStats()
{
	if (HeroPawn != None)
	{
		DoLevelUpStats();
	}
}

/**
 * Call that actually updates the hero's stats
 *
 * @network		Client, Server
 */
simulated function DoLevelUpStats()
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	if (HeroPawn != None)
	{
		UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
		if (UDKMOBAHeroPawnReplicationInfo != None && UDKMOBAHeroPawnReplicationInfo.AppliedLevel < UDKMOBAHeroPawnReplicationInfo.Level && HeroPawn.StatsModifier != None)
		{
			HeroPawn.StatsModifier.AddStatChange(STATNAME_Strength, HeroPawn.LevelStrength, MODTYPE_Addition, 0.f, true);
			HeroPawn.StatsModifier.AddStatChange(STATNAME_Agility, HeroPawn.LevelAgility, MODTYPE_Addition, 0.f, true);
			HeroPawn.StatsModifier.AddStatChange(STATNAME_Intelligence, HeroPawn.LevelIntelligence, MODTYPE_Addition, 0.f, true);

			switch (HeroPawn.MainStat)
			{
			case STAT_Strength:
				HeroPawn.StatsModifier.AddStatChange(STATNAME_Damage, HeroPawn.LevelStrength, MODTYPE_Addition, 0.f, true);
				break;

			case STAT_Agility:
				HeroPawn.StatsModifier.AddStatChange(STATNAME_Damage, HeroPawn.LevelAgility, MODTYPE_Addition, 0.f, true);
				break;

			case STAT_Intelligence:
				HeroPawn.StatsModifier.AddStatChange(STATNAME_Damage, HeroPawn.LevelIntelligence, MODTYPE_Addition, 0.f, true);
				break;
			}

			UDKMOBAHeroPawnReplicationInfo.ApplyLevel();
		}
	}
}

/**
 * Called when the user has indicated they want to level up one of their spells
 *
 * @param		SpellIndex		Spell index to level up
 * @network						Client
 */
simulated function LevelUpSpell(int SpellIndex)
{
	if (HeroPawn != None)
	{
		if (!CanLevelUpSpell(SpellIndex))
		{
			return;
		}

		// Sync with the server
		if (Role < Role_Authority)
		{
			ServerLevelUpSpell(SpellIndex);
		}

		// Perform level up spell
		PerformLevelUpSpell(SpellIndex);
	}
}

/**
 * Server-side call that actually updates the given hero spell
 *
 * @param		SpellIndex		Spell index to level up
 * @network						Server
 */
reliable server function ServerLevelUpSpell(int SpellIndex)
{
	if (HeroPawn != None)
	{
		if (!CanLevelUpSpell(SpellIndex))
		{
			return;
		}

		// Perform level up spell
		PerformLevelUpSpell(SpellIndex);
	}
}

/**
 * Called when the user has indicated they want to level up one of their spells
 *
 * @param		SpellIndex		Spell index to level up
 * @network						Server and client 
 */
simulated function PerformLevelUpSpell(int SpellIndex)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	if (HeroPawn != None)
	{
		UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
		if (UDKMOBAHeroPawnReplicationInfo != None && UDKMOBAHeroPawnReplicationInfo.AppliedLevel < UDKMOBAHeroPawnReplicationInfo.Level)
		{
			if (SpellIndex >= 0 && SpellIndex < UDKMOBAHeroPawnReplicationInfo.Spells.Length)
			{
				UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].Level++;
			}

			UDKMOBAHeroPawnReplicationInfo.ApplyLevel();
		}
	}
}

/**
 * Returns true if a spell can be leveled up or not.
 *
 * @param		SpellIndex		Index of the spell that the player wants to level up.
 */
simulated function bool CanLevelUpSpell(int SpellIndex)
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAHUD UDKMOBAHUD;
	
	if (HeroPawn == None)
	{
		return false;
	}

	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(HeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None)
	{
		return false;
	}

	// Check if the spell index is valid
	if (SpellIndex < 0 || SpellIndex >= UDKMOBAHeroPawnReplicationInfo.Spells.Length)
	{
		return false;
	}
	
	// Check if the spell can be upgraded or not
	if (UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex] == None || UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].Level + 1 >= UDKMOBAHeroPawnReplicationInfo.Spells[SpellIndex].MaxLevel)
	{
		if (UDKMOBAHeroPawnReplicationInfo.PlayerReplicationInfo != None)
		{
			foreach WorldInfo.AllControllers(class'UDKMOBAPlayerController', UDKMOBAPlayerController)
			{
				if (UDKMOBAPlayerController.PlayerReplicationInfo == UDKMOBAHeroPawnReplicationInfo.PlayerReplicationInfo)
				{
					UDKMOBAHUD = UDKMOBAHUD(UDKMOBAPlayerController.MyHUD);
					if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
					{
						UDKMOBAHUD.HUDMovie.AddCenteredMessage(Localize("HUD", "SpellIsMaxLevel", "UDKMOBA"));
					}

					break;
				}
			}
		}

		return false;
	}

	return true;
}

/**
 * This state handles when the player is aiming a spell
 *
 * @network		Server and local client
 */
state PlayerAimingSpell
{
}

/**
 * This state handles when the player commanding the hero pawn
 *
 * @network		Server and local client
 */
state PlayerCommanding
{
	/**
	 * Player wants to send his / her hero somewhere in the world
	 *
	 * @param		WorldMoveLocation		World location to send the hero to
	 * @network								Server and local client
	 */
	simulated function StartMoveCommand(Vector WorldMoveLocation)
	{
		// Sync with the server if on the client
		if (Role < Role_Authority)
		{
			ServerMoveCommand(WorldMoveLocation);
		}

		BeginMoveCommand(WorldMoveLocation);
	}

	/**
	 * Player wants to send his / her hero somewhere in the world
	 *
	 * @param		WorldMoveLocation		World location to send the hero to
	 * @network								Server
	 */
	reliable server function ServerMoveCommand(Vector WorldMoveLocation)
	{
		// Ensure this only runs on the server
		if (Role == Role_Authority)
		{
			BeginMoveCommand(WorldMoveLocation);
		}
	}

	/**
	 * Player wants to send his / her hero somewhere in the world
	 *
	 * @param		WorldMoveLocation		World location to send the hero to
	 * @network								Server and local client
	 */
	simulated function BeginMoveCommand(Vector WorldMoveLocation)
	{
		local Actor HitActor;
		local Vector HitLocation, HitNormal, SurfaceNormal;

		// Send it to the hero pawn
		if (HeroPawn != None)
		{
			HeroPawn.StartMoveCommand(WorldMoveLocation);

			// Move and play the confirmation particle system		
			if (WorldInfo.NetMode != NM_DedicatedServer && ConfirmationEmitter != None)
			{
				// Attempt to find the surface normal
				SurfaceNormal = Vect(0.f, 0.f, 0.f);
				ForEach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, PlayerCamera.CameraCache.POV.Location + Normal(WorldMoveLocation - PlayerCamera.CameraCache.POV.Location) * 16384.f, PlayerCamera.CameraCache.POV.Location)
				{
					if (UDKMOBAGroundBlockingVolume(HitActor) != None || WorldInfo(HitActor) != None)
					{
						SurfaceNormal = HitNormal;
						break;
					}
				}

				// Set the particle's template
				if (ConfirmationEmitter.ParticleSystemComponent.Template != Properties.MoveConfirmationParticleTemplate)
				{
					ConfirmationEmitter.SetTemplate(Properties.MoveConfirmationParticleTemplate);
				}
				// Move the particle to the correct location
				ConfirmationEmitter.SetLocation(WorldMoveLocation);
				ConfirmationEmitter.SetBase(None);
				// Rotate the particle to the surface normal
				ConfirmationEmitter.SetRotation(Rotator(SurfaceNormal));
				// Activate the particle system component
				ConfirmationEmitter.ParticleSystemComponent.ActivateSystem();
			}
		}
	}

	/**
	 * Player wants to send his / her hero to attack something
	 *
	 * @param		ActorToAttack			Actor to attack
	 * @network								Server and local client
	 */
	simulated function StartAttackCommand(Actor ActorToAttack)
	{
		local UDKMOBAAttackInterface UDKMOBAAttackInterface;
		local UDKMOBAHUD UDKMOBAHUD;

		// Check for invulnerability
		UDKMOBAAttackInterface = UDKMOBAAttackInterface(ActorToAttack);
		if (UDKMOBAAttackInterface != None && UDKMOBAAttackInterface.IsInvulnerable())
		{
			UDKMOBAHUD = UDKMOBAHUD(MyHUD);
			if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
			{
				if (UDKMOBAHUD.HUDProperties != None)
				{
					PlaySound(UDKMOBAHUD.HUDProperties.CommandDenied, true);
				}

				UDKMOBAHUD.HUDMovie.AddCenteredMessage(Localize("HUD", "CannotAttackInvulnerableTarget", "UDKMOBA"));
			}

			return;
		}

		// Sync with the server if on the client
		if (Role < Role_Authority)
		{
			ServerAttackCommand(ActorToAttack);
		}

		BeginAttackCommand(ActorToAttack);
	}

	/**
	 * Player wants to send his / her hero to attack something
	 *
	 * @param		ActorToAttack			Actor to attack
	 * @network								Server
	 */
	reliable server function ServerAttackCommand(Actor ActorToAttack)
	{
		// Ensure this only runs on the server
		if (Role == Role_Authority)
		{
			BeginAttackCommand(ActorToAttack);
		}
	}

	/**
	 * Player wants to send his / her hero to attack something
	 *
	 * @param		ActorToAttack			Actor to attack
	 * @network								Server and local client
	 */
	simulated function BeginAttackCommand(Actor ActorToAttack)
	{
		local UDKMOBAAttackInterface UDKMOBAAttackInterface;

		// Check for invulnerability
		UDKMOBAAttackInterface = UDKMOBAAttackInterface(ActorToAttack);
		if (UDKMOBAAttackInterface != None && UDKMOBAAttackInterface.IsInvulnerable())
		{
			return;
		}

		// Send it to the hero pawn
		if (HeroPawn != None)
		{
			HeroPawn.StartAttackCommand(ActorToAttack);
		}

		if (WorldInfo.NetMode != NM_DedicatedServer && ConfirmationEmitter != None)
		{
			// Set the particle's template
			if (ConfirmationEmitter.ParticleSystemComponent.Template != Properties.AttackConfirmationParticleTemplate)
			{
				ConfirmationEmitter.SetTemplate(Properties.AttackConfirmationParticleTemplate);
			}
			// Move the particle to the correct location
			ConfirmationEmitter.SetLocation(ActorToAttack.Location);
			ConfirmationEmitter.SetBase(ActorToAttack);
			// Rotate the particle to the surface normal
			ConfirmationEmitter.SetRotation(Rot(32768, 0, 0));
			// Activate the particle system component
			ConfirmationEmitter.ParticleSystemComponent.ActivateSystem();
		}
	}

	/**
	 * Player wants his / her hero to follow something
	 *
	 * @param		ActorToFollow			Actor to follow
	 * @network								Server and local client
	 */
	simulated function StartFollowCommand(Actor ActorToFollow)
	{
		// Sync with the server if on the client
		if (Role < Role_Authority)
		{
			ServerFollowCommand(ActorToFollow);
		}

		BeginFollowCommand(ActorToFollow);
	}

	/**
	 * Player wants his / her hero to follow something
	 *
	 * @param		ActorToFollow			Actor to follow
	 * @network								Local client
	 */
	reliable server function ServerFollowCommand(Actor ActorToFollow)
	{
		// Ensure this only runs on the server
		if (Role == Role_Authority)
		{
			BeginFollowCommand(ActorToFollow);
		}
	}

	/**
	 * Player wants his / her hero to follow something
	 *
	 * @param		ActorToFollow			Actor to follow
	 * @network								Server and local client
	 */
	simulated function BeginFollowCommand(Actor ActorToFollow)
	{
		// Send it to the hero pawn
		if (HeroPawn != None)
		{
			HeroPawn.StartFollowCommand(ActorToFollow);
		}

		// Set the particle's template
		if (WorldInfo.NetMode != NM_DedicatedServer && ConfirmationEmitter != None)
		{
			if (ConfirmationEmitter.ParticleSystemComponent.Template != Properties.MoveConfirmationParticleTemplate)
			{
				ConfirmationEmitter.SetTemplate(Properties.MoveConfirmationParticleTemplate);
			}
			// Move the particle to the correct location
			ConfirmationEmitter.SetLocation(ActorToFollow.Location);
			ConfirmationEmitter.SetBase(ActorToFollow);
			// Set the rotation
			ConfirmationEmitter.SetRotation(Rot(16384, 0, 0));
			// Activate the particle system component
			ConfirmationEmitter.ParticleSystemComponent.ActivateSystem();
		}
	}
}

/**
 * Keep hero rep info in sync team-wise with this rep info
 *
 * @network		Server and local client
 */
exec function SwitchTeam()
{
	local Actor A;

	Super.SwitchTeam();

	if (HeroPawn != None)
	{
		HeroPawn.PlayerReplicationInfo.Team = PlayerReplicationInfo.Team;
	}

	ForEach AllActors(class'Actor', A)
	{
		A.NotifyLocalPlayerTeamReceived();
	}
}

/**
 * The player wants to fire.
 *
 * @param		FireModeNum		Which fire mode to trigger, 0 usually indicates left mouse button
 * @network						Server and local client
 */
exec function StartFire(optional byte FireModeNum);

/**
 * This state handles when the player is waiting for the game to start
 *
 * @network		Server and local client
 */
auto state PlayerWaiting
{
	/**
	 * Called when the player wants to be restarted. Stubbed to override, as base functionality is not needed.
	 *
	 * @network		Server
	 */
	reliable server function ServerRestartPlayer();

	/**
	 * Console command which allows the player to fire his/her weapon. Stubbed to override, as base functionality is not needed.
	 *
	 * @param		FireModeNum			Which fire mode of the gun to fire
	 * @network							Server and local client
	 */
	exec function StartFire(optional byte FireModeNum);
}

// Default properties block
defaultproperties
{
`if(`notdefined(FINAL_RELEASE))
	CathodeHeroArchetype=UDKMOBAHeroPawn_Cathode'UDKMOBA_Game_Resources.Heroes.Cathode'
	DemoGuyHeroArchetype=UDKMOBAHeroPawn_DemoGuy'UDKMOBA_Game_Resources.Heroes.DemoGuy'
`endif
	CameraClass=class'UDKMOBACamera'
	CheatClass=class'UDKMOBACheatManager'
	bHidden=false
}