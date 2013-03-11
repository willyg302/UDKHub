//=============================================================================
// UDKMOBAMapInfo
//
// Custom map info which allows level designers to specify debug values such
// as setting which platform to emulate.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAMapInfo extends MapInfo;

// Force what platform the game should be on
var(Debug) const EPlatform ForcedPlatform;
// If true, then all creep spawners are disabled
var(Debug) const bool bDisableCreepSpawners;

// Minimap
var(Minimap) const Texture2D MinimapTexture;
// Minimap center
var(Minimap) const Vector MinimapWorldCenter;
// Minimap extent 
var(Minimap) const float MinimapWorldExtent;
// Minimap floor
var(Minimap) const Vector MinimapFloor;

// Inverse of MinimapWorldExtent (set automatically by UDKMOBAGFxHUD::ConfigHUD())
var float InverseMinimapWorldExtent;

/**
 * Converts from minimap space to world space
 *
 * @param		MinimapLocation			Minimap location to convert
 * @param		out_WorldLocation		Returned world location
 * @network								All
 */
final static function MinimapToWorld(Vector2D MinimapLocation, out Vector out_WorldLocation)
{
	local WorldInfo WorldInfo;
	local UDKMOBAMapInfo UDKMOBAMapInfo;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo == None)
	{
		return;
	}

	UDKMOBAMapInfo = UDKMOBAMapInfo(WorldInfo.GetMapInfo());
	if (UDKMOBAMapInfo == None)
	{
		return;
	}

	out_WorldLocation.X = UDKMOBAMapInfo.MinimapWorldCenter.X - (MinimapLocation.X * UDKMOBAMapInfo.MinimapWorldExtent);
	out_WorldLocation.Y = UDKMOBAMapInfo.MinimapWorldCenter.Y - (MinimapLocation.Y * UDKMOBAMapInfo.MinimapWorldExtent);
	out_WorldLocation.Z = 0.f;
}

/**
 * Converts from world space to minimap space
 *
 * @param		WorldLocation			World location to convert
 * @param		out_MinimapLocation		Returned minimap location
 * @network								All
 */
final static function WorldToMinimap(Vector WorldLocation, out Vector2D out_MinimapLocation)
{
	local WorldInfo WorldInfo;
	local UDKMOBAMapInfo UDKMOBAMapInfo;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo == None)
	{
		return;
	}

	UDKMOBAMapInfo = UDKMOBAMapInfo(WorldInfo.GetMapInfo());
	if (UDKMOBAMapInfo == None)
	{
		return;
	}

	out_MinimapLocation.X = (UDKMOBAMapInfo.MinimapWorldCenter.X - WorldLocation.X) * UDKMOBAMapInfo.InverseMinimapWorldExtent;
	out_MinimapLocation.Y = (UDKMOBAMapInfo.MinimapWorldCenter.Y - WorldLocation.Y) * UDKMOBAMapInfo.InverseMinimapWorldExtent;
}

// Default properties block
defaultproperties
{
	ForcedPlatform=P_PC
	MinimapFloor=(X=0.f,Y=0.f,Z=256.f)
}