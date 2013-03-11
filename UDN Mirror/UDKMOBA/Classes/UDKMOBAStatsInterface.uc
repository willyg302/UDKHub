//=============================================================================
// UDKMOBAStatsInterface
//
// Interface that should be implemented by actors that show expose some of the
// basic statistics such as health and mana.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKMOBAStatsInterface;

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
 * Returns true if the actor implementing this interface can have mana
 *
 * @return		True if the actor implementing this interface can have mana
 * @network		Server and client
 */
simulated function bool HasMana();

/**
 * Returns the mana as a percentage value
 *
 * @return		Return the mana as a percentage value
 * @network		Server and client
 */
simulated function float GetManaPercentage();