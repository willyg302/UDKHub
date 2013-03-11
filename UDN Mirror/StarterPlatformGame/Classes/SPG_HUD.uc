//=============================================================================
// SPG_HUD
//
// Simple HUD which shows the health on screen.
//
// Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class SPG_HUD extends HUD;

/**
 * Post render called after the scene has been rendered. Use Canvas to draw material, textures and text onto the
 * HUD.
 *
 * @network				Client
 */
event PostRender()
{
	local float XL, YL;
	local String Text;

	Super.PostRender();

	// Ensure that PlayerOwner and PlayerOwner.Pawn are valid
	if (PlayerOwner != None && PlayerOwner.Pawn != None)
	{
		// Set the text to say Health: and the numerical value of the player pawn's health
		Text = "Health: "$PlayerOwner.Pawn.Health;
		// Set the font
		Canvas.Font = class'Engine'.static.GetMediumFont();
		// Set the current drawing color
		Canvas.SetDrawColor(255, 255, 255);
		// Get the dimensions of the text in the font assigned
		Canvas.StrLen(Text, XL, YL);
		// Set the current drawing position to the be at the bottom left position with a padding of 4 pixels
		Canvas.SetPos(4, Canvas.ClipY - YL - 4);
		// Draw the text onto the screen
		Canvas.DrawText(Text);
	}
}

defaultproperties
{
}