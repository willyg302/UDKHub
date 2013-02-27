class SampleLocalMessage extends UTLocalMessage
	abstract;

static function int GetPtVal(
	optional int Switch,
	optional bool bPRI1HUD,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	return 0;
}

static function ClientReceive(
	PlayerController P,
	optional int Switch,
	optional PlayerReplicationInfo RelatedPRI_1,
	optional PlayerReplicationInfo RelatedPRI_2,
	optional Object OptionalObject
	)
{
	local string MessageString;
    local int MessageValue;
    if(UTPawn(P.Pawn).IsHumanControlled() && RelatedPRI_1 == P.PlayerReplicationInfo)
    {
    	MessageString = GetString(Switch, ,RelatedPRI_1,RelatedPRI_2,OptionalObject);
    	MessageValue = GetPtVal(Switch, ,RelatedPRI_1,RelatedPRI_2,OptionalObject);
        SampleHudWrapper(SamplePlayerController(P).myHUD).AddPointMessageQueue(MessageString$" +"$string(MessageValue));
        SamplePlayerReplicationInfo(SamplePlayerController(P).PlayerReplicationInfo).IncrementPoints(MessageValue);
	}
}
