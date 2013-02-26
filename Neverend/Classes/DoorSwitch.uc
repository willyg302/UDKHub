/**
 * Note to self: We extend from Actor instead of StaticMeshActor since
 * StaticMeshActor doesn't support PostBeginPlay(). Most of the junk
 * in the defaultproperties is copied directly from StaticMeshActor
 * and StaticMeshActorBase to give it similar functionality.
 */
class DoorSwitch extends Actor
	placeable;

var() const editconst StaticMeshComponent StaticMeshComponent;
var() MaterialInterface UnhitMaterial, HitMaterial;
var SoundCue ImpactSound, CloseSound;
var() name TriggerName, CloseName;

var bool bHasBeenHit;
var() float CloseTime;
var() bool bCloses;

simulated event PostBeginPlay()
{
	super.PostBeginPlay();
	StaticMeshComponent.SetMaterial(0,UnhitMaterial);
	StaticMeshComponent.SetMaterial(1,UnhitMaterial);
}

function BallHit()
{
	if(!bHasBeenHit)
	{
		ImpactSound.VolumeMultiplier = NEGame(WorldInfo.Game).savefile.SFXVolume;
		PlaySound(ImpactSound);
		StaticMeshComponent.SetMaterial(0,HitMaterial);
		StaticMeshComponent.SetMaterial(1,HitMaterial);
		NEGame(WorldInfo.Game).TriggerRemoteKismetEvent(TriggerName);
		bHasBeenHit = true;
		if(bCloses)
		{
			`log("Door closes, setting timer for "$CloseTime);
			SetTimer(CloseTime, false, 'CloseDoor');
		}
	}
}

function CloseDoor()
{
	`log("Door closing!");
	CloseSound.VolumeMultiplier = NEGame(WorldInfo.Game).savefile.SFXVolume;
	PlaySound(CloseSound);
	StaticMeshComponent.SetMaterial(0,UnhitMaterial);
	StaticMeshComponent.SetMaterial(1,UnhitMaterial);
	NEGame(WorldInfo.Game).TriggerRemoteKismetEvent(CloseName);
	bHasBeenHit = false;
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

	bHasBeenHit=false;
	ImpactSound=SoundCue'Never_End_MAudio.Sounds.Door_Open'
	CloseSound=SoundCue'Never_End_MAudio.Sounds.Door_Close'
	UnhitMaterial=MaterialInstanceConstant'Never_End_MAssets.Materials.Switch_Tile_MIC'
	HitMaterial=MaterialInstanceConstant'Never_End_MAssets.Materials.Green_Tile_MIC'

	bEdShouldSnap=true
	bStatic=false //TEST...
	bMovable=false
	bCollideActors=true
	bBlockActors=true
	bWorldGeometry=true
	bGameRelevant=true
	bCollideWhenPlacing=false
}
