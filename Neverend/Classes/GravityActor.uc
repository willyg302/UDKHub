class GravityActor extends KActorSpawnable;

var NEGame myGame;
var() MaterialInterface BallMaterial;

var SoundCue ImpactSound;
var float ImpactSoundThreshhold;
var float ImpactVelocityThreshhold;

var RB_ConstraintActor TwoDConstraint;

simulated event PostBeginPlay()
{
	//local RB_ConstraintActor TwoDConstraint;
	super.PostBeginPlay();
	SetUpConstraint();
	TwoDConstraint.InitConstraint(self, None);
	myGame = NEGame(WorldInfo.Game);
	StaticMeshComponent.SetMaterial(0,BallMaterial);
	StaticMeshComponent.SetMaterial(1,BallMaterial);
}

function SetUpConstraint()
{
	TwoDConstraint = Spawn(class'RB_ConstraintActorSpawnable', self, '', Location, rot(0,0,0));
	TwoDConstraint.ConstraintSetup.LinearYSetup.bLimited = 0;
	TwoDConstraint.ConstraintSetup.LinearXSetup.bLimited = 0;
}

simulated event Tick(Float DT)
{
	GravityForce(DT);
}

function Vector GetGravityVector()
{
	local Vector V;
	V.X = (myGame.CurrentRot % 2 == 0) ? (myGame.SimGravity * (myGame.CurrentRot - 1)) : 0.0;
	V.Y = (myGame.CurrentRot % 2 == 1) ? (myGame.SimGravity * (myGame.CurrentRot - 2)) : 0.0;
	V.Z = 0;
	return V;
}

simulated function GravityForce(Float DeltaTime)
{
	StaticMeshComponent.AddImpulse(GetGravityVector());
}

function Rotate(int direction)
{
	myGame.Rotate(direction);
}

event RigidBodyCollision(PrimitiveComponent HitComponent, PrimitiveComponent OtherComponent,
				const out CollisionImpactData RigidCollisionData, int ContactIndex)
{
	local float volume;
	super.RigidBodyCollision(HitComponent,OtherComponent,RigidCollisionData,ContactIndex);
	volume = VSize(RigidCollisionData.TotalNormalForceVector) / 200.0;
	if(volume > ImpactSoundThreshhold && VSize(velocity) > ImpactVelocityThreshhold)
	{
		ImpactSound.VolumeMultiplier = volume * myGame.savefile.SFXVolume;
		PlaySound(ImpactSound);
	}
}

defaultproperties
{
	Physics=PHYS_RigidBody

	bNoEncroachCheck=false
	SupportedEvents.Add(class'SeqEvent_Touch')
	SupportedEvents.Add(class'SeqEvent_Used')
	CollisionType = COLLIDE_CustomDefault
	
	ImpactSoundThreshhold=0.5
	ImpactVelocityThreshhold=5.0
}
