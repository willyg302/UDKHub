//=============================================================================
// UDKMOBADecalActorSpawnable
//
// This is a spawnable movable decal actor.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBADecalActorSpawnable extends DecalActorMovable;

/**
 * Sets the decal material to use
 *
 * @param		NewMaterialInterface		Decal material to use
 * @network									Server and client
 */
simulated function SetDecalMaterial(MaterialInterface NewMaterialInterface)
{
	if (Decal != None && NewMaterialInterface != None)
	{
		Decal.SetDecalMaterial(NewMaterialInterface);
	}
}

/**
 * Sets the decal size of the decal component
 *
 * @param		NewSize		New size of the decal projected by the decal component
 * @network					Server and client
 */
simulated function SetDecalSize(Vector2D NewSize)
{
	if (Decal != None)
	{
		Decal.Width = NewSize.X;
		Decal.Height = NewSize.Y;
	}
}

// Default properties block
defaultproperties
{
	Begin Object Name=NewDecalComponent
		DecalMaterial=Material'EngineMaterials.DefaultDecalMaterial'
	End Object

	bNoDelete=false
}