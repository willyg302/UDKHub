//=============================================================================
// UDKMOBAAttackInterface
//
// Interface that actors should implement if they can attack things and they
// themselves can be attacked.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKMOBAAttackInterface;

/**
 * Returns the weapon firing location and rotation
 *
 * @param		FireLocation		Output the firing location
 * @param		FireRotation		Output the firing rotation
 * @network							Server and client
 */
simulated function GetWeaponFiringLocationAndRotation(out Vector FireLocation, out Rotator FireRotation);

/**
 * Returns the enemy
 *
 * @return		Returns the current enemy
 * @network		Server and client
 */
simulated function Actor GetEnemy();

/**
 * Returns the team index that the pawn belongs to
 *
 * @return		Returns the team index that the pawn belongs to
 * @network		Server and client
 */
simulated function byte GetTeamNum();

/**
 * Returns the attack priority of this actor
 *
 * @param		Attacker		Actor that wants to attack this UDKMOBAAttackInterface
 * @return						Returns the attacking priority that this implementing actor belongs to
 * @network						Server and client
 */
simulated function int GetAttackPriority(Actor Attacker);

/**
 * Returns the health of this actor
 *
 * @return		Returns the health of this actor
 * @network		Server and client
 */
simulated function int GetHealth();

/**
 * Returns the health as a percentage value
 *
 * @return		The health as a percentage value
 * @network		Server and client
 */
simulated function float GetHealthPercentage();

/**
 * Returns the actor that implements this interface
 *
 * @return		Returns the actor that implements this interface
 * @network		Server and client
 */
simulated function Actor GetActor();

/**
 * Returns true if the actor is still valid to attack
 *
 * @return		Returns true if the actor is still valid to attack
 * @network		Server and client
 */
simulated function bool IsValidToAttack();

/**
 * Returns the amount of damage that this actor does for an attack. NOT used for spells.
 *
 * @return		The amount of damage done, with Blind taken account of.
 * @network		Server and client
 */
simulated function float GetDamage();

/**
 * Returns the amount of damage that this actor does for an attack.
 *
 * @return		The type of damage this actor does for auto-attacks.
 * @network		Server and client
 */
simulated function class<DamageType> GetDamageType();

/**
 * Returns true if the actor is currently invulnerable
 *
 * @return		Returns true if the actor is invulnerable
 * @network		Server and client
 */
simulated function bool IsInvulnerable();