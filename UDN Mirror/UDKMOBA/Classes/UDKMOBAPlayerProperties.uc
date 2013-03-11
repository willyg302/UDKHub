//=============================================================================
// UDKMOBAPlayerProperties
//
// An archetyped object which stores properties used by the player controller.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPlayerProperties extends Object
	HideCategories(Object)
	AutoExpandCategories(Properties)
	Abstract;

// Move confirmation particle effect
var(Properties) const ParticleSystem MoveConfirmationParticleTemplate;
// Attack confirmation particle effect
var(Properties) const ParticleSystem AttackConfirmationParticleTemplate;

// Default properties block
defaultproperties
{
}