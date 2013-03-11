//=============================================================================
// UDKMOBAGFxHeroStatusBarObject
//
// Handles showing the status bar for heroes
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxHeroStatusBarObject extends UDKMOBAGFxTowerStatusBarObject;

// Mana bar mask maximum horizontal position
var() const float ManaBarMaskMaxX;
// Mana bar mask minimum horizontal position
var() const float ManaBarMaskMinX;

// Mana bar mask
var ProtectedWrite GFxObject ManaBarMask;
// Cached mana percentage, this is used to prevent the status bar from updating unnecessarily
var ProtectedWrite float CachedManaPercentage;

/**
 * Initializes the hero status bar object
 *
 * @network		Client
 */
function Init()
{
	Super.Init();
	ManaBarMask = GetObject("manamask");
}

/**
 * Updates the mana bar based on the percentage
 *
 * @param		ManaPercentage		Percentage of the mana to set the mana bar at
 * @network							Client
 */
function UpdateMana(float ManaPercentage)
{
	if (ManaPercentage != CachedManaPercentage)
	{
		CachedManaPercentage = ManaPercentage;
		if (ManaBarMask != None)
		{
			ManaBarMask.SetFloat("x", Lerp(ManaBarMaskMinX, ManaBarMaskMaxX, ManaPercentage));
		}
	}
}

// Default properties
defaultproperties
{
	HealthBarMaskMaxX=-100.5f
	HealthBarMaskMinX=-283.5f
	ManaBarMaskMaxX=-100.5f
	ManaBarMaskMinX=-283.5f
}