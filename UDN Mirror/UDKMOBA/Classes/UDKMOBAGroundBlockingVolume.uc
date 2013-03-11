//=============================================================================
// UDKMOBAGroundBlockingVolume
//
// Blocking volume which blocks zero extent traces, to make it easier for
// level designers to make new levels.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAGroundBlockingVolume extends BlockingVolume;

// Default properties block
defaultproperties
{
	Begin Object Name=BrushComponent0
		BlockZeroExtent=true
	End Object
}