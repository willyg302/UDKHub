class IronsightPawn extends UTPawn;

var bool bIronsight;

// For now just return true (we can ADS at any time)
function bool CanIronsight()
{
	return true;
}

simulated function SetIronsight(bool bNewIronsight)
{
	bIronsight = bNewIronsight;
}