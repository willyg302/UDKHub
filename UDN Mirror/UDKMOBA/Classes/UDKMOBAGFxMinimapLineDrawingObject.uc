//=============================================================================
// UDKMOBAGFxMinimapLineDrawingObject
//
// GFx widget which is capable of drawing lines onto the movie clip
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxMinimapLineDrawingObject extends GFxObject;

// Width of the movie clip
var float Width;
// Height of the movie clip
var float Height;
// Half width of the movie clip
var float HalfWidth;
// Half height of the movie clip
var float HalfHeight;
// Next time the mouse should be scanned to draw
var float NextTimeToUpdateDrawingUsingMouse;
// Last position that mouse was in
var Vector2D LastMousePosition;

/**
 * Initializes the mini map line drawing object
 *
 * @network		Client
 */
function Init()
{
	Width = GetFloat("width");
	Height = GetFloat("height");
	HalfWidth = Width * 0.5f;
	HalfHeight = Height * 0.5f;
}

/**
 * Draws onto the object using screen space coordinates.
 *
 * @param		X						X position to use
 * @param		Y						Y position to use
 * @param		LineColor				Color of the lines to draw
 * @param		DrawingTimeInterval		Time between each redraw interval. This ensures that we don't draw too many lines to ensure performance is stable.
 */
function DrawUsingScreenSpaceCoordinates(float X, float Y, Color LineColor, float DrawingTimeInterval)
{
	local WorldInfo WorldInfo;
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo == None)
	{
		return;
	}

	if (WorldInfo.TimeSeconds < NextTimeToUpdateDrawingUsingMouse)
	{
		return;
	}

	// Set the next time draw
	NextTimeToUpdateDrawingUsingMouse = WorldInfo.TimeSeconds + FMin(DrawingTimeInterval, 0.01f);

	// Only draw a line if the mouse positions differ
	if (LastMousePosition.X != X && LastMousePosition.Y != Y)
	{
		// Draw line from the last mouse position to the current mouse position
		DrawLine(LastMousePosition.X, LastMousePosition.Y, X, Y, LineColor.R, LineColor.G, LineColor.B, LineColor.A);

		UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
		if (UDKMOBAPlayerController != None)
		{
			UDKMOBAPlayerController.ServerBroadcastLineDraw(LastMousePosition.X, LastMousePosition.Y, X, Y);
		}

		// Update the last line position
		LastMousePosition.X = X;
		LastMousePosition.Y = Y;
	}
}

/**
 * Draws a line 
 *
 * @param		X1			Movie clip coordinates where the line starts
 * @param		Y1			Movie clip coordinates where the line starts
 * @param		X2			Movie clip coordinates where the line ends
 * @param		Y2			Movie clip coordinates where the line ends
 * @param		R			Red color value
 * @param		G			Green color value
 * @param		B			Blue color value
 * @param		Alpha		Alpha color value
 * @network					Server and client
 */
function DrawLine(float X1, float Y1, float X2, float Y2, float R, float G, float B, float Alpha)
{
	ActionScriptVoid("drawLine");
}

/**
 * Clears all of the lines that have been drawn
 *
 * @network		Server and client
 */
function Clear()
{
	ActionScriptVoid("clear");
}

// Default properties block
defaultproperties
{
}