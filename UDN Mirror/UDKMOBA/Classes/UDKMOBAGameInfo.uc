//=============================================================================
// UDKMOBAGameInfo
//
// Game info which handles the game rules:
//
// * When players die
// * When the game ends
// * Functionality for the different platforms
// * Controls the day and night cycle length
// * Stores a bunch of colors used through out the game
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGameInfo extends SimpleGame;

// Enum platform
enum EPlatform
{
	P_Auto,
	P_Mobile,
	P_PC		// Also stands for Mac
};

// Colors with attached names
struct SNamedColor
{
	var() name ColorName;
	var() Color StoredColor<DisplayName=Color>;
};

// HUD type to use on the PC platform
var const class<HUD> PCHUDType;
// HUD type to use on the Mobile platform
var const class<HUD> MobileHUDType;
// Player controller class to use on the PC platform
var const class<PlayerController> PCPlayerControllerClass;
// Player controller class to use on the Mobile platform
var const class<PlayerController> MobilePlayerControllerClass;
// Properties
var const UDKMOBAGameProperties Properties;

/**
 * Called when the game info is first initialized
 *
 * @network		Server
 */
event PreBeginPlay()
{
	Super.PreBeginPlay();

	// Initialze the teams
	InitTeamInfos();
}

/**
 * Handles the creation of teams
 *
 * @network		Server
 */
function InitTeamInfos()
{
	local UDKMOBAGameReplicationInfo UDKMOBAGameReplicationInfo;
	local int i;

	// Grab the MOBA game replication info, abort if it does not exist
	UDKMOBAGameReplicationInfo = UDKMOBAGameReplicationInfo(GameReplicationInfo);
	if (UDKMOBAGameReplicationInfo == None)
	{
		return;
	}

	// Create the teams
	for (i = 0; i < 2; ++i)
	{
		UDKMOBAGameReplicationInfo.SetTeam(i, Spawn(class'UDKMOBATeamInfo'));
		if (UDKMOBAGameReplicationInfo.Teams[i] != None)
		{
			UDKMOBAGameReplicationInfo.Teams[i].TeamIndex = i;
		}
	}
}

/** 
 * Handles all player initialization that is shared between the travel methods (i.e. called from both PostLogin() and HandleSeamlessTravelPlayer())
 *
 * @param		Controller		Player that is being initialized
 * @network						Server
 */
function GenericPlayerInitialization(Controller Controller)
{
	local PlayerController PlayerController;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	PlayerController = PlayerController(Controller);
	if (PlayerController != None)
	{
		// Keep track of the best host to migrate to in case of a disconnect
		UpdateBestNextHosts();

		// Notify the game that we can now be muted and mute others
		UpdateGameplayMuteList(PlayerController);

		// Tell client what HUD class to use
		PlayerController.ClientSetHUD(GetHUDType());

		// Replicate the streaming status to the client
		ReplicateStreamingStatus(PlayerController);

		// Set the rich presence strings on the client (has to be done there)
		PlayerController.ClientSetOnlineStatus();
	}

	// Notify mutators of player login
	if (BaseMutator != None)
	{
		BaseMutator.NotifyLogin(Controller);
	}

	// Give the player a color, if the player does not have one
	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(Controller.PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None && (UDKMOBAPlayerReplicationInfo.PlayerColor == '' || UDKMOBAPlayerReplicationInfo.PlayerColor == 'None'))
	{
		UDKMOBAPlayerReplicationInfo.SetPlayerColor(GivePlayerColor(UDKMOBAPlayerReplicationInfo));
	}
}

/** 
 * Spawns a PlayerController at the specified location; split out from Login()/HandleSeamlessTravelPlayer() for easier overriding 
 *
 * @param		SpawnLocation		Spawn location
 * @param		SpawnRotation		Spawn rotation
 * @return							Returns the player controller spawned
 * @network							Server
 */
function PlayerController SpawnPlayerController(Vector SpawnLocation, Rotator SpawnRotation)
{
	local EPlatform Platform;

	// Get the platform
	Platform = GetPlatform();

	switch (Platform)
	{
	// Return the spawned Mobile player controller
	case P_Mobile:
		return Spawn(MobilePlayerControllerClass,,, SpawnLocation, SpawnRotation);

	// Return the spawned PC player controller
	default:
		return Spawn(PCPlayerControllerClass,,, SpawnLocation, SpawnRotation);
	}

	// Return the spawned PC player controller as a fail safe
	return Spawn(PCPlayerControllerClass,,, SpawnLocation, SpawnRotation);
}

