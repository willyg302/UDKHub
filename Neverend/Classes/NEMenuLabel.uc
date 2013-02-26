class NEMenuLabel extends MobileMenuLabel;

var float ScreenRatioX, ScreenRatioY;

function InitMenuObject(MobilePlayerInput PlayerInput, MobileMenuScene Scene, int ScreenWidth, int ScreenHeight, bool bIsFirstInitialization)
{
	ScreenRatioX = float(ScreenWidth) / 960.0;
	ScreenRatioY = float(ScreenHeight) / 640.0;
	super.InitMenuObject(PlayerInput, Scene, ScreenWidth, ScreenHeight, bIsFirstInitialization);
}

function RenderObject(canvas Canvas, float DeltaTime)
{
	Canvas.Font = TextFont;
	Canvas.DrawColor = bIsTouched ? TouchedColor : TextColor;
	Canvas.DrawColor.A *= Opacity * OwnerScene.Opacity;
	Canvas.SetPos(OwnerScene.Left + Left, OwnerScene.Top + Top);
	Canvas.DrawText(Caption,,TextXScale*ScreenRatioX, TextYScale*ScreenRatioY);
}
