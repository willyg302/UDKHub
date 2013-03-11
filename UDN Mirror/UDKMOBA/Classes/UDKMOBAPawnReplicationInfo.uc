//=============================================================================
// UDKMOBAPawnReplicationInfo
//
// Replication info which handles all single unit specific data which needs 
// to be transferred between the server and client. Information such as the 
// units' level, strength, and so forth.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPawnReplicationInfo extends PlayerReplicationInfo;

// Maximum amount of items the player can carry
const MAX_ITEM_COUNT = 6;
// Maximum amount of items the player can stash
const MAX_STASH_COUNT = 6;

// Link to the player replication info that owns this pawn
var PlayerReplicationInfo PlayerReplicationInfo;
// Current level index that this unit is at
var RepNotify int Level;
// How much mana this unit can have
var RepNotify float ManaMax;
// Spells that this unit has. This is maintained between the server and the client.
var array<UDKMOBASpell> Spells;
// Items that this unit has. This is maintained between the server and the client.
var array<UDKMOBAItem> Items;
// Items that this unit has in its stash. This is maintained between the server and the client
var array<UDKMOBAItem> Stash;
// Base strength of the unit (from levels and starting amount)
var float Strength;
// Base agility of the unit (from levels and starting amount)
var float Agility;
// Base intelligence of the unit (from levels and starting amount)
var float Intelligence;
// How much health the pawn should regenerate per second
var float HealthRegenerationAmount;
// How much mana the pawn should regenerate per second
var float ManaRegenerationAmount;
// How much damage this unit does
var float Damage;
// How much armor this unit has
var float Armor;
// How much magic resistance this unit has
var float MagicResistance;
// Whether this unit cannot take damage from magic
var bool MagicImmunity;
// Attack speed multiplier for this unit
var float AttackSpeed;
// How far this unit can see during the day
var float Sight;
// How far this unit can see during the night
var float SightNight;
// How far away this unit can attack enemies
var float Range;
// How fast this unit can run
var float Speed;
// Whether this unit can be seen by others
var bool Visibility;
// Whether this unit can see invisible characters
var bool TrueSight;
// Whether this unit can run through other heros
var bool Colliding;
// Whether this unit can cast spells/abilities
var bool CanCast;
// How often this unit will evade an attack
var float Evasion;
// How often this unit will miss an attack
var float Blind;
// How often this unit will evade a magic attack
var float MagicEvasion;
// How much to multiply magic damage from this unit
var float MagicAmp;
// How often this unit will miss a magic attack
var float Unpracticed;
// Default dropped item archetype
var UDKMOBADroppedItem DroppedItemArchetype;

// Replication block
replication
{
	// Replicate only if the values are dirty, this replication info is owned by the player and from server to client
	if (bNetDirty && bNetOwner)
		HealthRegenerationAmount, ManaRegenerationAmount, Evasion, Blind, MagicEvasion, MagicAmp, Unpracticed;

	// Replicate only if the values are dirty and from server to client
	if (bNetDirty)
		PlayerReplicationInfo, ManaMax, Level, Strength, Agility, Intelligence, Damage, Armor, MagicResistance, MagicImmunity, AttackSpeed, Sight, SightNight, Range, Speed, Visibility, TrueSight, Colliding, CanCast;
}

/**
 * Called when this actor is first initialized
 *
 * @network		All
 */
simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// Set the items and stash maximum amounts
	Items.Add(MAX_ITEM_COUNT);
	Stash.Add(MAX_STASH_COUNT);
}

/**
 * Purchases an item
 *
 * @param		ItemArchetype		Item archetype to purchase
 * @network							Server
 */
