//=============================================================================
// UTProj_LinkPlasmaPhysX
// Class used to add PhysX Effects to the Link Plasma projectile
//=============================================================================
class UTProj_LinkPlasmaPhysX extends UTProj_LinkPlasma;

defaultproperties
{
	ProjExplosionTemplate=ParticleSystem'WP_LinkGun_PhysX.Effects.P_WP_Linkgun_Impact'
}

simulated function SetExplosionEffectParameters(ParticleSystemComponent ProjExplosion)
{
        //`Log("Setting Link Gun Shadow");
        //ProjExplosion.CastShadow=true;
}
