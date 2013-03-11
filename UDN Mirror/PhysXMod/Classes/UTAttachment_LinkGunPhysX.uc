//=============================================================================
// UTAttachment_LinkGunPhysX
// Class used to add PhysX Effects to the Link Gun
//=============================================================================
class UTAttachment_LinkGunPhysX extends UTAttachment_LinkGun;

defaultproperties
{
	TeamBeamEndpointTemplates[2]=ParticleSystem'WP_LinkGun_PhysX.Effects.P_WP_Linkgun_Beam_Impact'
}
