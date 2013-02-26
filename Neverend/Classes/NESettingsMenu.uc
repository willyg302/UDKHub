class NESettingsMenu extends MobileMenuScene;

struct ButtonBounds
{
	var float Left, Right, Top, Bottom;
};

// 0 = General, 1 = Player, 2 = Credits
var int CurTab;

// BACKGROUNDS/TABS
var MobileMenuObject GenBack, PlayBack, CredBack;
var ButtonBounds GenTab, PlayTab, CredTab, CloseButton;

// GENERAL TAB
var MobileMenuSlider MusicVolume, FXVolume;
var ButtonBounds InvertMovement, FlipControls;

// PLAYER TAB
var NEMenuLabel TimeLabel, DeathsLabel, RestartsLabel, PointsLabel;
var MobileMenuHorizSweeper Achievements, LevelSweeper;
var ButtonBounds ReplayButton;

// So we don't switch all the time!
var float LastTabSwitchTime, TabSwitchThreshold;
var NEPlayerController PC;

var float ScreenRatioX, ScreenRatioY;

// Only really for the replay button, so it responds like a regular MobileMenuButton
var bool bButtonPressed;


function ButtonBounds SetUpBounds(float X, float Y, float L, float R, float T, float B)
{
	local ButtonBounds bb;
	bb.Left = X*L;
	bb.Right = X*R;
	bb.Top = Y*T;
	bb.Bottom = Y*B;
	return bb;
}

function bool IsInBounds(ButtonBounds bb, float X, float Y)
{
	return (X > bb.Left && X < bb.Right && Y > bb.Top && Y < bb.Bottom);
}

event InitMenuScene(MobilePlayerInput PlayerInput, int ScreenWidth, int ScreenHeight, bool bIsFirstInitialization)
{
	super.InitMenuScene(PlayerInput, ScreenWidth, ScreenHeight, bIsFirstInitialization);

	PC = NEPlayerController(PlayerInput.Outer);
	
	ScreenRatioX = float(ScreenWidth) / 960.0;
	ScreenRatioY = float(ScreenHeight) / 640.0;

	// TABS
	GenTab = SetUpBounds(ScreenRatioX, ScreenRatioY, 132, 359, 97, 166);
	PlayTab = SetUpBounds(ScreenRatioX, ScreenRatioY, 359, 547, 97, 166);
	CredTab = SetUpBounds(ScreenRatioX, ScreenRatioY, 547, 748, 97, 166);
	CloseButton = SetUpBounds(ScreenRatioX, ScreenRatioY, 748, 829, 85, 166);

	// BACKGROUNDS
	GenBack = FindMenuObject("GENBACK");
	PlayBack = FindMenuObject("PLAYBACK");
	CredBack = FindMenuObject("CREDBACK");

	// GENERAL TAB
	MusicVolume = MobileMenuSlider(FindMenuObject("MUSIC"));
	FXVolume = MobileMenuSlider(FindMenuObject("EFFECTS"));
	InvertMovement = SetUpBounds(ScreenRatioX, ScreenRatioY, 171, 249, 428, 506);
	FlipControls = SetUpBounds(ScreenRatioX, ScreenRatioY, 506, 584, 428, 506);

	// PLAYER TAB
	TimeLabel = NEMenuLabel(FindMenuObject("TIME"));
	DeathsLabel = NEMenuLabel(FindMenuObject("DEATHS"));
	RestartsLabel = NEMenuLabel(FindMenuObject("RESTARTS"));
	PointsLabel = NEMenuLabel(FindMenuObject("POINTS"));
	Achievements = MobileMenuHorizSweeper(FindMenuObject("ACHIEVE"));
	LevelSweeper = MobileMenuHorizSweeper(FindMenuObject("LEVEL"));
	ReplayButton = SetUpBounds(ScreenRatioX, ScreenRatioY, 170, 297, 415, 489);
	
	SetValues();
}

