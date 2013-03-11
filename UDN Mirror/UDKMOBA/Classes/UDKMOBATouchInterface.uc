//=============================================================================
// UDKMOBATouchInterface
//
// Interface that should be implemented by actors that can be detected on the
// touch pad.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKMOBATouchInterface;

/**
 * Invalidates the touch bounding box for this actor
 *
 * @network		Server and client
 */
simulated function InvalidateTouchBoundingBox();

/**
 * Returns the touch bounding box for this actor
 *
 * @return		Returns the touch bounding box
 * @network		Server and client
 */
simulated function Box GetTouchBoundingBox();

/**
 * Updates the touch bounding box for this actor
 *
 * @param		HUD		HUD to use if Canvas is required
 * @network				Server and client
 */
simulated function UpdateTouchBoundingBox(HUD HUD);

/**
 * Returns true if the point is within the screen bounding box
 *
 * @param		Point		Point to test
 * @return					Returns true if the point is within the screen bounding box
 * @network					Server and client
 */
simulated function bool IsPointInTouchBoundingBox(Vector2D Point);

/**
 * Returns the touch priority to allow other touch interfaces to be more (or less) important than others
 *
 * @return		Returns the touch priority to allow sorting of multiple touch priorities
 * @network		Server and client
 */
simulated function int GetTouchPriority();

/**
 * Returns the actor that implements this interface
 *
 * @return		Returns the actor that implements this interface
 * @network		Server and client
 */
simulated function Actor GetActor();