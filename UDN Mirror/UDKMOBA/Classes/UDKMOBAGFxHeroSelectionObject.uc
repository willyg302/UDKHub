//=============================================================================
// UDKMOBAGFxHeroSelectionObject
//
// Hero Menu GFxObject which initializes the hero menu which allows players to
// choose their hero.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGFxHeroSelectionObject extends GFxObject;

// Demo guy button
var ProtectedWrite GFxClikWidget DemoGuyBtn;
// Cathode button
var ProtectedWrite GFxClikWidget CathodeBtn;

/**
 * Initializes the hero selection.
 *
 * @network		Server
 */
function Init()
{
	// Demo guy button
	DemoGuyBtn = GFxClikWidget(GetObject("demoGuyBtn", class'GFxClikWidget'));
	if (DemoGuyBtn != None)
	{
		DemoGuyBtn.SetString("label", Localize("Hero", "DemoGuy", "UDKMOBA"));
		DemoGuyBtn.AddEventListener('CLIK_buttonPress', OnDemoGuyPress);
	}

	// Cathode button
	CathodeBtn = GFxClikWidget(GetObject("cathodeBtn", class'GFxClikWidget'));
	if (CathodeBtn != None)
	{
		CathodeBtn.SetString("label", Localize("Hero", "Cathode", "UDKMOBA"));
		CathodeBtn.AddEventListener('CLIK_buttonPress', OnCathodePress);
	}
}

/**
 * Player wants to select the demo guy hero
 *
 * @network		Server
 */
function OnDemoGuyPress(EventData event_data)
{
	ConsoleCommand("SwitchTeam");
	ConsoleCommand("SelectDemoGuyHero");
	SetVisible(false);
}

/**
 * Player wants to select the cathode hero
 *
 * @network		Server
 */
function OnCathodePress(EventData event_data)
{
	ConsoleCommand("SwitchTeam");
	ConsoleCommand("SelectCathodeHero");
	SetVisible(false);
}

// Default properties block
defaultproperties
{
}