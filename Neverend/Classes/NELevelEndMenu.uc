class NELevelEndMenu extends MobileMenuScene;

event OnTouch(MobileMenuObject Sender, EZoneTouchEvent EventType, float TouchX, float TouchY)
{
	if(Sender == none)
		return;
	if(Sender.Tag ~= "CONTINUE")
	{
		if(InputOwner != none && NEPlayerController(InputOwner.Outer) != none)
		{
			NEPlayerController(InputOwner.Outer).NextLevel();
		}
	}
	else if(Sender.Tag ~= "MAIN")
	{
		class'WorldInfo'.static.GetWorldInfo().Game.ConsoleCommand("open NE-MFront");
	}
}

event bool OnSceneTouch(EZoneTouchEvent EventType, float TouchX, float TouchY, bool bInside)
{
	return true;
}

function SetLabelValues(int Time, int Deaths, int Restarts, int Points)
{
	local int Hours, Mins, Seconds;
	local string NewTimeString;

	Seconds = Time;
	Hours = Seconds / 3600;
	Seconds -= Hours * 3600;
	Mins = Seconds / 60;
	Seconds -= Mins * 60;
	NewTimeString = (Hours > 0) ? (string(Hours) $ ":"): "";
	if(Hours > 0)
	{
		NewTimeString = NewTimeString $ ((Mins > 9) ? string(Mins) : ("0" $ string(Mins))) $ ":";
	}
	else
	{
		NewTimeString = NewTimeString $ string(Mins) $ ":";
	}
	NewTimeString = NewTimeString $ ((Seconds > 9) ? string(Seconds) : ("0" $ string(Seconds)));
	
	NEMenuLabel(FindMenuObject("TIME")).Caption = NewTimeString;
	NEMenuLabel(FindMenuObject("DEATHS")).Caption = string(Deaths);
	NEMenuLabel(FindMenuObject("RESTARTS")).Caption = string(Restarts);
	NEMenuLabel(FindMenuObject("POINTS")).Caption = string(Points);
}

defaultproperties
{
	
	Left=0.14896
	Top=0.21719
	Width=0.70313
	Height=0.56719
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
		ImageUVs=(bCustomCoords=true,U=452,V=0,UL=675,VL=363)
	End Object
	MenuObjects.Add(Background)

	Begin Object Class=MobileMenuButton Name=MainButton
		Tag="MAIN"
		Left=0.03556
		Top=0.73003
		Width=0.44296
		Height=0.20386
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		Images(0)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		Images(1)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImagesUVs(0)=(bCustomCoords=true,U=0,V=522,UL=299,VL=74)
		ImagesUVs(1)=(bCustomCoords=true,U=0,V=670,UL=299,VL=74)
	End Object
	MenuObjects.Add(MainButton)

	Begin Object Class=MobileMenuButton Name=ContinueButton
		Tag="CONTINUE"
		Left=0.52148
		Top=0.73003
		Width=0.44296
		Height=0.20386
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		Images(0)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		Images(1)=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImagesUVs(0)=(bCustomCoords=true,U=0,V=596,UL=299,VL=74)
		ImagesUVs(1)=(bCustomCoords=true,U=0,V=744,UL=299,VL=74)
	End Object
	MenuObjects.Add(ContinueButton)


	Begin Object Class=NEMenuLabel Name=TimeLabel
		Tag="TIME"
		Left=0.21778
		Top=0.33884
		bRelativeLeft=true
		bRelativeTop=true

		Caption="99:99:99"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(TimeLabel)

	Begin Object Class=NEMenuLabel Name=DeathsLabel
		Tag="DEATHS"
		Left=0.73926
		Top=0.33884
		bRelativeLeft=true
		bRelativeTop=true

		Caption="9999"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(DeathsLabel)

	Begin Object Class=NEMenuLabel Name=RestartsLabel
		Tag="RESTARTS"
		Left=0.73926
		Top=0.53994
		bRelativeLeft=true
		bRelativeTop=true

		Caption="9999"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(RestartsLabel)

	Begin Object Class=NEMenuLabel Name=PointsLabel
		Tag="POINTS"
		Left=0.35111
		Top=0.53994
		bRelativeLeft=true
		bRelativeTop=true

		Caption="99999"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(PointsLabel)
}
