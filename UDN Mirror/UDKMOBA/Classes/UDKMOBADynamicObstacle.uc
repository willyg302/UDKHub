//=============================================================================
// UDKMOBADynamicObstacle
//
// This a dynamic obstacle which can generate "holes" in the existing map
// navigation mesh. This is a reversible process, and thus can be used for 
// temporary things that require pathing around.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBADynamicObstacle extends NavMeshObstacle;

// List of possible shapes
enum EShape
{
	EShape_None,
	EShape_Square,
	EShape_Rectangle,
	EShape_Circle
};

// Shape of the nav mesh obstacle
var PrivateWrite EShape ShapeType;
// Used in EShape_Square
var PrivateWrite float Width;
// Used in EShape_Square and EShape_Rectangle
var PrivateWrite float Height;   
// Used in EShape_Circle
var PrivateWrite float Radius;
// Used in EShape_Circle
var PrivateWrite int Sides;
// Align the obstacle to the rotation of the actor?
var bool AlignToRotation;

/**
 * Called when the actor is initialized
 *
 * @network		Server and client
 */
simulated function PostBeginPlay()
{
	// Skip default post begin play function
	Super(Actor).PostBeginPlay();
}

/**
 * Sets the obstacle as a square
 *
 * @param		NewWidth		Width to use for the length of the square sides
 * @network						Server and client
 */
simulated function SetAsSquare(float NewWidth)
{
	if (NewWidth > 0.f)
	{
		ShapeType = EShape_Square;
		Width = NewWidth;
	}
}

/**
 * Sets the obstacle as a rectangle
 *
 * @param		NewWidth		Length of one of the rectangle sides
 * @param		NewHeight		Length of one of the rectangle sides
 * @network						Server and client
 */
simulated function SetAsRectangle(float NewWidth, float NewHeight)
{
	if (NewWidth > 0.f && NewHeight > 0.f)
	{
		ShapeType = EShape_Rectangle;
		Width = NewWidth;
		Height = NewHeight;
	}
}

/**
 * Sets the obstacle as a circle
 *
 * @param		NewRadius		Radius of the circle
 * @param		NewSides		Number of sides of the circle, avoid using large numbers here
 * @network						Server and client
 */
simulated function SetAsCircle(float NewRadius, float NewSides)
{
	if (NewRadius > 0.f && NewSides > 0)
	{
		ShapeType = EShape_Circle;
		Radius = NewRadius;
		Sides = NewSides;
	}
}

/**
 * Called when the dynamic obstacle should register its collision shape
 *
 * @param		Shape		Output array of shape points, in a clock wise fashion
 * @return					Returns true if the shape is a valid
 * @network					Server and client
 */
simulated event bool GetObstacleBoudingShape(out array<vector> Shape)
{
	local Vector Offset;
	local int i, Angle;
	local Rotator R;

	// Obstacle is a square
	if (ShapeType == EShape_Square)
	{
		if (AlignToRotation)
		{
			// Top right corner
			Offset.X = Width;
			Offset.Y = Width;
			Shape.AddItem(Location + (Offset >> Rotation));
			// Bottom right corner
			Offset.X = -Width;
			Offset.Y = Width;
			Shape.AddItem(Location + (Offset >> Rotation));
			// Bottom left corner
			Offset.X = -Width;
			Offset.Y = -Width;
			Shape.AddItem(Location + (Offset >> Rotation));
			// Top left corner
			Offset.X = Width;
			Offset.Y = -Width;
			Shape.AddItem(Location + (Offset >> Rotation));
		}
		else
		{
			// Top right corner
			Offset.X = Width;
			Offset.Y = Width;
			Shape.AddItem(Location + Offset);
			// Bottom right corner
			Offset.X = -Width;
			Offset.Y = Width;
			Shape.AddItem(Location + Offset);
			// Bottom left corner
			Offset.X = -Width;
			Offset.Y = -Width;
			Shape.AddItem(Location + Offset);
			// Top left corner
			Offset.X = Width;
			Offset.Y = -Width;
			Shape.AddItem(Location + Offset);
		}

		return true;
	}
	// Obstacle is a rectangle
	else if (ShapeType == EShape_Rectangle)
	{
		if (AlignToRotation)
		{
			// Top right corner
			Offset.X = Width;
			Offset.Y = Height;
			Shape.AddItem(Location + (Offset >> Rotation));
			// Bottom right corner
			Offset.X = -Width;
			Offset.Y = Height;
			Shape.AddItem(Location + (Offset >> Rotation));
			// Bottom left corner
			Offset.X = -Width;
			Offset.Y = -Height;
			Shape.AddItem(Location + (Offset >> Rotation));
			// Top left corner
			Offset.X = Width;
			Offset.Y = -Height;
			Shape.AddItem(Location + (Offset >> Rotation));
		}
		else
		{
			// Top right corner
			Offset.X = Width;
			Offset.Y = Height;
			Shape.AddItem(Location + Offset);
			// Bottom right corner
			Offset.X = -Width;
			Offset.Y = Height;
			Shape.AddItem(Location + Offset);
			// Bottom left corner
			Offset.X = -Width;
			Offset.Y = -Height;
			Shape.AddItem(Location + Offset);
			// Top left corner
			Offset.X = Width;
			Offset.Y = -Height;
			Shape.AddItem(Location + Offset);
		}

		return true;
	}
	// Obstacle is a circle
	else if (ShapeType == EShape_Circle && Sides > 0)
	{
		// Get the angle of each 'slice' defined by the number of sides
		Angle = 65536 / Sides;
		// If we are aligned to rotation, use the rotation as the starting point
		R =	(AlignToRotation) ? Rotation : Rot(0, 0, 0);
		// Set the radius
		Offset.X = Radius;
		Offset.Y = 0.f;
		// For each side...
		for (i = 0; i < Sides; ++i)
		{
			// Add the the left side point
			Shape.AddItem(Location + (Offset >> R));
			// Increment to the next side
			R.Yaw += Angle;
		}

		return true;
	}

	return false;
}

// Default properties block
defaultproperties
{
}