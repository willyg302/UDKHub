class NEPauseMenu extends MobileMenuScene;

event OnTouch(MobileMenuObject Sender, EZoneTouchEvent EventType, float TouchX, float TouchY)
{
	if(Sender == none || EventType != ZoneEvent_UnTouch)
		return;
	if(Sender.Tag ~= "RESUME")
	{
		if(InputOwner != none)
		{
			InputOwner.Outer.SetPause(false);
			InputOwner.CloseMenuScene(self);
		}
	}
	else if(Sender.Tag ~= "RESTART")
	{
		if(InputOwner != none && NEPlayerController(InputOwner.Outer) != none)
		{
			NEPlayerController(InputOwner.Outer).RestartLevel();
		}
	}
	else if(Sender.Tag ~= "MAIN")
	{
		if(InputOwner != none && NEPlayerController(InputOwner.Outer) != none)
		{
			NEPlayerController(InputOwner.Outer).ClearRestarts();
		}
		class'WorldInfo'.static.GetWorldInfo().Game.ConsoleCommand("open NE-MFront");
	}
}

event bool OnSceneTouch(EZoneTouchEvent EventType, float TouchX, float TouchY, bool bInside)
{
	return true;
}

defaultproperties
{
	Left=0.26458
	Top=0.32344
	Width=0.47083
	Height=0.35313
	bRelativeLeft=true
	bRelativeTop=true
	bRelativeWidth=true
	bRelativeHeight=true


	Begin Object Class=MobileMenuImage Name=Background
		Tag="Background"
		Left=0
		Top=0
		Width=1
		Height=1
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		Image=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImageDrawStyle=IDS_Stretched
		ImageUVs=(bCustomCoords=true,U=0,V=0,UL=452,VL=226)
	End Object
	MenuObjects.Add(Background)

	Begin Object Class=MobileMenuButton Name=ResumeButton
		Tag="RESUME"
		Left=0.0531
		Top=0.10619
		Width=0.41372
		Height=0.32743
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		Images(0)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		Images(1)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImagesUVs(0)=(bCustomCoords=true,U=0,V=226,UL=187,VL=74)
		ImagesUVs(1)=(bCustomCoords=true,U=0,V=374,UL=187,VL=74)
	End Object
	MenuObjects.Add(ResumeButton)

	Begin Object Class=MobileMenuButton Name=RestartButton
		Tag="RESTART"
		Left=0.53319
		Top=0.10619
		Width=0.41372
		Height=0.32743
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		Images(0)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		Images(1)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImagesUVs(0)=(bCustomCoords=true,U=217,V=226,UL=187,VL=74)
		ImagesUVs(1)=(bCustomCoords=true,U=217,V=374,UL=187,VL=74)
	End Object
	MenuObjects.Add(RestartButton)

	Begin Object Class=MobileMenuButton Name=MainButton
		Tag="MAIN"
		Left=0.0531
		Top=0.56637
		Width=0.89381
		Height=0.32743
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		Images(0)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		Images(1)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImagesUVs(0)=(bCustomCoords=true,U=0,V=300,UL=404,VL=74)
		ImagesUVs(1)=(bCustomCoords=true,U=0,V=448,UL=404,VL=74)
	End Object
	MenuObjects.Add(MainButton)
}
