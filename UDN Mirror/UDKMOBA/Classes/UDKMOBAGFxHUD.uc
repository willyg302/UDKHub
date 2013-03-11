//=============================================================================
// UDKMOBAGFxHUD
//
// Handles the display of information to the player, as well as interpretting
// some input from the player (clicking of HUD buttons etc)
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxHUD extends GFxMoviePlayer
	DependsOn(UDKMOBAMinimapInterface);

// Data used for tracking hero status
struct SHeroStatusBar
{
	var UDKMOBAGFxHeroStatusBarObject StatusBar;
	var UDKMOBAHeroPawn AssociatedHeroPawn;
};

// Data used for tracking creep status
struct SCreepStatusBar
{
	var UDKMOBAGFxCreepStatusBarObject StatusBar;
	var UDKMOBACreepPawn AssociatedCreepPawn;
};

// Data used for tracking tower status
struct STowerStatusBar
{
	var UDKMOBAGFxTowerStatusBarObject StatusBar;
	var UDKMOBATowerObjective AssociatedTowerObjective;
};

// Hero ability details
struct SHeroAbilityDetails
{
	var GFxObject AbilityMC;
	var GFxClikWidget LevelUpButton;
	var int CastSpellIndex;
	var int CurrentLevel;
	var int MaxLevel;
	var array<GFxObject> LevelMCs;
};

// Minimap icon details
struct SGFxMinimapIconLayerDetails
{
	var array<UDKMOBAGFxMinimapIconObject> MinimapIcons;
	var GFxObject LayerMC;
	var int LayerMCWidth;
	var int LayerMCHeight;
	var EMinimapLayer Layer;
};

// Shop item categories	(Basics 1, Basics 2, Basics 3, ... Upgrades 1, Upgrades 2, Upgrades 3, ...)
struct SGFxShopItemCategory
{
	var bool IsActive;
	var GFxClikWidget ItemCategoryRB;
	var string Tooltip;
	var UDKMOBAGFxShopListWidget ItemCategoryLst;
};

// Shop item types (Basics, upgrades)
struct SGFxShopItemType
{
	var bool IsActive;
	var GFxClikWidget ItemTypeRB;
	var GFxObject ItemCategoryMC;
	var array<SGFxShopItemCategory> ItemCategories;
};

// Inventory item object
struct SGFxInventoryItem
{
	var GFxClikWidget ButtonBtn;
	var GFxObject LabelTF;
	var GFxObject LabelBG;
	var GFxObject LevelTF;
	var GFxObject LevelBG;
	var GFxObject ItemICN;
};

// Root MC
var GFxObject RootMC;
// Top Bar
var GFxObject TopBackgroundMC;
// Menus
var GFxObject MenusAreaMC;
// Main menu button
var GFxClikWidget MainMenuButtonCB;
// Teams
var GFxObject TeamsAreaMC;
// Day night
var GFxObject DayNightMC;
var GFxObject DayNightBackgroundMC;
var GFxObject DayNightIndicatorMC;
var GFxObject DayNightTimerTF;
// Stats
var GFxObject StatsAreaMC;
var GFxObject StatsKDALabelTF;
var GFxObject StatsKDAValueTF;
var GFxObject StatsLHDLabelTF;
var GFxObject StatsLHDValueTF;
var GFxObject TeamsKillsTF;
var GFxObject TeamsDeathsTF;

// Hero Box
var GFxObject HeroAreaMC;
var GFxObject HeroBoxMC;
var GFxObject HeroNameTF;
var GFxObject HeroLevelMC;
var GFxObject HeroLevelStateTF;
var GFxObject HeroLevelProgressMC;
var GFxClikWidget LevelUpButtonCB;

// Hero Abilities Box
var GFxObject HeroAbilitiesAreaMC;
var GFxObject HeroHealthBarMaskMC;
var GFxObject HeroHealthStateTF;
var GFxObject HeroHealthPlusTF;
var GFxObject HeroManaBarMaskMC;
var GFxObject HeroManaStateTF;
var GFxObject HeroManaPlusTF;
var array<SHeroAbilityDetails> HeroAbilities;

// Minimap Box
var GFxObject MinimapAreaMC;
var GFxObject MinimapRadioButtonsMC;
var GFxClikWidget MinimapRadioButtonsGroup;
var GFxClikWidget MinimapCameraRB;
var GFxClikWidget MinimapMoveRB;
var GFxClikWidget MinimapDrawingRB;
var GFxClikWidget MinimapPingRB;
var GFxObject MinimapMC;
var UDKMOBAGFxMinimapLineDrawingObject MinimapFrustumMC;
var UDKMOBAGFxMinimapLineDrawingObject MinimapLineDrawingMC;
var GFxClikWidget MinimapCB;
var array<SGFxMinimapIconLayerDetails> MinimapIconMCLayers;
// Index used so that new symbol instances will always be created
var int MinimapIconIndex;
// Index used so that new symbol instances will always be created
var int MinimapPingIndex;
// Array of mini map pings
var array<GFxObject> MinimapPingMCs;

// Hero Stats Box
var GFxObject HeroStatsAreaMC;
var GFxClikWidget HeroStatsLevelUpCB;
var GFxObject HeroStatsDamageTF;
var GFxObject HeroStatsArmorTF;
var GFxObject HeroStatsSpeedTF;
var GFxObject HeroStatsStrengthTF;
var GFxObject HeroStatsAgilityTF;
var GFxObject HeroStatsIntelligenceTF;

// Shop widgets
var GFxObject ShopAreaMC;
var array<SGFxShopItemType> Shop;
// If true, then the shop is visible
var bool IsShopVisible;
var GFxObject ShopCategoryTooltipMC;
var GFxObject ShopCategoryTooltipTF;

// Inventory widgets
var GFxObject InventoryAreaMC;
var GFxClikWidget ShopCB;
var GFxObject CashTF;
var GFxObject StashTF;
var array<SGFxInventoryItem> InventoryItemMCs;
var array<SGFxInventoryItem> StashItemMCs;

// Log widgets
struct SLogMessage
{
	var GFxObject MessageTF;
	var GFxObject MessageMC;
	var float ExpireTime;
};

var GFxObject LogAreaMC;
var array<SLogMessage> LogMessages;
var GFxObject CenteredLogAreaMC;
var array<SLogMessage> CenteredLogMessages;

// Status bars
var GFxObject StatusBarAreaMC;
var array<STowerStatusBar> TowerStatusBars;
var array<SCreepStatusBar> CreepStatusBars;
var array<SHeroStatusBar> HeroStatusBars;

// Triggered when the user is actually 'applying' a level upgrade - choosing spell upgrade etc
var bool LevelUpMode;

// Dynamically drawn hero icons
var array<GFxObject> TeamLeftHeroes, TeamRightHeroes;

// Cached value for whether it's daytime or not (true = day)
var bool bIsDay;

var bool bSpellsInitialized;
var bool bInitialized;
var bool bCapturingMouseInput;

// Array of all minimap interfaces
var ProtectedWrite array<UDKMOBAMinimapInterface> MinimapInterfaces;
// Cached camera location
var ProtectedWrite Vector LastCameraLocation;
// Cached camera rotation
var ProtectedWrite Rotator LastCameraRotation;
// GFx HUD Properties
var const UDKMOBAGFxHUDProperties Properties;
// If true, then the mini map button is pressed
var ProtectedWrite bool MinimapButtonPressed;
// If true, then the player wants to draw on the mini map
var bool DrawOnMinimap;
// If true, then the player wants to move using the mini map
var bool MoveUsingMinimap;
// In game resolution size X
var ProtectedWrite int InGameSizeX;
// In game resolution size y
var ProtectedWrite int InGameSizeY;
// Scaleform resolution size X
var ProtectedWrite int MovieSizeX;
// Scaleform resolution size Y
var ProtectedWrite int MovieSizeY;
// Main menu object
var ProtectedWrite UDKMOBAGFxMainMenuObject MainMenuObject;
// Hero menu object
var ProtectedWrite UDKMOBAGFxHeroSelectionObject HeroMenuObject;
// Menu storage
var ProtectedWrite GFxObject MenuStorageMC;

/**
 * Called when the HUD is first displayed - needs to set everything up.
 *
 * @param		StartPaused		If true, then the movie is paused initially
 * @return						Returns true, if initialized successfully
 * @network						Client
 */
function bool Start(optional bool StartPaused = false)
{
	Super.Start();
	Advance(0);

	if (!bInitialized)
	{
		ConfigHUD();
	}

	return true;
}

/**
 * Cache references to MovieClips for later use.
 *
 * @network		Client
 */
function ConfigHUD()
{
	RootMC = GetVariableObject("root");

	MenusAreaMC = RootMC.GetObject("menusarea");
	if (MenusAreaMC != None)
	{
		MainMenuButtonCB = GFxClikWidget(MenusAreaMC.GetObject("menubuttonmain", class'GFxClikWidget'));
		if (MainMenuButtonCB != None)
		{			
			MainMenuButtonCB.AddEventListener('CLIK_buttonPress', OpenMainMenu);
			MainMenuButtonCB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
			MainMenuButtonCB.AddEventListener('CLIK_rollOut', DisableMouseCapture);
			MainMenuButtonCB.SetString("label", ParseLocalizedPropertyPath("UDKMOBA.HUD.MainMenu"));
			MainMenuButtonCB.SetBool("focused", false);	
		}
	}

	TeamsAreaMC = RootMC.GetObject("teamsarea");
	if (TeamsAreaMC != None)
	{
		TeamsKillsTF = TeamsAreaMC.GetObject("teamskills");
		TeamsDeathsTF = TeamsAreaMC.GetObject("teamsdeaths");
	}

	DayNightMC = RootMC.GetObject("daynight");
	if (DayNightMC != None)
	{
		DayNightBackgroundMC = DayNightMC.GetObject("daynightback");
		DayNightIndicatorMC = DayNightMC.GetObject("daynightbutton");
		DayNightTimerTF = DayNightMC.GetObject("daynighttimer");
	}

	StatsAreaMC = RootMC.GetObject("statsarea");
	if (StatsAreaMC != None)
	{
		StatsKDALabelTF = StatsAreaMC.GetObject("statskdalabel");
		if (StatsKDALabelTF != None)
		{
			StatsKDALabelTF.SetString("text", ParseLocalizedPropertyPath("UDKMOBA.HUD.StatsKDA"));
		}
		StatsKDAValueTF = StatsAreaMC.GetObject("statskdavalue");
		StatsLHDLabelTF = StatsAreaMC.GetObject("statslhdlabel");
		if (StatsLHDLabelTF != None)
		{
			StatsLHDLabelTF.SetString("text", ParseLocalizedPropertyPath("UDKMOBA.HUD.StatsLHD"));
		}
		StatsLHDValueTF = StatsAreaMC.GetObject("statslhdvalue");
	}

 	// Configure the hero area
	ConfigHero();

	// Configure the spells
	if (!bSpellsInitialized)
	{
		ConfigSpells();
	}

	// Configure the minimap
	ConfigMinimap();

	// Configure the shop
	ConfigShop();

	// Configure the inventory
	ConfigInventory();

	// Configure the log
	ConfigLog();

	// Configure all status bars
	ConfigStatusBars();

	// Grab the menu storage
	MenuStorageMC = RootMC.GetObject("menuStorageMC");
	if (MenuStorageMC != None)
	{
		HeroMenuObject = UDKMOBAGFxHeroSelectionObject(MenuStorageMC.AttachMovie("HeroMenu", "heromenu",, class'UDKMOBAGFxHeroSelectionObject'));
		if (HeroMenuObject != None)
		{
			HeroMenuObject.Init();
		}
	}

	bInitialized = true;
}

/**
 * Configures the hero box area
 *
 * @network		Client
 */
function ConfigHero()
{
	HeroAreaMC = RootMC.GetObject("heroarea");
	if (HeroAreaMC != None)
	{
		HeroBoxMC = HeroAreaMC.GetObject("herobox");
		if (HeroBoxMC != None)
		{
			HeroNameTF = HeroBoxMC.GetObject("heroname");
			HeroLevelMC = HeroBoxMC.GetObject("herolevel");
			if (HeroLevelMC != None)
			{
				HeroLevelStateTF = HeroLevelMC.GetObject("herolevelstate");
			}
			HeroLevelProgressMC = HeroBoxMC.GetObject("herolevelprogress");

			LevelUpButtonCB = GFxClikWidget(HeroBoxMC.GetObject("herolevelup", class'GFxClikWidget'));
			if (LevelUpButtonCB != None)
			{
				LevelUpButtonCB.AddEventListener('CLIK_buttonPress', StartLevelUp);
				LevelUpButtonCB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
				LevelUpButtonCB.AddEventListener('CLIK_rollOut', DisableMouseCapture);				
				LevelUpButtonCB.SetBool("focused", false);
				LevelUpButtonCB.SetVisible(false);	
			}

			HeroAbilitiesAreaMC = HeroAreaMC.GetObject("heroabilitiesarea");
			if (HeroAbilitiesAreaMC != None)
			{
				HeroHealthBarMaskMC = HeroAbilitiesAreaMC.GetObject("herohealthbarmask");
				HeroHealthStateTF = HeroAbilitiesAreaMC.GetObject("herohealthstate");
				if (HeroHealthStateTF != None)
				{
					HeroHealthStateTF.SetString("text", "");
				}
				HeroHealthPlusTF = HeroAbilitiesAreaMC.GetObject("herohealthplus");
				if (HeroHealthPlusTF != None)
				{
					HeroHealthPlusTF.SetString("text", "");
				}
				HeroManaBarMaskMC = HeroAbilitiesAreaMC.GetObject("heromanabarmask");
				HeroManaStateTF = HeroAbilitiesAreaMC.GetObject("heromanastate");
				if (HeroManaStateTF != None)
				{
					HeroManaStateTF.SetString("text", "");
				}
				HeroManaPlusTF = HeroAbilitiesAreaMC.GetObject("heromanaplus");
				if (HeroManaPlusTF != None)
				{
					HeroManaPlusTF.SetString("text", "");
				}
			}
		}

		HeroStatsAreaMC = HeroAreaMC.GetObject("herostatsarea");
		if (HeroStatsAreaMC != None)
		{
			HeroStatsLevelUpCB = GFxClikWidget(HeroStatsAreaMC.GetObject("herostatslevelup", class'GFxClikWidget'));
			if (HeroStatsLevelUpCB != None)
			{
				HeroStatsLevelUpCB.AddEventListener('CLIK_buttonPress', LevelUpStats);
				HeroStatsLevelUpCB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
				HeroStatsLevelUpCB.AddEventListener('CLIK_rollOut', DisableMouseCapture);
				HeroStatsLevelUpCB.SetBool("focused", false);
				HeroStatsLevelUpCB.SetVisible(false);
			}

			HeroStatsDamageTF = HeroStatsAreaMC.GetObject("herodamagetext");
			HeroStatsArmorTF = HeroStatsAreaMC.GetObject("heroarmortext");
			HeroStatsSpeedTF = HeroStatsAreaMC.GetObject("herospeedtext");
			HeroStatsStrengthTF = HeroStatsAreaMC.GetObject("herostrengthtext");
			HeroStatsAgilityTF = HeroStatsAreaMC.GetObject("heroagilitytext");
			HeroStatsIntelligenceTF = HeroStatsAreaMC.GetObject("herointelligencetext");
		}
	}
}

