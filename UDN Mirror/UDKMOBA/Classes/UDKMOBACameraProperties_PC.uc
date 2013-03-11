//=============================================================================
// UDKMOBACameraProperties_PC
//
// Camera properties used by the camera. Stored here to allow easy manipulation
// from within Unreal Editor. This is an abstract class, and platforms should
// extend this.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBACameraProperties_PC extends UDKMOBACameraProperties;

// Camera plane
var(Camera) const Vector MovementPlane;
// Camera plane normal
var(Camera) const Vector MovementPlaneNormal;

// Default properties block
defaultproperties
{	
}