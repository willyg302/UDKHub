class NEAchievementHandler extends Actor;

/**
 * Handles interfacing with Game Center and unlocking achievements. Also
 * manages local references to achievements (through AchievementArray) and
 * saving a copy of achievement data (through NESave).
 * 
 * As with leaderboards, the game ALWAYS takes precedence. What's saved to
 * NESave is what goes. Upon game start, we run a GC check to make sure the
 * two agree, and if they don't we update so GC = NESave.
 */

var array<AchievementDetails> DownloadedAchievements;
var array<int> PendingAchievements;
var bool bProcessingAchievements;

// Local data reference
struct AchievementData
{
	var string Title;
	var string Description;
	var int Points;
	var bool bUnlocked;
};
var array<AchievementData> AchievementArray;
var NEGame myGame;

var SoundCue UnlockedSound;

// Check that NESave and GC agree...done at startup
function CheckNEGCSync()
{
	local int i;
	for(i = 0; i < AchievementArray.Length; i++)
	{
		if(myGame.savefile.UnlockedAchievements[i] > 0 && myGame.savefile.GCAchievements[i] == 0)
			UnlockAchievement(i+1);
	}
}

event Destroyed()
{
	super.Destroyed();
	if(bProcessingAchievements)
		GarbageCollect();
}

function GarbageCollect()
{
	local OnlineSubsystem OnlineSubsystem;
	local int PlayerControllerId;
	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if(OnlineSubsystem == none || OnlineSubsystem.PlayerInterface == none)
		return;
	PlayerControllerId = GetALocalPlayerControllerId();
	OnlineSubsystem.PlayerInterface.ClearReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);
	OnlineSubsystem.PlayerInterface.ClearUnlockAchievementCompleteDelegate(PlayerControllerId, InternalOnUnlockAchievementComplete);
}

function AddGameHook(NEGame game)
{
	myGame = game;
}

/**
 * Unlocks achievement using the achievement's title.
 * Also checks to see if it has already been unlocked based on NESave,
 * since if NESave says it's unlocked, then GC MUST have it unlocked.
 */
function Unlock(string AchievementName)
{
	local int Index;
	for(Index = 0; Index < AchievementArray.Length; Index++)
	{
		if(AchievementArray[Index].Title == AchievementName)
			break;
	}
	if(myGame.savefile.UnlockedAchievements[Index] != 0)
		return;
	// Not unlocked according to NESave, so do unlock!
	myGame.savefile.UnlockedAchievements[Index] = 1;
	myGame.savefile.AuxPoints += AchievementArray[Index].Points;
	myGame.SaveGame();
	// Show unlocked message and play sound!
	myGame.NotifyAchievementUnlocked(AchievementArray[Index].Title, AchievementArray[Index].Points);
	UnlockAchievement(Index + 1);
}

function PlayAchievementPing()
{
	UnlockedSound.VolumeMultiplier = myGame.savefile.SFXVolume;
	PlaySound(UnlockedSound);
}

/**
 * Unlocks achievement using the achievement's ID. This is for GC only.
 */
function UnlockAchievement(int AchievementId)
{
	local OnlineSubsystem OnlineSubsystem;
	local int PlayerControllerId;

	// This achievement is already pending, and is in progress so just wait
	if(PendingAchievements.Find(AchievementId) != INDEX_NONE)
		return;
	
	PendingAchievements.AddItem(AchievementId);

	// If we're not processing achievements right now, process one now
	if(!bProcessingAchievements)
	{
		OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
		if(OnlineSubsystem != none && OnlineSubsystem.PlayerInterface != none)
		{
			PlayerControllerId = GetALocalPlayerControllerId();
			OnlineSubsystem.PlayerInterface.AddReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);
			OnlineSubsystem.PlayerInterface.ReadAchievements(PlayerControllerId);
			bProcessingAchievements = true;
		}
	}
}

/**
 * Called when the async achievements read has completed
 * @param TitleId: The title id that the read was for (0 means current title)
 */
function InternalOnReadAchievementsComplete(int TitleId)
{
	local OnlineSubsystem OnlineSubsystem;
	local int AchievementIndex, PlayerControllerId;

	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if(OnlineSubsystem == none || OnlineSubsystem.PlayerInterface == none)
		return;

	PlayerControllerId = GetALocalPlayerControllerId();
	DownloadedAchievements.Remove(0, DownloadedAchievements.Length);
	OnlineSubsystem.PlayerInterface.GetAchievements(PlayerControllerId, DownloadedAchievements, TitleId);

	// Grab all of the achievements
	if(DownloadedAchievements.Length > 0 && PendingAchievements.Length > 0)
	{
		AchievementIndex = DownloadedAchievements.Find('Id', PendingAchievements[0]);

		// Unlock the achievement		
		if (AchievementIndex != INDEX_NONE && !DownloadedAchievements[AchievementIndex].bWasAchievedOnline)
		{
			OnlineSubsystem.PlayerInterface.AddUnlockAchievementCompleteDelegate(PlayerControllerId, InternalOnUnlockAchievementComplete);
			OnlineSubsystem.PlayerInterface.UnlockAchievement(PlayerControllerId, PendingAchievements[0]);			
		}
	}
	OnlineSubsystem.PlayerInterface.ClearReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);
}

