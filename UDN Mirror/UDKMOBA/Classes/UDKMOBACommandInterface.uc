//=============================================================================
// UDKMOBACommandInterface
//
// Interface that should be implemented by actors that the player can interact
// with.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKMOBACommandInterface;

/**
 * Returns true if the requesting player replication info is able to follow this actor
 *
 * @param		RequestingPlayerReplicationInfo			PlayerReplicationInfo that is asking
 * @return												Returns true if the requesting player can follow this actor
 * @network												Server and client
 */
simulated function bool CanBeFollowed(PlayerReplicationInfo RequestingPlayerReplicationInfo);

/**
 * Returns true if the requesting player replication info is able to attack this actor
 *
 * @param		RequestingPlayerReplicationInfo			PlayerReplicationInfo that is asking
 * @return												Returns true if the requesting player can attack this actor
 * @network												Server and client
 */
simulated function bool CanBeAttacked(PlayerReplicationInfo RequestingPlayerReplicationInfo);