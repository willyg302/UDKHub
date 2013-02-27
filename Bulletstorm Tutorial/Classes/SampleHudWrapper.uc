class SampleHudWrapper extends UTHUDBase;

var GFxSampleHUD HudMovie;
var class<GFxSampleHUD> MinimapHUDClass;

singular event Destroyed()
{
	RemoveMovies();
	Super.Destroyed();
}

function RemoveMovies()
{
	if(HUDMovie != None)
	{
		HUDMovie.Close(true);
		HUDMovie = None;
	}
	Super.RemoveMovies();
}

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	CreateHUDMovie();
}

function CreateHUDMovie()
{
	HudMovie = new MinimapHUDClass;
	HudMovie.SetTimingMode(TM_Real);
	HudMovie.Init(class'Engine'.static.GetEngine().GamePlayers[HudMovie.LocalPlayerOwnerIndex]);
	HudMovie.ToggleCrosshair(true);
}

function int GetLocalPlayerOwnerIndex()
{
	return HudMovie.LocalPlayerOwnerIndex;
}

function SetVisible(bool bNewVisible)
{
	HudMovie.ToggleCrosshair(bNewVisible);
	Super.SetVisible(bNewVisible);
}

function DisplayHit(vector HitDir, int Damage, class<DamageType> damageType)
{
	HudMovie.DisplayHit(HitDir, Damage, DamageType);
}

function ResolutionChanged()
{
	super.ResolutionChanged();
	CreateHUDMovie();
}

event PostRender()
{
	super.PostRender();
	if(HudMovie != none)
		HudMovie.TickHud(0);
	if(bShowHud && bEnableActorOverlays)
		DrawHud();
}

event DrawHUD()
{
	local vector ViewPoint;
	local rotator ViewRotation;
	local float XL, YL, YPos;

	if (UTGRI != None && !UTGRI.bMatchIsOver  )
	{
		Canvas.Font = GetFontSizeIndex(0);
		PlayerOwner.GetPlayerViewPoint(ViewPoint, ViewRotation);
		DrawActorOverlays(Viewpoint, ViewRotation);
	}

	if ( bCrosshairOnFriendly )
	{
		// verify that crosshair trace might hit friendly
		bGreenCrosshair = CheckCrosshairOnFriendly();
		bCrosshairOnFriendly = false;
	}
	else
	{
		bGreenCrosshair = false;
	}



	if ( bShowDebugInfo )
	{
		Canvas.Font = GetFontSizeIndex(0);
		Canvas.DrawColor = ConsoleColor;
		Canvas.StrLen("X", XL, YL);
		YPos = 0;
		PlayerOwner.ViewTarget.DisplayDebug(self, YL, YPos);

		if (ShouldDisplayDebug('AI') && (Pawn(PlayerOwner.ViewTarget) != None))
		{
			DrawRoute(Pawn(PlayerOwner.ViewTarget));
		}
		return;
	}
}

function AddConsoleMessage(string M, class<LocalMessage> InMessageClass, PlayerReplicationInfo PRI, optional float LifeTime) {}

function AddPointMessage(string M, vector Loc, bool bLocked, optional float LifeTime, optional int LocPos)
{
    HudMovie.AddPointMessage(M, Loc, bLocked, LifeTime, LocPos);
}

function AddPointMessageQueue(string M,optional float LifeTime)
{
    HudMovie.AddPointMessageQueue(M, LifeTime);
}

defaultproperties
{
	bEnableActorOverlays=true
	MinimapHUDClass=class'Sample.GFxSampleHUD'
}
