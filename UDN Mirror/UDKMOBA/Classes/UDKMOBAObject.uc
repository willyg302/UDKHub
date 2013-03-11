//=============================================================================
// UDKMOBAObject
//
// Base object class which has a lot of utility functions.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAObject extends Object;

/**
 * Returns the player color
 *
 * @param		UDKMOBAPlayerReplicationInfo		Player replication info to get the color for
 * @param		out_Color							Output the color
 * @network											Returns true if a color could be returned
 * @network											All
 */
static function bool GetPlayerColor(UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo, out Color out_Color)
{
	local int Index;

	if (UDKMOBAPlayerReplicationInfo != None)
	{
		Index = class'UDKMOBAGameInfo'.default.Properties.PlayerColors.Find('ColorName', UDKMOBAPlayerReplicationInfo.PlayerColor);
		if (Index != INDEX_NONE)
		{
			out_Color = class'UDKMOBAGameInfo'.default.Properties.PlayerColors[Index].StoredColor;
			return true;
		}
	}

	return false;
}

/**
 * Returns the hit location and hit normal of the mouse trace
 *
 * @param		HUD					Reference to the HUD
 * @param		out_HitLocation		Hit location representing where the mouse trace hit
 * @param		out_HitNormal		Hit normal of the surface the mouse trace hit
 * @return							Returns true if the mouse trace hit something, and thus valid results
 * @network							All
 */
static function bool MouseToWorldCoordinates(HUD HUD, out Vector out_HitLocation, out Vector out_HitNormal)
{
	local WorldInfo WorldInfo;
	local PlayerController PlayerController;
	local LocalPlayer LocalPlayer;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo == None)
	{
		return false;
	}

	PlayerController = WorldInfo.GetALocalPlayerController();
	if (PlayerController == None)
	{
		return false;
	}

	LocalPlayer = LocalPlayer(PlayerController.Player);
	if (LocalPlayer == None || LocalPlayer.ViewportClient == None)
	{
		return false;
	}

	return ScreenSpaceCoordinatesToWorldCoordinates(HUD, LocalPlayer.ViewportClient.GetMousePosition(), out_HitLocation, out_HitNormal);
}

/**
 * Converts screen space coordinates into world space coordinates
 *
 * @param		HUD						Reference to the HUD
 * @param		ScreenSpaceLocation		Screen space location to convert
 * @param		out_HitLocation			Hit location representing where the mouse trace hit
 * @param		out_HitNormal			Hit normal of the surface the mouse trace hit
 * @return								Returns true if the trace hit something, and thus valid results
 * @network								All
 */
static function bool ScreenSpaceCoordinatesToWorldCoordinates(HUD HUD, Vector2D ScreenSpaceLocation, out Vector out_HitLocation, out Vector out_HitNormal)
{
	local Vector WorldOrigin, WorldDirection, HitLocation, HitNormal;
	local Actor Actor;
	local WorldInfo WorldInfo;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo == None)
	{
		return false;
	}

	// Get the deprojection coordinates from the screen location
	HUD.Canvas.Deproject(ScreenSpaceLocation, WorldOrigin, WorldDirection);

	// Perform a trace to find either UDKMOBAGroundBlockingVolume or the WorldInfo [BSP] 
	ForEach WorldInfo.TraceActors(class'Actor', Actor, HitLocation, HitNormal, WorldOrigin + WorldDirection * 16384.f, WorldOrigin)
	{
		if (ShouldBlockMouseWorldTrace(Actor))
		{
			out_HitLocation = HitLocation;
			out_HitNormal = HitNormal;
			return true;
		}
	}

	return false;
}

/**
 * Returns true if the actor should block the mouse world trace
 *
 * @param		Actor		Actor to test 
 * @network					All
 */
static function bool ShouldBlockMouseWorldTrace(Actor Actor)
{
	return (UDKMOBAGroundBlockingVolume(Actor) != None || WorldInfo(Actor) != None);
}

/**
 * Returns true if the point is within the screen bounding box
 *
 * @param		Point					Point to test
 * @param		ScreenBoundingBox		Bounding box to check if the point is within it
 * @return								Returns true if the point is within the screen bounding box
 * @network								All
 */
static function bool IsPointInTouchBoundingBox(Vector2D Point, Box ScreenBoundingBox)
{
	return (ScreenBoundingBox.Min.X <= Point.X && ScreenBoundingBox.Min.Y <= Point.Y && ScreenBoundingBox.Max.X >= Point.X && ScreenBoundingBox.Max.Y >= Point.Y);
}

/**
 * Returns the primitive components bounding box in screen space
 *
 * @param		HUD							HUD to use for projecting world space coordinates into screen space
 * @param		ComponentsBoundingBox		Components bounding box in world space
 * @param		OutBox						Output bounding box in screen space
 * @return									Returns true if the bounding box in screen space is able to be calculated or not
 * @network									All
 */