/**
 * Configures the mini map area
 */
function ConfigMinimap()
{
	local WorldInfo WorldInfo;
	local UDKMOBAMapInfo UDKMOBAMapInfo;
	local int i;

	MinimapAreaMC = RootMC.GetObject("minimaparea");
	if (MinimapAreaMC != None)
	{
		MinimapRadioButtonsMC = MinimapAreaMC.GetObject("minimapradiobuttons");
		if (MinimapRadioButtonsMC != None)
		{
			// On the PC platform, hide these buttons
			if (class'UDKMOBAGameInfo'.static.GetPlatform() == P_PC)
			{
				MinimapRadioButtonsMC.SetVisible(false);
			}
			// On everything else, find the radio buttons and add listener events
			else
			{
				MinimapRadioButtonsGroup = GFxClikWidget(MinimapRadioButtonsMC.GetObject("minimapGroup", class'GFxClikWidget'));
				if (MinimapRadioButtonsGroup != None)
				{
					MinimapRadioButtonsGroup.AddEventListener('CLIK_change', MinimapButtonGroupIndexChanged);
				}
				MinimapCameraRB = GFxClikWidget(MinimapRadioButtonsMC.GetObject("minimapcamerabtn", class'GFxClikWidget'));
				if (MinimapCameraRB != None)
				{
					MinimapCameraRB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
					MinimapCameraRB.AddEventListener('CLIK_rollOut', DisableMouseCapture);
				}				
				MinimapMoveRB = GFxClikWidget(MinimapRadioButtonsMC.GetObject("minimapmovebtn", class'GFxClikWidget'));
				if (MinimapMoveRB != None)
				{
					MinimapMoveRB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
					MinimapMoveRB.AddEventListener('CLIK_rollOut', DisableMouseCapture);
				}
				MinimapDrawingRB = GFxClikWidget(MinimapRadioButtonsMC.GetObject("minimapdrawbtn", class'GFxClikWidget'));
				if (MinimapDrawingRB != None)
				{
					MinimapDrawingRB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
					MinimapDrawingRB.AddEventListener('CLIK_rollOut', DisableMouseCapture);
				}
				MinimapPingRB = GFxClikWidget(MinimapRadioButtonsMC.GetObject("minimapradiobtn", class'GFxClikWidget'));
				if (MinimapPingRB != None)
				{
					MinimapDrawingRB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
					MinimapDrawingRB.AddEventListener('CLIK_rollOut', DisableMouseCapture);
				}
			}
		}
		// Initialize the mini map button
		MinimapCB = GFxClikWidget(MinimapAreaMC.GetObject("minimapbtn", class'GFxClikWidget'));
		if (MinimapCB != None)
		{
			MinimapCB.AddEventListener('CLIK_stateChange', MinimapStateChange);
			MinimapCB.AddEventListener('CLIK_rollOver', EnableMouseCapture);
			MinimapCB.AddEventListener('CLIK_rollOut', DisableMouseCapture);
		}
		// Initialize the mini map frustum 
		MinimapFrustumMC = UDKMOBAGFxMinimapLineDrawingObject(MinimapAreaMC.GetObject("minimapfrustum", class'UDKMOBAGFxMinimapLineDrawingObject'));
		MinimapFrustumMC.Init();	
		// Initialize the mini map line drawing object
		MinimapLineDrawingMC = UDKMOBAGFxMinimapLineDrawingObject(MinimapAreaMC.GetObject("minimaplinedraw", class'UDKMOBAGFxMinimapLineDrawingObject'));	
		MinimapLineDrawingMC.Init();
		// Grab the mini map
		MinimapMC = MinimapAreaMC.GetObject("minimap");
	}

	// Register all of the minimap layers
	if (Properties != None && Properties.MinimapIconLayers.Length > 0)
	{
		MinimapIconMCLayers.Length = Properties.MinimapIconLayers.Length;

		for (i = 0; i < Properties.MinimapIconLayers.Length; ++i)
		{
			if (Properties.MinimapIconLayers[i].LayerMCName != "")
			{
				MinimapIconMCLayers[i].LayerMC = MinimapMC.GetObject(Properties.MinimapIconLayers[i].LayerMCName);
				MinimapIconMCLayers[i].Layer = Properties.MinimapIconLayers[i].Layer;
				MinimapIconMCLayers[i].LayerMCWidth = MinimapIconMCLayers[i].LayerMC.GetFloat("width") * 0.5f;
				MinimapIconMCLayers[i].LayerMCHeight = MinimapIconMCLayers[i].LayerMC.GetFloat("height") * 0.5f;
			}
		}
	}

	// Assign the minimap texture
	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo != None)
	{
		UDKMOBAMapInfo = UDKMOBAMapInfo(WorldInfo.GetMapInfo());
		if (UDKMOBAMapInfo != None)
		{
			// Set the inverse value of mini map world extent
			UDKMOBAMapInfo.InverseMinimapWorldExtent = 1.f / UDKMOBAMapInfo.MinimapWorldExtent;

			if (UDKMOBAMapInfo.MinimapTexture != None)
			{
				SetExternalTexture("minimapportrait", UDKMOBAMapInfo.MinimapTexture);
			}
		}
	}
}

/**
 * Configures the shop area
 *
 * @network		Client
 */
function ConfigShop()
{
	local int i, j, k;
	local SGFxShopItemType ItemType;
	local SGFxShopItemCategory ItemCategory;
	local GFxObject GFxObject;

	ShopAreaMC = RootMC.GetObject("shoparea");
	if (ShopAreaMC != None)
	{
		ShopCategoryTooltipMC = ShopAreaMC.GetObject("tooltip");
		if (ShopCategoryTooltipMC != None)
		{
			ShopCategoryTooltipTF = ShopCategoryTooltipMC.GetObject("tooltiptext");
			ShopCategoryTooltipMC.SetVisible(false);
		}

		GFxObject = ShopAreaMC.GetObject("itemListViewLbl");
		if (GFxObject != None)
		{
			GFxObject.SetString("text", Localize("HUD", "View", "UDKMOBA"));
		}

		if (Properties.Shop.Length > 0)
		{
			for (i = 0; i < Properties.Shop.Length; ++i)
			{
				// Clear the item type variables
				ItemType.ItemTypeRB = None;
				ItemType.ItemCategoryMC = None;
				ItemType.IsActive = (i == 0);
				ItemType.ItemCategories.Remove(0, ItemType.ItemCategories.Length); 

				// Initialize the item type radio button
				ItemType.ItemTypeRB = GFxClikWidget(ShopAreaMC.GetObject(Properties.Shop[i].ItemTypeRBName, class'GFxClikWidget'));
				if (ItemType.ItemTypeRB != None)
				{
					ItemType.ItemTypeRB.SetString("label", ParseLocalizedPropertyPath(Properties.Shop[i].LocalizedItemTypeLabel));
					ItemType.ItemTypeRB.AddEventListener('CLIK_buttonPress', ChangeShopItemType);
				}

				ItemType.ItemCategoryMC = ShopAreaMC.GetObject(Properties.Shop[i].ItemCategoryMCName);
				if (ItemType.ItemCategoryMC != None)
				{
					if (Properties.Shop[i].ItemCategories.Length > 0)
					{
						for (j = 0; j < Properties.Shop[i].ItemCategories.Length; ++j)
						{
							// Clear the item category variables
							ItemCategory.ItemCategoryRB = None;
							ItemCategory.ItemCategoryLst = None;
							ItemCategory.IsActive = (j == 0);

							// Initialize the item category radio button
							ItemCategory.ItemCategoryRB = GFxClikWidget(ItemType.ItemCategoryMC.GetObject(Properties.Shop[i].ItemCategories[j].ItemCategoryRBName, class'GFxClikWidget'));
							ItemCategory.Tooltip = ParseLocalizedPropertyPath(Properties.Shop[i].ItemCategories[j].LocalizedItemCategoryTooltip);
							if (ItemCategory.ItemCategoryRB != None)
							{
								ItemCategory.ItemCategoryRB.AddEventListener('CLIK_buttonPress', ChangeShopCategory);
							}

							// Initialize the item category list
							ItemCategory.ItemCategoryLst = UDKMOBAGFxShopListWidget(ItemType.ItemCategoryMC.GetObject(Properties.Shop[i].ItemCategories[j].ItemCategoryLstName, class'UDKMOBAGFxShopListWidget'));
							if (ItemCategory.ItemCategoryLst != None)
							{
								// Hide all the lists except for the first one
								if (j != 0)
								{
									ItemCategory.ItemCategoryLst.SetVisible(false);
								}

								// Bind to the events
								ItemCategory.ItemCategoryLst.AddEventListener('CLIK_itemPress', PressShopItem);
							}
							
							ItemType.ItemCategories.AddItem(ItemCategory);
						}
					}
				
					if (i != 0)
					{
						ItemType.ItemCategoryMC.SetVisible(false);
					}
				}

				Shop.AddItem(ItemType);
			}

			// Populate the shop list
			for (i = 0; i < Shop.Length; ++i)
			{
				for (j = 0; j < Shop[i].ItemCategories.Length; ++j)
				{					
					for (k = 0; k < Properties.Shop[i].ItemCategories[j].ItemArchetypes.Length; ++k)
					{
						if (Properties.Shop[i].ItemCategories[j].ItemArchetypes[k] != None)
						{
							Shop[i].ItemCategories[j].ItemCategoryLst.AddShopItem(ParseLocalizedPropertyPath(Properties.Shop[i].ItemCategories[j].ItemArchetypes[k].ItemName), Properties.Shop[i].ItemCategories[j].ItemArchetypes[k].BuyCost, Properties.Shop[i].ItemCategories[j].ItemArchetypes[k].IconName);
						}
					}
				}
			}
		}

		ShopAreaMC.SetVisible(false);
		IsShopVisible = false;
	}
}

/**
 * Configure the inventory area
 *
 * @network		Client
 */
function ConfigInventory()
{
	local SGFxInventoryItem GFxInventoryItem;
	local int i;

	InventoryAreaMC = RootMC.GetObject("inventoryarea");
	if (InventoryAreaMC != None)
	{
		// Cash text field
		CashTF = InventoryAreaMC.GetObject("cashTxtFld");
		if (CashTF != None)
		{
			CashTF.SetString("text", "$0");
		}

		// Shop button
		ShopCB = GFxClikWidget(InventoryAreaMC.GetObject("shopBtn", class'GFxClikWidget'));
		if (ShopCB != None)
		{
			ShopCB.SetString("label", Localize("HUD", "Shop", "UDKMOBA"));
			ShopCB.AddEventListener('CLIK_buttonPress', PressShop);
			ToggleShopButtonChrome(true);
		}

		// Inventory item buttons
		for (i = 0; i < class'UDKMOBAPawnReplicationInfo'.const.MAX_ITEM_COUNT; ++i)
		{
			GFxInventoryItem.ButtonBtn = GFxClikWidget(InventoryAreaMC.GetObject("item"$i$"Btn", class'GFxClikWidget'));
			if (GFxInventoryItem.ButtonBtn != None)
			{				
				GFxInventoryItem.LabelTF = GFxInventoryItem.ButtonBtn.GetObject("textField");
				if (GFxInventoryItem.LabelTF != None)
				{
					GFxInventoryItem.LabelTF.SetVisible(false);
				}

				GFxInventoryItem.LabelBG = GFxInventoryItem.ButtonBtn.GetObject("textFieldBackground");
				if (GFxInventoryItem.LabelBG != None)
				{
					GFxInventoryItem.LabelBG.SetVisible(false);
				}

				GFxInventoryItem.ItemICN = GFxInventoryItem.ButtonBtn.GetObject("itemIcn");
				if (GFxInventoryItem.ItemICN != None)
				{
					GFxInventoryItem.ItemICN.SetVisible(false);
				}

				GFxInventoryItem.LevelTF = GFxInventoryItem.ButtonBtn.GetObject("levelTextField");
				if (GFxInventoryItem.LevelTF != None)
				{
					GFxInventoryItem.LevelTF.SetVisible(false);
				}

				GFxInventoryItem.LevelBG = GFxInventoryItem.ButtonBtn.GetObject("levelTextFieldBackground");
				if (GFxInventoryItem.LevelBG != None)
				{
					GFxInventoryItem.LevelBG.SetVisible(false);
				}
			}

			InventoryItemMCs.AddItem(GFxInventoryItem);
		}

		// Stash text field
		StashTF = InventoryAreaMC.GetObject("stashLbl");
		if (StashTF != None)
		{
			StashTF.SetString("text", Localize("HUD", "Stash", "UDKMOBA"));
		}

		for (i = 0; i < class'UDKMOBAPawnReplicationInfo'.const.MAX_STASH_COUNT; ++i)
		{
			GFxInventoryItem.ButtonBtn = GFxClikWidget(InventoryAreaMC.GetObject("stash"$i$"Btn", class'GFxClikWidget'));
			if (GFxInventoryItem.ButtonBtn != None)
			{
				GFxInventoryItem.ButtonBtn.AddEventListener('CLIK_buttonPress', OnStashItemPress);
				GFxInventoryItem.LabelTF = GFxInventoryItem.ButtonBtn.GetObject("textField");
				if (GFxInventoryItem.LabelTF != None)
				{
					GFxInventoryItem.LabelTF.SetVisible(false);
				}

				GFxInventoryItem.LabelBG = GFxInventoryItem.ButtonBtn.GetObject("textFieldBackground");
				if (GFxInventoryItem.LabelBG != None)
				{
					GFxInventoryItem.LabelBG.SetVisible(false);
				}

				GFxInventoryItem.ItemICN = GFxInventoryItem.ButtonBtn.GetObject("itemIcn");
				if (GFxInventoryItem.ItemICN != None)
				{
					GFxInventoryItem.ItemICN.SetVisible(false);
				}

				GFxInventoryItem.LevelTF = GFxInventoryItem.ButtonBtn.GetObject("levelTextField");
				if (GFxInventoryItem.LevelTF != None)
				{
					GFxInventoryItem.LevelTF.SetVisible(false);
				}

				GFxInventoryItem.LevelBG = GFxInventoryItem.ButtonBtn.GetObject("levelTextFieldBackground");
				if (GFxInventoryItem.LevelBG != None)
				{
					GFxInventoryItem.LevelBG.SetVisible(false);
				}
			}

			StashItemMCs.AddItem(GFxInventoryItem);
		}
	}
}