/**
 * Called when the game is shutting down.
 *
 * @network		Server
 */
event PreExit()
{
	if (AccessControl != None)
	{
		AccessControl.NotifyExit();
	}
}

/**
 * Returns the HUD type based on the platform
 *
 * @return		class<HUD>		Returns the HUD class based on the platform
 * @network						Server
 */
function class<HUD> GetHUDType()
{
	local EPlatform Platform;

	// Get the platform
	Platform = GetPlatform();

	switch (Platform)
	{
	// Return the mobile HUD type
	case P_Mobile:
		return MobileHUDType;

	// Return the PC HUD type
	default:
		return PCHUDType;
	}
	
	// Return the PC HUD type as a fail-safe
	return PCHUDType;
}

/**
 * Starts up the bots
 */
function StartBots();

/**
 * Called when the player wants to respawn with a pawn
 *
 * @param		NewPlayer		Player that wants to respawn
 * @network						Server
 */
function RestartPlayer(Controller NewPlayer)
{
	local NavigationPoint StartSpot;
	local int TeamNum, Idx;
	local array<SequenceObject> Events;
	local SeqEvent_PlayerSpawned SpawnedEvent;
	local LocalPlayer LocalPlayer; 
	local PlayerController PlayerController; 
	local Pawn SpawnedPawn;

	// Abort if the level is restarting, or the net mode is not the dedicated server or the listen server
	if (bRestartLevel && WorldInfo.NetMode != NM_DedicatedServer && WorldInfo.NetMode != NM_ListenServer)
	{
		return;
	}

	// Figure out the team number and find the start spot
	TeamNum = (NewPlayer.PlayerReplicationInfo == None || NewPlayer.PlayerReplicationInfo.Team == None) ? 255 : NewPlayer.PlayerReplicationInfo.Team.TeamIndex;
	StartSpot = FindPlayerStart(NewPlayer, TeamNum);

	// If a start spot wasn't found
	if (StartSpot == None)
	{
		// Check for a previously assigned spot
		if (NewPlayer.StartSpot != None)
		{
			StartSpot = NewPlayer.StartSpot;
		}
		else
		{
			// Otherwise abort
			return;
		}
	}

	// Try to create a pawn to use of the default class for this player
	SpawnedPawn = SpawnDefaultPawnFor(NewPlayer, StartSpot);
	if (SpawnedPawn != None)
	{
		// Initialize and start it up
		SpawnedPawn.SetAnchor(StartSpot);

		PlayerController = PlayerController(NewPlayer);
		if (PlayerController != None)
		{
			PlayerController.TimeMargin = -0.1f;
			StartSpot.AnchoredPawn = None;
		}

		// Set spawn properties in the pawn
		SpawnedPawn.LastStartSpot = PlayerStart(StartSpot);
		SpawnedPawn.LastStartTime = WorldInfo.TimeSeconds;

		// Spawned pawn should play some teleporting effects
		SpawnedPawn.PlayTeleportEffect(true, true);

		// Ask the controller to possess the spawned pawn
		NewPlayer.Possess(SpawnedPawn, false);

		// Pawn should spawn default inventory
		SpawnedPawn.AddDefaultInventory();

		// Set up the player defaults
		SetPlayerDefaults(SpawnedPawn);

		// Activate spawned events
		if (WorldInfo.GetGameSequence() != None)
		{
			WorldInfo.GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_PlayerSpawned', true, Events);
			for (Idx = 0; Idx < Events.Length; Idx++)
			{
				SpawnedEvent = SeqEvent_PlayerSpawned(Events[Idx]);
				if (SpawnedEvent != None && SpawnedEvent.CheckActivate(NewPlayer, NewPlayer))
				{
					SpawnedEvent.SpawnPoint = StartSpot;
					SpawnedEvent.PopulateLinkedVariableValues();
				}
			}
		}
	}

	// To fix custom post processing chain when not running in editor or PIE.
	PlayerController = PlayerController(NewPlayer);
	if (PlayerController != None)
	{
		LocalPlayer = LocalPlayer(PlayerController.Player); 
		if (LocalPlayer != None) 
		{ 
			// Remove and insert the post processing chain
			LocalPlayer.RemoveAllPostProcessingChains(); 
			LocalPlayer.InsertPostProcessingChain(LocalPlayer.Outer.GetWorldPostProcessChain(), INDEX_NONE, true); 

			// Notify the HUD to bind post process effects
			if (PlayerController.MyHUD != None)
			{
				PlayerController.MyHUD.NotifyBindPostProcessEffects();
			}
		} 
	}
}