event bool OnSceneTouch(EZoneTouchEvent EventType, float TouchX, float TouchY, bool bInside)
{
	if(EventType == ZoneEvent_Touch || EventType == ZoneEvent_Update || EventType == ZoneEvent_Stationary)
	{
		bButtonPressed = (IsInBounds(ReplayButton, TouchX, TouchY) && CurTab == 1);
	}
		
	if(EventType != ZoneEvent_UnTouch)
		return true;
	bButtonPressed = false;
	if(IsInBounds(InvertMovement, TouchX, TouchY) && CurTab == 0)
	{
		PC.myGame.savefile.bInvertMovement = !PC.myGame.savefile.bInvertMovement;
		PC.myGame.SaveGame();
	}
	if(IsInBounds(FlipControls, TouchX, TouchY) && CurTab == 0)
	{
		PC.myGame.savefile.bFlipControls = !PC.myGame.savefile.bFlipControls;
		PC.myGame.SaveGame();
	}
	if(IsInBounds(ReplayButton, TouchX, TouchY) && CurTab == 1)
		PC.LoadLevel(LevelSweeper.GetSweeperValue());
	if(IsInBounds(CloseButton, TouchX, TouchY))
	{
		if(InputOwner != none)
		{
			if(PC != none)
				PC.bSettingsMenuOpen = false;
			InputOwner.CloseMenuScene(self);
		}
	}
	if(IsInBounds(GenTab, TouchX, TouchY))
		SwitchTab(0);
	if(IsInBounds(PlayTab, TouchX, TouchY))
		SwitchTab(1);
	if(IsInBounds(CredTab, TouchX, TouchY))
		SwitchTab(2);
	if(PC == none)
		return true;
	PC.myGame.savefile.CurSettingsTab = CurTab;
	PC.myGame.SaveGame();
	
	return true;
}

function SaveSliderValue(string Tag, float Value)
{
	if(Tag ~= "MUSIC")
		PC.myGame.AdjustMusicVolume(Value);
	if(Tag ~= "EFFECTS")
		PC.myGame.savefile.SFXVolume = Value;
	PC.myGame.SaveGame();
}

function SaveSweeperValue(string Tag, int Value)
{
	if(Tag ~= "ACHIEVE")
		PC.myGame.savefile.CurSettingsAchievement = Value;
	if(Tag ~= "LEVEL")
		PC.myGame.savefile.CurSettingsLevel = Value;
	PC.myGame.SaveGame();
}

function RenderSweeper(string Tag, canvas Canvas, int Value, float SweepLeft, float SweepTop, float SweepOpacity)
{
	local int UnlockedY;
	local LinearColor DrawColor;
	Canvas.SetDrawColor(255, 255, 255, 255 * Opacity * SweepOpacity);
	Canvas.Font = Font'Never_End_MAssets.Armata';
	
	if(Tag ~= "ACHIEVE")
	{
		Canvas.SetPos(Left + SweepLeft, Top + SweepTop);
		DrawColor.R = 1.0;
		DrawColor.G = 1.0;
		DrawColor.B = 1.0;
		DrawColor.A *= (Opacity * SweepOpacity);
		UnlockedY = (bool(PC.myGame.savefile.UnlockedAchievements[Value]) ? 876 : 818);
		Canvas.DrawTile(Texture2D'Never_End_MAssets.Textures.Menu_T', 59 * ScreenRatioX, 58 * ScreenRatioY,
				128, UnlockedY, 59, 58, DrawColor);

		Canvas.SetPos(Left + SweepLeft + (79 * ScreenRatioX), Top + SweepTop + (2 * ScreenRatioY));
		Canvas.DrawText(PC.myGame.AchievementHandler.AchievementArray[Value].Title,, 0.5*ScreenRatioX, 0.5*ScreenRatioY);

		Canvas.SetDrawColor(187, 187, 187, 255 * Opacity * SweepOpacity);
		Canvas.SetPos(Left + SweepLeft + (79*ScreenRatioX), Top + SweepTop + (34*ScreenRatioY));
		Canvas.DrawText(PC.myGame.AchievementHandler.AchievementArray[Value].Description
				$ " (+" $ PC.myGame.AchievementHandler.AchievementArray[Value].Points $ ")",, 0.375*ScreenRatioX, 0.375*ScreenRatioY);
	}
	if(Tag ~= "LEVEL")
	{
		SetPlayerLabelValues(Value);
		Canvas.SetPos(Left + SweepLeft, Top + SweepTop);
		
		if(Value == 0)
		{
			Canvas.DrawText("Play Current Level",, ScreenRatioX, ScreenRatioY);
		}
		else
		{
			// BIG NUMBER
			Canvas.SetPos(Left + SweepLeft, Top + SweepTop - (16 * ScreenRatioY));
			Canvas.DrawText(Value,, 1.5*ScreenRatioX, 1.5*ScreenRatioY);
			// TITLE
			Canvas.SetPos(Left + SweepLeft + (103*ScreenRatioX), Top + SweepTop - (2*ScreenRatioY));
			Canvas.DrawText(PC.myGame.maps.MapArray[Value - 1].Title,, 0.75*ScreenRatioX, 0.75*ScreenRatioY);
			// DESCRIPTION
			Canvas.SetDrawColor(187, 187, 187, 255 * Opacity * SweepOpacity);
			Canvas.SetPos(Left + SweepLeft + (103*ScreenRatioX), Top + SweepTop + (41*ScreenRatioY));
			Canvas.DrawText(PC.myGame.maps.MapArray[Value - 1].Description1,, 0.375*ScreenRatioX, 0.375*ScreenRatioY);
			Canvas.SetPos(Left + SweepLeft + (103*ScreenRatioX), Top + SweepTop + (62*ScreenRatioY));
			Canvas.DrawText(PC.myGame.maps.MapArray[Value - 1].Description2,, 0.375*ScreenRatioX, 0.375*ScreenRatioY);
		}
	}
}

