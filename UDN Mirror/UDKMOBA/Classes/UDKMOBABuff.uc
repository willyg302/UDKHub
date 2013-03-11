//=============================================================================
// UDKMOBABuff
//
// A package of stat changes that can be applied to a Hero - from Items, Spells
// , etc.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBABuff extends Object
	editinlinenew
	hidecategories(Object)
	DependsOn(UDKMOBAStatsModifier);

// Stat changes
var(Buff) array<SStatChange> StatChanges;
// The name of the icon to display with any pawn effected by this buff - if any.
var(Buff) string BuffIcon;
// How long the buff will last (in seconds)
var(Buff) float Expiry;
// Whether this buff is removed when the target dies (true = not removed)
var(Buff) bool StaysOnDeath;

// Spell (or item) that gave this buff.
var UDKMOBASpell BuffOwner;

// Default properties block
defaultproperties
{
}