//=============================================================================
// UDKMOBAAIController
//
// Base AI Controller used for controlling most of the pawns in UDKMOBA. This
// is done just in case the player can control multiple units and so forth. The
// base functionality handles core behaviors such as attacking units and base
// movement and pathing functions.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAAIController extends AIController;

// Final destination of any move to make
var ProtectedWrite Vector FinalDestination;
// Temporarily store the next move location
var ProtectedWrite Vector NextMoveLocation;
// Temporarily store the next adjusted move location
var ProtectedWrite Vector AdjustedNextMoveLocation;
// Current enemy
var PrivateWrite Actor CurrentEnemy;
// Current enemy attack interface
var PrivateWrite UDKMOBAAttackInterface CurrentEnemyAttackInterface;
// Last enemy location
var PrivateWrite Vector LastEnemyLocation;
// Last evaluated attacking location
var PrivateWrite Vector LastEvaluatedAttackingLocation;
// Cached type cast of the pawn to a UDKMOBAPawn
var PrivateWrite UDKMOBAPawn CachedUDKMOBAPawn;

// State label used for debugging purposes
`if(`notdefined(FINAL_RELEASE))
var String Debug_StateLabel;
`endif

/**
 * Called when a controller should possess a pawn
 *
 * @param		inPawn					Pawn to possess
 * @param		bVehicleTransition		If true, then the player is jumping into a vehicle
 * @network								Server
 */
event Possess(Pawn inPawn, bool bVehicleTransition)
{
	Super.Possess(inPawn, bVehicleTransition);

	// Cache the MOBA Pawn
	CachedUDKMOBAPawn = UDKMOBAPawn(inPawn);
}

/** 
 * Clears the current enemy
 *
 * @network		Server
 */
function ClearCurrentEnemy()
{
	CurrentEnemy = None;
	CurrentEnemyAttackInterface = None;
	LastEnemyLocation = Vect(0.f, 0.f, 0.f);
	LastEvaluatedAttackingLocation = Vect(0.f, 0.f, 0.f);
}

/**
 * Sets the current enemy
 *
 * @param		PotentialEnemy						Enemy to set as the current enemy
 * @param		PotentialEnemyAttackInterface		Optional type cast to UDKMOBAAttackInterface, this just reduces type casting costs. This should be the same as PotentialEnemy
 * @return											Returns true if the current enemy was able to be set
 * @network											Server
 */
function bool SetCurrentEnemy(Actor PotentialEnemy, optional UDKMOBAAttackInterface PotentialEnemyAttackInterface)
{
	// Set the current enemy
	CurrentEnemy = PotentialEnemy;
	CurrentEnemyAttackInterface = (PotentialEnemyAttackInterface != None) ? PotentialEnemyAttackInterface : UDKMOBAAttackInterface(PotentialEnemy);
	
	// Clears the current enemy if it is invalid
	if (CurrentEnemy == None || CurrentEnemyAttackInterface == None)
	{
		ClearCurrentEnemy();
		return false;
	}

	return true;
}
/**
 * Called everytime the engine is updated
 *
 * @param		DeltaTime		Time that has passed since the last update
 * @network						Server
 */
function Tick(float DeltaTime)
{
	local Rotator DesiredRotation;

	Super.Tick(DeltaTime);
	
	// Perform any effects
	if (Pawn != None && Pawn.Health > 0)
	{
		// Smoothly rotate the pawn towards the focal point
		DesiredRotation = Rotator(GetFocalPoint() - Pawn.Location);
		Pawn.FaceRotation(RLerp(Pawn.Rotation, DesiredRotation, 3.125f * DeltaTime, true), DeltaTime);
	}
}

/**
 * Checks if the pawn can move directly to the check destination
 *
 * @param		CheckDestination		Destination to check if the pawn can move there
 * @return								Returns true if the pawn can reach the check destination
 * @network								Server
 */
function bool CanReachDestination(Vector CheckDestination)
{
	local Actor HitActor;
	local Vector HitLocation, HitNormal, PathCollisionExtent;

	// Abort if there is no pawn
	if (Pawn == None)
	{
		return false;
	}

	// Create the path collision extent
	PathCollisionExtent.X = Pawn.GetCollisionRadius();
	PathCollisionExtent.Y = Pawn.GetCollisionRadius();
	PathCollisionExtent.Z = 1.f;

	// Check if it has line of sight
	if (!FastTrace(CheckDestination, Pawn.Location, PathCollisionExtent))
	{
		return false;
	}

	// Check if any actors are in the way
	foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, CheckDestination, Pawn.Location, PathCollisionExtent)
	{
		// Can't walk through towers
		if (UDKMOBATowerObjective(HitActor) != None)
		{
			return false;
		}
	}

	return true;
}

/**
 * Generates a path in the navigation mesh to a point in the world
 *
 * @param		Goal					Point in the world to path find to
 * @param		WithinDistance			How accurate the path finding needs to be
 * @param		bAllowPartialPath		Returns true even though the path finder only finds part of the path?
 * @return								Returns true if a path was found
 * @network								Server
 */
function bool GeneratePathTo(Vector Goal, optional float WithinDistance, optional bool bAllowPartialPath)
{
	if (NavigationHandle == None)
	{
         return false;
	}

    // Set up the path finding
	class'NavMeshPath_Toward'.static.TowardPoint(NavigationHandle, Goal);
	class'NavMeshGoal_At'.static.AtLocation(NavigationHandle, Goal, WithinDistance, bAllowPartialPath);
	// Set the path finding final destination
	NavigationHandle.SetFinalDestination(Goal);
	// Perform the path finding
	return NavigationHandle.FindPath();
}

/**
 * Returns true if the controller's pawn is within attacking range of the current enemy
 *
 * @return		Returns true if the controller's pawn's weapon range trigger is touching the current enemy
 * @network		Server
 */
function bool IsWithinAttackingRange()
{
	// Early exit if the current enemy or the UDKMOBAPawn is invalid
	if (CurrentEnemy == None || CachedUDKMOBAPawn == None)
	{
		return false;
	}

	return (CachedUDKMOBAPawn.WeaponRangeTrigger.Touching.Find(CurrentEnemy) != INDEX_NONE);
}

/**
 * Returns true if the controller's pawn is facing the current enemy within the attacking angle defined by the pawn's fire mode
 *
 * @return		Returns true if the controller's pawn is facing the current enemy within the attacking angle defined by the pawn's fire mode
 * @network		Server
 */
function bool IsWithinAttackingAngle()
{
	local Vector CurrentEnemyLocation, PawnLocation;

	// Early exit if the current enemy or the UDKMOBAPawn is invalid
	if (CurrentEnemy == None || CachedUDKMOBAPawn == None)
	{
		return false;
	}

	// Ignore the Z axis
	CurrentEnemyLocation = CurrentEnemy.Location;
	CurrentEnemyLocation.Z = 0.f;

	// Ignore the Z axis
	PawnLocation = Pawn.Location;
	PawnLocation.Z = 0.f;

	return (Vector(Pawn.Rotation) dot Normal(CurrentEnemyLocation - PawnLocation) >= CachedUDKMOBAPawn.WeaponFireMode.GetAttackingAngle());
}

/**
 * Evaluates the best attacking destination and sets the destination position and the final destination accordingly
 *
 * @network		Server
 */
function EvaluateBestAttackingDestination()
{
	local int i, Slices, Slice;
	local Rotator R;
	local Vector V, SpotLocation, HitLocation, HitNormal, BestAttackingLocation;
	local Actor HitActor;
	local array<Vector> PotentialAttackingLocations;
	local float	BestRating, Rating;

	// Early exit if the objects required are not valid
	if (CurrentEnemy == None || Pawn == None || CachedUDKMOBAPawn == None || CachedUDKMOBAPawn.WeaponFireMode == None || CachedUDKMOBAPawn.WeaponRangeTrigger == None)
	{
		return;
	}

	// Check if the LastEnemyLocation hasn't changed much since the last time
	if (VSizeSq(LastEnemyLocation - CurrentEnemy.Location) < 4096.f)
	{
		// Set the destination position
		SetDestinationPosition(LastEvaluatedAttackingLocation);
		// Set the final destination
		FinalDestination = LastEvaluatedAttackingLocation;

		return;
	}

	// Check if within attacking range already
	if (IsWithinAttackingRange())
	{
		// No need to continue from here
		return;
	}

	// Update
	LastEnemyLocation = CurrentEnemy.Location;

	// Generate the best attacking locations
	Slices = 16;
	Slice = 65536 / Slices;
	R = Rot(0, 0, 0);

	for (i = 0; i < Slices; ++i)
	{
		// Generate a point that is within the attack circle
		V = CurrentEnemy.Location + Vector(R) * CachedUDKMOBAPawn.WeaponRangeTrigger.CollisionCylinderComponent.CollisionRadius;

		// Find spot since the location may not be valid
		SpotLocation = V;
		if (FindSpot(Pawn.GetCollisionExtent(), SpotLocation))
		{
			V = SpotLocation;
		}

		foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, V - Vect(0.f, 0.f, 16384.f), V)
		{
			if (HitActor.bWorldGeometry)
			{
				// Adjust this location to represent if the pawn was actually there
				V = HitLocation + Vect(0.f, 0.f, 1.f) * Pawn.GetCollisionHeight();

				// Check if this location can attack the creep
				// if (Pawn.Trace(HitLocation, HitNormal, CurrentEnemy.Location, V, true) == CurrentEnemy)
				foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, CurrentEnemy.Location, V)
				{
					// Trace will hit the enemy
					if (HitActor == CurrentEnemy)
					{
						PotentialAttackingLocations.AddItem(V);
					}
					// Something was in the way
					else if (HitActor.bWorldGeometry || UDKMOBAPawn(HitActor) != None || UDKMOBAObjective(HitActor) != None)
					{
						break;
					}
				}

				break;
			}
		}

		R.Yaw += Slice;
	}

	// Also add a "straight" attacking position
	V = CurrentEnemy.Location + Normal(CurrentEnemy.Location - CachedUDKMOBAPawn.Location) * CachedUDKMOBAPawn.WeaponRangeTrigger.CollisionCylinderComponent.CollisionRadius;
	foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, V - Vect(0.f, 0.f, 16384.f), V)
	{
		if (HitActor.bWorldGeometry)
		{
			// Adjust this location to represent if the pawn was actually there
			V = HitLocation + Vect(0.f, 0.f, 1.f) * Pawn.GetCollisionHeight();

			// Check if this location can attack the creep
			// if (Pawn.Trace(HitLocation, HitNormal, CurrentEnemy.Location, V, true) == CurrentEnemy)
			foreach TraceActors(class'Actor', HitActor, HitLocation, HitNormal, CurrentEnemy.Location, V)
			{
				// Trace will hit the enemy
				if (HitActor == CurrentEnemy)
				{
					PotentialAttackingLocations.AddItem(V);
				}
				// Something was in the way
				else if (HitActor.bWorldGeometry || UDKMOBAPawn(HitActor) != None || UDKMOBAObjective(HitActor) != None)
				{
					break;
				}
			}

			break;
		}
	}

	// Evaluate the best attacking location
	// * Closest to the enemy to move into position
	if (PotentialAttackingLocations.Length > 0)
	{
		BestRating = 65536.f;
		for (i = 0; i < PotentialAttackingLocations.Length; ++i)
		{
			Rating = VSizeSq(PotentialAttackingLocations[i] - Pawn.Location);
			if (IsZero(BestAttackingLocation) || Rating < BestRating)
			{
				BestAttackingLocation = PotentialAttackingLocations[i];
				Rating = BestRating;
			}
		}

		// Check if we need to find a spot which the pawn can move to
		SpotLocation = BestAttackingLocation;
		if (FindSpot(Pawn.GetCollisionExtent(), SpotLocation))
		{
			BestAttackingLocation = SpotLocation;
		}

		// Set the last evaluated attacking location
		LastEvaluatedAttackingLocation = BestAttackingLocation;
		// Set the destination position
		SetDestinationPosition(BestAttackingLocation);
		// Set the final destination
		FinalDestination = BestAttackingLocation;
		// Set the focal point
		SetFocalPoint(GetDestinationPosition() + Normal(GetDestinationPosition() - Pawn.Location) * 64.f);
	}
}

/**
 * This state handles when the creep should be attack the current enemy
 *
 * @network		Server
 */
state AttackingCurrentEnemy
{
	/**
	 * Called every time the AI controller is updated
	 *
	 * @param		DeltaTime		Time since the last update was done
	 * @network						Server
	 */
	function Tick(float DeltaTime)
	{
		local Vector CurrentDestinationPosition;

		Global.Tick(DeltaTime);

		// Set the focal point if I can see the enemy pawn
		if (FastTrace(CurrentEnemy.Location, Pawn.Location))
		{
			SetFocalPoint(CurrentEnemy.Location);
		}
		// Look towards where I am moving
		else
		{
			SetFocalPoint(GetDestinationPosition() + Normal(GetDestinationPosition() - Pawn.Location) * 64.f);
		}

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
		GotoState('AttackingCurrentEnemy', 'CanAttackCurrentEnemy');
	}

	/**
	 * Called when the state has ended and the actor is going to another state
	 *
	 * @param		NextStateName		Next state that the actor will go to
	 * @network							Server
	 */
	function EndState(Name NextStateName)
	{
		Super.EndState(NextStateName);

		// Stop firing
		if (Pawn != None && Pawn.IsFiring())
		{
			Pawn.StopFire(0);
		}
	}

// When the state begins
Begin:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "Begin";
`endif
	// If the pawn is none or has no weapon, then go straight to the end
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

