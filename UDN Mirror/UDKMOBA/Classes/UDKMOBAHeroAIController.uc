//=============================================================================
// UDKMOBAHeroAIController
//
// This class is a variation of the UDKMOBAAIController which has been extended
// to allow a few special abilities that players can do.
//
// * Allows players to define where pawns should move to
// * Allows players to follow another actor
// * Allows players to attack enemy actors
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAHeroAIController extends UDKMOBAAIController;

// Current leader to follow
var Actor CurrentLeader;
// Link to the controller that this hero controller is owned by
var Controller Controller;
// Cached link to the player controller that this hero controller is owned by
var UDKMOBAPlayerController UDKMOBAPlayerController;

/**
 * Send the pawn to a world location
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server
 */
function StartMoveCommand(Vector WorldMoveLocation)
{
	local Vector TempWorldMoveLocation, AdjustedMoveLocation;
	
	// Check if the pawn exists, otherwise abort
	if (Pawn == None)
	{
		return;
	}

	// Check if we need to find a spot which the pawn can move to
	TempWorldMoveLocation = WorldMoveLocation;
	if (FindSpot(Pawn.GetCollisionExtent(), TempWorldMoveLocation))
	{
		AdjustedMoveLocation = TempWorldMoveLocation;
	}
	// Otherwise, just set the final destination
	else
	{
		AdjustedMoveLocation = WorldMoveLocation;
	}

	// Set the destination position
	SetDestinationPosition(AdjustedMoveLocation);
	// Set the final destination
	FinalDestination = AdjustedMoveLocation;
	// Set the focal point
	SetFocalPoint(GetDestinationPosition() + Normal(GetDestinationPosition() - Pawn.Location) * 64.f);

	// Send to the moving to destination state
	GotoState('MovingToDestination');
}

/**
 * Send the pawn to attack an actor
 *
 * @param		ActorToAttack			Actor to attack
 * @network								Server
 */
simulated function StartAttackCommand(Actor ActorToAttack)
{
	// Check if there is a valid actor to attack and if the pawn is valid; otherwise abort
	if (ActorToAttack == None || Pawn == None)
	{
		return;
	}

	// Set the enemy
	if (!SetCurrentEnemy(ActorToAttack))
	{
		return;
	}

	// Go to the attacking state
	GotoState('AttackingCurrentEnemy');
}

/**
 * Send the pawn to follow an actor
 *
 * @param		ActorToFollow			Actor to follow
 * @network								Server
 */
simulated function StartFollowCommand(Actor ActorToFollow)
{
	// Check if there is a valid actor to follow and if the pawn is valid; otherwise abort
	if (ActorToFollow == None || Pawn == None)
	{
		return;
	}

	// Set the current leader
	CurrentLeader = ActorToFollow;

	// Set the destination position
	SetDestinationPosition(ActorToFollow.Location);

	// Always go to the following an actor state
	GotoState('FollowingAnActor');
}

/**
 * This state handles moving the pawn to the final destination
 *
 * @network		Server
 */