/**
 * Configures the log area
 *
 * @network		Client
 */
function ConfigLog()
{
	LogAreaMC = RootMC.GetObject("logarea");
	CenteredLogAreaMC = RootMC.GetObject("centeredlogarea");
}

/**
 * Configures the status bars
 *
 * @network		Client
 */
function ConfigStatusBars()
{
	local WorldInfo WorldInfo;
	local UDKMOBATowerObjective UDKMOBATowerObjective;
	local STowerStatusBar NewSTowerStatusBar;

	StatusBarAreaMC = RootMC.GetObject("statusbarsarea");
	if (StatusBarAreaMC != None)
	{
		WorldInfo = class'WorldInfo'.static.GetWorldInfo();
		if (WorldInfo != None)
		{
			foreach WorldInfo.AllActors(class'UDKMOBATowerObjective', UDKMOBATowerObjective)
			{
				NewSTowerStatusBar.StatusBar = UDKMOBAGFxTowerStatusBarObject(StatusBarAreaMC.AttachMovie("TowerStatusBar", "towerstatusbar"$TowerStatusBars.Length,, class'UDKMOBAGFxTowerStatusBarObject'));
				if (NewSTowerStatusBar.StatusBar != None)
				{
					NewSTowerStatusBar.StatusBar.Init();
					NewSTowerStatusBar.StatusBar.SetVisible(false);
				}
				NewSTowerStatusBar.AssociatedTowerObjective = UDKMOBATowerObjective;

				TowerStatusBars.AddItem(NewSTowerStatusBar);
			}
		}
	}
}

/**
 * Configures the spells by create spell buttons dynamically, and then cache references to MovieClips for spell icons for later use
 *
 * @network		Client
 */
function ConfigSpells()
{
	local UDKMOBAHeroPawn UDKMOBAHeroPawn;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local UDKMOBASpell CurSpell;
	local int SpellIndex, i, AbilityPad, LevelPad;
	local SHeroAbilityDetails CurSpellDetails;
	local GFxObject CurSpellLevel;
	local UDKMOBAGFxSpellIconObject CurSpellIcon;
	local ASDisplayInfo ASDisplayInfo;
	local PlayerInput PlayerInput;
	local GFxClikWidget CurClikButton;
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local GFxObject GFxObject;

	UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
	if (UDKMOBAPlayerController == None)
	{
		return;
	}

	UDKMOBAHeroPawn = UDKMOBAPlayerController.HeroPawn;
	if (UDKMOBAHeroPawn == None)
	{
		return;
	}

	UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAHeroPawn.PlayerReplicationInfo);
	if (UDKMOBAHeroPawnReplicationInfo == None)
	{
		return;
	}

	if (UDKMOBAHeroPawnReplicationInfo.Spells.Length > 2)
	{
		AbilityPad = 10;
		SpellIndex = 0;

		ForEach UDKMOBAHeroPawnReplicationInfo.Spells(CurSpell)
		{
			// Create spell button
			CurSpellDetails.AbilityMC = HeroAbilitiesAreaMC.AttachMovie("heroabilityicon", "herospell"$SpellIndex);
			CurClikButton = GFxClikWidget(CurSpellDetails.AbilityMC.GetObject("heroabilitymainbutton", class'GFxClikWidget'));
			CurClikButton.AddEventListener('CLIK_buttonPress', PressSpell);
			CurClikButton.AddEventListener('CLIK_rollOver', EnableMouseCapture);
			CurClikButton.AddEventListener('CLIK_rollOut', DisableMouseCapture);

			CurClikButton.SetInt("SpellIndex", SpellIndex);
			CurSpellDetails.MaxLevel = CurSpell.MaxLevel;
			CurSpellDetails.CastSpellIndex = SpellIndex;

			// Set the icon image
			CurSpellIcon = UDKMOBAGFxSpellIconObject(CurSpellDetails.AbilityMC.GetObject("iconimage", class'UDKMOBAGFxSpellIconObject'));
			CurSpellIcon.ChangeIconImage(CurSpell.IconName);

			switch (class'UDKMOBAGameInfo'.static.GetPlatform())
			{
			// Hide the key bind hint
			case P_Mobile:
				GFxObject = CurSpellDetails.AbilityMC.GetObject("heroabilitykeyhint");
				if (GFxObject != None)
				{
					GFxObject.SetVisible(false);
				}
				break;

			// Set the key bind hint
			case P_PC:
			default:
				PlayerInput = UDKMOBAPlayerController.PlayerInput;
				if (PlayerInput != None)
				{
					for (i = 0; i < PlayerInput.Bindings.Length; ++i)
					{
						if (PlayerInput.Bindings[i].Command == ("CastSpell"@SpellIndex))
						{							
							CurSpellDetails.AbilityMC.GetObject("heroabilitykeyhint").GetObject("heroabilitykeyhinttext").SetString("text", GetHintVersionOfKey(String(PlayerInput.Bindings[i].Name)));
						}
					}
				}
				break;
			}

			// hide level-up chrome
			CurClikButton = GFxClikWidget(CurSpellDetails.AbilityMC.GetObject("heroabilitylevelup", class'GFxClikWidget'));
			CurClikButton.AddEventListener('CLIK_buttonPress', LevelUpSpell);
			CurClikButton.AddEventListener('CLIK_rollOver', EnableMouseCapture);
			CurClikButton.AddEventListener('CLIK_rollOut', DisableMouseCapture);

			CurClikButton.SetInt("SpellIndex", SpellIndex);
			if (!LevelUpMode)
			{
				CurClikButton.SetVisible(false);
			}

			CurSpellDetails.LevelUpButton = CurClikButton;
			CurSpellDetails.AbilityMC.GetObject("heroabilitymanacost").SetVisible(false);

			// hide cool-down blind
			CurSpellDetails.AbilityMC.GetObject("heroabilitycooldown").SetVisible(false);

			// position spell icon
			ASDisplayInfo = CurSpellDetails.AbilityMC.GetDisplayInfo();
			ASDisplayInfo.X = 100 * SpellIndex + AbilityPad;
			ASDisplayInfo.Y = 65;
			CurSpellDetails.AbilityMC.SetDisplayInfo(ASDisplayInfo);

			// Level icons are 15px * 15px, and fit within an 80px gap
			LevelPad = 15 + ((80 - (CurSpell.MaxLevel * 15)) / (CurSpell.MaxLevel - 1));
			CurSpellDetails.LevelMCs.Remove(0, CurSpellDetails.LevelMCs.Length);
			for(i = 1; i <= CurSpell.MaxLevel; i++)
			{
				CurSpellLevel = HeroAbilitiesAreaMC.AttachMovie("heroabilitylevel", "herospelllevel"$SpellIndex$i);
				ASDisplayInfo = CurSpellLevel.GetDisplayInfo();
				ASDisplayInfo.X = 100 * SpellIndex + AbilityPad + (LevelPad * (i - 1));
				ASDisplayInfo.Y = 65 + 80 + AbilityPad;
				CurSpellLevel.SetDisplayInfo(ASDisplayInfo);
				CurSpellDetails.LevelMCs.AddItem(CurSpellLevel);
			}

			HeroAbilities.AddItem(CurSpellDetails);
			SpellIndex++;
		}

		bSpellsInitialized = true;
	}
}

/**
 * Adds a centered message to the HUD
 *
 * @param		Message			Message to display on the HUD
 * @param		LifeTime		Life time of the message
 * @network						Client
 */
function AddCenteredMessage(string Message, optional float LifeTime = 5.f)
{
	AddGenericMessage(CenteredLogMessages, CenteredLogAreaMC, "centeredLogMessage", Message, LifeTime);
}

/**
 * Adds a message to the HUD. This is usually put on the left hand
 *
 * @param		Message			Message to display on the HUD
 * @param		LifeTime		Life time of the message
 * @network						Client
 */
function AddMessage(string Message, optional float LifeTime = 2.f)
{
	AddGenericMessage(LogMessages, LogAreaMC, "logMessage", Message, LifeTime);
}

/**
 * Adds a generic message to the HUD. 
 *
 * @param		GenericMessagesArray		Messages array container
 * @param		MessageContainer			Scaleform object where all message objects will be instanced
 * @param		MessageSymbolName			Name of the Scaleform symbol which will be used when instancing the message object
 * @param		Message						Message to set
 * @param		LifeTime					Life time of the message
 * @network									Client
 */
protected function AddGenericMessage(out array<SLogMessage> GenericMessagesArray, GFxObject MessageContainer, string MessageSymbolName, string Message, float LifeTime)
{
	local SLogMessage NewSLogMessage;
	local GFxObject GFxObject;
	local int i, ReuseIndex;
	local WorldInfo WorldInfo;

	if (LogAreaMC == None)
	{
		return;
	}

	ReuseIndex = INDEX_NONE;
	if (GenericMessagesArray.Length > 0)
	{
		for (i = 0; i < GenericMessagesArray.Length; ++i)
		{
			if (GenericMessagesArray[i].MessageMC != None)
			{
				if (GenericMessagesArray[i].MessageMC.GetBool("hasExpired"))
				{
					if (ReuseIndex == INDEX_NONE)
					{					
						ReuseIndex = i;
						GenericMessagesArray[i].MessageMC.SetBool("hasExpired", false);
					}
				}
				else
				{
					GenericMessagesArray[i].MessageMC.SetFloat("y", GenericMessagesArray[i].MessageMC.GetFloat("y") - GenericMessagesArray[i].MessageMC.GetFloat("height"));
				}
			}
			else
			{
				GenericMessagesArray.Remove(i, 1);
				--i;
			}
		}
	}

	if (ReuseIndex != INDEX_NONE)
	{
		if (GenericMessagesArray[ReuseIndex].MessageMC != None)
		{
			WorldInfo = class'WorldInfo'.static.GetWorldInfo();
			if (WorldInfo != None)
			{
				GenericMessagesArray[ReuseIndex].ExpireTime = WorldInfo.TimeSeconds + LifeTime;
			}

			GenericMessagesArray[ReuseIndex].MessageMC.SetFloat("y", GenericMessagesArray[ReuseIndex].MessageMC.GetFloat("height") * -1.f);
			GenericMessagesArray[ReuseIndex].MessageMC.GotoAndPlay("show");		
			if (GenericMessagesArray[ReuseIndex].MessageTF != None)
			{
				GenericMessagesArray[ReuseIndex].MessageTF.SetString("htmlText", Message);
			}		
		}
	}
	else
	{
		NewSLogMessage.MessageMC = MessageContainer.AttachMovie(MessageSymbolName, MessageSymbolName$GenericMessagesArray.Length);
		if (NewSLogMessage.MessageMC != None)
		{
			WorldInfo = class'WorldInfo'.static.GetWorldInfo();
			if (WorldInfo != None)
			{
				NewSLogMessage.ExpireTime = WorldInfo.TimeSeconds + LifeTime;
			}

			NewSLogMessage.MessageMC.SetFloat("y", NewSLogMessage.MessageMC.GetFloat("height") * -1.f);
			NewSLogMessage.MessageMC.GotoAndPlay("show");		
			GFxObject = NewSLogMessage.MessageMC.GetObject("messageMC");
			if (GFxObject != None)
			{
				NewSLogMessage.MessageTF = GFxObject.GetObject("messageTF");
				if (NewSLogMessage.MessageTF != None)
				{
					NewSLogMessage.MessageTF.SetString("htmlText", Message);
				}		

				GenericMessagesArray.AddItem(NewSLogMessage);
			}		
		}
	}
}

/**
 * Returns the shortened version of a key's name for display on the HUD in a 'hint'. Brevity is essential - one or two characters is best
 *
 * @param		KeyName		Long name of the key
 * @network					Client
 */
function String GetHintVersionOfKey(String KeyName)
{
	local String Output;

	Output = Localize("HUD", Locs(KeyName), "UDKMOBA");
	return (Left(Output, 1) ~= "?" && Right(Output, 1) ~= "?") ? Caps(KeyName) : Output;
}

/**
 * Rescale/move things around to match the new aspect ratio
 */
