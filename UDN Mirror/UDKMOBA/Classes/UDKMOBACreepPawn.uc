//=============================================================================
// UDKMOBACreepPawn
//
// Variation of UDKMOBAPawn which is used for the creeps in the world. Creeps
// have a sight range, they give money when they are killed, give experience
// to heroes when killed and are owned by a creep factory placed in the map.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACreepPawn extends UDKMOBAPawn;

// Amount of money to give when this creep is killed
var(Creep) const int MoneyToGiveOnKill;
// Sight range of this creep
var(Creep) const float SightRange;
// Amount of experience to give when this creep is killed
var(Creep) const int ExperienceToGiveOnKill;

// Factory which owns this creep
var RepNotify UDKMOBACreepFactory Factory;

// Replication block
replication
{
	if (bNetInitial)
		Factory;
}

/**
 * Called when the pawn is initialized
 *
 * @network		Server and client
 */
simulated event PostBeginPlay()
{
	// Set the factory
	if (Role == Role_Authority)
	{
		Factory = UDKMOBACreepFactory(Owner);
		UpdateOcclusionColor();
	}

	Super.PostBeginPlay();

	// Add the default inventory for the creeps
	AddDefaultInventory();	
}

/**
 * Called when a variable that is flagged as RepNotify is replicated
 *
 * @param		VarName		Name of the variable that has been replicated
 * @network					Local client
 */
simulated event ReplicatedEvent(Name VarName)
{
	if (VarName == NameOf(Factory))
	{
		UpdateOcclusionColor();
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

/**
 * Updates the occlusion color
 *
 * @network		Server and clients
 */
simulated function UpdateOcclusionColor()
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	// Colorize the occlusion color
	if (WorldInfo.NetMode != NM_DedicatedServer && !WorldInfo.IsConsoleBuild())
	{
		UDKMOBAPlayerController = UDKMOBAPlayerController(GetALocalPlayerController());
		if (UDKMOBAPlayerController != None)
		{
			SetOcclusionColor(UDKMOBAPlayerController.GetTeamNum());
		}
	}	
}

/**
 * Called when the pawn has been killed
 *
 * @param		Killer			Controller that killed me
 * @param		DamageType		Damage type that was used to do the killing
 * @param		HitLocation		World location where the killing hit was done
 * @return						Returns true if the pawn was actually killed or not
 * @network						Server
 */
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local UDKMOBAHeroAIController UDKMOBAHeroAIController;
	local LocalPlayer LocalPlayer;
	local int EligibleHeroes;
	local UDKMOBAHeroPawn CurHeroPawn;
	local UDKMOBAGameInfo UDKMOBAGameInfo;
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	// Check who killed me, if it is a hero then award the hero some money
	if (Killer != None)
	{
		if (Killer.GetTeamNum() != GetTeamNum())
		{
			// Killed by an enemy - not denied. Give out experience to nearby enemy heros
			UDKMOBAGameInfo = UDKMOBAGameInfo(WorldInfo.Game);
			if (UDKMOBAGameInfo != None)
			{
				// First get the number of heroes eligible for earning experience
				EligibleHeroes = 0;
				foreach WorldInfo.AllPawns(class'UDKMOBAHeroPawn', CurHeroPawn, Location, UDKMOBAGameInfo.Properties.ExperienceRange)
				{
					if (CurHeroPawn.GetTeamNum() != GetTeamNum())
					{
						EligibleHeroes++;
					}
				}

				// Give those heroes experience which is shared among the heroes
				foreach WorldInfo.AllPawns(class'UDKMOBAHeroPawn', CurHeroPawn, Location, UDKMOBAGameInfo.Properties.ExperienceRange)
				{
					if (CurHeroPawn.GetTeamNum() != GetTeamNum())
					{
						UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(CurHeroPawn.PlayerReplicationInfo);
						if (UDKMOBAHeroPawnReplicationInfo != None)
						{
							UDKMOBAHeroPawnReplicationInfo.GiveExperience(ExperienceToGiveOnKill / EligibleHeroes);
						}
					}
				}
			}
		}

		UDKMOBAHeroAIController = UDKMOBAHeroAIController(Killer);
		if (UDKMOBAHeroAIController != None)
		{
			UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(UDKMOBAHeroAIController.Controller.PlayerReplicationInfo);
			if (UDKMOBAHeroAIController.Controller.GetTeamNum() == GetTeamNum())
			{
				// If it's a teammate, give them a deny stat
				if (UDKMOBAPlayerReplicationInfo != None)
				{
					UDKMOBAPlayerReplicationInfo.Denies++;
				}
			}
			else
			{
				// Otherwise send the hero some money, give them LastHit
				if (UDKMOBAPlayerReplicationInfo != None)
				{
					UDKMOBAPlayerReplicationInfo.ModifyMoney(MoneyToGiveOnKill);
					UDKMOBAPlayerReplicationInfo.LastHits++;
				}

				// If the last hit by controller is a player controller, then let the player know that some money arrived
				if (UDKMOBAHeroAIController.UDKMOBAPlayerController != None)
				{
					// Check if the killer player controller is a local player or not
					LocalPlayer = LocalPlayer(UDKMOBAHeroAIController.UDKMOBAPlayerController.Player);
					if (LocalPlayer != None)
					{
						UDKMOBAHeroAIController.UDKMOBAPlayerController.ReceivedMoney(MoneyToGiveOnKill, Location);
					}
					// If the player is not a local player, then send it across the network
					else
					{
						UDKMOBAHeroAIController.UDKMOBAPlayerController.ClientReceivedMoney(MoneyToGiveOnKill, Location + Vect(0.f, 0.f, 1.f) * GetCollisionHeight());
					}
				}
			}
		}
	}

	// Inform the factory that a creep has died
	if (Factory != None)
	{
		Factory.CreepDied();
	}

	// Notify the weapon
	if (Weapon != None)
	{
		Weapon.HolderDied();
	}

	// Notify the inventory manager
	if (InvManager != None)
	{
		InvManager.OwnerDied();
	}

	// Detach controller
	DetachFromController(true);

	// Destroy the weapon fire
	if (WeaponFireMode != None)
	{
		WeaponFireMode.Destroy();
	}
	
	// Destroy the weapon range trigger
	if (WeaponRangeTrigger != None)
	{
		WeaponRangeTrigger.Destroy();
		WeaponRangeTrigger = None;
	}
	
	// Remove it from the touch interfaces array in the local HUD
	PlayerController = GetALocalPlayerController();
	if (PlayerController != None)
	{
		UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
		if (UDKMOBAHUD != None)
		{
			UDKMOBAHUD.RemoveTouchInterface(Self);
			if (UDKMOBAHUD.HUDMovie != None)
			{
				UDKMOBAHUD.HUDMovie.RemoveMinimapInterface(Self);
			}
		}
	}

	bReplicateMovement = false;
	bTearOff = true;
	Velocity += TearOffMomentum;

	switch (class'UDKMOBAGameInfo'.static.GetPlatform())
	{
	// Best for FPS to instantly destroy the creep, rather than allow rag dolls
	case P_Mobile:
		Destroy();
		break;

	// Turn on rag doll for everything else
	default:
		BeginRagdoll();
		Lifespan = 5.f;
		break;
	}

	return true;
}

