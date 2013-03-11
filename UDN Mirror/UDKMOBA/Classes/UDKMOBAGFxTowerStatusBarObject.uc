//=============================================================================
// UDKMOBAGFxTowerStatusBarObject
//
// Handles showing the status bar for towers
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxTowerStatusBarObject extends GFxObject;

// Health bar mask maximum horizontal position
var() const float HealthBarMaskMaxX;
// Health bar mask minimum horizontal position
var() const float HealthBarMaskMinX;

// Health bar mask
var ProtectedWrite GFxObject HealthBarMask;
// Cached health percentage, this is used to prevent the status bar from updating unnecessarily
var ProtectedWrite float CachedHealthPercentage;

/**
 * Initializes the tower status bar object
 *
 * @network		Client
 */
function Init()
{
	HealthBarMask = GetObject("healthmask");
}

/**
 * Updates the health bar based on the percentage
 *
 * @param		HealthPercentage		Percentage of the health to set the health bar at
 * @network								Client
 */
function UpdateHealth(float HealthPercentage)
{
	if (HealthPercentage != CachedHealthPercentage)
	{
		CachedHealthPercentage = HealthPercentage;
		if (HealthBarMask != None)
		{
			HealthBarMask.SetFloat("x", Lerp(HealthBarMaskMinX, HealthBarMaskMaxX, HealthPercentage));
		}
	}
}

// Default properties block
defaultproperties
{
	CachedHealthPercentage=1.f
	HealthBarMaskMaxX=-134.f
	HealthBarMaskMinX=-378.f
}