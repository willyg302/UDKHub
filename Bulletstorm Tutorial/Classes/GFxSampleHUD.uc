class GFxSampleHUD extends GFxMoviePlayer;

var WorldInfo ThisWorld;
var UTGameReplicationInfo GRI;
var SamplePlayerReplicationInfo PRI;
var SamplePlayerController PC;
var GFxObject ScoreTF;


struct ScaleformMessage
{
    var GFxObject MC, TF;
};

struct native PointMessage
{
	var string Text;
	var float MessageLife;
	var vector Loc;
	var bool bLockedLoc;             //is this the original Loc, or a Queued Loc
	var int LocPos;                  //if not locked, how many msgs down is it?
	var ScaleformMessage gfx;        //GFxObject that owns this message
};
var array<PointMessage> PointMessages;

/** Last time trace test check for drawing postrender hud icons was performed */
var float LastPointMsgTraceTime;
/** true is last trace test check for drawing postrender hud icons succeeded */
var bool bPointMsgTraceSucceeded;

struct native PointMessageQueue
{
	var string Text;
	var float MessageLife;
};
var array<PointMessageQueue> PointQueue;

//we initialize 16 instances of the message at startup. FreeMsg holds free messages that
//may be assigned to a message.
var array<ScaleformMessage> FreeMsg;

function Init(optional LocalPlayer player)
{
    local int j;
	super.Init(player);

    PC = SamplePlayerController(GetPC());
	ThisWorld = PC.WorldInfo;
	GRI = UTGameReplicationInfo(ThisWorld.GRI);
	PRI = SamplePlayerReplicationInfo(PC.PlayerReplicationInfo);

    Start();
    Advance(0);

    ScoreTF = GetVariableObject(/*SWF PATH TO YOUR SCORE SYMBOL*/);

    for(j = 0; j < 16; j++) {
		InitScaleformMessage(j);
		InitScaleformTextfields(j);
    }
}

function InitScaleformMessage(int index)
{
	local ScaleformMessage mrow;
    mrow.MC = /*ROOT OF SWF*/.AttachMovie("bulletstorm", "bulletstorm"$index);
	FreeMsg.AddItem(mrow);
}

function InitScaleformTextfields(int i)
{
    FreeMsg[i].TF = FreeMsg[i].MC.GetObject("bulletanim").GetObject("bulletstormtf");
    FreeMsg[i].MC.SetVisible(false);
}

function AddPointMessageQueue(string M,optional float LifeTime)
{
    local int Idx, MsgIdx;
    local PointMessageQueue temp;

    MsgIdx = -1;
    temp.Text = M;
	temp.MessageLife = ((LifeTime != 0.f) ? LifeTime : 3.0);

	if(PointQueue.Length == 16)
		PointQueue.Remove(0,1);
	for (Idx = 0; Idx < PointQueue.Length && MsgIdx == -1; Idx++)
	{
        if (PointQueue[Idx].Text == "")
            MsgIdx = Idx;
	}
    if(MsgIdx != -1)
    {
        PointQueue.InsertItem(MsgIdx, temp);
    }
    else
    {
        PointQueue.AddItem(temp);
    }
}

function vector GenerateRandLoc()
{
    local vector generated;
    generated.X = (0.5 - FRand()) * 100.f;
    generated.Y = (0.5 - FRand()) * 100.f;
    generated.Z = 0.0;
    return generated;
}

//check if there is a message in PointMessages for queued messages to loc from
function CheckAvailableLoc()
{
    local int Idx,Idxx,Hit;
    Hit = -1;
    for(Idx = PointMessages.Length - 1; Idx > -1; Idx--)
    {
        if(PointMessages[Idx].Text != "")
        {
            Hit=Idx;
            break;
        }
    }
    if (Hit == -1)
        return;
    Hit=0;
    for(Idxx = 0; Idxx < PointQueue.Length; Idxx++)
    {
        AddPointMessage(PointQueue[Idxx].Text,PointMessages[Idx].Loc+GenerateRandLoc(),false,PointQueue[Idxx].MessageLife,Hit+1);
        PointQueue.Remove(Idxx--,1);
        Hit++;
    }
}

function FreePointMessage(int index)
{
    PointMessages[index].gfx.MC.gotoAndPlay("close");
    FreeMsg.AddItem(PointMessages[index].gfx);
    PointMessages.Remove(index,1);
}