/**
 * Returns the platform that this game is running as
 *
 * @network			Server
 */
static function EPlatform GetPlatform()
{
	local UDKMOBAMapInfo UDKMOBAMapInfo;
	local WorldInfo InstancedWorldInfo;

	// Grab the instanced world info, abort if none
	InstancedWorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (InstancedWorldInfo == None)
	{
		return P_PC;
	}

	// Return the forced platform designated by the map info, if it exists
	UDKMOBAMapInfo = UDKMOBAMapInfo(InstancedWorldInfo.GetMapInfo());
	if (UDKMOBAMapInfo != None && UDKMOBAMapInfo.ForcedPlatform != P_Auto)
	{
		return UDKMOBAMapInfo.ForcedPlatform;
	}

	// Auto detect the platform
	if (InstancedWorldInfo.IsConsoleBuild(CONSOLE_Mobile) || InstancedWorldInfo.IsConsoleBuild(CONSOLE_IPhone) || InstancedWorldInfo.IsConsoleBuild(CONSOLE_Android))
	{
		return P_Mobile;
	}

	// In case all else fails
	return P_PC;
}

/**
 * Returns a pawn of the default pawn class
 *
 * @param	NewPlayer		Controller for whom this pawn is spawned
 * @param	StartSpot		PlayerStart at which to spawn pawn
 * @return					Returns the pawn that was spawned for the player
 * @network					Server
 */
function Pawn SpawnDefaultPawnFor(Controller NewPlayer, NavigationPoint StartSpot)
{
	local Rotator StartRotation;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local Actor HitActor;
	local Vector HitLocation, HitNormal;

	// Check incoming variables
	if (NewPlayer == None || StartSpot == None)
	{
		return None;
	}

	// Check that we have access to the player replication info
	// Check that the player has set the hero they want to be
	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(NewPlayer.PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo == None || UDKMOBAPlayerReplicationInfo.HeroArchetype == None)
	{
		return None;
	}

	// Don't allow pawn to be spawned with any pitch or roll
	StartRotation.Yaw = StartSpot.Rotation.Yaw;

	// Trace down to find the exact starting position
	HitActor = Trace(HitLocation, HitNormal, StartSpot.Location - Vect(0.f, 0.f, 16384.f), StartSpot.Location, true);
	if (HitActor != None)
	{
		// Spawn and return the pawn
		return Spawn(UDKMOBAPlayerReplicationInfo.HeroArchetype.Class,,, HitLocation + UDKMOBAPlayerReplicationInfo.HeroArchetype.CylinderComponent.CollisionHeight * Vect(0.f, 0.f, 1.f), StartRotation, UDKMOBAPlayerReplicationInfo.HeroArchetype);
	}
	else
	{
		// Spawn and return the pawn
		return Spawn(UDKMOBAPlayerReplicationInfo.HeroArchetype.Class,,, StartSpot.Location, StartRotation, UDKMOBAPlayerReplicationInfo.HeroArchetype);
	}
}

/**
 * Return the 'best' player start for this player to start from.  PlayerStarts are rated by RatePlayerStart().
 *
 * @param		Player			Controller for whom we are choosing a playerstart
 * @param		InTeam			Specifies the Player's team (if the player hasn't joined a team yet)
 * @param		IncomingName	Specifies the tag of a teleporter to use as the Playerstart
 * @return						NavigationPoint chosen as player start (usually a PlayerStart)
 * @network						Server
 */
function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string IncomingName)
{
	local NavigationPoint NavigationPoint;
	local PlayerStart PlayerStart;

	// Allow mutator to override PlayerStart selection
	if (BaseMutator != None)
	{
		NavigationPoint = BaseMutator.FindPlayerStart(Player, InTeam, IncomingName);
		if (NavigationPoint != None)
		{
			return NavigationPoint;
		}
	}

	// Find the appropriate player start
	ForEach WorldInfo.AllNavigationPoints(class'PlayerStart', PlayerStart)
	{
		// Continue if the player start is not on the same TeamIndex
		if (InTeam != 255 && PlayerStart.TeamIndex != InTeam)
		{
			continue;
		}

		return PlayerStart;
	}
}

