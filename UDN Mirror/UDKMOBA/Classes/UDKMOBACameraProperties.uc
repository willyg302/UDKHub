//=============================================================================
// UDKMOBACameraProperties
//
// Camera properties used by the camera. Stored here to allow easy manipulation
// from within Unreal Editor. This is an abstract class, and platforms should
// extend this.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACameraProperties extends Object
	HideCategories(Object)
	Abstract;

// Constant camera rotation
var(Camera) const Rotator Rotation;
// Speed at which the camera blends from one place to another
var(Camera) const float BlendSpeed;

// Default properties block
defaultproperties
{
	BlendSpeed=3.125f
}