//=============================================================================
// UDKMOBAGFxShopListWidget
//
// GFx widget which represents the a shop list
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxShopListWidget extends GFxClikWidget;

/**
 * Adds an item to the shop
 *
 * @param		Label			Item name
 * @param		Cost			How much an item costs
 * @param		IconName		Name of the icon image to display
 */
function AddShopItem(string Label, int Cost, string IconName)
{
	ActionscriptVoid("addShopItem");
}

// Default properties block
defaultproperties
{
}