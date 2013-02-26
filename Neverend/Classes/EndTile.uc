/**
 * Note to self: We extend from Actor instead of StaticMeshActor since
 * StaticMeshActor doesn't support PostBeginPlay(). Most of the junk
 * in the defaultproperties is copied directly from StaticMeshActor
 * and StaticMeshActorBase to give it similar functionality.
 */
class EndTile extends Actor
	placeable;

var() const editconst StaticMeshComponent StaticMeshComponent;
var() MaterialInterface BasicMaterial;
var MaterialInstanceConstant matInst;
var SoundCue BeepSound;

var float HitTime;
var RollingBall BallInst;

var float DonePercent;
var bool bDoneReached;
var float DoneTime;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	StaticMeshComponent.SetMaterial(0,BasicMaterial);
	StaticMeshComponent.SetMaterial(1,BasicMaterial);
}

function UpdateMaterialInstance()
{
	
	if(DonePercent == DoneTime && !bDoneReached)
	{
		NEGame(WorldInfo.Game).EndLevel();
		ClearTimer('Beep');
		Beep();
		bDoneReached = true;
	}
}


function BallHit(RollingBall ball)
{
	if(BallInst == none && !bDoneReached)
	{
		HitTime = WorldInfo.TimeSeconds;
		BallInst = ball;
		Beep();
		SetTimer(DoneTime/2, false, 'Beep');
	}
}

function Beep()
{
	BeepSound.VolumeMultiplier = NEGame(WorldInfo.Game).savefile.SFXVolume;
	PlaySound(BeepSound);
}

event Tick(float DeltaTime)
{
	if(BallInst != none)
	{
		if(VSize(Location - BallInst.Location) > 64)
		{
			BallInst = none;
			ClearTimer('Beep');
		}
		else
		{
			DonePercent = FClamp(WorldInfo.TimeSeconds - HitTime, 0.0, DoneTime);
			UpdateMaterialInstance();
		}
	}
}

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent0
		bAllowApproximateOcclusion=true
		bForceDirectLightMap=true
		bUsePrecomputedShadows=true
		StaticMesh=StaticMesh'Never_End_MAssets.Cube'
		bNotifyRigidBodyCollision=True
		HiddenGame=False
		ScriptRigidBodyCollisionThreshold=0.001
		LightingChannels=(Dynamic=true)
		Scale = 0.250000
	End Object
	CollisionComponent=StaticMeshComponent0
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)

	bDoneReached=false;
	BeepSound=SoundCue'Never_End_MAudio.Sounds.Beep_Cue'
	BasicMaterial=MaterialInstanceConstant'Never_End_MAssets.Materials.End_Tile_MIC'

	bEdShouldSnap=true
	bStatic=false
	bMovable=false
	bCollideActors=true
	bBlockActors=true
	bWorldGeometry=true
	bGameRelevant=true
	bCollideWhenPlacing=false

	DonePercent=0.0
	DoneTime=0.75
}