// Check if we can currently attack the enemy or not
CanAttackCurrentEnemy:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "CanAttackCurrentEnemy";
`endif
	// Check if the current enemy is still valid
	if (CurrentEnemyAttackInterface != None && !CurrentEnemyAttackInterface.IsValidToAttack())
	{
		ClearCurrentEnemy();
		Goto('End');
	}
	// Check if within range to attack the enemy
	else if (IsWithinAttackingRange())
	{
		// Check if within angle of attack
		if (IsWithinAttackingAngle())
		{
			// If not firing, then start firing now
			if (!Pawn.IsFiring())
			{
				Pawn.StartFire(0);
			}
		}
		else
		{
			// If firing, then stop firing
			if (Pawn.IsFiring())
			{
				Pawn.StopFire(0);
			}
		}

		// Stop movement
		bPreciseDestination = false;
		// In range, but not within angle of attack then wait
		Sleep(0.f);
		Goto('CanAttackCurrentEnemy');
	}

// Evaluate the best attacking position
EvaluateBestAttackingPosition:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "EvaluateBestAttackingPosition";
`endif
	// Evaluate the best attacking location
	EvaluateBestAttackingDestination();

	// If firing, then stop firing
	if (Pawn.IsFiring())
	{
		Pawn.StopFire(0);
	}

// Attempt to move directly to the destination
MoveDirect:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "MoveDirect";
`endif
	// Check if the point is directly reachable or not
	if (CanReachDestination(GetDestinationPosition()))
	{
		// Move to the destination position
		bPreciseDestination = true;

		// Wait until we've reached the destination
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

// Wait until we've reached the destination
WaitUntilReachedDestination:
`if(`notdefined(FINAL_RELEASE))
	Debug_StateLabel = "WaitUntilReachedDestination";
`endif
	// Check if the current enemy is still valid
	if (CurrentEnemyAttackInterface != None && !CurrentEnemyAttackInterface.IsValidToAttack())
	{
		ClearCurrentEnemy();
		Goto('End');
	}
	// Check if within range to attack the enemy
	else if (IsWithinAttackingRange())
	{
		Sleep(0.f);
		Goto('CanAttackCurrentEnemy');
	}
	else
	{
		Sleep(0.f);
		Goto('WaitUntilReachedDestination');
	}

// End of the state loop
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