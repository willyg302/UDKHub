//=============================================================================
// UDKMOBAGFxMinimapIconObject
//
// Handles the data associated with the mini map icon.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxMinimapIconObject extends GFxObject;

// Stores the name of the mini map icon MovieClip symbol name which can be used as an identifier
var string MinimapIconMCSymbolName;
// Stores the mini map interface which this mini map icon represents. Saves having to type cast from the MinimapActor
var UDKMOBAMinimapInterface MinimapInterface;
// Stores the actor which this mini map icon represents
var Actor MinimapActor;
// Stores whether this mini map icon is visible or not
var bool IsVisible;
// Stores the frame name that this MovieClip is currently in
var string FrameName;

// Default properties block
defaultproperties
{
}