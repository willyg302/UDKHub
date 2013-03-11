//=============================================================================
// UDKMOBAItem
//
// This class has similar features to Inventory except that these are managed
// by UDKMOBAPlayerReplicationInfo. This is because:
//
// * InventoryManager and Inventory are destroyed when pawns die.
// * Items have to be replicated with all clients.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAItem extends UDKMOBASpell
	abstract;

// How much gold is needed to buy this item from a shop
var() const int BuyCost;
// How much gold is gained when returning this item to a shop
var() const int SellValue;
// Name of the item
var() const String ItemName;
// Maximum amount of charges
var() const int MaxCharges;
// If true, then this item is activated
var() ProtectedWrite RepNotify bool Activated;
// How many charges this item has currently
var() ProtectedWrite RepNotify int Charges;

// This item is a component of these items that are automatically created
var(Receipe) array<UDKMOBAItem> AutoCreatedItems;
// This item requires these items in order to be formed automatically
var(Receipe) array<UDKMOBAItem> AutoCreateRequirements;
// This item requires these items in order to be activated
var(Receipe) array<UDKMOBAItem> ActivationRequirements;

// Replicated inventory index
var RepNotify int InventoryIndex;
// Replicated stash index
var RepNotify int StashIndex;

// Replication block
replication
{
	// Replicate if the variables are dirty and only to the owner
	if (bNetDirty && bNetOwner)
		InventoryIndex, StashIndex, Charges;

	// Replicate if the variables are dirty
	if (bNetDirty)
		Activated;
}

/**
 * Called when the item is initialized
 * 
 * @network		All
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// Items always have full charges when they spawn, if they are initially set to zero
	if (Charges == 0)
	{
		Charges = MaxCharges;
	}
}

/**
 * Called when a variable flagged as RepNotify has been replicated
 *
 * @param		VarName			Name of the variable that was replicated
 * @network						Client
 */
simulated event ReplicatedEvent(name VarName)
{
	if (VarName == NameOf(OwnerReplicationInfo) || VarName == NameOf(InventoryIndex) || VarName == NameOf(StashIndex))
	{
		// When both OwnerReplicationInfo and OrderIndex are not valid, add it
		if (OwnerReplicationInfo != None)
		{
			if (InventoryIndex != INDEX_NONE)
			{
				OwnerReplicationInfo.AddItem(Self, InventoryIndex);
			}

			if (StashIndex != INDEX_NONE)
			{
				OwnerReplicationInfo.AddStashItem(Self, StashIndex);
			}

			Initialize();
		}
	}

	Super.ReplicatedEvent(VarName);
}

/**
 * Activates the item
 *
 * @network		Server and client
 */
simulated function ActivateItem()
{
	Activated = true;
}

// Default properties block
defaultproperties
{
	Level=1
	OrderIndex=-1
	ManaCost.Empty
	HasActive=false
	MaxLevel=0
	InventoryIndex=-1
	StashIndex=-1
}