class SampleLocalMessage_KillingSpree extends SampleLocalMessage;

var string SelfSpreeNote[6];
var int SpreePoints[6];
var SoundNodeWave SpreeSound[6];

static function string GetString(
	optional int Switch,
	optional bool bPRI1HUD,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	if (RelatedPRI_2 == None)
	{
		return Default.SelfSpreeNote[Switch];
	}
	return "";
}

static function int GetPtVal(
	optional int Switch,
	optional bool bPRI1HUD,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	if (RelatedPRI_2 == None)
	{
		return Default.SpreePoints[Switch];
	}
	return 0;
}

static simulated function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	Super.ClientReceive(P, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);

	if (RelatedPRI_2 != None)
		return;

	if ( (RelatedPRI_1 == P.PlayerReplicationInfo)
		|| (P.PlayerReplicationInfo.bOnlySpectator && (Pawn(P.ViewTarget) != None) && (Pawn(P.ViewTarget).PlayerReplicationInfo == RelatedPRI_1)) )
	{
		UTPlayerController(P).PlayAnnouncement(default.class,Switch );
		if ( Switch == 0 )
			UTPlayerController(P).ClientMusicEvent(8);
		else
			UTPlayerController(P).ClientMusicEvent(10);
	}
	else
		P.PlayBeepSound();
}

static function SoundNodeWave AnnouncementSound(int MessageIndex, Object OptionalObject, PlayerController PC)
{
	return Default.SpreeSound[MessageIndex];
}

defaultproperties
{
	bBeep=False
	SelfSpreeNote(0)="KILLING SPREE"
	SelfSpreeNote(1)="RAMPAGE"
	SelfSpreeNote(2)="DOMINATING"
	SelfSpreeNote(3)="UNSTOPPABLE"
	SelfSpreeNote(4)="GODLIKE"
	SelfSpreeNote(5)="MASSACRE"

    SpreePoints(0)=20
    SpreePoints(1)=30
    SpreePoints(2)=40
    SpreePoints(3)=50
    SpreePoints(4)=100
    SpreePoints(5)=250

    SpreeSound(0)=SoundNodeWave'A_Announcer_Reward.Rewards.A_RewardAnnouncer_KillingSpree'
	SpreeSound(1)=SoundNodeWave'A_Announcer_Reward.Rewards.A_RewardAnnouncer_Rampage'
	SpreeSound(2)=SoundNodeWave'A_Announcer_Reward.Rewards.A_RewardAnnouncer_Dominating'
	SpreeSound(3)=SoundNodeWave'A_Announcer_Reward.Rewards.A_RewardAnnouncer_Unstoppable'
	SpreeSound(4)=SoundNodeWave'A_Announcer_Reward.Rewards.A_RewardAnnouncer_GodLike'
	SpreeSound(5)=SoundNodeWave'A_Announcer_Reward.Rewards.A_RewardAnnouncer_Massacre'
	AnnouncementPriority=7
}
