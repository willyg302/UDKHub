//=============================================================================
// UDKMOBAPortraitSkeletalMeshActor
//
// Portrait skeletal mesh actor used for the portrait on the PC HUD.
// 
// Copyright 1998-2012 Epic Games, Inc. All Rights Reserved.
//=============================================================================
class UDKMOBAPortraitSkeletalMeshActor extends Actor;

// Light environment used by the skeletal mesh
var LightEnvironmentComponent LightEnvironment;
// Skeletal mesh used by this actor
var SkeletalMeshComponent SkeletalMesh;

// Default properties block
defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=true
		bIsCharacterLightEnvironment=true
		bUseBooleanEnvironmentShadowing=false
		InvisibleUpdateTime=1
		MinTimeBetweenFullUpdates=0.2f
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=SkeletalMeshComponent Name=MySkeletalMeshComponent
		AnimTreeTemplate=AnimTree'UDKMOBA_HUD_PC_Resources.AnimTrees.HeroIdleAnimTree'
		AnimSets(0)=AnimSet'CH_AnimHuman.Anims.K_AnimHuman_BaseMale'
		bCacheAnimSequenceNodes=false
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		CastShadow=true
		BlockRigidBody=false
		bUpdateSkelWhenNotRendered=false
		bIgnoreControllersWhenNotRendered=true
		bUpdateKinematicBonesFromAnimation=false
		bCastDynamicShadow=true
		LightEnvironment=MyLightEnvironment
		bAcceptsDynamicDecals=false
		MinDistFactorForKinematicUpdate=0.2f
		bChartDistanceFactor=true
		RBDominanceGroup=20
		bUseOnePassLightingOnTranslucency=true
		bPerBoneMotionBlur=true
	End Object
	SkeletalMesh=MySkeletalMeshComponent
	Components.Add(MySkeletalMeshComponent)

	RemoteRole=ROLE_None
}