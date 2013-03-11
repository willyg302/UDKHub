//=============================================================================
// UDKMOBAGFxSpellIconObject
//
// Handles the display of information to the player, as well as interpretting
// some input from the player (clicking of HUD buttons etc)
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxSpellIconObject extends GFxObject;

/**
 * Calls the 'setSpellIconImage()' ActionScript function with 'NewIconName' as a string parameter
 *
 * @param		NewIconName			Name of the icon resource to use
 * @network							Local client
 */
function ChangeIconImage(string NewIconName)
{
	ActionScriptVoid("setSpellIconImage");
}

// Default properties block
defaultproperties
{
}