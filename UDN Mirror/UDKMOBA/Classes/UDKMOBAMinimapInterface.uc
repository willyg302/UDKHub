//=============================================================================
// UDKMOBAMinimapInterface
//
// Interface that should be implemented by actors that is visible on the 
// minimap.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
interface UDKMOBAMinimapInterface;

// Enum of all of the layers
enum EMinimapLayer
{
	EML_None<DisplayName=No Layer>,
	EML_Ping<DisplayName=Ping Layer>,
	EML_Heroes<DisplayName=Heroes Layer>,
	EML_Couriers<DisplayName=Couriers Layer>,
	EML_Creeps<DisplayName=Creeps Layer>,
	EML_Towers<DisplayName=Towers Layer>,
	EML_Buildings<DisplayName=Buildings Layer>,
	EML_JungleCreeps<DisplayName=Jungle creeps Layer>,
};

/**
 * Returns what layer this actor should have it's movie clip in Scaleform
 *
 * @return		Returns the layer enum
 * @network		Server and client
 */
simulated function EMinimapLayer GetMinimapLayer();

/**
 * Returns whether or not this actor is still valid to be rendered on the mini map
 *
 * @return		Returns true if the mini map should render this actor or not
 * @network		Server and client
 */
simulated function bool IsVisibleOnMinimap();

/**
 * Returns the actor that implements this interface
 *
 * @return		Returns the actor that implements this interface
 * @network		Server and client
 */
simulated function Actor GetActor();

/**
 * Returns the name of the movie clip symbol to instance on the minimap
 *
 * @return		Returns the name of the movie clip symbol to instance on the minimap
 * @network		Server and client
 */
simulated function String GetMinimapMovieClipSymbolName();

/**
 * Updates the minimap icon
 *
 * @param		MinimapIcon		GFxObject which represents the minimap icon
 * @network						Server and client
 */
simulated function UpdateMinimapIcon(UDKMOBAGFxMinimapIconObject MinimapIcon);