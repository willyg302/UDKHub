//=============================================================================
// UDKMOBAHUD_Properties
// 
// Archetyped object used for storing property used by the HUD
//
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAHUD_Properties extends Object
	HideCategories(Object);

// All of thse are depracated
var(ReceivedMoney) const Font ReceivedMoneyFont<DisplayName=Font>;
var(ReceivedMoney) const float ReceivedMoneyLifeTime<DisplayName=Life Time>;
var(ReceivedMoney) const float ReceivedMoneyZLift<DisplayName=Z Lift>;
var(ReceivedMoney) const Color ReceivedMoneyColor<DisplayName=Color>;

// Sound to play back when a generic message is received
var(Sounds) const SoundCue GenericMessageReceived; // SoundCue'a_interface.RadioChirps.Radio_ChirpIn01_Cue'
// Sound to play back when a command is denied
var(Sounds) const SoundCue CommandDenied; // SoundCue'a_interface.menu.UT3MenuErrorCue'

// Default properties block
defaultproperties
{
}