static function bool GetPrimitiveComponentScreenBoundingBox(HUD HUD, Box ComponentsBoundingBox, out Box OutBox)
{
	local Vector BoundingBoxCoordinates[8];
	local int i;

	// Abort if HUD is none
	if (HUD == None)
	{
		return false;
	}

	// Z1
	// X1, Y1
	BoundingBoxCoordinates[0].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[0].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[0].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[0] = HUD.Canvas.Project(BoundingBoxCoordinates[0]);
	// X2, Y1
	BoundingBoxCoordinates[1].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[1].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[1].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[1] = HUD.Canvas.Project(BoundingBoxCoordinates[1]);
	// X1, Y2
	BoundingBoxCoordinates[2].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[2].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[2].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[2] = HUD.Canvas.Project(BoundingBoxCoordinates[2]);
	// X2, Y2
	BoundingBoxCoordinates[3].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[3].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[3].Z = ComponentsBoundingBox.Min.Z;
	BoundingBoxCoordinates[3] = HUD.Canvas.Project(BoundingBoxCoordinates[3]);

	// Z2
	// X1, Y1
	BoundingBoxCoordinates[4].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[4].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[4].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[4] = HUD.Canvas.Project(BoundingBoxCoordinates[4]);
	// X2, Y1
	BoundingBoxCoordinates[5].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[5].Y = ComponentsBoundingBox.Min.Y;
	BoundingBoxCoordinates[5].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[5] = HUD.Canvas.Project(BoundingBoxCoordinates[5]);
	// X1, Y2
	BoundingBoxCoordinates[6].X = ComponentsBoundingBox.Min.X;
	BoundingBoxCoordinates[6].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[6].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[6] = HUD.Canvas.Project(BoundingBoxCoordinates[6]);
	// X2, Y2
	BoundingBoxCoordinates[7].X = ComponentsBoundingBox.Max.X;
	BoundingBoxCoordinates[7].Y = ComponentsBoundingBox.Max.Y;
	BoundingBoxCoordinates[7].Z = ComponentsBoundingBox.Max.Z;
	BoundingBoxCoordinates[7] = HUD.Canvas.Project(BoundingBoxCoordinates[7]);
	
	// Find the left, top, right and bottom coordinates
	OutBox.Min.X = HUD.Canvas.ClipX;
	OutBox.Min.Y = HUD.Canvas.ClipY;
	OutBox.Max.X = 0;
	OutBox.Max.Y = 0;

	  // Iterate though the bounding box coordinates
	for (i = 0; i < ArrayCount(BoundingBoxCoordinates); ++i)
	{
		// Detect the smallest X coordinate
		if (OutBox.Min.X > BoundingBoxCoordinates[i].X)
		{
			OutBox.Min.X = BoundingBoxCoordinates[i].X;
		}

		// Detect the smallest Y coordinate
		if (OutBox.Min.Y > BoundingBoxCoordinates[i].Y)
		{
			OutBox.Min.Y = BoundingBoxCoordinates[i].Y;
		}

		// Detect the largest X coordinate
		if (OutBox.Max.X < BoundingBoxCoordinates[i].X)
		{
			OutBox.Max.X = BoundingBoxCoordinates[i].X;
		}

		// Detect the largest Y coordinate
		if (OutBox.Max.Y < BoundingBoxCoordinates[i].Y)
		{
			OutBox.Max.Y = BoundingBoxCoordinates[i].Y;
		}
	}

	return true;
}

/**
 * Calculates the intersection point between a line and a plane.
 *
 * @param		LineA					Point A representing the start or end of the line
 * @param		LineB					Point B representing the start or end of the line
 * @param		PlanePoint				Point somewhere on the plane
 * @param		PlaneNormal				Normal of the plane
 * @param		IntersectionPoint		Intersection point where the line intersects with the plane
 * @return								Returns true if there was an interesection between the line and the plane
 * @network								All
 */
static function bool LinePlaneIntersection(Vector LineA, Vector LineB, Vector PlanePoint, Vector PlaneNormal, out Vector IntersectionPoint)
{
	local Vector U, W;
	local float D, N, sI;

	U = LineB - LineA;
	W = LineA - PlanePoint;

    D = PlaneNormal dot U;
    N = (PlaneNormal dot W) * -1.f;

    if (Abs(D) < 0.000001f)
	{
		return false;
	}

	sI = N / D;
	if (sI < 0.f || sI > 1.f)
	{
		return false;
	}

	IntersectionPoint = LineA + sI * U;
	return true;
}

// Default properties block
defaultproperties
{
}