function PurchaseItem(UDKMOBAItem ItemArchetype)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local UDKMOBAItem Item;
	local UDKMOBAShopAreaVolume UDKMOBAShopAreaVolume;
	local UDKMOBADroppedItem DroppedItem;
	local int i, j;
	local Vector SpawnLocation;
	local Rotator SpawnRotation;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo == None)
	{
		return;
	}

	UDKMOBAPlayerController = UDKMOBAPlayerController(UDKMOBAPlayerReplicationInfo.Owner);
	if (UDKMOBAPlayerController == None)
	{
		return;
	}

	// Take away money
	UDKMOBAPlayerReplicationInfo.ModifyMoney(-ItemArchetype.BuyCost);

	// Spawn the item for the player
	Item = Spawn(ItemArchetype.Class, UDKMOBAPlayerController,,,, ItemArchetype);
	if (Item == None)
	{
		return;
	}

	Item.OwnerReplicationInfo = Self;
	Item.ClientSetOwner(UDKMOBAPlayerController);

	// Check if I can give the player the item directly
	UDKMOBAShopAreaVolume = UDKMOBAShopAreaVolume(UDKMOBAPlayerController.HeroPawn.PhysicsVolume);
	if (UDKMOBAShopAreaVolume != None && UDKMOBAShopAreaVolume.GetTeamNum() == UDKMOBAPlayerController.HeroPawn.GetTeamNum())
	{
		// Look for an available slot
		for (i = 0; i < Items.Length; ++i)
		{
			if (Items[i] == None)
			{
				AddItem(Item, i);
				// Set the inventory index, so when the item is replicated to the client they know where to put it
				Item.InventoryIndex = i;				

				// Check for auto creation
				if (ItemArchetype.AutoCreatedItems.Length > 0)
				{
					CheckForItemAutoCreation(UDKMOBAPlayerController, ItemArchetype, false);
				}

				// Check all items to see if any item needs to be activated
				for (j = 0; j < Items.Length; ++j)
				{
					if (Items[j] != None)
					{
						CheckForItemActivation(Items[j], false);
					}
				}

				return;
			}
		}
	}

	// Check if I can give the player the item in his/her stash
	for (i = 0; i < Stash.Length; ++i)
	{
		if (Stash[i] == None)
		{
			AddStashItem(Item, i);
			// Set the stash index, so when the item is replicated to the client they know where to put it
			Item.StashIndex = i;
			if (ItemArchetype.AutoCreatedItems.Length > 0)
			{
				CheckForItemAutoCreation(UDKMOBAPlayerController, ItemArchetype, true);
			}

			// Check all items to see if any item needs to be activated
			for (j = 0; j < Items.Length; ++j)
			{
				if (Items[j] != None)
				{
					CheckForItemActivation(Items[j], true);
				}
			}

			return;
		}
	}

	// Spawn the pick up
	if (DroppedItemArchetype != None)
	{
		// Find some where random to spawn the dropped pick up. Get the shop owned by the players team
		foreach AllActors(class'UDKMOBAShopAreaVolume', UDKMOBAShopAreaVolume)
		{
			if (UDKMOBAShopAreaVolume.GetTeamNum() == UDKMOBAPlayerController.HeroPawn.GetTeamNum())
			{
				SpawnLocation.X = RandRange(UDKMOBAShopAreaVolume.UpperLeftCorner.X, UDKMOBAShopAreaVolume.LowerRightCorner.X); 
				SpawnLocation.Y = RandRange(UDKMOBAShopAreaVolume.UpperLeftCorner.Y, UDKMOBAShopAreaVolume.LowerRightCorner.Y);
				SpawnLocation.Z = RandRange(UDKMOBAShopAreaVolume.UpperLeftCorner.Z, UDKMOBAShopAreaVolume.LowerRightCorner.Z);

				SpawnRotation.Yaw = RandRange(0, 65536);
				
				DroppedItem = Spawn(DroppedItemArchetype.Class,,, SpawnLocation, SpawnRotation, DroppedItemArchetype);
				if (DroppedItem != None)
				{
					DroppedItem.Item = Item;
				}

				return;
			}
		}		
	}
}

/**
 * Checks for item activation
 *
 * @param		Item			Item to check to see if they can be activated
 * @param		UsingStash		If true, then check the stash
 * @network						Server
 */
