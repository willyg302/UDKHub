//=============================================================================
// UDKMOBADoT
//
// Damage over time object. This is an object which handles dealing damage 
// over time to an Actor. 
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBADoT extends Object
	DependsOn(UDKMOBAPawn)
	editinlinenew
	hidecategories(Object);

// How long this DoT will apply for (in seconds)
var(DoT) float Duration;
// How much damage is given each time this DoT is proc'd
var(DoT) float DamageAmount;
// How often this DoT is proc'd (in seconds)
var(DoT) float Period;
// The type of damage this DoT does
var(DoT) class<DamageType> DamageType<AllowAbstract>;
// The type of attack this DoT counts as - effects the armor matrix multiplier
var(DoT) EAttackType AttackType;

// The pawn which is being effected by this DoT
var UDKMOBAPawn Target;
// Time in WorldInfo.TimeSeconds when this DoT will cease to function
var float ExpiryTime;
// The AI/Player controller for the entity that put this DoT on the target
var Controller Instigator;

/**
 * Called by a timer on the Target. Allows us to get to the DoT exec function with an argument.
 *
 * @network		Server
 */
function DamageCalled()
{
	if (Target != None)
	{
		Target.ProcDoT(Self);
	}
}

// Default properties block
defaultproperties
{
	AttackType=ATT_Spells
}