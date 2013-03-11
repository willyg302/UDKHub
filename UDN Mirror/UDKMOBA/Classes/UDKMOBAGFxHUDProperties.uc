//=============================================================================
// UDKMOBAGFxHUDProperties
//
// Stores properties in an archetype which is used by UDKMOBAGFxHUD.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxHUDProperties extends Object
	HideCategories(Object);

// Minimap icon layer details
struct SMinimapIconLayerDetails
{
	var() const string LayerMCName;
	var() const EMinimapLayer Layer;
};

// Shop item categories	(Basics 1, Basics 2, Basics 3, ... Upgrades 1, Upgrades 2, Upgrades 3, ...)
struct SShopItemCategory
{
	var() const string ItemCategoryRBName;
	var() const string ItemCategoryLstName;
	var() const string LocalizedItemCategoryTooltip;
	var() const array<UDKMOBAItem> ItemArchetypes;
};

// Shop item types (Basics, upgrades)
struct SShopItemType
{
	var() const string LocalizedItemTypeLabel;
	var() const string ItemTypeRBName;
	var() const string ItemCategoryMCName;
	var() const array<SShopItemCategory> ItemCategories;
};

// Minimap icon layers
var(Minimap) const array<SMinimapIconLayerDetails> MinimapIconLayers;
// How long, in seconds, to wait before the next mouse point is used to draw on the mini map
var(Minimap) const float DrawingTimeInterval;
// How long, in seconds, to wait before clearing all of the drawn lines
var(Minimap) const float ClearDrawnLinesTime;

// Shop
var(Shop) const array<SShopItemType> Shop;

// Default properties block
defaultproperties
{
	MinimapIconLayers.Add((Layer=EML_Ping,LayerMCName="minimappingicons"))
	MinimapIconLayers.Add((Layer=EML_Heroes,LayerMCName="minimapheroicons"))
	MinimapIconLayers.Add((Layer=EML_Couriers,LayerMCName="minimapcouriericons"))
	MinimapIconLayers.Add((Layer=EML_Creeps,LayerMCName="minimapcreepicons"))
	MinimapIconLayers.Add((Layer=EML_Towers,LayerMCName="minimaptowericons"))
	MinimapIconLayers.Add((Layer=EML_Buildings,LayerMCName="minimapbuildingicons"))
	MinimapIconLayers.Add((Layer=EML_JungleCreeps,LayerMCName="minimapjunglecreepicons"))
	DrawingTimeInterval=0.1f
	ClearDrawnLinesTime=5.f
	// Note these are all overridden by the archetype
	Shop.Add((LocalizedItemTypeLabel="UDKMOBA.HUD.Basics",ItemTypeRBName="itemListCategoryBasicsRdBtn",ItemCategoryMCName="basicsShopLst",ItemCategories=((ItemCategoryRBName="shopListBasicOneRdBtn",ItemCategoryLstName="shopListBasicOneLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Consumables"),(ItemCategoryRBName="shopListBasicTwoRdBtn",ItemCategoryLstName="shopListBasicTwoLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Attributes"),(ItemCategoryRBName="shopListBasicThreeRdBtn",ItemCategoryLstName="shopListBasicThreeLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Armaments"),(ItemCategoryRBName="shopListBasicFourRdBtn",ItemCategoryLstName="shopListBasicFourLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Arcane"))))
	Shop.Add((LocalizedItemTypeLabel="UDKMOBA.HUD.Upgrades",ItemTypeRBName="itemListCategoryUpgradesRdBtn",ItemCategoryMCName="upgradesShopLst",ItemCategories=((ItemCategoryRBName="shopListUpgradesOneRdBtn",ItemCategoryLstName="shopListUpgradesOneLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Common"),(ItemCategoryRBName="shopListUpgradesTwoRdBtn",ItemCategoryLstName="shopListUpgradesTwoLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Support"),(ItemCategoryRBName="shopListUpgradesThreeRdBtn",ItemCategoryLstName="shopListUpgradesThreeLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Caster"),(ItemCategoryRBName="shopListUpgradesFourRdBtn",ItemCategoryLstName="shopListUpgradesFourLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Weapons"),(ItemCategoryRBName="shopListUpgradesFiveRdBtn",ItemCategoryLstName="shopListUpgradesFiveLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Armor"),(ItemCategoryRBName="shopListUpgradesSixRdBtn",ItemCategoryLstName="shopListUpgradesSixLst",LocalizedItemCategoryTooltip="UDKMOBA.HUD.Artifacts"))))
}