function AddPointMessage(string M, vector Loc, bool bLocked, optional float LifeTime, optional int LocPos)
{
	local int Idx, MsgIdx;
    local PointMessage temp;

    MsgIdx = -1;
    temp.Text = M;
	temp.MessageLife = ThisWorld.TimeSeconds + ((LifeTime != 0.f) ? LifeTime : 3.0);
   	temp.Loc = Loc;
   	temp.bLockedLoc = bLocked;
   	temp.LocPos = ((LocPos != 0.f) ? LocPos : 0);


	if(PointMessages.Length == 16)
		FreePointMessage(0);
	temp.gfx = FreeMsg[0];
	temp.gfx.TF.SetString("text", M);
	temp.gfx.MC.SetVisible(true);
	temp.gfx.MC.gotoAndPlay("open");
	FreeMsg.Remove(0,1);

	for (Idx = 0; Idx < PointMessages.Length && MsgIdx == -1; Idx++)
	{
        if (PointMessages[Idx].Text == "")
            MsgIdx = Idx;
	}
    if(MsgIdx != -1)
    {
        PointMessages.InsertItem(MsgIdx, temp);
    }
    else
    {
        PointMessages.AddItem(temp);
    }
}


function DisplayPointMessages()
{
	local int Idx;
	local float XL, YL, xscale, x, y;
	local vector ScreenLoc,ViewLoc;
	local UTWeapon Weap;
	local rotator ViewRot;
	local SamplePawn P;

	if(PointMessages.Length == 0 || PC.bCinematicMode)
		return;

	P = SamplePawn(PC.Pawn);

    for(Idx = 0; Idx < PointMessages.Length; Idx++)
	{
		if(PointMessages[Idx].Text == "" || PointMessages[Idx].MessageLife < ThisWorld.TimeSeconds)
			FreePointMessage(Idx--);
	}
    for(Idx = 0; Idx < PointMessages.Length; Idx++)
	{
        PC.GetPlayerViewPoint(ViewLoc,ViewRot);
        if((vector(PC.Rotation) dot (PointMessages[Idx].Loc - ViewLoc)) > 0.f)
		{
			ScreenLoc = PC.myHUD.Canvas.Project(PointMessages[Idx].Loc);
            if(P != None )
			{
				Weap = UTWeapon(P.Weapon);
				if((Weap != None) && Weap.CoversScreenSpace(ScreenLoc, PC.myHUD.Canvas)) {
				    PointMessages[Idx].gfx.MC.SetVisible(false);
					continue;
				}
			}
			// periodically make sure really visible using traces
			if(ThisWorld.TimeSeconds - LastPointMsgTraceTime > 0.5)
			{
				LastPointMsgTraceTime = ThisWorld.TimeSeconds + 0.2*FRand();
				bPointMsgTraceSucceeded = PC.myHUD.FastTrace(PointMessages[Idx].Loc, P.Location);
			}
			if(!bPointMsgTraceSucceeded) {
				PointMessages[Idx].gfx.MC.SetVisible(false);
				continue;
			}
            XL = Len(PointMessages[Idx].Text)  * 12;
            YL = 20;
			xscale = FClamp( (2*3000.f - VSize(P.Location - PointMessages[Idx].Loc))/(2*3000.f), 0.55f, 1.f);
			xscale = xscale * xscale;

            x = FClamp(ScreenLoc.X, 100.f, PC.myHUD.Canvas.ClipX - 100.f - XL*xscale) - 256;
			y = FClamp(ScreenLoc.Y + ((PointMessages[Idx].bLockedLoc == false) ? (YL * 0.8 * PointMessages[Idx].LocPos) : 0.0), 116.f, PC.myHUD.Canvas.ClipY - 148.f - YL*xscale);

            PointMessages[Idx].gfx.MC.SetPosition(x,y);
		}
	}
}

function ToggleCrosshair(bool bToggle) {}

function FormatScore()
{
    local int MyPos, Points;
    Points = (PRI != None) ? PRI.Points : 0;
    MyPos = GRI.PRIArray.Find(PRI);
    ScoreTF.SetText(Points $ "." $ int(PRI.Score) $ "." $ string(MyPos+1));
}

function TickHud(float DeltaTime)
{
	CheckAvailableLoc();
    DisplayPointMessages();
    FormatScore();
}

function DisplayHit(vector HitDir, int Damage, class<DamageType> damageType) {}

defaultproperties
{
	bDisplayWithHudOff=FALSE
	MovieInfo=/*PATH TO YOUR SWF*/
	bEnableGammaCorrection=false
	//bDrawWeaponCrosshairs=true
	bAllowInput=FALSE;
	bAllowFocus=FALSE;
}
