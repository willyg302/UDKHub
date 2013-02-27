class SamplePlayerController extends UTPlayerController;

var SampleGame TheGame;

simulated function PostBeginPlay()
{
	super.PostBeginPlay();
	if(SampleGame(WorldInfo.Game) != none)
		TheGame = SampleGame(WorldInfo.Game);
}

function class<LocalMessage> ConvertSynMessage(class<LocalMessage> inMsg)
{
	local class<LocalMessage> TrueMessage;
    switch(inMsg)
    {
        case class'UTKillingSpreeMessage' :
   		    TrueMessage = class'SampleLocalMessage_KillingSpree';
   		    break;
        // ADD AS MANY MORE AS YOU WANT
   		default:
   		    TrueMessage = inMsg;
   		    break;
    }
    return TrueMessage;
}

reliable client event ReceiveLocalizedMessage(class<LocalMessage> Message, optional int Switch, optional PlayerReplicationInfo RelatedPRI_1, optional PlayerReplicationInfo RelatedPRI_2, optional Object OptionalObject)
{
	if(WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.GRI == None)
		return;
	ConvertSynMessage(Message).Static.ClientReceive(Self, Switch, RelatedPRI_1, RelatedPRI_2, OptionalObject);
}
