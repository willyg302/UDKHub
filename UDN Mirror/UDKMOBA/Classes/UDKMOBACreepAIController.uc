//=============================================================================
// UDKMOBACreepAIController
//
// AI which is used to control creep pawns. They extend from 
// UDKMOBAAIController to add functionality to determine the behavior for
// creeps.
//
// * Creeps will follow a route.
// * Creeps will attack enemies if they are within range, but as soon as the
//   enemy is out of sight they will go back to the route (kiting).
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACreepAIController extends UDKMOBAAIController;

// Cached reference to the creep pawn, so that type casting to it is not necessary all the time
var UDKMOBACreepPawn CreepPawn;
// Current route index
var int RouteIndex;
// Sight detection trigger
var UDKMOBATrigger SightDetectionTrigger;
// Visible attack interfaces in front of me
var array<UDKMOBAAttackInterface> VisibleAttackInterfaces;

/**
 * Overriding to ensure non-players get a PRI
 *
 * @network		Server
 */
event PostBeginPlay()
{
	Super(Actor).PostBeginPlay();

	if (!bDeleteMe && WorldInfo.NetMode != NM_Client)
	{
		// create a new player replication info
		InitPlayerReplicationInfo();
		InitNavigationHandle();
	}

	// randomly offset the sight counter to avoid hitches
	SightCounter = SightCounterInterval * FRand();
}

/**
 * Overriding to give us the PawnRepInfo, rather than the PlayerRepInfo
 *
 * @network		Server
 */
function InitPlayerReplicationInfo()
{
	PlayerReplicationInfo = Spawn(class'UDKMOBACreepReplicationInfo', Self);
}

`if(`notdefined(FINAL_RELEASE))
/**
 * List important Actor variables on canvas. HUD will call DisplayDebug() on the current ViewTarget when the ShowDebug exec is used
 *
 * @param		HUD			HUD with canvas to draw on
 * @param		out_YL		Height of the current font
 * @param		out_YPos	Y position on Canvas. out_YPos += out_YL, gives position to draw text for next debug line
 * @network					Server
 */