function ConfigureForRes(int ResX, int ResY)
{
	local float X, Y;

	InGameSizeX = ResX;
	InGameSizeY = ResY;

	if (RootMC != None)
	{
		MovieSizeX = 1920.f;
		MovieSizeY = 1080.f;
	}

	// Move the mini map area
	if (MinimapAreaMC != None)
	{
		X = 0.f;
		FromInGameResolutionToScaleformResolution(X, Y);
		MinimapAreaMC.SetFloat("x", X + 186.5f);
	}

	// Move the shop area
	if (ShopAreaMC != None)
	{
		X = InGameSizeX;
		FromInGameResolutionToScaleformResolution(X, Y);
		ShopAreaMC.SetFloat("x", X - 338);
	}

	// Move the inventory area
	if (InventoryAreaMC != None)
	{
		X = InGameSizeX;
		FromInGameResolutionToScaleformResolution(X, Y);
		InventoryAreaMC.SetFloat("x", X - 373.f);
	}

	// Move the stats area
	if (StatsAreaMC != None)
	{
		X = InGameSizeX;
		FromInGameResolutionToScaleformResolution(X, Y);
		StatsAreaMC.SetFloat("x", X - 200.f);
	}

	// Move the main menus area
	if (MenusAreaMC != None)
	{
		X = 0.f;
		FromInGameResolutionToScaleformResolution(X, Y);
		MenusAreaMC.SetFloat("x", X);
	}

	// Move the log area
	if (LogAreaMC != None)
	{
		X = 0.f;
		FromInGameResolutionToScaleformResolution(X, Y);
		LogAreaMC.SetFloat("x", X);
	}
}

/**
 * Converts from in game resolution space to Scaleform resolution space
 *
 * @param		PosX		Original position X to convert, will be replaced with the new X position
 * @param		PosY		Original position Y to convert, will be replaced with the new Y position
 */
function FromInGameResolutionToScaleformResolution(out float PosX, out float PosY)
{
	local float VirtualSizeX, OffsetX;
	
	// First get the virtual width of the in game resolution so that it matches the aspect ratio
	VirtualSizeX = (MovieSizeX * InGameSizeY) / MovieSizeY;
	// See if there is any offset at all
	OffsetX = (VirtualSizeX - InGameSizeX) * 0.5f;
	// Now calculate the output pos x
	PosX = ((OffsetX + PosX) / VirtualSizeX) * MovieSizeX;
	PosY = (PosY / InGameSizeY) * MovieSizeY;
}

/**
 * Adds a minimap interface to the minimap interfaces array if it doesn't exist
 *
 * @param		UDKMOBAMinimapInterface		Minimap interface to add
 * @network									Client
 */
function AddMinimapInterface(UDKMOBAMinimapInterface UDKMOBAMinimapInterface)
{
	if (UDKMOBAMinimapInterface != None && MinimapInterfaces.Find(UDKMOBAMinimapInterface) == INDEX_NONE)
	{
		MinimapInterfaces.AddItem(UDKMOBAMinimapInterface);
	}
}

/**
 * Removes a minimap interface to the minimap interfaces array if it exists
 *
 * @param		UDKMOBAMinimapInterface		Minimap interface to remove
 * @network									Client
 */
function RemoveMinimapInterface(UDKMOBAMinimapInterface UDKMOBAMinimapInterface)
{
	if (UDKMOBAMinimapInterface != None)
	{
		MinimapInterfaces.RemoveItem(UDKMOBAMinimapInterface);
	}
}

/**
 * Starts the timer which is responsible for clearing the drawn lines on the mini map
 *
 * @network		Client
 */
function StartTimerToClearDrawnLines()
{
	local PlayerController PlayerController;

	PlayerController = GetPC();
	if (PlayerController != None)
	{
		PlayerController.SetTimer(Properties.ClearDrawnLinesTime, false, NameOf(ClearDrawnLines), Self);
	}
}

/**
 * Stops the timer which is responsible for clearing the drawn lines on the mini map
 * 
 * @network		Client
 */
function StopTimerToClearDrawnLines()
{
	local PlayerController PlayerController;

	PlayerController = GetPC();
	if (PlayerController != None)
	{
		PlayerController.ClearTimer(NameOf(ClearDrawnLines), Self);
	}
}

/**
 * Called by a timer. Clears the drawn lines on the mini map
 *
 * @network		Client
 */
function ClearDrawnLines()
{
	if (MinimapLineDrawingMC != None)
	{
		MinimapLineDrawingMC.Clear();
	}
}

/**
 * Ensure all dynamic elements of the HUD are up to date
 *
 * @param		Canvas			Canvas instance
 * @param		DeltaTime		Time since this function was last called
 * @network						Server
 */
function Tick(Canvas Canvas, float DeltaTime)
{
	local PlayerController PlayerController;
	local UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo;
	local int Index;

	UpdateGameTimer();
	UpdateDayNightCycle();
	UpdateStats();
	UpdateHeroes();
	UpdateCurrentHero();

	if (!bSpellsInitialized)
	{
		ConfigSpells();
	}
	else
	{
		UpdateHeroAbilities();
	}

	UpdateHeroStats();
	UpdateLevelUp();

	if (MinimapButtonPressed)
	{
		if (DrawOnMinimap)
		{
			if (MinimapLineDrawingMC != None)
			{
				PlayerController = GetPC();
				if (PlayerController != None)
				{
					UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(PlayerController.PlayerReplicationInfo);
					if (UDKMOBAPlayerReplicationInfo != None)
					{
						Index = class'UDKMOBAGameInfo'.default.Properties.PlayerColors.Find('ColorName', UDKMOBAPlayerReplicationInfo.PlayerColor);
						if (Index != INDEX_NONE && Index >= 0 && Index < class'UDKMOBAGameInfo'.default.Properties.PlayerColors.Length)
						{
							MinimapLineDrawingMC.DrawUsingScreenSpaceCoordinates(MinimapLineDrawingMC.GetFloat("mouseX"), MinimapLineDrawingMC.GetFloat("mouseY"), class'UDKMOBAGameInfo'.default.Properties.PlayerColors[Index].StoredColor, Properties.DrawingTimeInterval);
						}
					}
				}
			}
		}
		else if (MoveUsingMinimap)
		{
			PerformMoveUsingMinimap();
		}
		else
		{
			UpdateCameraFromMinimap();
		}
	}

	UpdateMinimap();
	UpdateMinimapFrustum();
	UpdateGenericLogMessages(LogMessages);
	UpdateGenericLogMessages(CenteredLogMessages);
	UpdateStatusBars(Canvas);
	UpdateShop();
}

/**
 * Show the appropriate tooltip when mousing over shop categories
 *
 * @network		Client
 */
function UpdateShop()
{
	local int CatCounter, SubCatCounter;
	local ASDisplayInfo DI;
	local float ButtonX;

	ShopCategoryTooltipMC.SetVisible(false);
	for (CatCounter = 0; CatCounter < Shop.Length; ++CatCounter)
	{
		for (SubCatCounter = 0; SubCatCounter < Shop[CatCounter].ItemCategories.Length; ++SubCatCounter)
		{
			if (Shop[CatCounter].ItemCategories[SubCatCounter].ItemCategoryRB.GetString("state") == "over")
			{
				// We're moused over this - show tooltip
				ShopCategoryTooltipMC.SetVisible(true);

				DI = Shop[CatCounter].ItemCategories[SubCatCounter].ItemCategoryRB.GetDisplayInfo();
				ButtonX = DI.X;

				DI = ShopCategoryTooltipMC.GetDisplayInfo();
				DI.X = ButtonX - 28.f;
				ShopCategoryTooltipMC.SetDisplayInfo(DI);
				ShopCategoryTooltipTF.SetString("text", Shop[CatCounter].ItemCategories[SubCatCounter].Tooltip);
			}
		}
	}
}

/**
 * Toggles the on screen status bars
 *
 * @param		ShowOnScreenStatsBars		If true, then the on screen status bars are shown
 * @network									Client
 */
function ToggleOnScreenStatsBars(bool ShowOnScreenStatsBars)
{
	local int i;

	if (TowerStatusBars.Length > 0)
	{
		for (i = 0; i < TowerStatusBars.Length; ++i)
		{
			if (TowerStatusBars[i].StatusBar != None && TowerStatusBars[i].AssociatedTowerObjective != None)
			{
				TowerStatusBars[i].StatusBar.SetVisible(ShowOnScreenStatsBars);
			}
		}
	}

	if (CreepStatusBars.Length > 0)
	{
		for (i = 0; i < CreepStatusBars.Length; ++i)
		{
			if (CreepStatusBars[i].StatusBar != None && CreepStatusBars[i].AssociatedCreepPawn != None)
			{
				CreepStatusBars[i].StatusBar.SetVisible(ShowOnScreenStatsBars);
			}
		}
	}

	if (HeroStatusBars.Length > 0)
	{
		for (i = 0; i < HeroStatusBars.Length; ++i)
		{
			if (HeroStatusBars[i].StatusBar != None && HeroStatusBars[i].AssociatedHeroPawn != None)
			{
				HeroStatusBars[i].StatusBar.SetVisible(ShowOnScreenStatsBars);
			}
		}
	}
}

/**
 * Updates the on screen status bars
 *
 * @param		Canvas		Canvas instance used for performing projections
 * @network					Client
 */
function UpdateStatusBars(Canvas Canvas)
{
	local int i, Index, SecIndex;
	local Vector ScreenPosition;
	local WorldInfo WorldInfo;
	local UDKMOBACreepPawn UDKMOBACreepPawn;
	local SCreepStatusBar NewSCreepStatusBar;
	local UDKMOBAHeroPawn UDKMOBAHeroPawn;
	local SHeroStatusBar NewSHeroStatusBar;

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo != None)
	{
		// Update creep status bars
		foreach WorldInfo.AllPawns(class'UDKMOBACreepPawn', UDKMOBACreepPawn)
		{
			Index = CreepStatusBars.Find('AssociatedCreepPawn', UDKMOBACreepPawn);
			// Doesn't exist, create
			if (Index == INDEX_NONE)
			{
				SecIndex = CreepStatusBars.Find('AssociatedCreepPawn', None);
				if (SecIndex != INDEX_NONE)
				{					
					CreepStatusBars[SecIndex].AssociatedCreepPawn = UDKMOBACreepPawn;
				}
				else
				{
					NewSCreepStatusBar.StatusBar = UDKMOBAGFxCreepStatusBarObject(StatusBarAreaMC.AttachMovie("CreepStatusBar", "creepstatusbar_"$CreepStatusBars.Length,, class'UDKMOBAGFxCreepStatusBarObject'));
					if (NewSCreepStatusBar.StatusBar != None)
					{
						NewSCreepStatusBar.StatusBar.Init();
						NewSCreepStatusBar.StatusBar.SetVisible(false);
					}
					NewSCreepStatusBar.AssociatedCreepPawn = UDKMOBACreepPawn;
					CreepStatusBars.AddItem(NewSCreepStatusBar);
				}
			}
		}

		if (CreepStatusBars.Length > 0)
		{
			for (i = 0; i < CreepStatusBars.Length; ++i)
			{
				if (CreepStatusBars[i].AssociatedCreepPawn != None)
				{
					// Dead, so hide the status bar and remove the association
					if (CreepStatusBars[i].AssociatedCreepPawn.Health <= 0)
					{
						CreepStatusBars[i].StatusBar.SetVisible(false);
						CreepStatusBars[i].AssociatedCreepPawn = None;
					}
					// Update position
					else
					{
						ScreenPosition = Canvas.Project(CreepStatusBars[i].AssociatedCreepPawn.Location + Vect(0.f, 0.f, 1.f) * CreepStatusBars[i].AssociatedCreepPawn.GetCollisionHeight());
						FromInGameResolutionToScaleformResolution(ScreenPosition.X, ScreenPosition.Y);
						CreepStatusBars[i].StatusBar.SetPosition(ScreenPosition.X, ScreenPosition.Y);
						CreepStatusBars[i].StatusBar.UpdateHealth(float(CreepStatusBars[i].AssociatedCreepPawn.Health) / float(CreepStatusBars[i].AssociatedCreepPawn.HealthMax));
						CreepStatusBars[i].StatusBar.GotoAndStop((CreepStatusBars[i].AssociatedCreepPawn.GetTeamNum() == GetPC().GetTeamNum()) ? "friendly" : "enemy");
					}
				}
				else
				{
					CreepStatusBars[i].StatusBar.SetVisible(false);
				}
			}
		}

		// Update creep status bars
		foreach WorldInfo.AllPawns(class'UDKMOBAHeroPawn', UDKMOBAHeroPawn)
		{
			Index = HeroStatusBars.Find('AssociatedHeroPawn', UDKMOBAHeroPawn);
			// Doesn't exist, create
			if (Index == INDEX_NONE)
			{
				SecIndex = HeroStatusBars.Find('AssociatedHeroPawn', None);
				if (SecIndex != INDEX_NONE)
				{					
					HeroStatusBars[SecIndex].AssociatedHeroPawn = UDKMOBAHeroPawn;
				}
				else
				{
					NewSHeroStatusBar.StatusBar = UDKMOBAGFxHeroStatusBarObject(StatusBarAreaMC.AttachMovie("HeroStatusBar", "creepstatusbar_"$HeroStatusBars.Length,, class'UDKMOBAGFxHeroStatusBarObject'));
					if (NewSHeroStatusBar.StatusBar != None)
					{
						NewSHeroStatusBar.StatusBar.Init();
						NewSHeroStatusBar.StatusBar.SetVisible(false);
					}
					NewSHeroStatusBar.AssociatedHeroPawn = UDKMOBAHeroPawn;
					HeroStatusBars.AddItem(NewSHeroStatusBar);
				}
			}
		}

		if (HeroStatusBars.Length > 0)
		{
			for (i = 0; i < HeroStatusBars.Length; ++i)
			{
				if (HeroStatusBars[i].AssociatedHeroPawn != None)
				{
					// Dead, so hide the status bar and remove the association
					if (HeroStatusBars[i].AssociatedHeroPawn.Health <= 0)
					{
						HeroStatusBars[i].StatusBar.SetVisible(false);
						HeroStatusBars[i].AssociatedHeroPawn = None;
					}
					// Update position
					else
					{
						ScreenPosition = Canvas.Project(HeroStatusBars[i].AssociatedHeroPawn.Location + Vect(0.f, 0.f, 1.f) * HeroStatusBars[i].AssociatedHeroPawn.GetCollisionHeight());
						FromInGameResolutionToScaleformResolution(ScreenPosition.X, ScreenPosition.Y);
						HeroStatusBars[i].StatusBar.SetPosition(ScreenPosition.X, ScreenPosition.Y);
						HeroStatusBars[i].StatusBar.UpdateHealth(float(HeroStatusBars[i].AssociatedHeroPawn.Health) / float(HeroStatusBars[i].AssociatedHeroPawn.HealthMax));
						HeroStatusBars[i].StatusBar.UpdateMana(HeroStatusBars[i].AssociatedHeroPawn.GetManaPercentage());
						HeroStatusBars[i].StatusBar.GotoAndStop((HeroStatusBars[i].AssociatedHeroPawn.GetTeamNum() == GetPC().GetTeamNum()) ? "friendly" : "enemy");
					}
				}
				else
				{
					HeroStatusBars[i].StatusBar.SetVisible(false);
				}
			}
		}
	}

	// Update tower status bars
	if (TowerStatusBars.Length > 0)
	{
		for (i = 0; i < TowerStatusBars.Length; ++i)
		{
			if (TowerStatusBars[i].AssociatedTowerObjective != None && TowerStatusBars[i].StatusBar != None)
			{
				if (TowerStatusBars[i].AssociatedTowerObjective.Health <= 0)
				{
					TowerStatusBars[i].StatusBar.SetVisible(false);
					TowerStatusBars[i].AssociatedTowerObjective = None;
				}
				else
				{
					ScreenPosition = Canvas.Project(TowerStatusBars[i].AssociatedTowerObjective.Location + Vect(0.f, 0.f, 64.f));
					FromInGameResolutionToScaleformResolution(ScreenPosition.X, ScreenPosition.Y);
					TowerStatusBars[i].StatusBar.SetPosition(ScreenPosition.X, ScreenPosition.Y);
					TowerStatusBars[i].StatusBar.UpdateHealth(float(TowerStatusBars[i].AssociatedTowerObjective.Health) / float(TowerStatusBars[i].AssociatedTowerObjective.HealthMax));

					if (TowerStatusBars[i].AssociatedTowerObjective.GetTeamNum() == GetPC().GetTeamNum())
					{
						TowerStatusBars[i].StatusBar.GotoAndStop("friendly");
					}
					else
					{
						if (TowerStatusBars[i].AssociatedTowerObjective.IsInvulnerable())
						{
							TowerStatusBars[i].StatusBar.GotoAndStop("invulnerable");
						}
						else
						{
							TowerStatusBars[i].StatusBar.GotoAndStop("enemy");
						}
					}
				}
			}
		}
	}
}

