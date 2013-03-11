//=============================================================================
// UDKMOBADroppedItem
//
// This is an actor which represents an item that has been dropped on the
// ground. These may belong to someone.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBADroppedItem extends Actor;

// Static mesh component
var() const StaticMeshComponent StaticMesh;
var() const DynamicLightEnvironmentComponent LightEnvironment;
// Item stored in the dropped item
var UDKMOBAItem Item;

// Default properties block
defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
	End Object
	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

	Begin Object Class=StaticMeshComponent Name=MyStaticMeshComponent
	    BlockRigidBody=false
		LightEnvironment=MyLightEnvironment
		bUsePrecomputedShadows=false
	End Object 
	StaticMesh=MyStaticMeshComponent
	Components.Add(MyStaticMeshComponent)

	bWorldGeometry=false
	bGameRelevant=true
	RemoteRole=ROLE_SimulatedProxy
	bCollideActors=false
}