//=============================================================================
// UTAttachment_ShockRiflePhysX
// Class used to add PhysX Effects to the Shock Rifle
//=============================================================================
class UTAttachment_ShockRiflePhysX extends UTAttachment_ShockRifle;

defaultproperties
{
	DefaultImpactEffect=(ParticleTemplate=ParticleSystem'WP_ShockRifle_PhysX.Particles.P_WP_ShockRifle_Beam_Impact', Sound=SoundCue'A_Weapon_ShockRifle.Cue.A_Weapon_SR_AltFireImpactCue')
}
