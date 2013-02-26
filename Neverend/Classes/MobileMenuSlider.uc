class MobileMenuSlider extends MobileMenuObject;

var Texture2D Image;
var UVCoords ImageUV;
var LinearColor ImageColor;

/* NubLeft is a 0 - 1 range of the nub's position on the slider. To left is 0, to right is 1.
 * NubHeight is relative to Height, at 1.0 NubHeight = Height
 * NubWidth is also relative to height.
 */
var float NubLeft, NubWidth, NubHeight;
var bool bRelativeNubWidth, bRelativeNubHeight;

var Vector LastTouchLocation, CurrentTouchLocation;

// True if current touch is a swipe
var bool bSwipe;
// Minimum distance a touch must move to be a swipe. Less than this, it is a tap.
var float SwipeTolerance;

// NOT TO BE CONFUSED WITH BISACTIVE!!!
var bool bActive;

var float SliderMin, SliderMax;

// Snaps to nearest integer value
var bool bIncremental;

// If the person touches the nub off-center, we want to keep this offset as we slide
var float TouchOffset;

// If true, if player slides outside of slider zone and releases, the slide will not register
var bool bHasCancel;

function InitMenuObject(MobilePlayerInput PlayerInput, MobileMenuScene Scene, int ScreenWidth, int ScreenHeight, bool bIsFirstInitialization)
{
	super.InitMenuObject(PlayerInput, Scene, ScreenWidth, ScreenHeight, bIsFirstInitialization);
	NubLeft = 0.0;
	NubHeight = bRelativeNubHeight ? (NubHeight * Height) : NubHeight;
	NubWidth = bRelativeNubWidth ? (NubWidth * Height) : NubWidth;
}

function RenderObject(canvas Canvas, float DeltaTime)
{
	local LinearColor DrawColor;
	Canvas.SetPos(OwnerScene.Left + Left + GetNubPixelLeft(), OwnerScene.Top + Top);
	Drawcolor = ImageColor;
	Drawcolor.A *= Opacity * OwnerScene.Opacity;
	Canvas.DrawTile(Image, NubWidth, NubHeight, ImageUV.U, ImageUV.V, ImageUV.UL, ImageUV.VL, DrawColor);
}

//Pixels from left edge of slider that left edge of nub is
function float GetNubPixelLeft()
{
	return (NubLeft * (Width - NubWidth));
}

function SetNubPosition(float X)
{
	local float ret;
	ret = FClamp((X - OwnerScene.Left - Left - 0.5*NubWidth - TouchOffset) / (Width - NubWidth), 0.0, 1.0);
	NubLeft = bIncremental ? (float(Round(ret * (SliderMax - SliderMin))) / (SliderMax - SliderMin)) : ret;
}

//Transforms slider value into a more usable number based on max/min and clamping
function float GetSliderValue()
{
	local float ret;
	ret = Lerp(SliderMin, SliderMax, NubLeft);
	return bIncremental ? float(Round(ret)) : ret;
}

function SetSliderValue(float Value)
{
	NubLeft = FClamp((Value - SliderMin) / (SliderMax - SliderMin), 0.0, 1.0);
}

event bool OnTouch(EZoneTouchEvent EventType, float TouchX, float TouchY, MobileMenuObject ObjectOver, float DeltaTime)
{
	if(EventType == ZoneEvent_Touch)
	{
		if(CheckBounds(TouchX, TouchY))
		{
			if(CheckHitNub(TouchX, TouchY))
				TouchOffset = TouchX - OwnerScene.Left - Left - GetNubPixelLeft() - 0.5*NubWidth;
			bActive = true;
			bSwipe = false;
			LastTouchLocation.X = TouchX;
			LastTouchLocation.Y = TouchY;
			SetNubPosition(TouchX);
		}
	}
	else if(EventType == ZoneEvent_Update || EventType == ZoneEvent_Stationary)
	{
		if(bActive)
		{
			CurrentTouchLocation.X = TouchX;
			CurrentTouchLocation.Y = TouchY;
			SetNubPosition(TouchX);
			CheckSwipe();
		}
	}
	else if(EventType == ZoneEvent_Untouch)
	{
		if(bHasCancel && !CheckBounds(TouchX, TouchY))
			SetNubPosition(LastTouchLocation.X);
		NESettingsMenu(OwnerScene).SaveSliderValue(Tag, GetSliderValue());
		bActive = false;
		TouchOffset = 0.0;
	}
	else if(EventType == ZoneEvent_Cancelled)
	{
		bActive = false;
	}
	return true;
}

function bool CheckHitNub(float X, float Y)
{
	X -= (OwnerScene.Left + Left);
	Y -= OwnerScene.Top;
	if(X >= GetNubPixelLeft() && X <= GetNubPixelLeft() + NubWidth && Y >= Top && Y <= Top + NubHeight)
		return true;
	return false;
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
	ImageColor=(r=1.0,g=1.0,b=1.0,a=1.0)
	bIsActive=true;
	bActive=false;
	TouchOffset=0.0
	SwipeTolerance=5.0
}
