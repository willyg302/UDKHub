class IronsightPlayerController extends UTPlayerController;

simulated exec function Ironsight()
{
	if((IronsightPawn(Pawn) != none) && IronsightPawn(Pawn).CanIronsight())
	{
		IronsightPawn(Pawn).SetIronsight(true);
	}
	else
	{
		IronsightPawn(Pawn).SetIronsight(false);
	}
}

// Alternate fire now toggles Ironsights.
exec function StartAltFire(optional Byte FireModeNum)
{
	Ironsight();
}

exec function StopAltFire(optional byte FireModeNum)
{
	if(IronsightPawn(Pawn) != none)
		IronsightPawn(Pawn).SetIronsight(false);
}