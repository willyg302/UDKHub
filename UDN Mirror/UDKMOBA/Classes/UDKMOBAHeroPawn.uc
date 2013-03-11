//=============================================================================
// UDKMOBAHeroPawn
//
// Hero pawn is a sub class of UDKMOBAPawn as it has new features:
//
// * Stores what spells the hero has
// * UI specific information
// * Stat definitions
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAHeroPawn extends UDKMOBAPawn;

// Main stat enum
enum EMainStat
{
	STAT_Strength<DisplayName=Strength>,
	STAT_Agility<DisplayName=Agility>,
	STAT_Intelligence<DisplayName=Intelligence>,
};

// Spells that this hero has 
var(Hero) const archetype array<UDKMOBASpell> SpellArchetypes;
// The name of the Hero shown on the HUD etc
var(Hero) const String HeroName;
// The static portrait to use on mobile
var(Hero) const Texture2D HeroPortrait;
// Light component to help the visibility of this hero
var(Hero) const LightComponent Light;
// The 'main' stat of the hero - this stat also gives them damage
var(Hero) EMainStat MainStat;

// Next time the hero should regenerate health
var ProtectedWrite float NextHealthRegenerationTime;

/**
 * Called when the pawn is first initialized
 *
 * @network		Server and client
 */
simulated event PostBeginPlay()
{
	local UTWaterVolume UTWaterVolume;

	Super.PostBeginPlay();

	// Grab all of the water volumes
	ForEach AllActors(class'UTWaterVolume', UTWaterVolume)
	{
		WaterVolumes.AddItem(UTWaterVolume);
	}

	// Only do this on the server
	if (Role == Role_Authority)
	{
		// Set the main stat
		switch (MainStat)
		{
		case STAT_Strength:
			StatsModifier.AddStatChange(STATNAME_Damage, BaseStrength, MODTYPE_Addition, 0.f, true);
			break;

		case STAT_Agility:
			StatsModifier.AddStatChange(STATNAME_Damage, BaseAgility, MODTYPE_Addition, 0.f, true);
			break;

		case STAT_Intelligence:
			StatsModifier.AddStatChange(STATNAME_Damage, BaseIntelligence, MODTYPE_Addition, 0.f, true);
			break;
		}

		HealthFloat = BaseHealth;
	}
}

/**
 * This pawn has died.
 *
 * @param	Killer			Who killed this pawn
 * @param	DamageType		What killed it
 * @param	HitLocation		Where did the hit occur
 *
 * @returns true if allowed
 */
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	
	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None)
	{
		UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(UDKMOBAPawnReplicationInfo.PlayerReplicationInfo);
		if (UDKMOBAPlayerReplicationInfo != None)
		{
			UDKMOBAPlayerReplicationInfo.NextRespawnTime = WorldInfo.TimeSeconds + 15.f + (UDKMOBAPawnReplicationInfo.Level * 5.f);
		}
	}

	return Super.Died(Killer, DamageType, HitLocation);
}

/**
 * Performs any client side stuff to represent that this tower is dying
 *
 * @param		DamageType		Damage type that killed this tower
 * @param		HitLoc			Hit location of the hit that killed this tower
 * @network						Server and client
 */
simulated function PlayDying(class<DamageType> DamageType, vector HitLoc)
{
	Super.PlayDying(DamageType, HitLoc);

	BeginRagdoll();
}

/**
 * Called when the physics volume that the pawn is in has changed.
 *
 * @param		NewVolume		The new physics volume that the player is in
 * @network						Server and client
 */
simulated event PhysicsVolumeChange(PhysicsVolume NewVolume)
{
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;
	local UDKMOBAHUD UDKMOBAHUD;
	local PlayerController PlayerController;

	Super.PhysicsVolumeChange(NewVolume);

	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo != None && UDKMOBAPawnReplicationInfo.PlayerReplicationInfo != None)
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PlayerController)
		{
			if (PlayerController.PlayerReplicationInfo == UDKMOBAPawnReplicationInfo.PlayerReplicationInfo)
			{
				UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
				if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
				{
					UDKMOBAHUD.HUDMovie.ToggleShopButtonChrome(UDKMOBAShopAreaVolume(NewVolume) != None);
				}

				break;
			}
		}
	}
}

/**
 * Called when the player changes color
 *
 * @network		Server and client
 */
simulated function NotifyPlayerColorChanged()
{	
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local UDKMOBAPawnReplicationInfo UDKMOBAPawnReplicationInfo;
	local Color PlayerColor;
	local LinearColor OcclusionColor;
	local int i;
	local MaterialInstanceConstant MaterialInstanceConstant;
	
	// Early out if this is the dedicated server
	if (WorldInfo.NetMode == NM_DedicatedServer)
	{
		return;
	}

	UDKMOBAPawnReplicationInfo = UDKMOBAPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPawnReplicationInfo == None)
	{
		return;
	}

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(UDKMOBAPawnReplicationInfo.PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo == None)
	{
		return;
	}

	if (class'UDKMOBAObject'.static.GetPlayerColor(UDKMOBAPlayerReplicationInfo, PlayerColor))
	{
		// Update the light component
		if (Light != None)
		{	
			Light.SetLightProperties(, PlayerColor);
		}

		// Update the occlusion color
		OcclusionColor = ColorToLinearColor(PlayerColor);
		for (i = 0; i < OcclusionSkeletalMeshComponent.GetNumElements(); ++i)
		{
			MaterialInstanceConstant = MaterialInstanceConstant(OcclusionSkeletalMeshComponent.GetMaterial(i));
			if (MaterialInstanceConstant != None)
			{
				MaterialInstanceConstant.SetVectorParameterValue('OcclusionColor', OcclusionColor);
			}
		}	
	}
}

