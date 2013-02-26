class NESave extends Object;

// Last unlocked level the player has reached. (default is 1, since level 1 is unlocked)
var int Level;
// Whether the game has been beaten. Once it has, time stops incrementing.
var bool bBeatGame;

/* Total values.
 * Time stops being counted once game is beaten, but others continue to add up.
 */
var int Time, Deaths, Restarts, Points;

/* Auxiliary values.
 * These represent the difference between the total value and the sum of all level values.
 * Since players can replay to lower their individual level time/deaths/etc. but their
 * total time/deaths/etc. goes up. Achievements points go into AuxPoints.
 */
var int AuxTime, AuxDeaths, AuxRestarts, AuxPoints;

/* Level-specific values.
 * These are recalculated upon each level end and replay, so players can replay levels
 * to lower time/deaths/etc. and improve points.
 */
var int LevelTime[50], LevelDeaths[50], LevelRestarts[50], LevelPoints[50];

/* Temporary values for the current level being played (whether replay or not)
 * All three are zeroed out if the user quits to menu or beats the level.
 * In the case of beating the level, these are copied into the appropriate level arrays.
 * Time/deaths also clear upon every restart, but CurRestarts propagates across it.
 */
var int CurTime, CurDeaths, CurRestarts;


/** GAME SETTINGS **/

/* VOLUME MULTIPLIERS. 1.0 = normal. 1.5 = loud. 0.1 = barely audible.
 * Since our sounds are manually played, these have no bearing on sound
 * groups and instead directly affect the sounds being played.
 */
var float SFXVolume, MusicVolume;

/* Invert movement means that pressing left moves ball right, vice versa.
 * Flip controls means that rotate controls are on the bottom, movement on top.
 */
var bool bInvertMovement, bFlipControls;

/** END GAME SETTINGS **/


/* We be nice and save these values so that the user can go back to the
 * settings screen and find it the same way he last left it.
 */
var int CurSettingsTab, CurSettingsLevel, CurSettingsAchievement;


/* 0 for locked, 1 for unlocked
 * UnlockedAchievements is what the game trusts and displays.
 * GCAchievements is what the game believes is the current state of GC unlocks.
 * At game startup, we test to see that the two are the same. If they are not,
 * we unlock GCAchievements until they are.
 */
var byte UnlockedAchievements[15], GCAchievements[15];


function bool SaveGame()
{
     return class'Engine'.static.BasicSaveObject(self, "neverendsave.bin", true, 1);
}

function bool LoadGame()
{
     return class'Engine'.static.BasicLoadObject(self, "neverendsave.bin", true, 1);
}

// Just to be safe...
defaultproperties
{
	Level=1
	bBeatGame=false
	
	// TOTALS
	Time=0
	Deaths=0
	Restarts=0
	Points=0

	// AUXILIARY
	AuxTime=0
	AuxDeaths=0
	AuxRestarts=0
	AuxPoints=0

	// We assume the level arrays will be 0-initialized.

	// CURRENT LEVELS
	CurTime=0
	CurDeaths=0
	CurRestarts=0

	// GAME SETTINGS
	SFXVolume=1.0
	MusicVolume=1.0
	bInvertMovement=false
	bFlipControls=false
	
	// SETTINGS MENU SAVE STUFF
	CurSettingsTab=0
	CurSettingsLevel=0;
	CurSettingsAchievement=0;
}