function CheckForItemActivation(UDKMOBAItem Item, bool UsingStash)
{
	local int i, j;
	local array<UDKMOBAItem> ActivationRequirementsCopy;

	// Early out
	if (Item.Activated || Item.ActivationRequirements.Length <= 0)
	{
		return;
	}

	ActivationRequirementsCopy = Item.ActivationRequirements;
	// Iterate through each requirement and see if it exists
	for (i = 0; i < ActivationRequirementsCopy.Length; ++i)
	{
		// Only using the stash
		if (UsingStash)
		{
			for (j = 0; j < Stash.Length; ++j)
			{
				// If there is a matching archetype, then remove it from the activation requirements list
				if (Stash[j] != None && Stash[j].Activated && Stash[j].ObjectArchetype == ActivationRequirementsCopy[i])
				{
					ActivationRequirementsCopy.Remove(i, 1);
					i--;
					break;
				}
			}
		}
		// Not using the stash 
		else
		{
			for (j = 0; j < Items.Length; ++j)
			{
				// If there is a matching object archetype, then remove it from the activation requirements list
				if (Items[j] != None && Items[j].Activated && Items[j].ObjectArchetype == ActivationRequirementsCopy[i])
				{
					ActivationRequirementsCopy.Remove(i, 1);
					i--;
					break;
				}
			}
		}
	}

	// If not all items required are present, then abort
	if (ActivationRequirementsCopy.Length > 0)
	{
		return;
	}

	// Activate the item
	Item.ActivateItem();

	// Remove the required items
	if (UsingStash)
	{
		for (i = 0; i < Item.ActivationRequirements.Length; ++i)
		{
			for (j = 0; j < Stash.Length; ++j)
			{
				if (Stash[j] != None && Stash[j].Activated && Stash[j].ObjectArchetype == Item.ActivationRequirements[i])
				{
					RemoveStashItem(j);
				}
			}
		}
	}
	else
	{
		for (i = 0; i < Item.ActivationRequirements.Length; ++i)
		{
			for (j = 0; j < Items.Length; ++j)
			{
				if (Items[j] != None && Items[j].Activated && Items[j].ObjectArchetype == Item.ActivationRequirements[i])
				{
					RemoveItem(j);
				}
			}
		}
	}
}

/**
 * Checks for item auto creation
 *
 * @param		UDKMOBAPlayerController		Player controller that is auto creating the item
 * @param		ItemArchetype				Item archetype to check for auto creation
 * @param		UsingStash					If true, then use the stash only
 * @network									Server
 */
function CheckForItemAutoCreation(UDKMOBAPlayerController UDKMOBAPlayerController, UDKMOBAItem ItemArchetype, bool UsingStash)
{
	local int i, j, k;
	local array<UDKMOBAItem> PlayerInventoryCopy, ItemRequirementsCopy;
	local bool IsInShopArea, RemovedItem;
	
	if (ItemArchetype.AutoCreatedItems.Length > 0)
	{
		IsInShopArea = true;
		if (UDKMOBAPlayerController.HeroPawn != None)
		{
			IsInShopArea = UDKMOBAShopAreaVolume(UDKMOBAPlayerController.HeroPawn.PhysicsVolume) != None;
		}

		// Iterate through each potential new item
		for (i = 0; i < ItemArchetype.AutoCreatedItems.Length; ++i)
		{
			if (ItemArchetype.AutoCreatedItems[i].AutoCreateRequirements.Length > 0)
			{
				// Check to make sure requirements are met
				if (!UsingStash)
				{
					PlayerInventoryCopy = Items;

					// Add the stash items as well
					if (IsInShopArea)
					{
						for (j = 0; j < Stash.Length; ++j)
						{
							if (Stash[j] != None)
							{
								PlayerInventoryCopy.AddItem(Stash[j]);
							}
						}
					}
				}
				else
				{
					PlayerInventoryCopy = Stash;
				}

				ItemRequirementsCopy = ItemArchetype.AutoCreatedItems[i].AutoCreateRequirements;

				for (j = 0; j < ItemRequirementsCopy.Length; ++j)
				{
					if (ItemRequirementsCopy[j] != None)
					{
						for (k = 0; k < PlayerInventoryCopy.Length; ++k)
						{
							// Match, so pop it from both arrays
							if (PlayerInventoryCopy[k] != None && ItemRequirementsCopy[j] == PlayerInventoryCopy[k].ObjectArchetype)
							{
								ItemRequirementsCopy.Remove(j, 1);
								PlayerInventoryCopy.Remove(k, 1);
								j--;
								k--;
								break;
							}
						}
					}
					else
					{
						ItemRequirementsCopy.Remove(j, 1);
						j--;
					}
				}

				// All requirements have been met, so spawn the item for the player
				if (ItemRequirementsCopy.Length <= 0)
				{
					for (j = 0; j < ItemArchetype.AutoCreatedItems[i].AutoCreateRequirements.Length; ++j)
					{
						if (UsingStash)
						{
							// Remove the items from the stash
							for (k = 0; k < Stash.Length; ++k)
							{
								if (Stash[k] != None && Stash[k].ObjectArchetype == ItemArchetype.AutoCreatedItems[i].AutoCreateRequirements[j])
								{
									RemoveStashItem(k);
									break;
								}
							}
						}
						else
						{
							// If in the shop area, remove from stash first; if not removed from the stash then remove from the player's inventory
							if (IsInShopArea)
							{
								RemovedItem = false;
								for (k = 0; k < Stash.Length; ++k)
								{
									if (Stash[k] != None && Stash[k].ObjectArchetype == ItemArchetype.AutoCreatedItems[i].AutoCreateRequirements[j])
									{
										RemoveStashItem(k);
										RemovedItem = true;
										break;
									}
								}

								if (!RemovedItem)
								{
									for (k = 0; k < Items.Length; ++k)
									{
										if (Items[k] != None && Items[k].ObjectArchetype == ItemArchetype.AutoCreatedItems[i].AutoCreateRequirements[j])
										{
											RemoveItem(k);
											break;
										}
									}
								}
							}
							// Remove from the players inventory
							else
							{
								for (k = 0; k < Items.Length; ++k)
								{
									if (Items[k] != None && Items[k].ObjectArchetype == ItemArchetype.AutoCreatedItems[i].AutoCreateRequirements[j])
									{
										RemoveItem(k);
										break;
									}
								}
							}
						}
					}

					PurchaseItem(ItemArchetype.AutoCreatedItems[i]);
					return;
				}
			}
		}
	}
}

