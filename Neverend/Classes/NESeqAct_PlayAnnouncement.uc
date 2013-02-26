class NESeqAct_PlayAnnouncement extends SequenceAction;
	//PerObjectLocalized;

var() String AnnouncementOne;
var() String AnnouncementTwo;
var() String AnnouncementThree;
var() String AnnouncementFour;

defaultproperties
{
	ObjName="Never End Announce"
	ObjCategory="Voice/Announcements"
	HandlerName="NEDispAnnounce"
	VariableLinks(1)=(ExpectedType=class'SeqVar_String', LinkDesc="AnnouncementOne", bWriteable=true, PropertyName=AnnouncementOne)
	VariableLinks(2)=(ExpectedType=class'SeqVar_String', LinkDesc="AnnouncementTwo", bWriteable=true, PropertyName=AnnouncementTwo)
	VariableLinks(3)=(ExpectedType=class'SeqVar_String', LinkDesc="AnnouncementThree", bWriteable=true, PropertyName=AnnouncementThree)
	VariableLinks(4)=(ExpectedType=class'SeqVar_String', LinkDesc="AnnouncementFour", bWriteable=true, PropertyName=AnnouncementFour)
}




