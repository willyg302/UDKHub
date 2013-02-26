class NEMobileHUD extends MobileHUD;

var NEGame myGame;

var Texture2D MainTexture;
var Font ArmataFont, MessageFont;
var float LastTime;
var Color MessageColor;

// WILL NOT CHANGE...Initialized in PostBeginPlay()
var vector2D ViewportSize;
var float ScaleFactorX, ScaleFactorY;

struct native Announce
{
	var string Text[4];
	var bool bBeginMessage;
};
var array<Announce> Announces;

struct native AchievementMessage
{
	var string Title;
	var int Points;
};
var array<AchievementMessage> AchievementMessages;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	myGame = NEGame(PlayerOwner.WorldInfo.Game);
	LocalPlayer(PlayerOwner.Player).ViewportClient.GetViewportSize(ViewportSize);
	// Our default is iPhone 4
	ScaleFactorX = ViewportSize.X/960;
	ScaleFactorY = ViewportSize.Y/640;
}

function bool ShowMobileHud()
{
	return bShowMobileHud && bShowHud;
}

/* ANNOUNCEMENTS */

function AddAnnounce(NESeqAct_PlayAnnouncement action)
{
	local Announce temp;
	temp.Text[0] = action.AnnouncementOne;
	temp.Text[1] = action.AnnouncementTwo;
	temp.Text[2] = action.AnnouncementThree;
	temp.Text[3] = action.AnnouncementFour;
	temp.bBeginMessage = false;
	Announces.AddItem(temp);
}

function AddBegin(string level, string title, string descOne, string descTwo)
{
	local Announce temp;
	temp.Text[0] = level;
	temp.Text[1] = title;
	temp.Text[2] = descOne;
	temp.Text[3] = descTwo;
	temp.bBeginMessage = true;
	Announces.AddItem(temp);
}

function RemoveAnnounce()
{
	if(Announces.Length > 0)
		Announces.Remove(0,1);
	if(Announces.Length == 0)
		myGame.TogglePause(false);
}

/* ACHIEVEMENTS */

function AddAchievementMessage(string Title, int Points)
{
	local AchievementMessage temp;
	temp.Title = Title;
	temp.Points = Points;
	if(AchievementMessages.Length == 0)
	{
		SetTimer(3.0, false, 'RemoveAchievementMessage');
		myGame.AchievementHandler.PlayAchievementPing();
	}
	AchievementMessages.AddItem(temp);
}

function RemoveAchievementMessage()
{
	if(AchievementMessages.Length > 0)
		AchievementMessages.Remove(0,1);
	if(AchievementMessages.Length > 0)
	{
		SetTimer(3.0, false, 'RemoveAchievementMessage');
		myGame.AchievementHandler.PlayAchievementPing();
	}
}

function DrawTime()
{
	local int Hours, Mins, Seconds;
	local string NewTimeString;
	local float XL, YL;

	Seconds = PlayerOwner.WorldInfo.TimeSeconds;
	if(Seconds != LastTime && !myGame.bIsPaused)
	{
		myGame.savefile.CurTime++;
		LastTime = Seconds;
	}
	
	Seconds = myGame.savefile.CurTime + (myGame.savefile.bBeatGame ? 0 : myGame.savefile.Time);
	//Seconds = myGame.savefile.Time - ReplayTime;
	
	Hours = Seconds / 3600;
	Seconds -= Hours * 3600;
	Mins = Seconds / 60;
	Seconds -= Mins * 60;
	NewTimeString = ((Hours > 99) ? String(Hours) : ("0" $ ((Hours > 9) ? String(Hours) : ("0" $ String(Hours))))) $ ":";
	NewTimeString = NewTimeString $ ((Mins > 9) ? String(Mins) : ("0" $ String(Mins))) $ ":";
	NewTimeString = NewTimeString $ ((Seconds > 9) ? String(Seconds) : ("0" $ String(Seconds)));

	Canvas.SetPos(ViewportSize.X/3, 0);
	Canvas.SetDrawColor(255,255,255,255);
	Canvas.DrawTile(MainTexture, ViewportSize.X/3, ViewportSize.Y * 0.1125, 0,0, 316, 72);

	Canvas.Font = ArmataFont;
	Canvas.StrLen(NewTimeString,XL,YL);
	XL *= ScaleFactorX;
	YL *= ScaleFactorY;
	Canvas.SetPos((ViewportSize.X - XL)/2, (ViewportSize.Y*0.1125 - YL)/2);
	Canvas.DrawColor = ButtonCaptionColor;
	Canvas.DrawText(NewTimeString,,ScaleFactorX, ScaleFactorY);

}