/**
 * Updates the generic messages. When they've expired they will be automatically hidden and array entries with no message movie clips will be removed
 *
 * @param		GenericMessagesArray		Array of generic messages to check
 * @network									Client
 */
protected function UpdateGenericLogMessages(out array<SLogMessage> GenericMessagesArray)
{
	local WorldInfo WorldInfo;
	local int i;

	if (GenericMessagesArray.Length <= 0)
	{
		return;
	}

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo != None)
	{
		for (i = 0; i < GenericMessagesArray.Length; ++i)
		{
			if (GenericMessagesArray[i].MessageMC != None)
			{
				if (GenericMessagesArray[i].ExpireTime != -1.f && WorldInfo.TimeSeconds >= GenericMessagesArray[i].ExpireTime)
				{
					GenericMessagesArray[i].MessageMC.GotoAndPlay("hide");
					GenericMessagesArray[i].ExpireTime = -1.f;
				}
			}
			else
			{
				GenericMessagesArray.Remove(i, 1);
				--i;
			}
		}
	}
}

/**
 * Keep the game timer (top-center of screen) up-to-date
 *
 * @network		Client
 */
function UpdateGameTimer()
{
	local UDKMOBAGameReplicationInfo MOBAGRI;

	MOBAGRI = UDKMOBAGameReplicationInfo(class'WorldInfo'.static.GetWorldInfo().GRI);
	if (MOBAGRI != None)
	{
		DayNightTimerTF.SetString("text", TimeFormat(MOBAGRI.ServerGameTime));
	}
}

/**
 * Rotates the day/night cycle wheel (top-center of screen) and sets the day/night cycle indicator as necessary
 *
 * @network		Client
 */
function UpdateDayNightCycle()
{
	local UDKMOBAGameReplicationInfo MOBAGRI;
	local float CycleRatio;
	local ASDisplayInfo DI;

	MOBAGRI = UDKMOBAGameReplicationInfo(class'WorldInfo'.static.GetWorldInfo().GRI);
	if (MOBAGRI != None)
	{
		CycleRatio = (MOBAGRI.ServerGameTime % class'UDKMOBAGameInfo'.default.Properties.DayNightCycleLength) / class'UDKMOBAGameInfo'.default.Properties.DayNightCycleLength;

		DI = DayNightBackgroundMC.GetDisplayInfo();
		DI.Rotation = CycleRatio * 360.f;
		DayNightBackgroundMC.SetDisplayInfo(DI);
		if (bIsDay != (CycleRatio < 0.5f))
		{
			bIsDay = (CycleRatio < 0.5f);
			if (bIsDay)
			{
				DayNightIndicatorMC.GoToAndPlay("day");
			}
			else
			{
				DayNightIndicatorMC.GoToAndPlay("night");
			}
		}

	}
}

/**
 * Update kill/death/etc stats (top-right of screen) on the HUD from the PRI
 *
 * @network		Client
 */
function UpdateStats()
{
	local UDKMOBAPlayerReplicationInfo ThePRI;
	local String ScoreBits;
	local UDKMOBAGameReplicationInfo MOBAGRI;
	local TeamInfo CurTeam;

	ThePRI = UDKMOBAPlayerReplicationInfo(GetPC().PlayerReplicationInfo);

	if (ThePRI != None)
	{
		ScoreBits = ThePRI.Kills @ "/" @ ThePRI.Deaths @ "/" @ ThePRI.Assists;
		StatsKDAValueTF.SetString("text", ScoreBits);

		ScoreBits = ThePRI.LastHits @ "/" @ ThePRI.Denies;
		StatsLHDValueTF.SetString("text", ScoreBits);

		MOBAGRI = UDKMOBAGameReplicationInfo(class'WorldInfo'.static.GetWorldInfo().GRI);
		if (MOBAGRI != None)
		{
			foreach MOBAGRI.Teams(CurTeam)
			{
				if 
				(
					// Player in game, put their team on left
					(ThePRI.Team != None && CurTeam.TeamIndex == ThePRI.Team.TeamIndex) 
					||
					// Player spectating, put good left, bad right
					(CurTeam.TeamIndex == 0)
				)
				{
					TeamsKillsTF.SetString("text", String(Int(CurTeam.Score)));
				}
				else
				{
					TeamsDeathsTF.SetString("text", String(Int(CurTeam.Score)));
				}
			}
		}
	}
}

/**
 * Draws all the hero icons (top-center of screen)
 *
 * @network		Client
 */
function UpdateHeroes()
{
	local int LocalTeamIndex;
	local int SlotsLeft, SlotsRight;
	local UDKMOBAPlayerReplicationInfo CurUDKMOBAPRI;
	local UDKMOBAHeroPawn CurPawn;
	local UDKMOBAHeroAIController CurHeroController;

	LocalTeamIndex = GetPC().GetTeamNum();

	foreach class'WorldInfo'.static.GetWorldInfo().AllPawns(class'UDKMOBAHeroPawn', CurPawn)
	{
		CurHeroController = UDKMOBAHeroAIController(CurPawn.Controller);
		if (CurHeroController != None)
		{
			CurUDKMOBAPRI = UDKMOBAPlayerReplicationInfo(CurHeroController.Controller.PlayerReplicationInfo);
			if (CurUDKMOBAPRI != None && CurUDKMOBAPRI.GetTeamNum() != 255 && CurUDKMOBAPRI.HeroArchetype != None)
			{
				// Team 0 (or the players team) go left
				if ((LocalTeamIndex != 255 && LocalTeamIndex == CurUDKMOBAPRI.GetTeamNum()) || (LocalTeamIndex == 255 && CurUDKMOBAPRI.GetTeamNum() == 0))
				{
					SlotsLeft++;
					DrawHeroIconForPRI(CurPawn, CurUDKMOBAPRI, true, SlotsLeft);
				}
				else
				{
					SlotsRight++;
					DrawHeroIconForPRI(CurPawn, CurUDKMOBAPRI, false, SlotsRight);
				}
			}
		}
	}
}

/**
 * Draw the hero icon for the given PRI - shows their alive/dead status, and if on the same team as this player, their ulti state and health
 *
 * @param		ThePawn			The hero
 * @param		ThePRI			The hero's PRI
 * @param		ShowOnLeft		If true, then show the hero icon on the left otherwise it will be on the right
 * @param		SideIndex		The position on the array
 * @network						Client
 */
function DrawHeroIconForPRI(UDKMOBAHeroPawn UDKMOBAHeroPawn, UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo, bool ShowOnLeft, int SideIndex)
{
	local GFxObject NewHeroIcon, HeroHealthMask;
	local String IconName;
	local ASDisplayInfo ASDisplayInfo;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	if (UDKMOBAPlayerReplicationInfo == None || UDKMOBAHeroPawn == None)
	{
		return;
	}

	if 
	(
		(ShowOnLeft && TeamLeftHeroes.Length >= SideIndex && TeamLeftHeroes[SideIndex - 1] != None)
		||
		(!ShowOnLeft && TeamRightHeroes.Length >= SideIndex && TeamRightHeroes[SideIndex - 1] != None)
	)
	{
		// use existing icon
		if (ShowOnLeft)
		{
			NewHeroIcon = TeamLeftHeroes[SideIndex - 1];
		}
		else
		{
			NewHeroIcon = TeamRightHeroes[SideIndex - 1];
		}
	}
	else
	{
		// create icon
		if (ShowOnLeft)
		{
			IconName = "leftheroicon"$SideIndex;
		}
		else
		{
			IconName = "rightheroicon"$SideIndex;
		}

		NewHeroIcon = TeamsAreaMC.AttachMovie("teamshero", IconName);
		if (ShowOnLeft)
		{
			TeamLeftHeroes.AddItem(NewHeroIcon);
		}
		else
		{
			TeamRightHeroes.AddItem(NewHeroIcon);
		}

		ASDisplayInfo = NewHeroIcon.GetDisplayInfo();
		if (ShowOnLeft)
		{
			ASDisplayInfo.X = -145 - (50 * SideIndex);
		}
		else
		{
			ASDisplayInfo.X = 145 + (50 * (SideIndex - 1));
		}
		ASDisplayInfo.Y = 0;
		NewHeroIcon.SetDisplayInfo(ASDisplayInfo);
	}

	if (NewHeroIcon != None)
	{
		// Color bar
		NewHeroIcon.GetObject("teamsherocolor").GoToAndStop(String(UDKMOBAPlayerReplicationInfo.PlayerColor));

		if (UDKMOBAHeroPawn.IsAliveAndWell())
		{
			// Health bar
			HeroHealthMask = NewHeroIcon.GetObject("teamsherohealth").GetObject("healthmask");
			ASDisplayInfo = HeroHealthMask.GetDisplayInfo();
			ASDisplayInfo.X = int((1.f - (float(UDKMOBAHeroPawn.Health) / float(UDKMOBAHeroPawn.HealthMax))) * -50.f);
			HeroHealthMask.SetDisplayInfo(ASDisplayInfo);

			NewHeroIcon.GetObject("teamsherodeath").SetVisible(false);
		}
		else
		{
			// Death timer
			UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAHeroPawn.PlayerReplicationInfo);
			if (UDKMOBAHeroPawnReplicationInfo != None)
			{
				NewHeroIcon.GetObject("teamsherodeath").SetVisible(true);
				NewHeroIcon.GetObject("teamsherodeath").GetObject("teamsherodeathtimer").SetString("text", String(int(UDKMOBAHeroPawnReplicationInfo.ReviveTime)));
			}
		}
	}
}

/**
 * Update level etc for the current hero (bottom-center of screen)
 *
 * @network		Client
 */