/**
 * Returns true if something can be trasferred to the stash
 *
 * @param		StashIndex		Index to stash into
 * @return						Returns true if an item can be transferred to the stash index
 * @network						All
 */
simulated function bool CanTransferStashToInventory(int StashIndex)
{
	local int i, ItemCount;

	// Check if there is enough space
	if (Items.Length > 0)
	{
		for (i = 0; i < Items.Length; ++i)
		{
			if (Items[i] != None)
			{
				ItemCount++;
			}
		}

		if (ItemCount >= MAX_ITEM_COUNT)
		{
			return false;
		}
	}

	return true;
}

/**
 * Transfers an item from the stash to inventory. 
 *
 * @param		StashIndex		Index into the stash array to transfer into the inventory array
 * @network						All
 */
simulated function TransferStashToInventory(int StashIndex)
{
	local int i;
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAHUD UDKMOBAHUD;
	local UDKMOBAItem ItemTransferred, ItemTransferredObjectArchetype;

	if (StashIndex < 0 || StashIndex >= Stash.Length || Stash[StashIndex] == None)
	{
		return;
	}
	
	for (i = 0; i < Items.Length; ++i)
	{
		if (Items[i] == None)
		{
			ItemTransferred = Stash[StashIndex];
			Stash[StashIndex] = None;

			ItemTransferred.StashIndex = INDEX_NONE;
			ItemTransferred.InventoryIndex = i;			

			AddItem(ItemTransferred, i);

			// Notify the HUD for the player that owns this pawn replication info
			if (PlayerReplicationInfo != None)
			{
				foreach WorldInfo.AllControllers(class'UDKMOBAPlayerController', UDKMOBAPlayerController)
				{
					if (UDKMOBAPlayerController.PlayerReplicationInfo == PlayerReplicationInfo)
					{
						UDKMOBAHUD = UDKMOBAHUD(UDKMOBAPlayerController.MyHUD);
						if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
						{
							UDKMOBAHUD.HUDMovie.NotifyItemReceived(ItemTransferred, i, UDKMOBAHUD.HUDMovie.InventoryItemMCs);
							UDKMOBAHUD.HUDMovie.NotifyItemReceived(None, StashIndex, UDKMOBAHUD.HUDMovie.StashItemMCs);
						}

						// Ask the game info to check for combination
						ItemTransferredObjectArchetype = UDKMOBAItem(ItemTransferred.ObjectArchetype);
						if (Role == Role_Authority && ItemTransferredObjectArchetype.AutoCreatedItems.Length > 0)
						{
							CheckForItemAutoCreation(UDKMOBAPlayerController, ItemTransferredObjectArchetype, false);
						}

						break;
					}
				}
			}

			break;
		}
	}
}

