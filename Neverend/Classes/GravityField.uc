class GravityField extends Volume
    placeable;

var() float GravityModifier;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
	if(RollingBall(Other) != none)
	{
		RollingBall(Other).GravityModifier = GravityModifier;
		RollingBall(Other).CurrentGravField = self;
	}
}

simulated event UnTouch(Actor Other)
{
	super.UnTouch(Other);
	if(RollingBall(Other) != none)
	{
		if(RollingBall(Other).CurrentGravField == self)
		{
			RollingBall(Other).GravityModifier = 1.0;
			RollingBall(Other).CurrentGravField = none;
		}
	}
}
