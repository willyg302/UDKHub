class NESeqCond_DoTutorial extends SequenceCondition;

event Activated()
{
	local bool bTutorialOK;
	local WorldInfo WI;

	WI = GetWorldInfo();

	bTutorialOK = false;
	if(NEGame(WI.Game).bDoTutorial)
	    bTutorialOK = true;
	OutputLinks[ bTutorialOK ? 0 : 1].bHasImpulse = true;
}

defaultproperties
{
	ObjName="Do NeverEnd Tutorial"
	OutputLinks(0)=(LinkDesc="Play Tutorial")
	OutputLinks(1)=(LinkDesc="Abort Tutorial")
}
