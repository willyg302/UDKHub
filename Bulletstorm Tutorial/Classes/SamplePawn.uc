class SamplePawn extends UTPawn;

function bool Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	if(Super.Died(Killer, DamageType, HitLocation))
	{
        if((Killer != None))
		{
			if(UTPawn(Killer.Pawn).IsHumanControlled())
        	{
            	SampleHudWrapper(UTPlayerController(Killer).myHUD).AddPointMessage(class<SampleDamageType>(DamageType).Static.GetPointMsg(),Location+GetCollisionHeight()*vect(0,0,1.1),True);
        	    SamplePlayerReplicationInfo(SamplePlayerController(Killer).PlayerReplicationInfo).IncrementPoints(class<SampleDamageType>(DamageType).Default.PointValue);
			}
		}

		return true;
	}
	return false;
}
