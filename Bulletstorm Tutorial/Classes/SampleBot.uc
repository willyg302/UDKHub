class SampleBot extends UTBot;

state Fallback
{
	function bool FireWeaponAt(Actor A)
	{
		if((A == Enemy) && (Pawn.Weapon != None) && (Pawn.Weapon.AIRating < 0.5)
			&& (WorldInfo.TimeSeconds - Pawn.SpawnTime < SampleGame(WorldInfo.Game).SpawnProtectionTime)
			&& (UTSquadAI(Squad).PriorityObjective(self) == 0)
			&& (PickupFactory(Routegoal) != None) )
		{
			return false;
		}
		return Global.FireWeaponAt(A);
	}
}
