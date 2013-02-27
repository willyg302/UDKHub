class SampleDamageType extends UTDamageType
	abstract;

var() string PointString;
var int PointValue;

static function string GetPointMsg()
{
	return Default.PointString$" +"$string(Default.PointValue);
}

static function int IncrementKills(UTPlayerReplicationInfo KillerPRI)
{
	local int KillCount;
	KillCount = KillerPRI.IncrementKillStat(static.GetStatsName('KILLS'));
	if((KillCount == Default.RewardCount) && (SamplePlayerController(KillerPRI.Owner) != None))
	{
		SamplePlayerController(KillerPRI.Owner).ReceiveLocalizedMessage(Default.RewardAnnouncementClass, Default.RewardAnnouncementSwitch);
		if(default.RewardEvent == '')
		{
			`warn("No reward event for "$default.class);
		}
		else
		{
			KillerPRI.IncrementEventStat(default.RewardEvent);
		}
	}
	return KillCount;
}
