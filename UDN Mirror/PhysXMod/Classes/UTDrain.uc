//=============================================================================
// UTDrain
// Fluid Drain implemented to catch PhysX Particles
//=============================================================================

class UTDrain extends StaticMeshActor;

defaultproperties
{
	//Needed for spawning
	bStatic=False
	bNoDelete=False
	bHidden=True
	
	//Make this a drain
	Begin Object Name=StaticMeshComponent0
		BlockRigidBody=TRUE
		bFluidDrain=TRUE
		RBChannel=RBCC_FluidDrain
		RBCollideWithChannels=(FluidDrain=True)
	End Object
}
