class BigBlock extends GravityActor
	placeable;

var RB_BigBlockActor BlockGroup;

function SetUpConstraint()
{
	super.SetUpConstraint();
	TwoDConstraint.ConstraintSetup.bSwingLimited = true;
	TwoDConstraint.ConstraintSetup.Swing1LimitAngle = 0;
	TwoDConstraint.ConstraintSetup.Swing2LimitAngle = 0;
	TwoDConstraint.ConstraintSetup.bTwistLimited = true;
	TwoDConstraint.ConstraintSetup.TwistLimitAngle = 0;
}

event RigidBodyCollision(PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	local float volume;
	super(KActorSpawnable).RigidBodyCollision(HitComponent,OtherComponent,RigidCollisionData,ContactIndex);

	volume = VSize(RigidCollisionData.TotalNormalForceVector) / 200.0;
	
	//if(Acos(Normal(RigidCollisionData.ContactInfos[0].ContactPosition - Location) dot Normal(GetGravityVector())) < 45.0*DegToRad)
	if(volume > ImpactSoundThreshhold && VSize(velocity) > ImpactVelocityThreshhold)
	{
		//`log("PASSED Valid Collision Check");
		if(!BlockGroup.bInCollision)
		{
			//`log("PASSED Block Group Not in Collision");
			ImpactSound.VolumeMultiplier = 4.0 * volume * myGame.savefile.SFXVolume;
			PlaySound(ImpactSound);
		}
		BlockGroup.SetCollisionTimer();
	}
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'Never_End_MAssets.Cube'
		bNotifyRigidBodyCollision=True
		HiddenGame=False
		ScriptRigidBodyCollisionThreshold=0.001
		LightingChannels=(Dynamic=true)
		Scale = 0.250000
	End Object
	Components.Add(StaticMeshComponent0)

	ImpactSound=SoundCue'Never_End_MAudio.Sounds.Heavy_Thud'
	BallMaterial = Material'Never_End_MAssets.Materials.Transparent_M'

	ImpactSoundThreshhold=4.0
}
