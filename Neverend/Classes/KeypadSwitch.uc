class KeypadSwitch extends DoorSwitch
	placeable;

var KeypadMonitor KeypadGroup;
var int RegisteredValue;

function BallHit()
{
	if(!bHasBeenHit)
	{
		StaticMeshComponent.SetMaterial(0,HitMaterial);
		StaticMeshComponent.SetMaterial(1,HitMaterial);
		bHasBeenHit = true;
		KeypadGroup.NotifyHit(RegisteredValue);
	}
}

function ResetSwitch()
{
	SetTimer(1.0, false, 'AllowHit');
}

function AllowHit()
{
	StaticMeshComponent.SetMaterial(0,UnhitMaterial);
	StaticMeshComponent.SetMaterial(1,UnhitMaterial);
	bHasBeenHit = false;
}

defaultproperties
{
	ImpactSound=SoundCue'Never_End_MAudio.Sounds.Beep_Cue'
}