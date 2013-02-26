class NEPlayerController extends GamePlayerController;

var NEGame myGame;

var bool MoveLeftIsPressed, MoveRightIsPressed, bRotating;

var MobilePlayerInput MPI;
var MobileInputZone MainZone;
var vector2D ViewportSize;

var bool bSettingsMenuOpen;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	myGame = NEGame(WorldInfo.Game);
	WorldInfo.WorldGravityZ = 0.0;
	myGame.RegisterController(self);
}

function RollingBall GetPlayerBall()
{
	return myGame.Ball;
}

event InitInputSystem()
{
	Super.InitInputSystem();
	LocalPlayer(Player).ViewportClient.GetViewportSize(ViewportSize);
	SetupZones();
}

function SetupZones()
{
	// Cache the MPI
	MPI = MobilePlayerInput(PlayerInput);
	MPI.ActivateInputGroup("UberGroup");
	MainZone = MPI.FindZone("RollingBallZone");

	if(MainZone != none)
	{
		`log("[NEPlayerController] Initializing Input Zone");
		MainZone.X = 0;
		MainZone.Y = 0;
		MainZone.SizeX = ViewportSize.X;
		MainZone.SizeY = ViewportSize.Y;
		MainZone.ActiveSizeX = MainZone.SizeX;
		MainZone.ActiveSizeY = MainZone.SizeY;

		MainZone.OnProcessInputDelegate = MainZoneInput;
	}
}

function bool MainZoneInput(MobileInputZone Zone, float DeltaTime, int Handle, EZoneTouchEvent EventType, Vector2D TouchLocation)
{
	if(myGame.bIsPaused) {
		if(EventType == ZoneEvent_Touch) {
			if(NEMobileHUD(myHUD).Announces.Length > 0)
				NEMobileHUD(myHUD).RemoveAnnounce();
		}
		return false;
	}

	if(EventType == ZoneEvent_Touch) {
		if(TouchLocation.X > (ViewportSize.X / 3) && TouchLocation.X < (2*ViewportSize.X / 3)
				&& TouchLocation.Y < (ViewportSize.Y * 0.1125) && !myGame.bIsEntryGame) {
			SetPause(true);
			MPI.OpenMenuScene(class'NEPauseMenu');

		} else if((myGame.savefile.bFlipControls ? (ViewportSize.Y - TouchLocation.Y) : TouchLocation.Y) > (ViewportSize.Y * 0.5)) {
			if(TouchLocation.X < (ViewportSize.X * 0.5)) {
				MoveLeft();
			} else {
				MoveRight();
			}
		} else {
			if(TouchLocation.X < (ViewportSize.X * 0.5)) {
				MoveDown();
			} else {
				MoveUp();
			}
		}
	}
	if(EventType == ZoneEvent_UnTouch) {
		if((myGame.savefile.bFlipControls ? (ViewportSize.Y - TouchLocation.Y) : TouchLocation.Y) > (ViewportSize.Y * 0.5)) {
			MoveRelease();
		}
	}
	return false;
}





/////////////////////////////////////////////////////////
//			Ball Movement Functions				//
/////////////////////////////////////////////////////////

simulated function BallLeft(float DeltaTime, int InvertMovement)
{
	if(MoveLeftIsPressed == True)
		myGame.Ball.StaticMeshComponent.AddTorque(myGame.static.MakeVector(0,0,-1350*InvertMovement));
}

simulated function BallRight(float DeltaTime, int InvertMovement)
{
	if(MoveRightIsPressed == True)
		myGame.Ball.StaticMeshComponent.AddTorque(myGame.static.MakeVector(0,0,1350*InvertMovement));
}

/////////////////////////////////////////////////////////
//				Exec Functions					//
/////////////////////////////////////////////////////////
exec function MoveUp()
{
	if(!bRotating)
		myGame.Ball.Rotate(-1);
}

exec function MoveDown()
{
	if(!bRotating)
		myGame.Ball.Rotate(1);
}

exec function MoveLeft()
{
	MoveRightIsPressed = False;
	MoveLeftIsPressed = True;
}

exec function MoveRight()
{
	MoveLeftIsPressed = False;
	MoveRightIsPressed = True;
}

exec function MoveRelease()
{
	MoveLeftIsPressed = False;
	MoveRightIsPressed = False;
}



event PlayerTick( float DeltaTime )
{
	local int InvertMovement;
	super.PlayerTick(DeltaTime);
	InvertMovement = (myGame.savefile.bInvertMovement ? -1 : 1);
	BallLeft(DeltaTime, InvertMovement);
	BallRight(DeltaTime, InvertMovement);
}

// Overriden to tell it to always use the Camera's viewpoint as the player view point
simulated event GetPlayerViewPoint(out vector out_Location, out Rotator out_Rotation )
{
	PlayerCamera.GetCameraViewPoint(out_Location, out_Rotation);
}

/**
 * Reset Camera Mode to default
 */
event ResetCameraMode()
{
	if (Pawn != None)
		SetCameraMode(Pawn.GetDefaultCameraMode(Self)); // If we have a pawn, let's ask it which camera mode we should use
	else
		SetCameraMode('FirstPerson'); // otherwise default to first person view.
}

// Override to do nothing
function UpdateRotation(float DeltaTime);
function ProcessViewRotation(float DeltaTime, out Rotator out_ViewRotation, Rotator DeltaRot);


function NEDispAnnounce(NESeqAct_PlayAnnouncement action)
{
	//If we display a message, we want to toggle pausing...
	myGame.TogglePause(true);
	NEMobileHUD(myHUD).AddAnnounce(action);
}

function NEDispBegin(NESeqAct_PlayBegin action)
{
	myGame.TogglePause(true);
	NEMobileHUD(myHUD).AddBegin(string(myGame.level),
			myGame.maps.MapArray[myGame.level-1].Title,
			myGame.maps.MapArray[myGame.level-1].Description1,
			myGame.maps.MapArray[myGame.level-1].Description2);
}

function NELoadLevel(NESeqAct_LoadLevel action)
{
	LoadLevel(action.level);
}

/* 0 to load last unlocked level
 * -1 to load current level (as in a restart)
 */
function LoadLevel(int level)
{
	if(level == 0)
		level = myGame.savefile.Level;
	if(level == -1)
		level = myGame.level;
	ConsoleCommand("open NE-Level" $ string(level));
}

function RestartLevel()
{
	if(!myGame.bIsReplay)
		myGame.HandleRestart();
	LoadLevel(-1);
}

function NextLevel()
{
	if(!myGame.bIsReplay)
	{
		LoadLevel(0);
	}
	else
	{
		ConsoleCommand("open NE-MFront");
	}
}

function NEOpenSettings(NESeqAct_OpenSettings action)
{
	if(!bSettingsMenuOpen)
	{
		bSettingsMenuOpen = true;
		MPI.OpenMenuScene(class'NESettingsMenu');
	}
}

function NEResetGame(NESeqAct_ResetGame action)
{
	myGame.savefile = new class'NESave';
	myGame.savefile.SaveGame();
	ConsoleCommand("open NE-MFront");
}

function OpenLevelEndMenu(int Time, int Deaths, int Restarts, int Points)
{
	local NELevelEndMenu myMenu;
	myMenu = NELevelEndMenu(MPI.OpenMenuScene(class'NELevelEndMenu'));
	myMenu.SetLabelValues(Time, Deaths, Restarts, Points);
}

function ClearRestarts()
{
	myGame.savefile.CurRestarts = 0;
	myGame.SaveGame();
}

function WriteLeaderboardScore(int Score)
{
	local NEStatsWrite SW;
	local UniqueNetId zeroID, UniqueID;
	local OnlineSubsystem OnlineSubsystem;

	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if(OnlineSubsystem == none || OnlineSubsystem.PlayerInterface == none)
		return;
	OnlineSubsystem.PlayerInterface.GetUniquePlayerId(0, UniqueID);

	SW = new class'NEStatsWrite';
	if(UniqueID != zeroID)
	{
		SW.SetIntStat(class'NEStatsWrite'.const.LEADERBOARD_SCORE, Score);
		OnlineSubsystem.StatsInterface.WriteOnlineStats('Game', UniqueID, SW);
	}
}


defaultproperties
{
	CameraClass=class'NECamera'
	bRotating=false
	InputClass=class'GameFramework.MobilePlayerInput'
	bSettingsMenuOpen=false
}
