class SamplePlayerReplicationInfo extends UTPlayerReplicationInfo;

var databinding int Points;

function Reset()
{
	Super.Reset();
	Points = 0;
}

function CopyProperties(PlayerReplicationInfo PRI)
{
	local SamplePlayerReplicationInfo RTPRI;
	Super.CopyProperties(PRI);
	RTPRI = SamplePlayerReplicationInfo(PRI);
	if(RTPRI == None)
		return;
    RTPRI.Points = Points;
}

function IncrementPoints(int Add)
{
    Points += Add;
}

