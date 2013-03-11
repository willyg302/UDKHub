//=============================================================================
// UDKMOBAHUD
//
// Base HUD class used by the MOBA Starter kit. Only base functionality is 
// done here, and specific platforms integrate the base functionality so that
// it makes sense on the platform.
//
// Most of the actual widgets displayed on the HUD is done using Scaleform
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAHUD extends HUD
	abstract;

// Struct which describes the money received
struct SReceivedMoneyMessage
{
	var string Text;
	var Vector WorldLocation;
	var float LifeTime;
};

// HUD PC Properties
var const UDKMOBAHUD_Properties HUDProperties;
// Array which holds all of the money messages
var ProtectedWrite array<SReceivedMoneyMessage> ReceivedMoneyMessages;
// Relative scale to 1024.f
var float ScaleX;
// Relative scale to 768.f
var float ScaleY;
// GFx movie used to display the HUD
var UDKMOBAGFxHUD HUDMovie;
// Array of all touchable interfaces
var ProtectedWrite array<UDKMOBATouchInterface> TouchInterfaces;

/**
 * Called when the HUD is first initialized
 *
 * @network		Client
 */
function PostBeginPlay()
{
	local Actor Actor;
	local UDKMOBATouchInterface UDKMOBATouchInterface;

	Super.PostBeginPlay();

	// Initially fill the touch interfaces
	foreach DynamicActors(class'Actor', Actor, class'UDKMOBATouchInterface')
	{
		// Cast each actor to the touch interface
		UDKMOBATouchInterface = UDKMOBATouchInterface(Actor);
		if (UDKMOBATouchInterface != None)
		{
			TouchInterfaces.AddItem(UDKMOBATouchInterface);			
		}
	}
}

/**
 * Adds a touch interface to the touch interfaces array if it doesn't exist
 *
 * @param		UDKMOBATouchInterface		Touch interface to add
 * @network									Client
 */
function AddTouchInterface(UDKMOBATouchInterface UDKMOBATouchInterface)
{
	if (UDKMOBATouchInterface != None && TouchInterfaces.Find(UDKMOBATouchInterface) == INDEX_NONE)
	{
		TouchInterfaces.AddItem(UDKMOBATouchInterface);
	}
}

/**
 * Removes a touch interface to the touch interfaces array if it exists
 *
 * @param		UDKMOBATouchInterface		Touch interface to remove
 * @network									Client
 */
function RemoveTouchInterface(UDKMOBATouchInterface UDKMOBATouchInterface)
{
	if (UDKMOBATouchInterface != None)
	{
		UDKMOBATouchInterface.InvalidateTouchBoundingBox();
		TouchInterfaces.RemoveItem(UDKMOBATouchInterface);
	}
}

/**
 * Precalculate most common values, to avoid doing 1200 times the same operations
 *
 * @network		Client
 */
function PreCalcValues()
{
	Super.PreCalcValues();

	ScaleX = 1024.f / SizeX;
	ScaleY = 768.f / SizeY;

	ResolutionChanged();
}

/**
 * Player receives notification about money received from the world
 *
 * @param		Amount				Amount of money received
 * @param		WorldLocation		Where in the world money was received
 * @network							Client
 */
function ReceivedMoney(int Amount, Vector WorldLocation)
{
	local SReceivedMoneyMessage ReceivedMoneyMessage;

	if (HUDProperties == None)
	{
		return;
	}

	// Create a new received money message
	ReceivedMoneyMessage.Text = "$"$Amount;
	ReceivedMoneyMessage.WorldLocation = WorldLocation;
	ReceivedMoneyMessage.LifeTime = HUDProperties.ReceivedMoneyLifeTime;

	// Add the received money message to array
	ReceivedMoneyMessages.AddItem(ReceivedMoneyMessage);
}

/**
 * Called when the HUD should handle rendering
 *
 * @network		Client
 */
event PostRender()
{
`if(`notdefined(FINAL_RELEASE))
	local UDKMOBACreepAIController UDKMOBACreepAIController;
	local float outYL, outYPos;