simulated function DisplayDebug(HUD HUD, out float out_YL, out float out_YPos)
{
	local Vector ScreenLocation;
	local string Text;
	local float XL, YL;

	if (HUD == None || CreepPawn == None)
	{
		return;
	}

	// Print out what state and the state label that the creep is in
	HUD.Canvas.Font = class'Engine'.static.GetTinyFont();
	HUD.Canvas.SetDrawColor(255, 0, 255, 255);
	ScreenLocation = HUD.Canvas.Project(CreepPawn.Location + Vect(0.f, 0.f, 0.f) * CreepPawn.GetCollisionHeight());
	Text = GetStateName()$"::"$Debug_StateLabel;
	HUD.Canvas.TextSize(Text, XL, YL);
	HUD.Canvas.SetPos(ScreenLocation.X - (XL * 0.5f), ScreenLocation.Y);
	HUD.Canvas.DrawText(Text);

	// Draw the 3D line which represents where they want to go
	HUD.Draw3DLine(CreepPawn.Location, GetDestinationPosition(), MakeColor(255, 0, 0)); 
}
`endif

/**
 * Called when the trigger used for sight has been touched
 *
 * @param		Caller			Trigger that called this function
 * @param		Other			Actor that touched the trigger
 * @param		OtherComp		Other's primitive component that touched the trigger
 * @param		HitLocation		Where in the world the touch occurred
 * @param		HitNormal		Surface normal of the touch that occurred
 * @network						Server
 */                
simulated function InternalOnSightTriggerTouch(Actor Caller, Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local UDKMOBAAttackInterface UDKMOBAAttackInterface;

	// Ensure the caller matches the sight detection trigger
	if (Caller == SightDetectionTrigger)
	{		
		// Don't include ourselves
		if (Other == CreepPawn)
		{
			return;
		}
		
		// Ensure other is UDKMOBAAttackInterface
		//  * Is valid for attacking
		//  * On a different team
		//  * Is not currently in my visible attack interfaces
		UDKMOBAAttackInterface = UDKMOBAAttackInterface(Other);
		if (UDKMOBAAttackInterface != None && UDKMOBAAttackInterface.IsValidToAttack() && CreepPawn.GetTeamNum() != UDKMOBAAttackInterface.GetTeamNum() && VisibleAttackInterfaces.Find(UDKMOBAAttackInterface) == INDEX_NONE)
		{
			// Add this attack interface to the attack interfaces array
			VisibleAttackInterfaces.AddItem(UDKMOBAAttackInterface);
		}
	}
}

/**
 * Called when the trigger used for sight has been untouched
 *
 * @param		Caller			Trigger that called this function
 * @param		Other			Actor that touched the trigger
 * @network						Server
 */
simulated function InternalOnSightTriggerUnTouch(Actor Caller, Actor Other)
{
	local UDKMOBAAttackInterface UDKMOBAAttackInterface;

	// Ensure the caller matches the sight detection trigger
	if (Caller == SightDetectionTrigger)
	{
		// Remove UDKMOBAAttackInterface from the visible attack interfaces array
		UDKMOBAAttackInterface = UDKMOBAAttackInterface(Other);
		if (UDKMOBAAttackInterface != None)
		{
			VisibleAttackInterfaces.RemoveItem(UDKMOBAAttackInterface);
		}
	}
}

/**
 * Called when this Actor is scheduled to be removed from the game
 *
 * network		Server
 */
simulated function Destroyed()
{
	Super.Destroyed();

	// Destroy the sight detection trigger
	if (SightDetectionTrigger != None)
	{
		// Unbind the delegates
		SightDetectionTrigger.OnTouch = None;
		SightDetectionTrigger.OnUnTouch = None;
		SightDetectionTrigger.Destroy();
	}
}

/**
 * Called when this creep AI controller should be initialized. Separated from PostBeginPlay() because various variables need to be set in order for this to work
 *
 * @network		Server
 */
function Initialize()
{
	// Cache the creep pawn
	CreepPawn = UDKMOBACreepPawn(Pawn);
	// Set the route at zero
	RouteIndex = 0;

	// Start the what to do logic
	WhatToDoNext();
	SetTimer(0.25f, true, NameOf(WhatToDoNext));

	// Spawn the attack detection trigger
	SightDetectionTrigger = Spawn(class'UDKMOBATrigger');
	if (SightDetectionTrigger != None)
	{
		// Attach it to the creep pawn
		SightDetectionTrigger.SetBase(CreepPawn);

		// Set the collision radius
		if (SightDetectionTrigger.CollisionCylinderComponent != None)
		{
			SightDetectionTrigger.CollisionCylinderComponent.SetCylinderSize(CreepPawn.SightRange, 64.f);
		}

		// Bind the delegates
		SightDetectionTrigger.OnTouch = InternalOnSightTriggerTouch;
		SightDetectionTrigger.OnUnTouch = InternalOnSightTriggerUnTouch;
	}
}

/**
 * Usually called via a timer. This function contains most of the core logic in what the creeps should do at any given moment
 *
 * @network		Server
 */
function WhatToDoNext()
{
	local UDKMOBAAttackInterface AttackInterface, BestAttackInterface;
	local int i, AttackPriority, HighestAttackPriority;

	// Check that the creep pawn does not equal none
	if (CreepPawn == None)
	{
		ClearTimer(NameOf(WhatToDoNext));
		return;
	}

	// ==================
	// Enemy attack logic
	// ==================
	// Check if the current enemy is still valid to attack or not. If it is not, then set Current Enemy to none
	if (CurrentEnemy != None)
	{
		AttackInterface = UDKMOBAAttackInterface(CurrentEnemy);
		if (AttackInterface != None && (!AttackInterface.IsValidToAttack() || VSizeSq(Pawn.Location - CurrentEnemy.Location) >= CreepPawn.SightRange))
		{
			ClearCurrentEnemy();
		}
	}

	// If I don't currently have an enemy, then scan for a potential enemy
	if (CurrentEnemy == None)
	{
		// If there are attack interfaces, then attack
		if (VisibleAttackInterfaces.Length > 0)
		{
			for (i = 0; i < VisibleAttackInterfaces.Length; ++i)
			{
				if (VisibleAttackInterfaces[i].IsValidToAttack())
				{
					AttackPriority = VisibleAttackInterfaces[i].GetAttackPriority(Self);
					if (BestAttackInterface == None || HighestAttackPriority < AttackPriority)
					{
						BestAttackInterface = VisibleAttackInterfaces[i];
						HighestAttackPriority = AttackPriority;
					}
				}
			}
		}

		// If there is a best attack interface then attack it
		if (BestAttackInterface != None)
		{
			SetCurrentEnemy(BestAttackInterface.GetActor(), BestAttackInterface);

			if (!IsInState('AttackingCurrentEnemy'))
			{
				GotoState('AttackingCurrentEnemy');
			}

			return;
		}			
	}
	// We have a current enemy
	else
	{
		// Go to the attacking state
		if (!IsInState('AttackingCurrentEnemy'))
		{
			GotoState('AttackingCurrentEnemy');
		}

		return;
	}

	// Just move using the route defined in the actory factory
	if (!IsInState('MovingAlongRoute'))
	{
		GotoState('MovingAlongRoute');
	}
}

/**
 * This state handles moving the creep using the route
 *
 * @network		Server
 */
state MovingAlongRoute
{
	/**
	 * Called when this state is first entered
	 *
	 * @param		PreviousStateName		Name of the previous state that this actor was in
	 * @network								Server
	 */
	function BeginState(Name PreviousStateName)
	{
		Super.BeginState(PreviousStateName);

		// Set the initial destination position
		if (CreepPawn != None && CreepPawn.Factory != None && CreepPawn.Factory.Route != None)
		{
			// Set the destination position
			SetDestinationPosition(CreepPawn.Factory.Route.RouteList[RouteIndex].Actor.Location);
			// Set the focal point
			SetFocalPoint(GetDestinationPosition() + Normal(GetDestinationPosition() - Pawn.Location) * 64.f);
		}
	}

	/**
	 * Called every time the controller should update itself
	 *
	 * @param		DeltaTime		Last time since Tick() was called
	 * @network		Server
	 */
	function Tick(float DeltaTime)
	{
		local vector CurrentDestinationPosition;

		Global.Tick(DeltaTime);

		// Adjust the destination position height to match the pawn height so that ReachedDestination succeeds
		CurrentDestinationPosition = GetDestinationPosition();
		CurrentDestinationPosition.Z = Pawn.Location.Z;
		SetDestinationPosition(CurrentDestinationPosition);
	}

	/**
	 * Called when the pawn has reached the destination defined by DestinationPosition
	 *
	 * @network		Server
	 */
	event ReachedPreciseDestination()
	{
		GotoState('MovingAlongRoute', 'HasReachedDestination');
	}

// Beginning of the state
Begin:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "Begin";
`endif
	// If the pawn is none, then go straight to the end
	if (CreepPawn == None)
	{
		Goto('End');
	}

	// If the pawn is not walking, then wait until it does 
	if (CreepPawn.Physics != PHYS_Walking)
	{
		Sleep(0.f);
		Goto('Begin');
	}

// Attempt to move directly to the destination position
MoveDirect:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "MoveDirect";
`endif
	// Check if the point is directly reachable or not
	if (CanReachDestination(GetDestinationPosition()))
	{
		// Move to the destination position
		bPreciseDestination = true;
	}

// Wait until we've reached the destination position
WaitingForReachedDestinationNotification:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "WaitingForReachedDestinationNotification";
`endif
	Sleep(0.f);
	Goto('WaitingForReachedDestinationNotification');

// We've reached the destination position, go to the next routing point
HasReachedDestination:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "HasReachedDestination";
`endif
	// Pawn has reached current destination, go to the next destination
	if (RouteIndex != CreepPawn.Factory.Route.RouteList.Length - 1)
	{
		RouteIndex++;
	}

	// Set the destination position
	SetDestinationPosition(CreepPawn.Factory.Route.RouteList[RouteIndex].Actor.Location);
	// Set the focal point
	SetFocalPoint(GetDestinationPosition() + Normal(GetDestinationPosition() - Pawn.Location) * 64.f);
	// Go back to the begin
	Sleep(0.f);
	Goto('Begin');

// Ending of the state
End:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "End";
`endif
	bPreciseDestination = false;
	GotoState('');
}

// Default properties block
defaultproperties
{
}