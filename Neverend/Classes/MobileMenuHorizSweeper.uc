class MobileMenuHorizSweeper extends MobileMenuObject;

/* Initially this was supposed to be a kinetic horizontal scrolling list,
 * but because UDK Canvas does not support proper clipping of text, this
 * was abandoned (NOTE: could have been done using ScriptedTextures, but
 * too complex for the simple settings menu).
 * 
 * The current version is like a slider, depending on where you touch
 * within bounds it displays that list element (far left is 0, far right
 * is numItems - 1).
 */

// SweeperLeft is a 0 - 1 range of the current position on the slider. To left is 0, to right is 1.
var float SweeperLeft;

var Vector LastTouchLocation, CurrentTouchLocation;

// True if current touch is a swipe
var bool bSwipe;
// Minimum distance a touch must move to be a swipe. Less than this, it is a tap.
var float SwipeTolerance;

// NOT TO BE CONFUSED WITH BISACTIVE!!!
var bool bActive;

// Index of max element on sweeper. 0 index is min, so num elements is SweeperMax + 1
var float SweeperMax;

// If true, if player slides outside of slider zone and releases, the slide will not register
var bool bHasCancel;

function InitMenuObject(MobilePlayerInput PlayerInput, MobileMenuScene Scene, int ScreenWidth, int ScreenHeight, bool bIsFirstInitialization)
{
	super.InitMenuObject(PlayerInput, Scene, ScreenWidth, ScreenHeight, bIsFirstInitialization);
	SweeperLeft = 0.0;
}

function RenderObject(canvas Canvas, float DeltaTime)
{
	NESettingsMenu(OwnerScene).RenderSweeper(Tag, Canvas, GetSweeperValue(), Left, Top, Opacity);
}

function SetSweeperPosition(float X)
{
	local float ret;
	ret = FClamp((X - OwnerScene.Left - Left) / Width, 0.0, 1.0);
	SweeperLeft = float(Round(ret * SweeperMax)) / SweeperMax;
}

//Transforms sweeper 0-1 float value into usable int index value
function int GetSweeperValue()
{
	return Round(Lerp(0, SweeperMax, SweeperLeft));
}

function SetSweeperValue(int Value)
{
	SweeperLeft = FClamp(float(Value) / SweeperMax, 0.0, 1.0);
}

// for dynamic lists
function SetSweeperMax(int Value)
{
	SweeperMax = float(Value);
}

event bool OnTouch(EZoneTouchEvent EventType, float TouchX, float TouchY, MobileMenuObject ObjectOver, float DeltaTime)
{
	if(EventType == ZoneEvent_Touch)
	{
		if(CheckBounds(TouchX, TouchY))
		{
			bActive = true;
			bSwipe = false;
			LastTouchLocation.X = TouchX;
			LastTouchLocation.Y = TouchY;
			SetSweeperPosition(TouchX);
		}
	}
	else if(EventType == ZoneEvent_Update || EventType == ZoneEvent_Stationary)
	{
		if(bActive)
		{
			CurrentTouchLocation.X = TouchX;
			CurrentTouchLocation.Y = TouchY;
			SetSweeperPosition(TouchX);
			CheckSwipe();
		}
	}
	else if(EventType == ZoneEvent_Untouch)
	{
		if(bHasCancel && !CheckBounds(TouchX, TouchY))
			SetSweeperPosition(LastTouchLocation.X);
		NESettingsMenu(OwnerScene).SaveSweeperValue(Tag, GetSweeperValue());
		bActive = false;
	}
	else if(EventType == ZoneEvent_Cancelled)
	{
		bActive = false;
	}
	return true;
}

function bool CheckBounds(float X, float Y)
{
	X -= OwnerScene.Left;
	Y -= OwnerScene.Top;
	if(X >= Left && X <= Left + Width && Y >= Top && Y <= Top + Height)
		return true;
	return false;
}

function CheckSwipe()
{
	if(VSize(LastTouchLocation - CurrentTouchLocation) > SwipeTolerance)
		bSwipe = true;
}

defaultproperties
{
	bIsActive=true;
	bActive=false;
	SwipeTolerance=5.0
}
