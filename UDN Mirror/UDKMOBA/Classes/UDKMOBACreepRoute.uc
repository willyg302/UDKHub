//=============================================================================
// UDKMOBACreepRoute
//
// This is an Unreal Editor placeable actor used for defining the route points
// for a creep to follow. This doesn't extend from NavgiationPoint because
// there is no need to affect the navigation tree with this, since the game
// is using navigation meshes.
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACreepRoute extends Actor
	ClassGroup(MOBA)
	HideCategories(Attachment, Collision, Physics, Debug, Object)
	Placeable;

// Default properties block
defaultproperties
{
	bEdShouldSnap=true
	bStatic=true
	bNoDelete=true
	bCollideWhenPlacing=true

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.Flag1'
		HiddenGame=true
		HiddenEditor=false
		AlwaysLoadOnClient=false
		AlwaysLoadOnServer=false
		SpriteCategoryName="Pawns"
	End Object
	Components.Add(Sprite)

	Begin Object Class=CylinderComponent Name=CollisionCylinder
		CollisionRadius=50.f
		CollisionHeight=50.f
	End Object
	CollisionComponent=CollisionCylinder
	Components.Add(CollisionCylinder)
}