function UpdateCurrentHero()
{
	local UDKMOBAHeroPawn UDKMOBAHeroPawn;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local ASDisplayInfo ASDisplayInfo;

	if (UDKMOBAPlayerController(UDKMOBAHUD(ExternalInterface).PlayerOwner) != None)
	{
		UDKMOBAHeroPawn = UDKMOBAPlayerController(UDKMOBAHUD(ExternalInterface).PlayerOwner).HeroPawn;
		if (UDKMOBAHeroPawn != None)
		{
			UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAHeroPawn.PlayerReplicationInfo);
			if (UDKMOBAHeroPawnReplicationInfo != None)
			{
				// Health bar
				ASDisplayInfo = HeroHealthBarMaskMC.GetDisplayInfo();
				ASDisplayInfo.X = Int(400 * (Float(UDKMOBAHeroPawn.Health) / Float(UDKMOBAHeroPawn.HealthMax))) - 400;
				HeroHealthBarMaskMC.SetDisplayInfo(ASDisplayInfo);
				HeroHealthStateTF.SetString("text", UDKMOBAHeroPawn.Health@"/"@UDKMOBAHeroPawn.HealthMax);
				HeroHealthPlusTF.SetString("text", "+"$PrintFloat(UDKMOBAHeroPawnReplicationInfo.HealthRegenerationAmount, 2));

				// Name
				HeroNameTF.SetString("text", UDKMOBAHeroPawn.HeroName);

				// Experience bar
				// experience mask goes between X -146 and X -10
				HeroLevelStateTF.SetString("text", String(UDKMOBAHeroPawnReplicationInfo.Level));
				ASDisplayInfo = HeroLevelProgressMC.GetDisplayInfo();
				ASDisplayInfo.X = -10 - ((1.f - UDKMOBAHeroPawnReplicationInfo.ProgressToNextLevel()) * 136);
				HeroLevelProgressMC.SetDisplayInfo(ASDisplayInfo);

				// Level up button
				if (LevelUpButtonCB != None)
				{
					LevelUpButtonCB.SetVisible(false);
					if (UDKMOBAHeroPawnReplicationInfo.AppliedLevel < UDKMOBAHeroPawnReplicationInfo.Level)
					{
						LevelUpButtonCB.SetString("label", Repl(ParseLocalizedPropertyPath("UDKMOBA.HUD.LevelUp"), "%i", string(UDKMOBAHeroPawnReplicationInfo.Level - UDKMOBAHeroPawnReplicationInfo.AppliedLevel)));
						LevelUpButtonCB.SetVisible(true);
					}
				}

				// Mana bar
				ASDisplayInfo = HeroManaBarMaskMC.GetDisplayInfo();
				ASDisplayInfo.X = Int(400 * (UDKMOBAHeroPawn.Mana / UDKMOBAHeroPawnReplicationInfo.ManaMax)) - 400;
				HeroManaBarMaskMC.SetDisplayInfo(ASDisplayInfo);
				HeroManaStateTF.SetString("text", Int(UDKMOBAHeroPawn.Mana)@"/"@Int(UDKMOBAHeroPawnReplicationInfo.ManaMax));
				HeroManaPlusTF.SetString("text", "+"$PrintFloat(UDKMOBAHeroPawnReplicationInfo.ManaRegenerationAmount, 2));
			}
		}
	}
}

/**
 * Update level, cooldown, etc for each of the current hero's abilities (bottom-center of screen)
 *
 * @network		Client
 */
function UpdateHeroAbilities()
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAHeroPawn UDKMOBAHeroPawn;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local int i, SpellLevelIndex;

	UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
	if (UDKMOBAPlayerController != None)
	{
		UDKMOBAHeroPawn = UDKMOBAPlayerController.HeroPawn;
		if (UDKMOBAHeroPawn != None)
		{
			UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAHeroPawn.PlayerReplicationInfo);
			if (UDKMOBAHeroPawnReplicationInfo != None)
			{
				for (i = 0; i < UDKMOBAHeroPawnReplicationInfo.Spells.Length; i++)
				{
					if (HeroAbilities[i].CurrentLevel != UDKMOBAHeroPawnReplicationInfo.Spells[i].Level)
					{
						HeroAbilities[i].CurrentLevel = UDKMOBAHeroPawnReplicationInfo.Spells[i].Level;

						for (SpellLevelIndex = 0; SpellLevelIndex < HeroAbilities[i].LevelMCs.Length; SpellLevelIndex++)
						{
							if (SpellLevelIndex <= UDKMOBAHeroPawnReplicationInfo.Spells[i].Level)
							{
								HeroAbilities[i].LevelMCs[SpellLevelIndex].GoToAndStopI(2);
							}
							else
							{
								HeroAbilities[i].LevelMCs[SpellLevelIndex].GoToAndStopI(1);
							}
						}

						if (UDKMOBAHeroPawnReplicationInfo.Spells[i].Level < 0)
						{
							HeroAbilities[i].AbilityMC.GetObject("heroabilitymanacost").SetVisible(false);
						}
						else
						{
							HeroAbilities[i].AbilityMC.GetObject("heroabilitymanacost").SetVisible(true);
							HeroAbilities[i].AbilityMC.GetObject("heroabilitymanacost").GetObject("heroabilitymanacosttext").SetString("text", String(Int(UDKMOBAHeroPawnReplicationInfo.Spells[i].GetManaCost())));
						}
					}
				}
			}
		}
	}
}

/**
 * Update strength, agility, damage, etc for the current hero (bottom-center of screen)
 *
 * @network		Client
 */
function UpdateHeroStats()
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAHeroPawn UDKMOBAHeroPawn;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;

	UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
	if (UDKMOBAPlayerController != None)
	{
		UDKMOBAHeroPawn = UDKMOBAPlayerController.HeroPawn;
		if (UDKMOBAHeroPawn != None)
		{
			UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAHeroPawn.PlayerReplicationInfo);
			if (UDKMOBAHeroPawnReplicationInfo != None)
			{
				HeroStatsDamageTF.SetString("text", UDKMOBAHeroPawnReplicationInfo.GetDamageText());
				HeroStatsArmorTF.SetString("text", UDKMOBAHeroPawnReplicationInfo.GetArmorText());
				HeroStatsSpeedTF.SetString("text", UDKMOBAHeroPawnReplicationInfo.GetSpeedText());
				HeroStatsStrengthTF.SetString("text", UDKMOBAHeroPawnReplicationInfo.GetStrengthText());
				HeroStatsAgilityTF.SetString("text", UDKMOBAHeroPawnReplicationInfo.GetAgilityText());
				HeroStatsIntelligenceTF.SetString("text", UDKMOBAHeroPawnReplicationInfo.GetIntelligenceText());
			}
		}
	}
}

/**
 * Hide any 'you can upgrade' elements if the hero can't upgrade them right now
 *
 * @network		Client
 */
function UpdateLevelUp()
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBAHeroPawn UDKMOBAHeroPawn;
	local UDKMOBAHeroPawnReplicationInfo UDKMOBAHeroPawnReplicationInfo;
	local SHeroAbilityDetails CurSpell;

	UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
	if (UDKMOBAPlayerController != None)
	{
		UDKMOBAHeroPawn = UDKMOBAPlayerController.HeroPawn;
		if (UDKMOBAHeroPawn != None)
		{
			UDKMOBAHeroPawnReplicationInfo = UDKMOBAHeroPawnReplicationInfo(UDKMOBAHeroPawn.PlayerReplicationInfo);
			if (UDKMOBAHeroPawnReplicationInfo != None)
			{
				if (UDKMOBAHeroPawnReplicationInfo.Level == UDKMOBAHeroPawnReplicationInfo.AppliedLevel)
				{
					LevelUpMode = false;
					HeroStatsLevelUpCB.SetVisible(false);

					foreach HeroAbilities(CurSpell)
					{
						CurSpell.AbilityMC.GetObject("heroabilitylevelup").SetVisible(false);
					}
				}
			}
		}
	}
}

/**
 * This updates the cameras position using the mini map
 *
 * @network		Client
 */
function UpdateCameraFromMinimap()
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local UDKMOBACamera UDKMOBACamera;
	local Vector WorldLocation;
	local Vector2D MinimapLocation;
	
	// Get the player controller
	UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
	if (UDKMOBAPlayerController == None)
	{
		return;
	}

	UDKMOBACamera = UDKMOBACamera(UDKMOBAPlayerController.PlayerCamera);
	if (UDKMOBACamera != None)
	{		
		// Convert from the movie clip space to world space
		MinimapLocation.X = MinimapCB.GetFloat("mouseX") / (MinimapCB.GetFloat("width") * 0.5f);
		MinimapLocation.Y = MinimapCB.GetFloat("mouseY") / (MinimapCB.GetFloat("height") * 0.5f);
		class'UDKMOBAMapInfo'.static.MinimapToWorld(MinimapLocation, WorldLocation);

		if (UDKMOBAPlayerController.HeroPawn != None)
		{
			WorldLocation.Z = UDKMOBAPlayerController.HeroPawn.Location.Z;
		}

		// Update the camera
		UDKMOBACamera.SetDesiredCameraLocation(WorldLocation);
	}
}

/**
 * This updates the mini map
 *
 * @network		Client
 */
function UpdateMinimap()
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;
	local array<UDKMOBAMinimapInterface> ProcessingMinimapInterfaces;
	local int i, j, Index;
	local Vector RelativeMinimapPosition;
	local UDKMOBAMapInfo UDKMOBAMapInfo;
	local EMinimapLayer Layer;
	local UDKMOBAGFxMinimapIconObject MinimapIcon;
	local string MovieClipSymbolName;
	local bool HasUsedExistingMovieClip;

	PlayerController = GetPC();
	if (PlayerController == None)
	{
		return;
	}

	UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
	if (UDKMOBAHUD == None)
	{
		return;
	}

	// Get the MOBA Map Info
	UDKMOBAMapInfo = UDKMOBAMapInfo(PlayerController.WorldInfo.GetMapInfo());
	if (UDKMOBAMapInfo == None)
	{
		return;
	}

	// Copy the minimap interface across
	ProcessingMinimapInterfaces = MinimapInterfaces;

	// Iterate through all of the layers and update their MC's
	if (MinimapIconMCLayers.Length > 0)
	{
		for (i = 0; i < MinimapIconMCLayers.Length; ++i)
		{
			if (MinimapIconMCLayers[i].LayerMC != None && MinimapIconMCLayers[i].MinimapIcons.Length > 0)
			{
				for (j = 0; j < MinimapIconMCLayers[i].MinimapIcons.Length; ++j)
				{
					if (MinimapIconMCLayers[i].MinimapIcons[j].MinimapActor != None && MinimapIconMCLayers[i].MinimapIcons[j].MinimapInterface != None)
					{
						// Pop it from the mini map interfaces
						ProcessingMinimapInterfaces.RemoveItem(MinimapIconMCLayers[i].MinimapIcons[j].MinimapInterface);

						// Check if the mini map icon should still be visible or not
						if (MinimapIconMCLayers[i].MinimapIcons[j].MinimapInterface.IsVisibleOnMinimap())
						{
							if (!MinimapIconMCLayers[i].MinimapIcons[j].IsVisible)
							{
								MinimapIconMCLayers[i].MinimapIcons[j].IsVisible = true;
								MinimapIconMCLayers[i].MinimapIcons[j].SetVisible(true);
							}

							// Update the location
							// Calculate the relative minimap position
							RelativeMinimapPosition = (UDKMOBAMapInfo.MinimapWorldCenter - MinimapIconMCLayers[i].MinimapIcons[j].MinimapActor.Location) * UDKMOBAMapInfo.InverseMinimapWorldExtent;
							// Update the position 
							MinimapIconMCLayers[i].MinimapIcons[j].SetPosition(RelativeMinimapPosition.X * MinimapIconMCLayers[i].LayerMCWidth, RelativeMinimapPosition.Y * MinimapIconMCLayers[i].LayerMCHeight);
							// Update the minimap icon
							MinimapIconMCLayers[i].MinimapIcons[j].MinimapInterface.UpdateMinimapIcon(MinimapIconMCLayers[i].MinimapIcons[j]);

						}
						else if (MinimapIconMCLayers[i].MinimapIcons[j].IsVisible)
						{
							MinimapIconMCLayers[i].MinimapIcons[j].IsVisible = false;
							MinimapIconMCLayers[i].MinimapIcons[j].SetVisible(false);
						}
					}
				}
			}
		}
	}

	// For any ProcessingMinimapInterfaces remaining, we need to add them to our arrays
	if (ProcessingMinimapInterfaces.Length > 0)
	{
		for (i = 0; i < ProcessingMinimapInterfaces.Length; ++i)
		{
			if (ProcessingMinimapInterfaces[i] != None && ProcessingMinimapInterfaces[i].IsVisibleOnMinimap())
			{
				Layer = ProcessingMinimapInterfaces[i].GetMinimapLayer();
				if (Layer != EML_None)
				{
					Index = MinimapIconMCLayers.Find('Layer', Layer);
					if (Index != INDEX_NONE && MinimapIconMCLayers[Index].LayerMC != None)
					{
						HasUsedExistingMovieClip = false;
						MovieClipSymbolName = ProcessingMinimapInterfaces[i].GetMinimapMovieClipSymbolName();
						if (MovieClipSymbolName != "")
						{
							// Before creating, check if there is any free icons we can use
							for (j = 0; j < MinimapIconMCLayers[Index].MinimapIcons.Length; ++j)
							{
								if (!MinimapIconMCLayers[Index].MinimapIcons[j].IsVisible && MovieClipSymbolName ~= MinimapIconMCLayers[Index].MinimapIcons[j].MinimapIconMCSymbolName)
								{
									MinimapIconMCLayers[Index].MinimapIcons[j].MinimapInterface = ProcessingMinimapInterfaces[i];
									MinimapIconMCLayers[Index].MinimapIcons[j].MinimapActor = ProcessingMinimapInterfaces[i].GetActor();
									MinimapIconMCLayers[Index].MinimapIcons[j].IsVisible = false;
									MinimapIconMCLayers[Index].MinimapIcons[j].SetVisible(false);

									// Update the minimap icon
									MinimapIconMCLayers[Index].MinimapIcons[j].MinimapInterface.UpdateMinimapIcon(MinimapIconMCLayers[Index].MinimapIcons[j]);

									HasUsedExistingMovieClip = true;
									break;
								}
							}

							// Create a new movie to attach
							if (!HasUsedExistingMovieClip)
							{
								MinimapIcon = UDKMOBAGFxMinimapIconObject(MinimapIconMCLayers[Index].LayerMC.AttachMovie(MovieClipSymbolName, MovieClipSymbolName$MinimapIconIndex,, class'UDKMOBAGFxMinimapIconObject'));
								MinimapIcon.MinimapIconMCSymbolName = MovieClipSymbolName;
								MinimapIcon.MinimapInterface = ProcessingMinimapInterfaces[i];
								MinimapIcon.MinimapActor = ProcessingMinimapInterfaces[i].GetActor();
								MinimapIcon.IsVisible = false;
								MinimapIcon.SetVisible(false);

								// Update the minimap icon
								ProcessingMinimapInterfaces[i].UpdateMinimapIcon(MinimapIcon);

								// Append the entry
								MinimapIconMCLayers[Index].MinimapIcons.AddItem(MinimapIcon);
							}
						}
					}
				}
			}
		}
	}
}