function SwitchTab(int Tab)
{
	CurTab = Tab;
	
	GenBack.bIsHidden = (Tab != 0);
	PlayBack.bIsHidden = (Tab != 1);
	CredBack.bIsHidden = (Tab != 2);

	// GENERAL
	MusicVolume.bIsHidden = (Tab != 0);
	FXVolume.bIsHidden = (Tab != 0);
	MusicVolume.bIsActive = (Tab == 0);
	FXVolume.bIsActive = (Tab == 0);

	// PLAYER
	TimeLabel.bIsHidden = (Tab != 1);
	DeathsLabel.bIsHidden = (Tab != 1);
	RestartsLabel.bIsHidden = (Tab != 1);
	PointsLabel.bIsHidden = (Tab != 1);
	Achievements.bIsHidden = (Tab != 1);
	LevelSweeper.bIsHidden = (Tab != 1);
	Achievements.bIsActive = (Tab == 1);
	LevelSweeper.bIsActive = (Tab == 1);
}

function SetValues()
{
	if(PC == none)
		return;

	// GENERAL
	MusicVolume.SetSliderValue(PC.myGame.savefile.MusicVolume);
	FXVolume.SetSliderValue(PC.myGame.savefile.SFXVolume);

	// PLAYER
	SetPlayerLabelValues(PC.myGame.savefile.CurSettingsLevel);
	Achievements.SetSweeperMax(PC.myGame.AchievementHandler.AchievementArray.Length - 1);
	Achievements.SetSweeperValue(PC.myGame.savefile.CurSettingsAchievement);
	LevelSweeper.SetSweeperMax(PC.myGame.savefile.Level);
	LevelSweeper.SetSweeperValue(PC.myGame.savefile.CurSettingsLevel);
	
	SwitchTab(PC.myGame.savefile.CurSettingsTab);
}

function SetPlayerLabelValues(int CurLevel)
{
	local int Hours, Mins, Seconds;
	local string NewTimeString;
	local int Time, Deaths, Restarts, Points;
	if(PC == none)
		return;
	if(CurLevel == 0 || CurLevel == PC.myGame.savefile.Level)
	{
		Time = PC.myGame.savefile.Time;
		Deaths = PC.myGame.savefile.Deaths;
		Restarts = PC.myGame.savefile.Restarts;
		Points = PC.myGame.savefile.Points;
	}
	else
	{
		Time = PC.myGame.savefile.LevelTime[CurLevel-1];
		Deaths = PC.myGame.savefile.LevelDeaths[CurLevel-1];
		Restarts = PC.myGame.savefile.LevelRestarts[CurLevel-1];
		Points = PC.myGame.savefile.LevelPoints[CurLevel-1];
	}
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
	
	TimeLabel.Caption = NewTimeString;
	DeathsLabel.Caption = string(Deaths);
	RestartsLabel.Caption = string(Restarts);
	PointsLabel.Caption = string(Points);
}

function RenderScene(Canvas Canvas,float RenderDelta)
{
	local LinearColor DrawColor;
	local Texture2D MenuT;
	local int YIdx;
	super.RenderScene(Canvas, RenderDelta);
	
	Canvas.SetDrawColor(255, 255, 255, 255 * Opacity);
	MenuT = Texture2D'Never_End_MAssets.Textures.Menu_T';
	DrawColor.R = 1.0;
	DrawColor.G = 1.0;
	DrawColor.B = 1.0;
	DrawColor.A *= Opacity;
	if(CurTab == 0)
	{
		YIdx = (PC.myGame.savefile.bInvertMovement) ? 681 : 603;
		Canvas.SetPos(InvertMovement.Left, InvertMovement.Top);
		Canvas.DrawTile(MenuT, 78*ScreenRatioX, 78*ScreenRatioY, 300, YIdx, 78, 78, DrawColor);
		YIdx = (PC.myGame.savefile.bFlipControls) ? 681 : 603;
		Canvas.SetPos(FlipControls.Left, FlipControls.Top);
		Canvas.DrawTile(MenuT, 78*ScreenRatioX, 78*ScreenRatioY, 300, YIdx, 78, 78, DrawColor);

	}
	if(CurTab == 1)
	{
		YIdx = (bButtonPressed) ? 892 : 818;
		Canvas.SetPos(ReplayButton.Left, ReplayButton.Top);
		Canvas.DrawTile(MenuT, 127*ScreenRatioX, 74*ScreenRatioY, 0, YIdx, 127, 74, DrawColor);
	}
}