/**
 * Returns the team index that the pawn belongs to
 *
 * @return			Returns the team index that the pawn belongs to
 * @network			Server and clients
 */
simulated function byte GetTeamNum()
{
	if (Factory != None)
	{
		return Factory.TeamIndex;
	}

	return Super.GetTeamNum();
}
				
/**
 * Starts firing the pawn weapon
 *
 * @param		bFinished		Not used
 * @return						Always returns true
 * @network						Server
 */
function bool BotFire(bool bFinished)
{
	StartFire(0);
	return true;
}

// ======================================
// UDKMOBAMinimapInterface implementation
// ======================================
/**
 * Returns what layer this actor should have it's movie clip in Scaleform
 *
 * @return		Returns the layer enum
 * @network		Server and client
 */
simulated function EMinimapLayer GetMinimapLayer()
{
	return EML_Creeps;
}

/**
 * Updates the minimap icon
 *
 * @param		MinimapIcon		GFxObject which represents the minimap icon
 * @network						Server and client
 */
simulated function UpdateMinimapIcon(UDKMOBAGFxMinimapIconObject MinimapIcon)
{
	local PlayerController PlayerController;
	local string DesiredFrameName;

	PlayerController = GetALocalPlayerController();
	if (PlayerController != None)
	{
		DesiredFrameName = (PlayerController.GetTeamNum() == GetTeamNum()) ? "friendly" : "enemy";
		if (DesiredFrameName != MinimapIcon.FrameName)
		{
			MinimapIcon.GotoAndStop(DesiredFrameName);
		}
	}
}

// =====================================
// UDKMOBAAttackInterface implementation
// =====================================
/**
 * Returns true if the actor is still valid to attack
 *
 * @return		Returns true if the actor is still valid to attack
 * @network		Server and clients
 */
simulated function bool IsValidToAttack()
{
	return Factory != None && Super.IsValidToAttack();
}

// ====================================
// UDKMOBATouchInterface implementation
// ====================================
/**
 * Returns the touch priority to allow other touch interfaces to be more (or less) important than others
 *
 * @return		Returns the touch priority to allow sorting of multiple touch priorities
 * @network		Server and clients
 */
simulated function int GetTouchPriority()
{
	return 10;
}

// Default properties block
defaultproperties
{
	MoneyToGiveOnKill=10
	ExperienceToGiveOnKill=25
	bDontPossess=true
	SightRange=384.f
	BaseSpeed=200
	ControllerClass=class'UDKMOBACreepAIController'
}