/**
 * Called when the game should start the match
 *
 * @network		Server
 */
function StartMatch()
{
	local UDKMOBAGameReplicationInfo MOBAGRI;

	Super.StartMatch();

	MOBAGRI = UDKMOBAGameReplicationInfo(GameReplicationInfo);
	MOBAGRI.ServerGameTime = 0.f;
	MOBAGRI.bGameTimeChanging = true;

	// Go to the match in progress state
	GotoState('MatchInProgress');
}

/**
 * Called from the server side UDKMOBAPlayerReplicationInfo that a player has picked a hero
 *
 * @network		Server
 */
function NotifyHeroPick()
{
	// Check if the match should start
	CheckMatchStart();
}

/**
 * Checks if the match should start or not
 *
 * @network		Server
 */
function CheckMatchStart();

/**
 * Return whether a team change is allowed
 *
 * @param		Other		Controller that wants to change teams
 * @param		N			Team index to switch to
 * @param		bNewTeam	If true, then create a new team info if there isn't one matching the TeamIndex desired
 */
function bool ChangeTeam(Controller Other, int N, bool bNewTeam)
{
	// Ensure that we have a GRI
	// Check the value of N
	// Can't change the team for a controller that doesn't exist
	// Can't change the team for a controller that doesn't have a valid player replication info
	if (GameReplicationInfo == None || GameReplicationInfo.Teams.Length == 0 || Other == None || Other.PlayerReplicationInfo == None)
	{
		return false;
	}

	// N is 255, return true so that players picks his team
	if (N == 255)
	{
		return true;
	}
	// N does not equal to 255, check if it is valid
	else if (N < 0 || N >= GameReplicationInfo.Teams.Length || GameReplicationInfo.Teams[N] == None)
	{
		return false;
	}

	// Check if the player is already on a team, if so then remove the player from that team
	if (Other.PlayerReplicationInfo.Team != None)
	{
		Other.PlayerReplicationInfo.Team.RemoveFromTeam(Other);
	}

	// Join the team
	GameReplicationInfo.Teams[N].AddToTeam(Other);

	// Check if the match should start
	CheckMatchStart();
	return true;
}

/**
 * Called every time the game is updated
 *
 * @param		DeltaTime		Time since the last update was called
 * @network						Server
 */
function Tick (float DeltaTime)
{
	Super.Tick(DeltaTime);

	// Handle the tick server game time
	TickServerGameTime(DeltaTime);
}

/**
 * Increments the day/night cycle and the gametime, replicating as appropriate to all clients.
 * Overridden in states where these change
 *
 * @param		DeltaTime		Time since the last time update was called
 * @network						Server
 */
function TickServerGameTime(float DeltaTime);

/**
 * Find an unused player color and return it so the asking player can use it
 *
 * @param		AskingPRI		Player replication info that is asking for the color
 * @network						Server
 */
function name GivePlayerColor(UDKMOBAPlayerReplicationInfo AskingPRI)
{
	local array<SNamedColor> AvailableColors;
	local PlayerReplicationInfo CurPRI;
	local UDKMOBAPlayerReplicationInfo CurUDKMOBAPRI;
	local int Index;

	// Grab the available colors
	AvailableColors = Properties.PlayerColors;
	// Iterate through all of the player replication infos to remove colors that have already been used
	foreach GameReplicationInfo.PRIArray(CurPRI)
	{
		CurUDKMOBAPRI = UDKMOBAPlayerReplicationInfo(CurPRI);
		if (CurUDKMOBAPRI != None && CurUDKMOBAPRI != AskingPRI)
		{
			Index = AvailableColors.Find('ColorName', CurUDKMOBAPRI.PlayerColor);
			if (Index != INDEX_NONE)
			{
				AvailableColors.Remove(Index, 1);
			}
		}
	}

	// Return the first entry of the available color
	return AvailableColors[0].ColorName;
}

/**
 * This state is when the match has not yet started, and players are choosing their heros or waiting to be started
 *
 * @network		Server
 */