state MovingToDestination
{
	/**
	 * Called every time the controller is updated
	 *
	 * @param		DeltaTime		Time since the last time the controller is updated
	 * @network						Server
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
	 * Called when the controller's pawn has reached the destination defined by GetDestinationPosition()
	 *
	 * @network		Server
	 */
	event ReachedPreciseDestination()
	{
		if (VSizeSq2D(GetDestinationPosition() - FinalDestination) > 0.05f)
		{
			// Set destination position
			SetDestinationPosition(FinalDestination);
			// Go back to the beginning
			GotoState('MovingToDestination', 'Begin');
		}
		// Destination trigger is at the final destination, so finish move
		else 
		{
			// If the player's pawn has reached the final destination, the notify the player
			if (UDKMOBAPlayerController != None)
			{
				UDKMOBAPlayerController.NotifyReachedDestination();
			}

			GotoState('');
		}
	}

// State loop begin
Begin:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "Begin";
`endif
	// If the pawn is none, then go straight to the end
	if (Pawn == None)
	{
		Goto('End');
	}

	// If the pawn is not walking, then wait until it does 
	if (Pawn.Physics != PHYS_Walking)
	{
		Sleep(0.f);
		Goto('Begin');
	}

// Attempt to move directly to the destination
MoveDirect:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "MoveDirect";
`endif
	// Check if the point is directly reachable or not
	if (CanReachDestination(GetDestinationPosition()))
	{
		//Set the focal point
		SetFocalPoint(GetDestinationPosition());

		// Move to the destination position
		bPreciseDestination = true;
		Sleep(0.f);
		Goto('WaitUntilReachedDestination');
	}

// Attempt to path find to the destination
MoveViaPathFinding:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "MoveViaPathFinding";
`endif
	// Generate the path and get the next move location
	if (GeneratePathTo(FinalDestination, Pawn.GetCollisionRadius(), true) && NavigationHandle.GetNextMoveLocation(NextMoveLocation, Pawn.GetCollisionRadius()))
	{
		// Adjust the next move location
		AdjustedNextMoveLocation = NextMoveLocation;
		if (FindSpot(Pawn.GetCollisionExtent(), AdjustedNextMoveLocation))
		{
			NextMoveLocation = AdjustedNextMoveLocation;
		}

		// Set the destination to the next move location
		SetDestinationPosition(NextMoveLocation);
		//Set the focal point
		SetFocalPoint(GetDestinationPosition());

		// Move towards the destination
		bPreciseDestination = true;
	}
	else
	{
`if(`notdefined(FINAL_RELEASE))
		`Log(Self$"::"$GetStateName()$"::MoveViaPathFinding::Couldn't path find!");
`endif
		Goto('End');
	}

// Wait until it has reached the destination
WaitUntilReachedDestination:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "WaitUntilReachedDestination";
`endif
	Sleep(0.f);
	Goto('WaitUntilReachedDestination');

// State loop end
End:
	bPreciseDestination = false;
	GotoState('');
}

/**
 * This state handles moving the pawn to an actor
 *
 * @network		Server
 */
state FollowingAnActor
{
	/**
	 * Called every time the controller is updated
	 *
	 * @param		DeltaTime		Time since the last time the controller is updated
	 * @network						Server
	 */
	function Tick(float DeltaTime)
	{
		Global.Tick(DeltaTime);

		// Set the focal point if I can see the leader
		if (FastTrace(CurrentLeader.Location, Pawn.Location))
		{
			SetFocalPoint(CurrentLeader.Location);
		}
		// Look towards where I am moving
		else
		{
			SetFocalPoint(GetDestinationPosition() + Normal(GetDestinationPosition() - Pawn.Location) * 64.f);
		}
	}

	/**
	 * Called when the controller's pawn has reached the destination defined by GetDestinationPosition()
	 *
	 * @network		Server
	 */
	event ReachedPreciseDestination()
	{
		if (VSizeSq2D(GetDestinationPosition() - CurrentLeader.Location) > 0.05f)
		{
			// Set destination position
			SetDestinationPosition(CurrentLeader.Location);
			// Go back to the beginning
			GotoState('FollowingAnActor', 'Begin');
		}
	}

// Begin state loop
Begin:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "Begin";
`endif
	// If the pawn is none, then go straight to the end
	if (Pawn == None)
	{
		Goto('End');
	}

	// If the pawn is not walking, then wait until it does 
	if (Pawn.Physics != PHYS_Walking)
	{
		Sleep(0.f);
		Goto('Begin');
	}

// Attempt to move to the current leader directly
MoveDirect:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "MoveDirect";
`endif
	// Check if the point is directly reachable or not
	if (CanReachDestination(CurrentLeader.Location))
	{
		// Move to the destination position
		bPreciseDestination = true;
		Sleep(0.f);
		Goto('KeepFollowingLeader');
	}

// Attempt to move to the current leader using path finding
MoveViaPathFinding:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "MoveViaPathFinding";
`endif
	// Generate the path and get the next move location
	if (GeneratePathTo(CurrentLeader.Location, Pawn.GetCollisionRadius(), true) && NavigationHandle.GetNextMoveLocation(NextMoveLocation, Pawn.GetCollisionRadius()))
	{
		// Adjust the next move location
		AdjustedNextMoveLocation = NextMoveLocation;
		if (FindSpot(Pawn.GetCollisionExtent(), AdjustedNextMoveLocation))
		{
			// Set the destination to the adjusted next move location
			NextMoveLocation = AdjustedNextMoveLocation;
		}

		// Set the destination to the next move location
		SetDestinationPosition(NextMoveLocation);

		// Move towards the destination
		bPreciseDestination = true;
	}
	else
	{
`if(`notdefined(FINAL_RELEASE))
		`Log(Self$"::"$GetStateName()$"::MoveViaPathFinding::Couldn't path find!");
`endif
		Goto('End');
	}

// Wait until reached destination
WaitUntilReachedDestination:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "WaitUntilReachedDestination";
`endif
	Sleep(0.f);
	Goto('WaitUntilReachedDestination');

// Keeps following leader 
KeepFollowingLeader:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "KeepFollowingLeader";
`endif
	// Update the destination position
	NextMoveLocation = CurrentLeader.Location;
	NextMoveLocation.Z = Pawn.Location.Z;
	SetDestinationPosition(NextMoveLocation);
	Sleep(0.f);
	Goto('KeepFollowingLeader');

// End state loop
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
	bIsPlayer=true
}