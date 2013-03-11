//=============================================================================
// UDKMOBATrigger
//
// A trigger which has delegate binds for its Touch and Untouch events. This is
// used for detecting when actors reach a destination, or has touched other 
// actors to use an event based system rather than constantly polling for that
// sort of information.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBATrigger extends Actor;

// Reference to the cylinder component used as the collision component
var const CylinderComponent CollisionCylinderComponent;

/**
 * Called when the trigger touches an actor within the world
 *
 * @param		Other			Actor that was touched
 * @param		OtherComp		Actor's primitive component that was touched
 * @param		HitLocation		World location where the touch occured
 * @param		HitNormal		Surface normal calculated when the touch occured
 * @network						Server and client
 */
simulated singular event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
`if(`notdefined(FINAL_RELEASE))
	if (bDebug && UDKMOBATowerObjective(Other) != None)
	{
		`Log(Self$"::"$GetFuncName()$":: Other = "$Other$", OtherComp = "$OtherComp$", HitLocation = "$HitLocation$", HitNormal = "$HitNormal);
	}
`endif 
	OnTouch(Self, Other, OtherComp, HitLocation, HitNormal);
}

/**
 * Called when the trigger untouches an actor within the world (that is to say, an actor that was touched but no longer is)
 *
 * @param		Other			Actor that was untouched
 * @network						Server and client
 */
simulated singular event UnTouch(Actor Other)
{
`if(`notdefined(FINAL_RELEASE))
	if (bDebug && UDKMOBATowerObjective(Other) != None)
	{
		`Log(Self$"::"$GetFuncName()$":: Other = "$Other);
	}
`endif 
	OnUnTouch(Self, Other);
}

/**
 * Called when the trigger should update. Currently only used for debugging
 * 
 * @param		DeltaTime		Time since the last update was called
 * @network						Server and client
 */
`if(`notdefined(FINAL_RELEASE))
simulated event Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);

	if (bDebug)
	{
		DrawDebugCylinder(Location + Vect(0.f, 0.f, 1.f) * CollisionCylinderComponent.CollisionHeight, Location - Vect(0.f, 0.f, 1.f) * CollisionCylinderComponent.CollisionHeight, CollisionCylinderComponent.CollisionRadius, 16, 255, 0, 255);
	}
}
`endif 

/**
 * Called when the trigger touches an actor within the world
 *
 * @param		Caller			Always a reference to this actor
 * @param		Other			Actor that was touched
 * @param		OtherComp		Actor's primitive component that was touched
 * @param		HitLocation		World location where the touch occured
 * @param		HitNormal		Surface normal calculated when the touch occured
 * @network						Server and client
 */
simulated delegate OnTouch(Actor Caller, Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal);

/**
 * Called when the trigger untouches an actor within the world (that is to say, an actor that was touched but no longer is)
 *
 * @param		Caller			Always a reference to this actor
 * @param		Other			Actor that was untouched
 * @network						Server and client
 */
simulated delegate OnUnTouch(Actor Caller, Actor Other);

// Default properties block
defaultproperties
{
	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=+256.f
		CollisionHeight=+64.f
		BlockNonZeroExtent=true
		BlockZeroExtent=false
		BlockActors=false
		CollideActors=true
	End Object
	CollisionComponent=CollisionCylinder
	CollisionCylinderComponent=CollisionCylinder
	Components.Add(CollisionCylinder)

	bHidden=true
	bCollideActors=true
	bCollideWorld=false
	bIgnoreEncroachers=true
	bCollideAsEncroacher=true
	bPushedByEncroachers=true
}