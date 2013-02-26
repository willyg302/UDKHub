class NESeqAct_LoadLevel extends SequenceAction;

var() int Level;

defaultproperties
{
	ObjName="Load NeverEnd Level"
	HandlerName="NELoadLevel"
	VariableLinks(1)=(ExpectedType=class'SeqVar_Int',LinkDesc="Level",bWriteable=true,PropertyName=Level)
}
