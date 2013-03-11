//=============================================================================
// UDKMOBAGameProperties
//
// An archetyped object which stores game properties.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGameProperties extends Object
	DependsOn(UDKMOBAGameInfo, UDKMOBAPawn)
	HideCategories(Object);

// How many seconds it takes to go through a day and a night
var(World) float DayNightCycleLength;
// Range within which heroes get experience for a kill
var(Combat) const float ExperienceRange;
// Colors for players
var(Color) const array<SNamedColor> PlayerColors;

// Combinations of armor and attack types, and the effect they have on damage
struct SArmorAttackMultiplier
{
	var() EArmorType ArmorType;
	var() EAttackType AttackType;
	var() float Multiplier;
};

// Armor attack matrix
var(ArmorAttackMatrix) const array<SArmorAttackMultiplier> ArmorAttackMatrix;

// Default properties block
defaultproperties
{
	DayNightCycleLength=720.f
	ExperienceRange=768.f
	PlayerColors(0)=(ColorName="lightblue",StoredColor=(R=0,G=191,B=255,A=255))
	PlayerColors(1)=(ColorName="yellow",StoredColor=(R=255,G=255,B=0,A=255))
	PlayerColors(2)=(ColorName="pink",StoredColor=(R=255,G=127,B=255,A=255))
	PlayerColors(3)=(ColorName="lightgreen",StoredColor=(R=127,G=255,B=127,A=255))
	PlayerColors(4)=(ColorName="darkblue",StoredColor=(R=0,G=0,B=127,A=255))
	PlayerColors(5)=(ColorName="orange",StoredColor=(R=255,G=63,B=0,A=255))
	PlayerColors(6)=(ColorName="purple",StoredColor=(R=127,G=0,B=255,A=255))
	PlayerColors(7)=(ColorName="cyan",StoredColor=(R=0,G=255,B=255,A=255))
	PlayerColors(8)=(ColorName="darkgreen",StoredColor=(R=0,G=63,B=0,A=255))
	PlayerColors(9)=(ColorName="brown",StoredColor=(R=95,G=31,B=0,A=255))

	// These values as here: http://www.playdota.com/mechanics/damagearmor
	ArmorAttackMatrix.Add((ArmorType=ART_Light,AttackType=ATT_Pierce,Multiplier=2.f))
	ArmorAttackMatrix.Add((ArmorType=ART_Medium,AttackType=ATT_Normal,Multiplier=1.5f))
	ArmorAttackMatrix.Add((ArmorType=ART_Medium,AttackType=ATT_Pierce,Multiplier=0.75f))
	ArmorAttackMatrix.Add((ArmorType=ART_Medium,AttackType=ATT_Siege,Multiplier=0.5f))
	ArmorAttackMatrix.Add((ArmorType=ART_Heavy,AttackType=ATT_Normal,Multiplier=1.25f))
	ArmorAttackMatrix.Add((ArmorType=ART_Heavy,AttackType=ATT_Pierce,Multiplier=0.75f))
	ArmorAttackMatrix.Add((ArmorType=ART_Heavy,AttackType=ATT_Siege,Multiplier=1.25f))
	ArmorAttackMatrix.Add((ArmorType=ART_Fortified,AttackType=ATT_Chaos,Multiplier=0.4f))
	ArmorAttackMatrix.Add((ArmorType=ART_Fortified,AttackType=ATT_Hero,Multiplier=0.5f))
	ArmorAttackMatrix.Add((ArmorType=ART_Fortified,AttackType=ATT_Normal,Multiplier=0.7f))
	ArmorAttackMatrix.Add((ArmorType=ART_Fortified,AttackType=ATT_Pierce,Multiplier=0.35f))
	ArmorAttackMatrix.Add((ArmorType=ART_Fortified,AttackType=ATT_Siege,Multiplier=1.5f))
	ArmorAttackMatrix.Add((ArmorType=ART_Hero,AttackType=ATT_Normal,Multiplier=0.75f))
	ArmorAttackMatrix.Add((ArmorType=ART_Hero,AttackType=ATT_Pierce,Multiplier=0.5f))
	ArmorAttackMatrix.Add((ArmorType=ART_Hero,AttackType=ATT_Siege,Multiplier=0.75f))
	ArmorAttackMatrix.Add((ArmorType=ART_Hero,AttackType=ATT_Spells,Multiplier=0.75f))
	ArmorAttackMatrix.Add((ArmorType=ART_Unarmored,AttackType=ATT_Pierce,Multiplier=1.5f))
}