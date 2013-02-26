class NECamera extends Camera;

var Rotator CameraAngle;
var float CameraInterpolationRate;
//var bool bInitialized;

/** Overriden to set starting rotation and location of camera */
function PostBeginPlay()
{
	super.PostBeginPlay();
	CameraAngle.Pitch   = -90.f * DegToUnrRot; // Top down viewpoint
	CameraAngle.Roll    = 0;
	CameraAngle.Yaw     = 0;

	ViewTarget.POV.Rotation = CameraAngle;
	ViewTarget.POV.FOV = default.DefaultFOV;
	FreeCamDistance = default.FreeCamDistance;
}

function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	local Vector CurrentLocation, DesiredLocation;
	local int CurrentRotation, DesiredRotation;
	local Rotator TargetRot;

    //if(!bInitialized)
    //{
    	ViewTarget.Target = NEPlayerController(PCOwner).GetPlayerBall();
		//bInitialized = true;
    //}


	CurrentLocation = ViewTarget.POV.Location;
	DesiredLocation = ViewTarget.Target.Location;
	DesiredLocation -= Vector(CameraAngle) * FreeCamDistance;

	// If we haven't reached the desired location, interpolate to it
	if(CurrentLocation != DesiredLocation)
		ViewTarget.POV.Location += (DesiredLocation - CurrentLocation) * DeltaTime * CameraInterpolationRate;


	CurrentRotation = ViewTarget.POV.Rotation.Roll;
	DesiredRotation = RollingBall(ViewTarget.Target).myGame.CurrentRot * 16384;

	if(CurrentRotation != DesiredRotation)
	{
		NEPlayerController(PCOwner).bRotating = true;
        TargetRot.Pitch = ViewTarget.POV.Rotation.Pitch;
		TargetRot.Yaw = ViewTarget.POV.Rotation.Yaw;
		TargetRot.Roll = DesiredRotation;

        ViewTarget.POV.Rotation.Roll = RInterpTo (ViewTarget.POV.Rotation, TargetRot, DeltaTime, 10.0).Roll;
	}
	else
	{
		NEPlayerController(PCOwner).bRotating = false;
	}
}

DefaultProperties
{
	DefaultFOV=90.f
	FreeCamDistance=250.f
	CameraInterpolationRate=7.5f

	//bInitialized=false
}