/**
 * Updates the mini map frustum, which is drawn as an outline on the screen representing the camera bounds
 * 
 * @network		Client
 */
function UpdateMinimapFrustum()
{
	local PlayerController PlayerController;
	local UDKMOBAHUD UDKMOBAHUD;
	local int i;
	local Vector WorldOrigin, WorldDirection, Frustum[4], CameraLocation;
	local Rotator CameraRotation;
	local Vector2D ViewportResolution, ScreenFrustum[4];
	local UDKMOBAMapInfo UDKMOBAMapInfo;	
	local LocalPlayer LocalPlayer;

	PlayerController = GetPC();
	if (PlayerController == None)
	{
		return;
	}

	UDKMOBAHUD = UDKMOBAHUD(PlayerController.MyHUD);
	if (UDKMOBAHUD == None)
	{
		return;
	}

	// Get the MOBA Map Info
	UDKMOBAMapInfo = UDKMOBAMapInfo(PlayerController.WorldInfo.GetMapInfo());
	if (UDKMOBAMapInfo == None)
	{
		return;
	}

	// Update the frustum which represents the camera view
	if (MinimapFrustumMC != None)
	{
		// Grab the camera location and rotation
		PlayerController.GetPlayerViewPoint(CameraLocation, CameraRotation);

		// Check if the camera location and rotation differ, if they do then update
		if (CameraLocation != LastCameraLocation || CameraRotation != LastCameraRotation)
		{
			// Update the camera location and rotation
			LastCameraLocation = CameraLocation;
			LastCameraRotation = CameraRotation;

			LocalPlayer = LocalPlayer(PlayerController.Player);
			if (LocalPlayer != None && LocalPlayer.ViewportClient != None)
			{
				LocalPlayer.ViewportClient.GetViewportSize(ViewportResolution);

				// Clear the lines first
				MinimapFrustumMC.Clear();

				// Get each point which represents the frustum
				ScreenFrustum[0].X = 0.f;
				ScreenFrustum[0].Y = 0.f;
				ScreenFrustum[1].X = ViewportResolution.X;
				ScreenFrustum[1].Y = 0.f;
				ScreenFrustum[2].X = ViewportResolution.X;
				ScreenFrustum[2].Y = ViewportResolution.Y;
				ScreenFrustum[3].X = 0.f;
				ScreenFrustum[3].Y = ViewportResolution.Y;

				// Transform the screen coordinates to world coordinates, then to minimap coordinates
				for (i = 0; i < 4; ++i)
				{
					UDKMOBAHUD.Canvas.Deproject(ScreenFrustum[i], WorldOrigin, WorldDirection);
					class'UDKMOBAObject'.static.LinePlaneIntersection(WorldOrigin, WorldOrigin + WorldDirection * 16384.f, UDKMOBAMapInfo.MinimapFloor, Vect(0.f, 0.f, -1.f), Frustum[i]);
					Frustum[i] = (UDKMOBAMapInfo.MinimapWorldCenter - Frustum[i]) * UDKMOBAMapInfo.InverseMinimapWorldExtent;				
					Frustum[i].X *= MinimapFrustumMC.HalfWidth;
					Frustum[i].Y *= MinimapFrustumMC.HalfHeight;
				}

				// Draw the lines
				for (i = 0; i < 3; ++i)
				{
					MinimapFrustumMC.DrawLine(Frustum[i].X, Frustum[i].Y, Frustum[i + 1].X, Frustum[i + 1].Y, 255, 255, 255, 191);
				}
				MinimapFrustumMC.DrawLine(Frustum[3].X, Frustum[3].Y, Frustum[0].X, Frustum[0].Y, 255, 255, 255, 191);
			}
		}
	}
}

/**
 * Sets the hero portrait dynamically
 *
 * @param		NewHeroTexture		Texture to use for the hero portrait
 * @network							Client
 */
function SetHeroPortrait(Texture NewHeroTexture)
{
	SetExternalTexture("heroportrait", NewHeroTexture);
}

/**
 * Converts the given number of seconds into HH:mm:ss format. If the time is less than one hour, this will just be in mm:ss format (no zero hours displayed).
 *
 * @param		Seconds		Seconds The number of seconds passed.
 * @return					The time formatted as above.
 * @network					Client
 */
function String TimeFormat(float Seconds)
{
	local String Output;
	local int Minutes;

	if (Seconds > 3600)
	{
		// has hours, include them, make minutes have leading zero
		Output = FFloor(Seconds / 3600) $ ":";
		Seconds -= FFloor(Seconds / 3600);

		Minutes = FFloor(Seconds / 60);
		if (Minutes < 10)
		{
			Output $= "0" $ Minutes $ ":";
		}
	}
	else
	{
		Minutes = FFloor(Seconds / 60);
		Output = Minutes $ ":";
	}
	if ((Seconds % 60) < 10)
	{
		Output $= "0";
	}
	return Output $ Int(Seconds % 60);
}

/**
 * Called when a stash item has been clicked
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function OnStashItemPress(GFxClikWidget.EventData ev)
{
	local int Index;
	local GFxClikWidget ButtonPressed;
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	ButtonPressed = GFxClikWidget(ev._this.GetObject("target", class'GFxClikWidget'));
	if (ButtonPressed != None)
	{
		Index = StashItemMCs.Find('ButtonBtn', ButtonPressed);
		if (Index >= 0 && Index < StashItemMCs.Length)
		{
			// Attempt to transfer an item from the stash to the inventory
			UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
			if (UDKMOBAPlayerController != None)
			{
				UDKMOBAPlayerController.TranfersStashToInventory(Index);
			}
		}
	}
}

/**
 * Called when the player wants to change the type of items he/she wants to see in the shop. This is done via CLIKwidget
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function ChangeShopItemType(GFxClikWidget.EventData ev)
{
	local int i;
	local GFxClikWidget ButtonPressed;

	ButtonPressed = GFxClikWidget(ev._this.GetObject("target", class'GFxClikWidget'));
	if (ButtonPressed != None && Shop.Length > 0)
	{
		for (i = 0; i < Shop.Length; ++i)
		{
			Shop[i].ItemCategoryMC.SetVisible(Shop[i].ItemTypeRB == ButtonPressed);
			Shop[i].IsActive = Shop[i].ItemTypeRB == ButtonPressed;
		}
	}
}

/**
 * Called when the player wants to change the category of items he/she wants to see in the shop. This is done via CLIKwidget
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function ChangeShopCategory(GFxClikWidget.EventData ev)
{
	local int i, j;
	local GFxClikWidget ButtonPressed;

	ButtonPressed = GFxClikWidget(ev._this.GetObject("target", class'GFxClikWidget'));
	for (i = 0; i < Shop.Length; ++i)
	{
		if (Shop[i].IsActive)
		{
			for (j = 0; j < Shop[i].ItemCategories.Length; ++j)
			{
				Shop[i].ItemCategories[j].ItemCategoryLst.SetVisible(Shop[i].ItemCategories[j].ItemCategoryRB == ButtonPressed);
				Shop[i].ItemCategories[j].IsActive = Shop[i].ItemCategories[j].ItemCategoryRB == ButtonPressed;
			}

			break;
		}
	}
}

/**
 * Trigger display of the main menu
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function OpenMainMenu(GFxClikWidget.EventData ev)
{
	local PlayerController PlayerController;

	if (MenuStorageMC != None)
	{
		PlayerController = GetPC();
		if (PlayerController != None)
		{
			PlayerController.SetPause(true);
		}

		if (MainMenuObject == None)
		{
			MainMenuObject = UDKMOBAGFxMainMenuObject(MenuStorageMC.AttachMovie("MainMenu", "mainmenu",, class'UDKMOBAGFxMainMenuObject'));
			if (MainMenuObject != None)
			{
				MainMenuObject.Init();
			}
		}
		else
		{
			MainMenuObject.SetVisible(true);
		}
	}
}

/**
 * Show 'level up' overlay over abilities etc so player can choose how to level up
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function StartLevelUp(GFxClikWidget.EventData ev)
{
	local SHeroAbilityDetails CurSpell;

	HandleButtonPress();
	if (!LevelUpMode)
	{
		LevelUpMode = true;
		HeroStatsLevelUpCB.SetVisible(true);

		foreach HeroAbilities(CurSpell)
		{
			CurSpell.AbilityMC.GetObject("heroabilitylevelup").SetVisible(true);
		}
	}
}

/**
 * The user has chosen to 'level up' by upgrading their heros' stats
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function LevelUpStats(GFxClikWidget.EventData ev)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	HandleButtonPress();
	if (LevelUpMode)
	{
		UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
		if (UDKMOBAPlayerController != None)
		{
			UDKMOBAPlayerController.LevelUpStats();
		}
	}
}

/**
 * Called when a user clicks on a spell icon during 'level up mode'
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function LevelUpSpell(GFxClikWidget.EventData ev)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local GFxObject Button;

	HandleButtonPress();
	Button = ev._this.GetObject("target");
	if (LevelUpMode)
	{
		// upgrade the spell
		UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
		if (UDKMOBAPlayerController != None)
		{
			UDKMOBAPlayerController.LevelUpSpell(Button.GetInt("SpellIndex"));
		}
	}
}

/**
 * Players is wanting to move to a location specified by the mini map
 *
 * @network		Client
 */
function PerformMoveUsingMinimap()
{
	local Vector2D MinimapLocation;
	local Vector StartTrace, EndTrace, HitLocation, HitNormal;
	local WorldInfo WorldInfo;
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local bool DeferredMove;
	local array<Vector> ValidPositions;
	local UDKMOBAMapInfo UDKMOBAMapInfo;
	local Actor Actor;
	local int i;

	if (MinimapCB == None)
	{
		return;
	}

	UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
	if (UDKMOBAPlayerController == None)
	{
		return;
	}

	WorldInfo = class'WorldInfo'.static.GetWorldInfo();
	if (WorldInfo == None)
	{
		return;
	}

	UDKMOBAMapInfo = UDKMOBAMapInfo(WorldInfo.GetMapInfo());
	if (UDKMOBAMapInfo == None)
	{
		return;
	}

	// Get the mini map location
	MinimapLocation.X = MinimapCB.GetFloat("mouseX") / (MinimapCB.GetFloat("width") * 0.5f);
	MinimapLocation.Y = MinimapCB.GetFloat("mouseY") / (MinimapCB.GetFloat("height") * 0.5f);

	// Calculate the start trace
	class'UDKMOBAMapInfo'.static.MinimapToWorld(MinimapLocation, StartTrace);
	StartTrace.Z = 8192.f;

	// Calculate the end trace
	EndTrace = StartTrace;
	EndTrace.Z = -8192.f;

	// Perform a trace to find either UDKMOBAGroundBlockingVolume or the WorldInfo [BSP] 
	foreach UDKMOBAPlayerController.TraceActors(class'Actor', Actor, HitLocation, HitNormal, EndTrace, StartTrace)
	{
		if (class'UDKMOBAObject'.static.ShouldBlockMouseWorldTrace(Actor))
		{
			DeferredMove = false;

			// Check if this hit location is within a blocking volume
			for (i = 0; i < UDKMOBAPlayerController.BlockingVolumes.Length; ++i)
			{
				if (UDKMOBAPlayerController.BlockingVolumes[i].EncompassesPoint(HitLocation) && UDKMOBAPlayerController.NavigationHandle != None)
				{
					DeferredMove = true;
					break;
				}
			}

			// Attempt to find a valid position for the move
			if (!DeferredMove)
			{
				UDKMOBAPlayerController.NavigationHandle.GetValidPositionsForBox(HitLocation, 512.f, UDKMOBAPlayerController.HeroPawn.GetCollisionExtent(), false, ValidPositions, 1);
				if (ValidPositions.Length > 0)
				{
					for (i = 0; i < ValidPositions.Length; ++i)
					{
						// Move to the valid position
						UDKMOBAPlayerController.StartMoveCommand(ValidPositions[i]);
						break;
					}
				}
				
				break;
			}
		}
	}
}

/**
 * Enable mouse capturing
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function EnableMouseCapture(GFxClikWidget.EventData ev)
{
	bCapturingMouseInput = true;
}

/**
 * Disable mouse capturing
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function DisableMouseCapture(GFxClikWidget.EventData ev)
{
	bCapturingMouseInput = false;
}

/**
 * Called when the state of the mini map CLIKwidget has changed
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function MinimapStateChange(GFxClikWidget.EventData ev)
{
	local GFxObject Button;
	local String StateName;
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	Button = ev._this.GetObject("target");
	StateName = Button.GetString("state");	

	// Pressed
	if (StateName ~= "down")
	{
		UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
		if (UDKMOBAPlayerController != None)
		{
			if (UDKMOBAPlayerController.PingOnMinimap)
			{
				PerformPingUsingScreenSpaceCoordinates(Button.GetFloat("mouseX"), Button.GetFloat("mouseY"));
			}
			else
			{
				if (DrawOnMinimap && MinimapLineDrawingMC != None)
				{
					MinimapLineDrawingMC.LastMousePosition.X = MinimapLineDrawingMC.GetFloat("mouseX");
					MinimapLineDrawingMC.LastMousePosition.Y = MinimapLineDrawingMC.GetFloat("mouseY");
				}

				MinimapButtonPressed = true;
			}
		}
	}
	// Released
	else if (StateName ~= "release" && MinimapButtonPressed)
	{
		MinimapButtonPressed = false;
	}
}

/**
 * Performs a ping using world space coordinates. This allows players to ping using the world, and it will translate the world location to a mini map location
 *
 * @param		WorldLocation		Location in the world to ping
 * @network							Client
 */
