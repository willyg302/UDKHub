//=============================================================================
// UDKMOBAObjective
//
// Base class to use for objectives in the game. This is usually for things
// like towers and the ancient.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAObjective extends UDKMOBAPawn
	abstract
	ClassGroup(MOBA)
	placeable;

// Static mesh used by the objective
var(Objective) const StaticMeshComponent StaticMesh;
// Team that this objective belongs to
var(Objective) const byte TeamIndex;

/**
 * Returns the team that this objective belongs to
 *
 * @return		Returns the team that this objective belongs to
 * @network		Server and client
 */
simulated function byte GetTeamNum()
{
	return TeamIndex;
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
	return EML_Towers;
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

// Default properties block
defaultproperties
{
	Components.Remove(MySkeletalMeshComponent)
	Components.Remove(MyWeaponSkeletalMeshComponent)
	Mesh=None
	WeaponSkeletalMesh=None
	OcclusionSkeletalMeshComponent=None

	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
		LightEnvironment=MyLightEnvironment
		bOverrideLightMapResolution=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
	End Object
	StaticMesh=MyStaticMeshComponent
	Components.Add(MyStaticMeshComponent)

	MinimapMovieClipSymbolName="minimapsquareicon"
	bNoDelete=true
}