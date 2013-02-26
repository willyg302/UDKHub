class RollingBall extends GravityActor
	placeable;

var ParticleSystem DestroyTemplate;
var SoundCue DestroySound;

var float MinCrushAngle;

// Gravity Field Stuff
var float GravityModifier;
var GravityField CurrentGravField;

function PlayDeath()
{
	local ParticleSystemComponent Explo;
	SetPhysics(PHYS_None);
	SetCollision(false,false,false);
	StaticMeshComponent.SetHidden(true);
	if(DestroyTemplate != none)
	{
		Explo = WorldInfo.MyEmitterPool.SpawnEmitter(DestroyTemplate, Location, Rotation);
		Explo.SetScale(0.25);
		DestroySound.VolumeMultiplier = 0.6 * myGame.savefile.SFXVolume;
		PlaySound(DestroySound);
	}
	self.Destroy();
}

simulated event Destroyed()
{
	super.Destroyed();
	myGame.savefile.CurDeaths++;
	myGame.RespawnBall();
}

// For Gravity Field!
simulated function GravityForce(float DeltaTime)
{
	StaticMeshComponent.AddImpulse(GetGravityVector() * GravityModifier);
}

event RigidBodyCollision(PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
		const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	if(OtherComponent != none) {
		if(BallDeathVolume(OtherComponent.Owner) != none)
			PlayDeath();
		/* First we test if the block is above the ball. To do this we get the angle between the gravity vector (down) and
		 * the vector FROM ball TO block. They should be in opposite directions, so we test if the angle is above 135 degrees.
		 * Then we test to see if the ball is on ground by performing a fast trace in the gravity direction.
		 * If both these are true, we know the block is being "crushed" between them.
		 */
		if(BigBlock(OtherComponent.Owner) != none)
		{
			if(Acos(Normal(RigidCollisionData.ContactInfos[0].ContactPosition - Location) dot Normal(GetGravityVector())) > MinCrushAngle*DegToRad
				&& !FastTrace(Location + 32*Normal(GetGravityVector()), Location))
			{
				PlayDeath();
				
			}
		}
		if(DoorSwitch(OtherComponent.Owner) != none)
			DoorSwitch(OtherComponent.Owner).BallHit();
		if(EndTile(OtherComponent.Owner) != none)
			EndTile(OtherComponent.Owner).BallHit(self);
	}
	super.RigidBodyCollision(HitComponent,OtherComponent,RigidCollisionData,ContactIndex);
}

defaultproperties
{
	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'Never_End_MAssets.Ball'
		bNotifyRigidBodyCollision=True
		HiddenGame=False
		ScriptRigidBodyCollisionThreshold=0.001
		LightingChannels=(Dynamic=true)
		Scale = 0.150000
	End Object
	Components.Add(StaticMeshComponent0)

	ImpactSound=SoundCue'Never_End_MAudio.Sounds.Ball_Drop'
	BallMaterial = MaterialInstanceConstant'Never_End_MAssets.Materials.White_Tile_MIC'

	DestroyTemplate=ParticleSystem'WP_ShockRifle.Particles.P_WP_ShockRifle_Explo'
	DestroySound=SoundCue'Never_End_MAudio.Sounds.Death_Cue'
	MinCrushAngle=135

	GravityModifier=1.0
}