`endif
	local Actor Actor;
	local UDKMOBAMinimapInterface UDKMOBAMinimapInterface;

	Super.PostRender();

	// If no player owner, then abort
	if (PlayerOwner == None)
	{
		return;
	}

	// Update touch interfaces
	UpdateTouchInterfaces();

	// Add the ScaleForm HUD if needed, and tick it
	if (HUDMovie == None)
	{
		HUDMovie = new class'UDKMOBAGFxHUD';
		if (HUDMovie != None)
		{
			HUDMovie.LocalPlayerOwnerIndex = GetLocalPlayerOwnerIndex();
			HUDMovie.SetTimingMode(TM_Real);
			HUDMovie.ExternalInterface = Self;
			HUDMovie.SetPriority(2);
			HUDMovie.bAllowFocus = true;

			// Initially fill the minimap interfaces
			foreach DynamicActors(class'Actor', Actor, class'UDKMOBAMinimapInterface')
			{
				// Cast each actor the minimap interface
				UDKMOBAMinimapInterface = UDKMOBAMinimapInterface(Actor);
				if (UDKMOBAMinimapInterface != None)
				{
					HUDMovie.AddMinimapInterface(UDKMOBAMinimapInterface);
				}
			}

			if (!HUDMovie.bMovieIsOpen)
			{
				HUDMovie.Start();
			}

			HUDMovie.SetViewScaleMode(SM_NoBorder);
			ResolutionChanged();
		}
	}

	// Tick the HUD Movie
	if (HUDMovie != None && HUDMovie.bMovieIsOpen)
	{
		HUDMovie.Tick(Canvas, RenderDelta);
	}

	// Render and update the received money messages
	RenderAndUpdateReceivedMoney();

`if(`notdefined(FINAL_RELEASE))
	if (bShowDebugInfo)
	{
		// Render debug	for AI creeps
		if (ShouldDisplayDebug('AICREEP'))
		{
			ForEach WorldInfo.AllControllers(class'UDKMOBACreepAIController', UDKMOBACreepAIController)
			{
				// Only display debug for those that have pawns
				if (UDKMOBACreepAIController.Pawn != None)
				{
					UDKMOBACreepAIController.DisplayDebug(Self, outYL, outYPos);
				}
			}
		}
	}
`endif
}

/**
 */
function AddConsoleMessage(string M, class<LocalMessage> InMessageClass, PlayerReplicationInfo PRI, optional float LifeTime)
{
	if (HUDMovie != None)
	{
		if (PlayerOwner != None)
		{
			if (HUDProperties != None)
			{
				PlayerOwner.PlaySound(HUDProperties.GenericMessageReceived, true);
			}
		}

		HUDMovie.AddMessage(M, FMax(LifeTime, 5.f));
	}
	else
	{
		Super.AddConsoleMessage(M, InMessageClass, PRI, LifeTime);
	}
}

/**
 * Tells anything that needs to reconfigure on screen resolution changes what the new resolution
 * is - eg the ScaleForm HUD.
 *
 * @network		Client
 */
protected function ResolutionChanged()
{
	if (HUDMovie != None)
	{
		HUDMovie.ConfigureForRes(Canvas.ClipX, Canvas.ClipY);
	}
}

/** 
 * Returns the index of the local player that owns this HUD
 *
 * @return		Returns the player index that matches the local player
 * @network		Client
 */
function int GetLocalPlayerOwnerIndex()
{
	return class'Engine'.static.GetEngine().GamePlayers.Find(LocalPlayer(PlayerOwner.Player));
}

/**
 * Updates all of the touch interfaces
 *
 * @network		Client
 */
protected function UpdateTouchInterfaces()
{
	local int i;

	if (TouchInterfaces.Length > 0)
	{
		for (i = 0; i < TouchInterfaces.Length; ++i)
		{
			// Ensure the touch interface is valid			
			if (TouchInterfaces[i] != None)
			{
				switch (class'UDKMOBAGameInfo'.static.GetPlatform())
				{
				case P_Mobile:
					TouchInterfaces[i].UpdateTouchBoundingBox(Self);
					break;

				default:
					// Ensure the touch interfaces actor has been rendered at least 0.05f seconds ago
					if (WorldInfo.TimeSeconds - TouchInterfaces[i].GetActor().LastRenderTime < 0.05f)
					{
						TouchInterfaces[i].UpdateTouchBoundingBox(Self);
					}
					// Else invalidate their touch bounding box
					else
					{
						TouchInterfaces[i].InvalidateTouchBoundingBox();
					}
					break;
				}
			}
			// Otherwise remove it
			else
			{
				TouchInterfaces.Remove(i, 1);
				i--;
			}
		}
	}
}

