class NEGame extends FrameworkGame;

var RollingBall Ball;

var float SimGravity;
var int CurrentRot; //0 is down, 1 left, 2 up, 3 right

var bool bIsEntryGame;
var bool bIsPaused;
var bool bDoTutorial;

/** MUSIC SYSTEM **/
//var int currentTrack, numTracks;
var AudioComponent musicTracks[2];

var AudioComponent CurrentMusic;
var float CurrentMusicMultiplier;
var string CurrentMusicMobile;

/** SAVE SYSTEM **/
var NESave savefile;

/** MAP DATA **/
var GlobalMapData maps;
var bool bIsReplay;
// CURRENT LEVEL THE PLAYER IS PLAYING
// NOT necessarily the last unlocked level
var int level;

/** ACHIEVEMENTS **/
var NEAchievementHandler AchievementHandler;

// VERY IMPORTANT!
var NEPlayerController BallController;

function RegisterController(NEPlayerController PC)
{
	BallController = PC;
}

event PreBeginPlay()
{
	super.PreBeginPlay();
	savefile = new class'NESave';
	LoadGame();
	maps = new class'GlobalMapData';
	AchievementHandler = Spawn(class'NEAchievementHandler');
	AchievementHandler.AddGameHook(self);
	AchievementHandler.CheckNEGCSync();
	if(!bIsEntryGame)
	{
		level = int(Mid(WorldInfo.GetmapName(), InStr(WorldInfo.GetmapName(), "Level")+5));
		bIsReplay = (level < savefile.Level);
		// Zero it out, this is always true
		savefile.CurTime = 0;
		savefile.CurDeaths = 0;
		SaveGame();
	}
}

function PostBeginPlay()
{
	super.PostBeginPlay();
	SpawnBall();
	SetTimer(1.0, false, 'AssignMusic');
}

function RespawnBall()
{
	SetTimer(2.0, false, 'SpawnBall');
}

function SpawnBall()
{
	local vector V;
	CurrentRot = 0;
	V = MakeVector(-64,0,32);
	Ball = Spawn(class'RollingBall',,,V);
}

static function vector MakeVector(float X, float Y, float Z)
{
	local vector V;
	V.X = X;
	V.Y = Y;
	V.Z = Z;
	return V;
}