/**
 * Returns the team index that the pawn belongs to
 *
 * @return		Returns the team index that the pawn belongs to
 * @network		Server and client
 */
simulated function byte GetTeamNum()
{
	local UDKMOBAHeroAIController UDKMOBAHeroAIController;

	// Abort if we couldn't get to the UDKMOBAPlayerController
	UDKMOBAHeroAIController = UDKMOBAHeroAIController(Controller);
	if (UDKMOBAHeroAIController != None && UDKMOBAHeroAIController.UDKMOBAPlayerController != None)
	{
		return UDKMOBAHeroAIController.UDKMOBAPlayerController.GetTeamNum();
	}

	return Super.GetTeamNum();
}

/**
 * Player wants to send his / her hero somewhere in the world
 *
 * @param		WorldMoveLocation		World location to send the hero to
 * @network								Server
 */
function StartMoveCommand(Vector WorldMoveLocation)
{
	local UDKMOBAHeroAIController UDKMOBAHeroAIController;

	// Forward this to the pathing controller
	UDKMOBAHeroAIController = UDKMOBAHeroAIController(Controller);
	if (UDKMOBAHeroAIController != None)
	{
		UDKMOBAHeroAIController.StartMoveCommand(WorldMoveLocation);
	}
}

/**
 * Player wants to send his / her hero to attack something
 *
 * @param		ActorToAttack			Actor to attack
 * @network								Server and client
 */
simulated function StartAttackCommand(Actor ActorToAttack)
{
	local UDKMOBAHeroAIController UDKMOBAHeroAIController;

	// Forward this to the pathing controller
	UDKMOBAHeroAIController = UDKMOBAHeroAIController(Controller);
	if (UDKMOBAHeroAIController != None)
	{
		UDKMOBAHeroAIController.StartAttackCommand(ActorToAttack);
	}
}

/**
 * Player wants his / her hero to follow something
 *
 * @param		ActorToFollow			Actor to follow
 * @network								Server and client
 */
simulated function StartFollowCommand(Actor ActorToFollow)
{
	local UDKMOBAHeroAIController UDKMOBAHeroAIController;

	// Forward this to the pathing controller
	UDKMOBAHeroAIController = UDKMOBAHeroAIController(Controller);
	if (UDKMOBAHeroAIController != None)
	{
		UDKMOBAHeroAIController.StartFollowCommand(ActorToFollow);
	}
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
	return EML_Heroes;
}

/**
 * Updates the minimap icon
 *
 * @param		MinimapIcon		GFxObject which represents the minimap icon
 * @network						Server and client
 */
simulated function UpdateMinimapIcon(UDKMOBAGFxMinimapIconObject MinimapIcon)
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local string DesiredFrameName;
	local float MinimapScaleFactor;
	
	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo != None)
	{
		UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(UDKMOBAHeroPawnReplicationInfo.PlayerReplicationInfo);
		if (UDKMOBAPlayerReplicationInfo != None)
		{
			DesiredFrameName = String(UDKMOBAPlayerReplicationInfo.PlayerColor);
			if (DesiredFrameName != MinimapIcon.FrameName)
			{
				MinimapIcon.GotoAndStop(DesiredFrameName);
			}

			MinimapScaleFactor = 1.8f;
			MinimapIcon.SetFloat("scaleX", MinimapScaleFactor);
			MinimapIcon.SetFloat("scaleY", MinimapScaleFactor);
		}
	}
}

// ====================================
// UDKMOBATouchInterface implementation
// ====================================
/**
 * Returns the touch priority to allow other touch interfaces to be more (or less) important than others
 *
 * @return		Returns the touch priority to allow sorting of multiple touch priorities
 * @network		Server and client
 */
simulated function int GetTouchPriority()
{
	return 9000;
}

// ====================================
// UDKMOBAStatsInterface implementation
// ====================================
/**
 * Returns true if the actor implementing this interface has mana
 *
 * @return		True if the actor implementing this interface has mana
 * @network		Server and client
 */
simulated function bool HasMana()
{
	return true;
}

/**
 * Returns the mana as a percentage value
 *
 * @return		The mana as a percentage value
 * @network		Server and client
 */
simulated function float GetManaPercentage()
{
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo != None)
	{
		return Mana / UDKMOBAHeroPawnReplicationInfo.ManaMax;
	}
	return 0.f;
}

// Default properties block
defaultproperties
{
	Begin Object Class=PointLightComponent Name=MyPointLightComponent
	End Object
	Components.Add(MyPointLightComponent)
	Light=MyPointLightComponent

	Health=1000
	Mana=100.f
	BaseHealth=150.f
	BaseHealthRegen=.25f
	BaseMana=0.f
	BaseManaRegen=0.01f
	BaseStrength=18.f
	LevelStrength=2.f
	BaseAgility=18.f
	LevelAgility=2.f
	BaseIntelligence=18.f
	LevelIntelligence=2.f
	MainStat=STAT_Strength
	BaseDamage=20.f
	BaseArmor=2.f
	BaseEvasion=0.f
	BaseBlind=0.f
	BaseMagicResistance=1.f
	BaseMagicAmp=1.f
	BaseMagicImmunity=false
	BaseUnpracticed=0.f
	BaseAttackSpeed=2.f
	BaseSight=512.f
	BaseRange=128.f
	BaseSpeed=600.f
	BaseVisibility=true
	BaseTrueSight=false
	BaseColliding=true
	BaseCanCast=true
	ControllerClass=class'UDKMOBAHeroAIController'
	ArmorType=ART_Hero
	AttackType=ATT_Hero
}