function DrawAnnounce()
{
	local float XL, YL;
	local int i;
	Canvas.SetPos(0, ViewportSize.Y * 0.625);
	Canvas.SetDrawColor(255,255,255,255);
	Canvas.DrawTile(MainTexture, ViewportSize.X, ViewportSize.Y /4, 0,80, 1024, 160);

	if(Announces[0].bBeginMessage)
	{
		Canvas.Font = ArmataFont;
		Canvas.DrawColor = MessageColor;
		Canvas.SetPos(100 * ScaleFactorX, ViewportSize.Y*0.625 + 23 * ScaleFactorY);
		Canvas.DrawText(Announces[0].Text[0],,2*ScaleFactorX, 2*ScaleFactorY);
		Canvas.SetPos(300 * ScaleFactorX, ViewportSize.Y*0.625 + 10 * ScaleFactorY);
		Canvas.DrawText(Announces[0].Text[1],,ScaleFactorX, ScaleFactorY);
		Canvas.Font = MessageFont;
		for(i = 0; i < 2; i++)
		{
			Canvas.SetPos(300 * ScaleFactorX, ViewportSize.Y*0.625 + 82 * ScaleFactorY  + 35 * i * ScaleFactorY);
			Canvas.DrawText(Announces[0].Text[2+i],,ScaleFactorX, ScaleFactorY);
		}
	}
	else
	{
		Canvas.SetPos(55 * ScaleFactorX, 417 * ScaleFactorY);
		Canvas.DrawTile(MainTexture,140 * ScaleFactorX, 126 * ScaleFactorY, 0,243, 140, 126);
		Canvas.Font = MessageFont;
		Canvas.DrawColor = MessageColor;
		for(i = 0; i < 4; i++)
		{
			Canvas.StrLen(Announces[0].Text[i],XL,YL);
			Canvas.SetPos(250 * ScaleFactorX, ViewportSize.Y*0.625 + 12 * ScaleFactorY + 36 * i * ScaleFactorY);
			Canvas.DrawText(Announces[0].Text[i],,ScaleFactorX, ScaleFactorY);
		}
	}
}

function DrawAchievementMessage()
{
	local float RampIn, RampPos;
	RampIn = FClamp(GetTimerCount('RemoveAchievementMessage'), 0.0, 0.5);
	RampPos = Lerp(500, 960, 1 - 2*RampIn);
	Canvas.Font = ArmataFont;
	Canvas.SetDrawColor(255,255,255,255);
	// Back
	Canvas.SetPos(RampPos * ScaleFactorX, 530 * ScaleFactorY);
	Canvas.DrawTile(MainTexture, 480 * ScaleFactorX, 80 * ScaleFactorY, 544, 243, 480, 80);
	// Icon
	Canvas.SetPos((RampPos + 23) * ScaleFactorX, 541 * ScaleFactorY);
	Canvas.DrawTile(Texture2D'Never_End_MAssets.Textures.Menu_T', 59 * ScaleFactorX, 58 * ScaleFactorY, 128, 876, 59, 58);
	if(RampIn < 0.5)
		return;
	// Title
	Canvas.SetPos((RampPos + 102) * ScaleFactorX, 543 * ScaleFactorY);
	Canvas.DrawText(AchievementMessages[0].Title,,0.5 * ScaleFactorX, 0.5 * ScaleFactorY);
	// Description
	Canvas.SetDrawColor(187, 187, 187, 255);
	Canvas.SetPos((RampPos + 102) * ScaleFactorX, 575 * ScaleFactorY);
	Canvas.DrawText("You have earned " $ string(AchievementMessages[0].Points) $ " points!"
			,,0.375 * ScaleFactorX, 0.375 * ScaleFactorY);
}

function PostRender()
{
	super.PostRender();
	if(!ShowMobileHud())
		return;
	// TIME
	if(!myGame.bIsEntryGame)
		DrawTime();
	if(Announces.Length > 0)
		DrawAnnounce();
	if(AchievementMessages.Length > 0)
		DrawAchievementMessage();
}

defaultproperties
{
	ButtonFont = Font'EngineFonts.SmallFont'
	ButtonCaptionColor=(R=0,G=0,B=0,A=255);
	MessageColor=(R=250,G=250,B=250,A=255);
	MainTexture=Texture2D'Never_End_MAssets.Textures.Mobile_T'
	ArmataFont=Font'Never_End_MAssets.Armata'
	MessageFont=Font'Never_End_MAssets.Armata_Small'
}