function bool LoadGame()
{
	local bool success;
	local NESave createsave;
	success = savefile.LoadGame();
	if(!success)
	{
		createsave = new class'NESave';
		createsave.SaveGame();
		success = savefile.LoadGame();
		`log("[NEGame] New player, playing TUTORIAL");
		bDoTutorial = true;
	}
	return success;
}

function bool SaveGame()
{
	local bool success;
	success = savefile.SaveGame();
	return success;
}

function bool IsMobile()
{
	return WorldInfo.IsConsoleBuild(CONSOLE_Mobile);
}

/** BEGIN Music Functions **/
function AssignMusic()
{
	CurrentMusic = musicTracks[maps.MapArray[level-1].Track];
	CurrentMusicMobile = string(maps.MapArray[level-1].Track);
	CurrentMusicMultiplier = CurrentMusic.VolumeMultiplier;
	StartMusic();
}

function StartMusic()
{
	if(IsMobile())
	{
		if(savefile.MusicVolume != 0.0)
			ConsoleCommand("mobile PlaySong NE_Track_"$CurrentMusicMobile);
	}
	else
	{
		CurrentMusic.VolumeMultiplier = CurrentMusicMultiplier * savefile.MusicVolume;
		CurrentMusic.Play();
	}
}

function AdjustMusicVolume(float Value)
{
	if(IsMobile())
	{
		// Only if there's been a change
		if(Value != savefile.MusicVolume)
		{
			if(Value == 0.0)
			{
				ConsoleCommand("mobile StopSong NE_Track_"$CurrentMusicMobile);
			}
			else
			{
				ConsoleCommand("mobile PlaySong NE_Track_"$CurrentMusicMobile);
			}
		}
	}
	else
	{
		CurrentMusic.VolumeMultiplier = CurrentMusicMultiplier * Value;
	}
	savefile.MusicVolume = Value;
}

/** END Music Functions **/


//For messages, we simulate pausing the clock but NOT the game
function TogglePause(bool newPause)
{
	bIsPaused = newPause;
}

function Rotate(int direction)			 //-1 for clockwise, 1 for counterclockwise
{
	CurrentRot += direction;
	if(CurrentRot == 4) CurrentRot = 0;
	if(CurrentRot == -1) CurrentRot = 3;
}



function TriggerRemoteKismetEvent( name EventName )
{
	local array<SequenceObject> AllSeqEvents;
	local Sequence GameSeq;
	local int i;
	GameSeq = WorldInfo.GetGameSequence();
	if (GameSeq != None)
	{
		GameSeq.FindSeqObjectsByClass(class'SeqEvent_RemoteEvent', true, AllSeqEvents);
		for (i = 0; i < AllSeqEvents.Length; i++)
		{
			if(SeqEvent_RemoteEvent(AllSeqEvents[i]).EventName == EventName)
				SeqEvent_RemoteEvent(AllSeqEvents[i]).CheckActivate(WorldInfo, None);
		}
	}
}


// DATA FUNCTIONS FOLLOW

function HandleRestart()
{
	savefile.CurRestarts++;
	SaveGame();
}

function int GetLevelTimeSum(int ToLevel)
{
	local int i, total;
	total = 0;
	for(i = 0; i < ToLevel; i++)
		total += savefile.LevelTime[i];
	return total;
}

function int GetLevelDeathsSum(int ToLevel)
{
	local int i, total;
	total = 0;
	for(i = 0; i < ToLevel; i++)
		total += savefile.LevelDeaths[i];
	return total;
}

function int GetLevelRestartsSum(int ToLevel)
{
	local int i, total;
	total = 0;
	for(i = 0; i < ToLevel; i++)
		total += savefile.LevelRestarts[i];
	return total;
}

function int GetLevelPointsSum(int ToLevel)
{
	local int i, total;
	total = 0;
	for(i = 0; i < ToLevel; i++)
		total += savefile.LevelPoints[i];
	return total;
}

function EndLevel()
{
	TogglePause(true);
	HandleLevelEnd();
	//Clear Achievement Delegates before opening menu...allows garbage collection
	AchievementHandler.GarbageCollect();
	//Write scores to GC Leaderboard
	BallController.WriteLeaderboardScore(savefile.Points);
	BallController.OpenLevelEndMenu(savefile.LevelTime[level-1], savefile.LevelDeaths[level-1],
			savefile.LevelRestarts[level-1], savefile.LevelPoints[level-1]);
}

function HandleLevelEnd()
{
	local int earnedPoints;
	

	// Save lower time/deaths/restart values
	if(bIsReplay)
	{
		savefile.LevelTime[level-1] = Min(savefile.LevelTime[level-1], savefile.CurTime);
		savefile.LevelDeaths[level-1] = Min(savefile.LevelDeaths[level-1], savefile.CurDeaths);
		savefile.LevelRestarts[level-1] = Min(savefile.LevelRestarts[level-1], savefile.CurRestarts);
	}
	else
	{
		savefile.Level++;
		savefile.LevelTime[level-1] = savefile.CurTime;
		savefile.LevelDeaths[level-1] = savefile.CurDeaths;
		savefile.LevelRestarts[level-1] = savefile.CurRestarts;
	}

	// Calculate level points
	earnedPoints = maps.MapArray[level-1].MaxPoints;
	savefile.LevelPoints[level-1] = Clamp(earnedPoints
			- savefile.LevelTime[level-1]
			- 10*savefile.LevelDeaths[level-1]
			- 25*savefile.LevelRestarts[level-1], 0, earnedPoints);

	// Add to totals
	savefile.Time += (savefile.bBeatGame ? 0 : savefile.CurTime);
	savefile.Deaths += savefile.CurDeaths;
	savefile.Restarts += savefile.CurRestarts;

	// Augment auxiliaries (points are for achievements, not augmented)
	savefile.AuxTime = savefile.Time - GetLevelTimeSum(50);
	savefile.AuxDeaths = savefile.Deaths - GetLevelDeathsSum(50);
	savefile.AuxRestarts = savefile.Restarts - GetLevelRestartsSum(50);
	
	

	// Now we unlock achievements!
	if(savefile.Deaths > 8)
		AchievementHandler.Unlock("A Good Cat");
	if(savefile.Level > 10 && GetLevelDeathsSum(10) == 0)
		AchievementHandler.Unlock("Like A Boss");
	if(savefile.Level > 10 && GetLevelTimeSum(10) <= 120)
		AchievementHandler.Unlock("Blazing Start");
	if(savefile.Level > 14 && savefile.LevelTime[13] <= 40)
		AchievementHandler.Unlock("Better Than Jules");
	if(savefile.Level > 24 && savefile.LevelTime[23] <= 40)
		AchievementHandler.Unlock("Trap King");

	if(savefile.Level > 25)
		AchievementHandler.Unlock("Glass Half Full");
	if(savefile.Level > 25 && GetLevelDeathsSum(25) == 0)
		AchievementHandler.Unlock("The Cautious Type");
	if(savefile.Level > 25 && GetLevelTimeSum(25) <= 450)
		AchievementHandler.Unlock("Eager To Finish");

	if(savefile.Level > 47 && savefile.LevelTime[46] <= 40)
		AchievementHandler.Unlock("A Regular Houdini");
	if(savefile.Level > 48 && savefile.LevelTime[47] <= 40)
		AchievementHandler.Unlock("Fast Eyes");
	if(savefile.Level > 49 && savefile.LevelTime[48] <= 40)
		AchievementHandler.Unlock("Peregrine");

	if(savefile.Level > 50)
		AchievementHandler.Unlock("The End");
	if(savefile.Level > 50 && GetLevelRestartsSum(50) == 0)
		AchievementHandler.Unlock("No Hesitation");
	if(savefile.Level > 50 && GetLevelDeathsSum(50) == 0)
		AchievementHandler.Unlock("Indestructi-ball");
	if(savefile.Level > 50 && GetLevelTimeSum(50) <= 1200)
		AchievementHandler.Unlock("Ball of Fury");

	// Did we beat the game?
	if(savefile.Level > 50 && !savefile.bBeatGame)
		savefile.bBeatGame = true;

	// Recalc total points
	earnedPoints = GetLevelPointsSum(50);
	savefile.Points = Clamp(earnedPoints
			- savefile.AuxTime
			- 5*savefile.AuxDeaths
			- 10*savefile.AuxRestarts
			+ savefile.AuxPoints, 0, earnedPoints + savefile.AuxPoints);

	// Zero out currents (time/death will be zeroed upon level begin)
	savefile.CurRestarts = 0;
	
	SaveGame();
	
}

function NotifyAchievementUnlocked(string Title, int Points)
{
	NEMobileHUD(BallController.myHUD).AddAchievementMessage(Title, Points);
}

defaultproperties
{
	bDelayedStart=false
	PlayerControllerClass=class'NEPlayerController'
	HUDType=class'NEMobileHUD'

	SimGravity = 16.875000

	bIsEntryGame = false;
	bIsPaused = false;

	bPauseable=true

	/**MUSIC**/
	//currentTrack=0;
	//numTracks = 2;
	Begin Object Class=AudioComponent Name=Music01Comp
		SoundCue=SoundCue'Never_End_MAudio.Music.Game_Music_One_Cue'
		VolumeMultiplier=0.6
	End Object
	musicTracks[0] = Music01Comp

	Begin Object Class=AudioComponent Name=Music02Comp
		SoundCue=SoundCue'Never_End_MAudio.Music.Game_Music_Two_Cue'
		VolumeMultiplier=0.75
	End Object
	musicTracks[1] = Music02Comp
	bDoTutorial = false;
}
