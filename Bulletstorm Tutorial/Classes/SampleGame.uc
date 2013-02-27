class SampleGame extends UTGame
	config(Game)
	dependson(UTCharInfo);

defaultproperties
{
	PlayerReplicationInfoClass=class'Sample.SamplePlayerReplicationInfo'
    DefaultInventory(0)=class'Sample.SampleWeap_LinkGun'
    PlayerControllerClass=class'Sample.SamplePlayerController'
    DefaultPawnClass=class'Sample.SamplePawn'
    BotClass=class'Sample.SampleBot'
    bUseClassicHud=true
    HUDType=class'Sample.SampleHudWrapper'
	bGivePhysicsGun=false
}
