//=============================================================================
// UDKMOBACameraProperties_Mobile
//
// Camera properties used by the camera. Stored here to allow easy manipulation
// from within Unreal Editor. This is an abstract class, and platforms should
// extend this.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACameraProperties_Mobile extends UDKMOBACameraProperties;

// How high off the ground the camera should be, used on Mobile only
var(Camera) const float HoverDistance;

// Default properties block
defaultproperties
{
}