defaultproperties
{
	Left=0.1375
	Top=0.13282
	Width=0.72605
	Height=0.70782
	bRelativeLeft=true
	bRelativeTop=true
	bRelativeWidth=true
	bRelativeHeight=true


	/**
	 * MENU STUFF:
	 * 
	 * Width:  829 - 132 = 697
	 * Height: 538 - 85 = 453
	 */

	Begin Object Class=MobileMenuImage Name=GenBack
		Tag="GENBACK"
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
		ImageUVs=(bCustomCoords=true,U=1127,V=0,UL=697,VL=453)
	End Object
	MenuObjects.Add(GenBack)

	Begin Object Class=MobileMenuImage Name=PlayBack
		Tag="PLAYBACK"
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
		ImageUVs=(bCustomCoords=true,U=430,V=453,UL=697,VL=453)
	End Object
	MenuObjects.Add(PlayBack)

	Begin Object Class=MobileMenuImage Name=CredBack
		Tag="CREDBACK"
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
		ImageUVs=(bCustomCoords=true,U=1127,V=453,UL=697,VL=453)
	End Object
	MenuObjects.Add(CredBack)


	// GENERAL TAB

	Begin Object Class=MobileMenuSlider Name=MusicVolume
		Tag="MUSIC"
		Left=0.28407
		Top=0.25607
		Width=0.49928
		Height=0.08389
		NubWidth=1
		NubHeight=1
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		bRelativeNubWidth=true
		bRelativeNubHeight=true
		SliderMin=0.0
		SliderMax=1.0
		bIncremental=true
		Image=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImageUV=(bCustomCoords=true,U=300,V=760,UL=38,VL=38)
	End Object
	MenuObjects.Add(MusicVolume)

	Begin Object Class=MobileMenuSlider Name=FXVolume
		Tag="EFFECTS"
		Left=0.28407
		Top=0.44371
		Width=0.49928
		Height=0.08389
		NubWidth=1
		NubHeight=1
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		bRelativeNubWidth=true
		bRelativeNubHeight=true
		SliderMin=0.0
		SliderMax=1.5
		bIncremental=false
		Image=Texture2D'Never_End_MAssets.Textures.Menu_T'
		ImageUV=(bCustomCoords=true,U=300,V=760,UL=38,VL=38)
	End Object
	MenuObjects.Add(FXVolume)


	// PLAYER TAB

	Begin Object Class=NEMenuLabel Name=TimeLabel
		Tag="TIME"
		Left=0.37159
		Top=0.22075
		bRelativeLeft=true
		bRelativeTop=true
		TextXScale=0.75
		TextYScale=0.75

		Caption="999:99:99"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(TimeLabel)

	Begin Object Class=NEMenuLabel Name=DeathsLabel
		Tag="DEATHS"
		Left=0.74892
		Top=0.22075
		bRelativeLeft=true
		bRelativeTop=true
		TextXScale=0.75
		TextYScale=0.75

		Caption="99999"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(DeathsLabel)

	Begin Object Class=NEMenuLabel Name=RestartsLabel
		Tag="RESTARTS"
		Left=0.74892
		Top=0.34216
		bRelativeLeft=true
		bRelativeTop=true
		TextXScale=0.75
		TextYScale=0.75

		Caption="99999"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(RestartsLabel)

	Begin Object Class=NEMenuLabel Name=PointsLabel
		Tag="POINTS"
		Left=0.46915
		Top=0.34216
		bRelativeLeft=true
		bRelativeTop=true
		TextXScale=0.75
		TextYScale=0.75

		Caption="99999"
		TextFont=Font'Never_End_MAssets.Armata'
		TextColor=(R=250,G=250,B=250,A=255);
		TouchedColor=(R=250,G=250,B=250,A=255);
	End Object
	MenuObjects.Add(PointsLabel)

	Begin Object Class=MobileMenuHorizSweeper Name=Achievements
		Tag="ACHIEVE"
		Left=0.27116
		Top=0.50993
		Width=0.65710
		Height=0.12804
		
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		
		SweeperMax=0 // Dynamic, will be written later
	End Object
	MenuObjects.Add(Achievements)

	Begin Object Class=MobileMenuHorizSweeper Name=LevelSweeper
		Tag="LEVEL"
		Left=0.27116
		Top=0.74614
		Width=0.65710
		Height=0.21413
		
		bRelativeLeft=true
		bRelativeTop=true
		bRelativeWidth=true
		bRelativeHeight=true
		
		SweeperMax=0 // Dynamic, will be written later
	End Object
	MenuObjects.Add(LevelSweeper)
}