/**
 * This adds an item to the Items array and ensures that no duplicates are added
 *
 * @param		NewItem			New item to add
 * @param		ItemIndex		Where in the items array to add this item
 * @network						Server and client
 */
simulated function AddItem(UDKMOBAItem NewItem, int ItemIndex)
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	// Abort if the new item was none, if the new item's owner is not me, and if I've already added the item to the items array
	if (NewItem == None || NewItem.OwnerReplicationInfo != Self || Items.Find(NewItem) != INDEX_NONE)
	{
		return;
	}

	// Add the item
	Items[ItemIndex] = NewItem;
	
	// Notify the HUD for the player that owns this pawn replication info
	if (PlayerReplicationInfo != None)
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PlayerController)
		{
			if (PlayerController.PlayerReplicationInfo == PlayerReplicationInfo)
			{
				UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
				if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
				{
					UDKMOBAHUD.HUDMovie.NotifyItemReceived(NewItem, ItemIndex, UDKMOBAHUD.HUDMovie.InventoryItemMCs);
					break;
				}
			}
		}
	}
}

/**
 * Removes an item from the inventory
 * 
 * @param		ItemIndex		Index into the inventory array to remove
 * @network						Server
 */
simulated function RemoveItem(int ItemIndex)
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	if (ItemIndex < 0 || ItemIndex >= Items.Length || Items[ItemIndex] == None)
	{
		return;
	}

	Items[ItemIndex].Destroy();
	Items[ItemIndex] = None;

	// Notify the HUD for the player that owns this pawn replication info
	if (PlayerReplicationInfo != None)
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PlayerController)
		{
			if (PlayerController.PlayerReplicationInfo == PlayerReplicationInfo)
			{
				UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
				if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
				{
					UDKMOBAHUD.HUDMovie.NotifyItemReceived(None, ItemIndex, UDKMOBAHUD.HUDMovie.InventoryItemMCs);
					break;
				}
			}
		}
	}
}

/**
 * This adds an item to the Stash array and ensures that no duplicates are added
 *
 * @param		NewItem			New item to add
 * @param		StashIndex		Where in the stash array to add this item
 * @network						Server and client
 */
simulated function AddStashItem(UDKMOBAItem NewItem, int StashIndex)
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	// Abort if the new item was none, if the new item's owner is not me, and if I've already added the item to the items array
	if (NewItem == None || NewItem.OwnerReplicationInfo != Self || Stash.Find(NewItem) != INDEX_NONE)
	{
		return;
	}

	// Add the item
	Stash[StashIndex] = NewItem;

	// Notify the HUD for the player that owns this pawn replication info
	if (PlayerReplicationInfo != None)
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PlayerController)
		{
			if (PlayerController.PlayerReplicationInfo == PlayerReplicationInfo)
			{
				UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
				if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
				{
					UDKMOBAHUD.HUDMovie.NotifyItemReceived(NewItem, StashIndex, UDKMOBAHUD.HUDMovie.StashItemMCs);
					break;
				}
			}
		}
	}
}

/**
 * Removes an item from the stash
 *
 * @param		StashItemIndex		Index into the stash array to remove
 * @network							Server
 */
simulated function RemoveStashItem(int StashItemIndex)
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;

	if (StashItemIndex < 0 || StashItemIndex >= Stash.Length || Stash[StashItemIndex] == None)
	{
		return;
	}

	Stash[StashItemIndex].Destroy();
	Stash[StashItemIndex] = None;

	// Notify the HUD for the player that owns this pawn replication info
	if (PlayerReplicationInfo != None)
	{
		foreach WorldInfo.AllControllers(class'PlayerController', PlayerController)
		{
			if (PlayerController.PlayerReplicationInfo == PlayerReplicationInfo)
			{
				UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
				if (UDKMOBAHUD != None && UDKMOBAHUD.HUDMovie != None)
				{
					UDKMOBAHUD.HUDMovie.NotifyItemReceived(None, StashItemIndex, UDKMOBAHUD.HUDMovie.StashItemMCs);
					break;
				}
			}
		}
	}
}

/**
 * This adds a spell to the Spells array and ensures that no duplicates are added
 *
 * @param		NewSpell		New spell to add
 * @param		SpellIndex		Where in the spells array to add this spell
 * @network						Server and client
 */