auto state PendingMatch
{
	/**
	 * Checks if the match should start or not
	 *
	 * @network		Server
	 */
	function CheckMatchStart()
	{
		local int i;
		local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

		// Check we have access to the game replication info and the PRI array
		if (GameReplicationInfo == None || GameReplicationInfo.PRIArray.Length < 0)
		{
			return;
		}

		// Iterate through the player replication info
		for (i = 0; i < GameReplicationInfo.PRIArray.Length; ++i)
		{
			UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]);			
			if (UDKMOBAPlayerReplicationInfo != None)
			{
				// Return if this player has not picked a team yet
				// Return if this player has not picked a hero yet
				if (UDKMOBAPlayerReplicationInfo.Team == None || UDKMOBAPlayerReplicationInfo.HeroArchetype == None)
				{
					return;
				}
			}
		}

		// Everyone has picked, start the game
		StartMatch();
	}
}

/**
 * This state is used when the match is in progress
 *
 * @network		Server
 */
state MatchInProgress
{
	/**
	 * Increments the day/night cycle and the gametime, replicating as appropriate to all clients.
	 * Overridden in states where these change
	 *
	 * @param		DeltaTime		Time since the last time update was called
	 * @network						Server
	 */
	function TickServerGameTime(float DeltaTime)
	{
		local UDKMOBAGameReplicationInfo UDKMOBAGameReplicationInfo;

		UDKMOBAGameReplicationInfo = UDKMOBAGameReplicationInfo(GameReplicationInfo);
		if (UDKMOBAGameReplicationInfo != None)
		{
			UDKMOBAGameReplicationInfo.ServerGameTime += DeltaTime;
		}
	}

	/**
	 */
	function Tick(float DeltaTime)
	{
		local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
		local UDKMOBAPlayerController UDKMOBAPlayerController;
		local int i;

		Super.Tick(DeltaTime);

		if (GameReplicationInfo != None && GameReplicationInfo.PRIArray.Length > 0)
		{
			for (i = 0; i < GameReplicationInfo.PRIArray.Length; ++i)
			{
				UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(GameReplicationInfo.PRIArray[i]);
				if (UDKMOBAPlayerReplicationInfo != None && WorldInfo.TimeSeconds >= UDKMOBAPlayerReplicationInfo.NextRespawnTime)	
				{
					UDKMOBAPlayerController = UDKMOBAPlayerController(UDKMOBAPlayerReplicationInfo.Owner);
					if (UDKMOBAPlayerController != None && (UDKMOBAPlayerController.HeroPawn == None || !UDKMOBAPlayerController.HeroPawn.IsAliveAndWell()))
					{
						RestartPlayer(UDKMOBAPlayerController);
					}
				}
			}
		}
	}
}

/**
 * This state is used when the match is over
 *
 * @network		Server
 */
state MatchOver
{
	/**
	 * Called when this state is first started
	 *
	 * @param		PreviousStateName		Name of the state this was in prior
	 * @network								Server
	 */
	event BeginState(Name PreviousStateName)
	{
		local UDKMOBAGameReplicationInfo UDKMOBAGameReplicationInfo;

		Super.BeginState(PreviousStateName);

		UDKMOBAGameReplicationInfo = UDKMOBAGameReplicationInfo(GameReplicationInfo);
		if (UDKMOBAGameReplicationInfo != None)
		{
			UDKMOBAGameReplicationInfo.bGameTimeChanging = false;
		}
	}

	/**
	 * Returns true or false if the match is in progress or not
	 *
	 * @return		Returns true or false if the match is in progress or not
	 * @network		server
	 */
	function bool MatchIsInProgress()
	{
		return false;
	}
}

// Default properties block
defaultproperties
{
	bTeamGame=true
	bDelayedStart=true
	PCHUDType=class'UDKMOBAHUD_PC'
	MobileHUDType=class'UDKMOBAHUD_Mobile'
	PCPlayerControllerClass=class'UDKMOBAPlayerController_PC'
	MobilePlayerControllerClass=class'UDKMOBAPlayerController_Mobile'
	PlayerControllerClass=class'UDKMOBAPlayerController'
	PlayerReplicationInfoClass=class'UDKMOBAPlayerReplicationInfo'
	GameReplicationInfoClass=class'UDKMOBAGameReplicationInfo'	
	Properties=UDKMOBAGameProperties'UDKMOBA_Game_Resources.Properties.GameProperties'
}