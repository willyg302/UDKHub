//=============================================================================
// UTWeap_LinkGunPhysX
// Class used to add PhysX Effects to the Link Gun
//=============================================================================
class UTWeap_LinkGunPhysX extends UTWeap_LinkGun;

defaultproperties
{
	WeaponProjectiles(0)=class'UTProj_LinkPlasmaPhysX'
        AttachmentClass=class'UTAttachment_LinkgunPhysX'
}
               