function PerformPingUsingWorldSpaceCoordinates(Vector WorldLocation)
{
	local Vector2D MinimapLocation;
	local int Index;

	class'UDKMOBAMapInfo'.static.WorldToMinimap(WorldLocation, MinimapLocation);
	Index = MinimapIconMCLayers.Find('Layer', EML_Ping);
	if (Index != INDEX_NONE && MinimapIconMCLayers[Index].LayerMC != None)
	{
		PerformPingUsingScreenSpaceCoordinates(MinimapLocation.X * MinimapIconMCLayers[Index].LayerMC.GetFloat("width") * 0.5f, MinimapLocation.Y * MinimapIconMCLayers[Index].LayerMC.GetFloat("height") * 0.5f);
	}
}

/**
 * Performs a ping using screen space coordinates. This allows players to ping using the mini map
 *
 * @param		X									X position in screen space coordinates
 * @param		Y									Y position is screen space coordinates
 * @param		UDKMOBAPlayerReplicationInfo		Replication info that performed the ping, if none then assume the local player
 * @network											Client
 */
function PerformPingUsingScreenSpaceCoordinates(float X, float Y, optional UDKMOBAPlayerReplicationInfo UDKMOBAPlayerReplicationInfo)
{
	local int i, Index, ColorIndex;
	local GFxObject GFxObject;
	local UDKMOBAPlayerController UDKMOBAPlayerController;
	local ASColorTransform ASColorTransform;

	if (UDKMOBAPlayerReplicationInfo == None)
	{
		UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
		if (UDKMOBAPlayerController == None)
		{
			return;
		}

		UDKMOBAPlayerReplicationInfo = UDKMOBAPlayerReplicationInfo(UDKMOBAPlayerController.PlayerReplicationInfo);
		if (UDKMOBAPlayerReplicationInfo == None)
		{
			return;
		}

		UDKMOBAPlayerController.ServerBroadcastPing(X, Y);
	}

	Index = MinimapIconMCLayers.Find('Layer', EML_Ping);
	if (Index != INDEX_NONE && MinimapIconMCLayers[Index].LayerMC != None)
	{		
		// Check to see if we can reuse an existing mini map ping movie clip
		if (MinimapPingMCs.Length > 0)
		{
			for (i = 0; i < MinimapPingMCs.Length; ++i)
			{
				if (MinimapPingMCs[i] != None && MinimapPingMCs[i].GetBool("isFinished"))
				{
					GFxObject = MinimapPingMCs[i];
					GFxObject.SetBool("isFinished", false);
					GFxObject.GetObject("minimapping").GotoAndPlay("ping");
					break;
				}
			}
		}

		if (GFxObject == None)
		{
			GFxObject = MinimapIconMCLayers[Index].LayerMC.AttachMovie("minimappingwrapper", "minimappingwrapper_"$MinimapPingIndex);
			MinimapPingMCs.AddItem(GFxObject);
			MinimapPingIndex++;
		}

		// Set the position
		GFxObject.SetPosition(X, Y);
		// Set the color
		ColorIndex = class'UDKMOBAGameInfo'.default.Properties.PlayerColors.Find('ColorName', UDKMOBAPlayerReplicationInfo.PlayerColor);
		if (ColorIndex != INDEX_NONE)
		{
			ASColorTransform.multiply.R = 0.f;
			ASColorTransform.multiply.G = 0.f;
			ASColorTransform.multiply.B = 0.f;
			ASColorTransform.multiply.A = float(class'UDKMOBAGameInfo'.default.Properties.PlayerColors[ColorIndex].StoredColor.A) / 255.f;

			ASColorTransform.add.R = float(class'UDKMOBAGameInfo'.default.Properties.PlayerColors[ColorIndex].StoredColor.R) / 255.f;
			ASColorTransform.add.G = float(class'UDKMOBAGameInfo'.default.Properties.PlayerColors[ColorIndex].StoredColor.G) / 255.f;
			ASColorTransform.add.B = float(class'UDKMOBAGameInfo'.default.Properties.PlayerColors[ColorIndex].StoredColor.B) / 255.f;
			ASColorTransform.add.A = 0.f;

			GFxObject.GetObject("minimapping").SetColorTransform(ASColorTransform);
		}						
	}
}

/**
 * Called when the mini map radio buttons have changed. This is only used for mobile
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function MinimapButtonGroupIndexChanged(GFxClikWidget.EventData ev)
{
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
	if (UDKMOBAPlayerController != None)
	{
		switch (MinimapRadioButtonsGroup.GetInt("selectedIndex"))
		{
		// Move
		case 1:
			UDKMOBAPlayerController.TogglePingOnMinimap(false);
			UDKMOBAPlayerController.ToggleDrawOnMinimap(false);
			MoveUsingMinimap = true;			
			break;

		// Draw
		case 2:
			UDKMOBAPlayerController.TogglePingOnMinimap(false);
			UDKMOBAPlayerController.ToggleDrawOnMinimap(true);
			MoveUsingMinimap = false;
			break;

		// Ping
		case 3:
			UDKMOBAPlayerController.TogglePingOnMinimap(true);
			UDKMOBAPlayerController.ToggleDrawOnMinimap(false);
			MoveUsingMinimap = false;
			break;

		// Camera
		default:
			UDKMOBAPlayerController.TogglePingOnMinimap(false);
			UDKMOBAPlayerController.ToggleDrawOnMinimap(false);
			MoveUsingMinimap = false;
			break;
		}
	}
}

/**
 * Called when the shop button has been clicked. This opens the shop menu
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function PressShop(GFxClikWidget.EventData ev)
{
	if (ShopAreaMC != None)
	{
		IsShopVisible = !IsShopVisible;
		ShopAreaMC.SetVisible(IsShopVisible);
	}
}

/**
 * Called when a user clicks on a spell icon
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function PressSpell(GFxClikWidget.EventData ev)
{
	local GFxObject Button;

	HandleButtonPress();
	Button = ev._this.GetObject("target");
	ConsoleCommand("CastSpell"@Button.GetInt("SpellIndex"));
}

/**
 * Call when handling any button presses on the HUD; this prevents any other actions from occuring usually
 *
 * @network		Client
 */
function HandleButtonPress()
{
	local UDKMOBAPlayerController_Mobile UDKMOBAPlayerController_Mobile;

	switch (class'UDKMOBAGameInfo'.static.GetPlatform())
	{
	// Clear touch events to prevent them from doing anything
	case P_Mobile:
		UDKMOBAPlayerController_Mobile = UDKMOBAPlayerController_Mobile(GetPC());
		if (UDKMOBAPlayerController_Mobile != None)
		{
			UDKMOBAPlayerController_Mobile.TouchEvents.Remove(0, UDKMOBAPlayerController_Mobile.TouchEvents.Length);
		}
		break;

	default:
		break;
	}
}

/**
 * Called when a user clicks on a shop item list
 *
 * @param		ev		Event data generated by the CLIKwidget
 * @network				Client
 */
function PressShopItem(GFxClikWidget.EventData ev)
{
	local int ItemTypeIndex, ItemCategoryIndex, ItemIndex;
	local UDKMOBAPlayerController UDKMOBAPlayerController;

	if (Properties != None && Properties.Shop.Length > 0)
	{
		// Get the item type index
		ItemTypeIndex = Shop.Find('IsActive', true);
		if (ItemTypeIndex >= 0 && ItemTypeIndex < Properties.Shop.Length)
		{
			// Get the item category index
			ItemCategoryIndex = Shop[ItemTypeIndex].ItemCategories.Find('IsActive', true);
			if (ItemCategoryIndex >= 0 && ItemCategoryIndex < Properties.Shop[ItemTypeIndex].ItemCategories.Length)
			{
				// Get the item index
				ItemIndex = ev._this.GetInt("index");
				if (ItemIndex >= 0 && ItemIndex < Properties.Shop[ItemTypeIndex].ItemCategories[ItemCategoryIndex].ItemArchetypes.Length && Properties.Shop[ItemTypeIndex].ItemCategories[ItemCategoryIndex].ItemArchetypes[ItemIndex] != None)
				{
					UDKMOBAPlayerController = UDKMOBAPlayerController(GetPC());
					if (UDKMOBAPlayerController != None)
					{
						UDKMOBAPlayerController.PurchaseItem(Properties.Shop[ItemTypeIndex].ItemCategories[ItemCategoryIndex].ItemArchetypes[ItemIndex]);
					}
				}
			}
		}
	}
}

/**
 * Print the given float with the given number of decimal places - used when you want less precision than the normal 4 places.
 *
 * @param		InputFloat			Float parameter 
 * @param		DecimalPlaces		Number of decimal places you care about
 */
function String PrintFloat(float InputFloat, optional int DecimalPlaces = 0)
{
	local int DecimalIndex, DecimalsLength;
	local String OutputString;

	DecimalIndex = InStr(String(InputFloat), ".");
	OutputString = Left(String(InputFloat), DecimalIndex);
	if (DecimalPlaces > 0)
	{
		DecimalsLength = Min(Len(String(InputFloat)) - DecimalIndex - 1, DecimalPlaces);
		OutputString $= "." $ Mid(String(InputFloat), DecimalIndex + 1, DecimalsLength);
	}
	return OutputString;
}

/**
 * Handles any pending left click commands
 *
 * @network		Client
 */
function HandlePendingLeftClickCommand();

/**
 * Handles any pending right click commands
 *
 * @network		Client
 */
function HandlePendingRightClickCommand()
{
	local float HalfMinimapWidth, HalfMinimapHeight, MouseX, MouseY;

	if (MinimapCB != None)
	{
		HalfMinimapWidth = MinimapCB.GetFloat("width") * 0.5f;
		HalfMinimapHeight = MinimapCB.GetFloat("height") * 0.5f;
		MouseX = MinimapCB.GetFloat("mouseX");
		MouseY = MinimapCB.GetFloat("mouseY");

		if (MouseX <= HalfMinimapWidth && MouseY <= HalfMinimapHeight && MouseX >= -HalfMinimapWidth && MouseY >= -HalfMinimapHeight)
		{
			PerformMoveUsingMinimap();
		}
	}
}

/**
 * Toggles the shop button chrome
 *
 * @param		TintToGold		If true, then change the shop button chrome to gold
 * @network						Client
 */
function ToggleShopButtonChrome(bool TintToGold)
{
	local GFxObject GFxObject;
	local ASColorTransform ASColorTransform;

	if (ShopCB != None)
	{
		GFxObject = ShopCB.GetObject("shopBtnBackground");
		if (GFxObject != None)
		{			
			if (!TintToGold)
			{		
				ASColorTransform.Multiply = MakeLinearColor(1.f, 1.f, 1.f, 1.f);
				ASColorTransform.Add = MakeLinearColor(0.f, 0.f, 0.f, 0.f);
			}
			else
			{
				ASColorTransform.Multiply = MakeLinearColor(0.f, 0.f, 0.f, 1.f);
				ASColorTransform.Add = MakeLinearColor(255.f, 127.f, 0.f, 0.f);
			}

			GFxObject.SetColorTransform(ASColorTransform);
		}
	}
}

/**
 * Notification of when an item has been received. Depending on the item array specified, this can affect the player inventory or the player stash
 *
 * @param		NewItem			Item that has been received
 * @param		ItemIndex		Index that the item is sitting in
 * @param		ItemArray		Array of GFxClikWidgets to modify
 */
function NotifyItemReceived(UDKMOBAItem NewItem, int ItemIndex, out array<SGFxInventoryItem> ItemArray)
{
	if (ItemIndex < 0 || ItemIndex >= ItemArray.Length)
	{
		return;
	}

	// Update the icon
	if (ItemArray[ItemIndex].ItemICN != None)
	{
		if (NewItem != None && NewItem.IconName != "")
		{
			ItemArray[ItemIndex].ItemICN.SetVisible(true);
			ItemArray[ItemIndex].ItemICN.GotoAndStop(NewItem.IconName);
		}
		else
		{
			ItemArray[ItemIndex].ItemICN.SetVisible(false);
		}
	}

	// Update the levels
	if (ItemArray[ItemIndex].LevelTF != None && ItemArray[ItemIndex].LevelBG != None)
	{
		if (NewItem != None && NewItem.MaxLevel > 0)
		{
			ItemArray[ItemIndex].LevelTF.SetString("text", string(NewItem.Level));
			ItemArray[ItemIndex].LevelTF.SetVisible(true);
			ItemArray[ItemIndex].LevelBG.SetVisible(true);
		}
		else
		{
			ItemArray[ItemIndex].LevelTF.SetVisible(false);
			ItemArray[ItemIndex].LevelBG.SetVisible(false);
		}
	}

	// Update the charges
	if (ItemArray[ItemIndex].LabelTF != None && ItemArray[ItemIndex].LabelBG != None)
	{
		if (NewItem != None && NewItem.MaxCharges > 0)
		{
			ItemArray[ItemIndex].LabelTF.SetString("text", string(NewItem.Charges));
			ItemArray[ItemIndex].LabelTF.SetVisible(true);
			ItemArray[ItemIndex].LabelBG.SetVisible(true);
		}
		else
		{
			ItemArray[ItemIndex].LabelTF.SetVisible(false);
			ItemArray[ItemIndex].LabelBG.SetVisible(false);
		}
	}
}

/**
 * Called when the amount of money the player has, has been updated
 *
 * @param		Amount		New money amount
 * @network					Client
 */
function NotifyMoneyUpdated(int Amount)
{
	if (CashTF != None)
	{
		CashTF.SetString("text", "$"$Amount);
	}
}

// Default properties block
defaultproperties
{
	bDisplayWithHudOff=true
	bEnableGammaCorrection=false
	MovieInfo=SwfMovie'UDKMOBA_HUD_GFx.udkmoba_hud'
	MinimapIconIndex=0
	MinimapPingIndex=0
	Properties=UDKMOBAGFxHUDProperties'UDKMOBA_HUD_GFx_Resources.Properties.GFxHUDProperties'
}