/**
 * Renders and updates the received money text
 *
 * @network		All
 */
protected function RenderAndUpdateReceivedMoney()
{
	local int i;
	local Vector ScreenLocation;
	local float Delta, XL, YL;

	// Check if HUDProperties is valid
	// Check if there is any received money messages to render and or update
	if (HUDProperties == None || HUDProperties.ReceivedMoneyFont == None || ReceivedMoneyMessages.Length <= 0)
	{
		return;
	}

	// Render and update all received money messages 
	for (i = 0; i < ReceivedMoneyMessages.Length; ++i)
	{
		// Create the life delta
		Delta = ReceivedMoneyMessages[i].LifeTime / HUDProperties.ReceivedMoneyLifeTime;

		// Render the money message
		Canvas.Font = HUDProperties.ReceivedMoneyFont;
		Canvas.StrLen(ReceivedMoneyMessages[i].Text, XL, YL);
		ScreenLocation = Canvas.Project(ReceivedMoneyMessages[i].WorldLocation);
		Canvas.SetPos(ScreenLocation.X - (XL * 0.5f), ScreenLocation.Y - (HUDProperties.ReceivedMoneyZLift * (1.f - Delta)));
		Canvas.DrawColor = HUDProperties.ReceivedMoneyColor;
		Canvas.DrawColor.A = 255.f * Delta;
		Canvas.DrawText(ReceivedMoneyMessages[i].Text);

		// Update the money message life time
		ReceivedMoneyMessages[i].LifeTime -= RenderDelta;

		// Remove money messages that are no longer alive
		if (ReceivedMoneyMessages[i].LifeTime <= 0.f)
		{			
			ReceivedMoneyMessages.Remove(i, 1);
			--i;
		}
	}
}

/**
 * Entry point for basic debug rendering on the HUD. Activated and controlled via the "showdebug" console command. Can be overridden to display custom debug per-game
 *
 * @param		out_YL			Line height of the font
 * @param		out_YPos		Current line position of the text
 * @network						Client
 */
function ShowDebugInfo(out float out_YL, out float out_YPos)
{
	Super.ShowDebugInfo(out_YL, out_YPos);

	if (ShouldDisplayDebug('BoundingBoxes'))
	{
		RenderScreenBoundingBoxes();
	}
}

/**
 * Renders screen bounding boxes onto the HUD. Usually used for debugging
 *
 * @network		Client
 */
function RenderScreenBoundingBoxes()
{
	local Actor Actor;
	local Box ScreenBoundingBox;
	local UDKMOBATouchInterface UDKMOBATouchInterface;

	ForEach DynamicActors(class'Actor', Actor, class'UDKMOBATouchInterface')
	{
		UDKMOBATouchInterface = UDKMOBATouchInterface(Actor);
		if (UDKMOBATouchInterface != None)
		{
			ScreenBoundingBox = UDKMOBATouchInterface.GetTouchBoundingBox();
			// Ensure that the screen bounding box is valid
			if (ScreenBoundingBox.Min.X != -1 && ScreenBoundingBox.Min.Y != -1 && ScreenBoundingBox.Max.X != -1 && ScreenBoundingBox.Max.Y != -1)
			{
				Canvas.SetPos(ScreenBoundingBox.Min.X, ScreenBoundingBox.Min.Y);
				Canvas.SetDrawColor(255, 0, 255, 127);
				Canvas.DrawBox(ScreenBoundingBox.Max.X - ScreenBoundingBox.Min.X, ScreenBoundingBox.Max.Y - ScreenBoundingBox.Min.Y);
			}
		}
	}
}

// Default properties block
defaultproperties
{
}