simulated function AddSpell(UDKMOBASpell NewSpell, int SpellIndex)
{
	// Abort if the new spell was none, if the new spell's owner is not me, and if I've already added the spell to the spells array
	if (NewSpell == None || NewSpell.OwnerReplicationInfo != Self || Spells.Find(NewSpell) != INDEX_NONE)
	{
		return;
	}

	// Add the spell
	Spells[SpellIndex] = NewSpell;
}

/**
 * Called immediately when a hero gets enough experience for going up a level. Will emit effects, sounds etc for this event
 *
 * @network		Server and client
 */
simulated function GainLevel()
{
	Level++;
}

/**
 * Return the damage of the hero, including modifier like buffs, items, etc for display. In 'XX +X' format, showing base vs buffs
 *
 * @return		Returns the armor as text
 * @network		Server and client
 */
simulated function String GetDamageText()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None && UDKMOBAPlayerReplicationInfo.HeroArchetype != None)
	{
		if (Damage == UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseDamage)
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseDamage));
		}
		else
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseDamage))@"+"$String(int(Damage) - int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseDamage));
		}
	}

	return String(Int(Damage));
}

/**
 * Return the armor of the hero, including modifier like buffs, items, etc for display. In 'XX +X' format, showing base vs buffs
 *
 * @return		Returns the armor as text
 * @network		Server and client
 */
simulated function String GetArmorText()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None && UDKMOBAPlayerReplicationInfo.HeroArchetype != None)
	{
		if (Armor == UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseArmor)
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseArmor));
		}
		else
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseArmor))@"+"$String(int(Armor) - int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseArmor));
		}
	}

	return String(Int(Armor));
}

/**
 * Return the speed of the hero, including modifiers like buffs, items, etc for display. In 'XX +X' format, showing base vs buffs
 *
 * @return		Returns the speed as text
 * @network		Server and client
 */
simulated function String GetSpeedText()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None && UDKMOBAPlayerReplicationInfo.HeroArchetype != None)
	{
		if (Speed == UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseSpeed)
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseSpeed));
		}
		else
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseSpeed))@"+"$String(int(Speed) - int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseSpeed));
		}
	}

	return String(Int(Speed));
}

/**
 * Return the strength of the hero, including modifiers like buffs, items, etc for display. In 'XX +X' format, showing base vs buffs
 *
 * @return		Returns the strength as text
 * @network		Server and client
 */
simulated function String GetStrengthText()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None && UDKMOBAPlayerReplicationInfo.HeroArchetype != None)
	{
		if (Strength == UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseStrength)
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseStrength));
		}
		else
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseStrength))@"+"$String(int(Strength) - int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseStrength));
		}
	}

	return String(Int(Strength));
}

/**
 * Return the agility of the hero, including modifiers like buffs, items, etc for display. In 'XX +X' format, showing base vs buffs
 *
 * @return		Returns the agility as text
 * @network		Server and client
 */
simulated function String GetAgilityText()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None && UDKMOBAPlayerReplicationInfo.HeroArchetype != None)
	{
		if (Agility == UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseAgility)
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseAgility));
		}
		else
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseAgility))@"+"$String(int(Agility) - int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseAgility));
		}
	}

	return String(Int(Agility));
}

/**
 * Return the intelligence of the hero, including modifiers like buffs, items, etc for display. In 'XX +X' format, showing base vs buffs
 *
 * @return		Returns the intelligence as text
 * @network		Server and client
 */
simulated function String GetIntelligenceText()
{
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;

	UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerReplicationInfo);
	if (UDKMOBAPlayerReplicationInfo != None && UDKMOBAPlayerReplicationInfo.HeroArchetype != None)
	{
		if (Intelligence == UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseIntelligence)
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseIntelligence));
		}
		else
		{
			return String(int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseIntelligence))@"+"$String(int(Intelligence) - int(UDKMOBAPlayerReplicationInfo.HeroArchetype.BaseIntelligence));
		}
	}

	return String(Int(Intelligence));
}

// Default properties block
defaultproperties
{
	Level=1
	ManaMax=10
	DroppedItemArchetype=UDKMOBADroppedItem'UDKMOBA_Game_Resources.Items.DroppedItem'
}