/**
 * Called when the achievement unlocking has completed
 * @param bWasSuccessful true if the async action completed without error, false if there was an error
 */
function InternalOnUnlockAchievementComplete(bool bWasSuccessful)
{
	local OnlineSubsystem OnlineSubsystem;
	local int AchievementIndex, PlayerControllerId;

	PlayerControllerId = GetALocalPlayerControllerId();

	if(bWasSuccessful && PendingAchievements.Length > 0)
	{
		AchievementIndex = DownloadedAchievements.Find('Id', PendingAchievements[0]);
		myGame.savefile.GCAchievements[AchievementIndex - 1] = 1;
		myGame.SaveGame();
	}
	PendingAchievements.Remove(0, 1);

	OnlineSubsystem = class'GameEngine'.static.GetOnlineSubsystem();
	if(OnlineSubsystem == none || OnlineSubsystem.PlayerInterface == none)
		return;

	if (PendingAchievements.Length > 0)
	{
		OnlineSubsystem.PlayerInterface.AddReadAchievementsCompleteDelegate(PlayerControllerId, InternalOnReadAchievementsComplete);	
		OnlineSubsystem.PlayerInterface.ReadAchievements(PlayerControllerId);
	}
	else
	{
		OnlineSubsystem.PlayerInterface.ClearUnlockAchievementCompleteDelegate(PlayerControllerId, InternalOnUnlockAchievementComplete);
		bProcessingAchievements = false;
	}
}

/**
 * Returns a local Player Controller ID
 */
function int GetALocalPlayerControllerId()
{
	local PlayerController PlayerController;
	local LocalPlayer LocalPlayer;
	
	PlayerController = GetALocalPlayerController();
	if(PlayerController == none)
		return INDEX_NONE;
	LocalPlayer = LocalPlayer(PlayerController.Player);
	if(LocalPlayer == none)
		return INDEX_NONE;
	return class'UIInteraction'.static.GetPlayerIndex(LocalPlayer.ControllerId);
}


defaultproperties
{
	AchievementArray.Add((Title="A Good Cat",Description="Died 9 times",Points=100,bUnlocked=false))
	
	AchievementArray.Add((Title="Like A Boss",Description="First 10 levels with 0 deaths",Points=250,bUnlocked=false))
	AchievementArray.Add((Title="Blazing Start",Description="First 10 levels in 120 seconds",Points=250,bUnlocked=false))

	AchievementArray.Add((Title="Better Than Jules",Description="Around the World in 40 seconds",Points=100,bUnlocked=false))
	AchievementArray.Add((Title="Trap King",Description="Level 24 in 40 seconds",Points=100,bUnlocked=false))
	
	AchievementArray.Add((Title="Glass Half Full",Description="Completed level 25",Points=500,bUnlocked=false))
	AchievementArray.Add((Title="The Cautious Type",Description="First 25 levels with 0 deaths",Points=500,bUnlocked=false))
	AchievementArray.Add((Title="Eager To Finish",Description="First 25 levels in 450 seconds",Points=500,bUnlocked=false))

	AchievementArray.Add((Title="A Regular Houdini",Description="Level 47 in 40 seconds",Points=100,bUnlocked=false))
	AchievementArray.Add((Title="Fast Eyes",Description="Level 48 in 40 seconds",Points=100,bUnlocked=false))
	AchievementArray.Add((Title="Peregrine",Description="Level 49 in 40 seconds",Points=100,bUnlocked=false))
	
	AchievementArray.Add((Title="The End",Description="Completed level 50",Points=5000,bUnlocked=false))
	AchievementArray.Add((Title="No Hesitation",Description="All levels with 0 restarts",Points=1000,bUnlocked=false))
	AchievementArray.Add((Title="Indestructi-ball",Description="All levels with 0 deaths",Points=1000,bUnlocked=false))
	AchievementArray.Add((Title="Ball of Fury",Description="All levels in 1200 seconds",Points=1000,bUnlocked=false))

	UnlockedSound=SoundCue'Never_End_MAudio.Sounds.Unlocked_Cue'
}
