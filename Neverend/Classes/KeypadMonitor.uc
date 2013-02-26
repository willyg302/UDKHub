class KeypadMonitor extends Actor
    placeable;

var() array<KeypadSwitch> NumberSwitches;
var() KeypadSwitch EnterSwitch;
var bool bInCollision;

var int curValue, desValue;

var() name TriggerName;
var SoundCue NumberSound, EnterWrongSound, EnterRightSound;

event PreBeginPlay()
{
	local int i;
	for(i = 0; i < NumberSwitches.Length; i++)
	{
		NumberSwitches[i].KeypadGroup = self;
		NumberSwitches[i].RegisteredValue = i+1;
	}
	EnterSwitch.KeypadGroup = self;
	EnterSwitch.RegisteredValue = 0;
}

function ResetKeypad()
{
	local int i;
	for(i = 0; i < NumberSwitches.Length; i++)
		NumberSwitches[i].ResetSwitch();
	EnterSwitch.ResetSwitch();
	curValue = 0;
}

function LockKeypad()
{
	local int i;
	for(i = 0; i < NumberSwitches.Length; i++)
		NumberSwitches[i].bHasBeenHit = true;
	EnterSwitch.bHasBeenHit = true;
	NEGame(WorldInfo.Game).TriggerRemoteKismetEvent(TriggerName);
}

function NotifyHit(int SwitchValue)
{
	if(SwitchValue == 0)
	{
		if(curValue == desValue)
		{
			EnterRightSound.VolumeMultiplier = NEGame(WorldInfo.Game).savefile.SFXVolume;
			PlaySound(EnterRightSound);
			LockKeypad();
		}
		else
		{
			EnterWrongSound.VolumeMultiplier = NEGame(WorldInfo.Game).savefile.SFXVolume;
			PlaySound(EnterWrongSound);
			ResetKeypad();
		}
	}
	else
	{
		curValue = (10 * curValue) + SwitchValue;
		NumberSound.VolumeMultiplier = NEGame(WorldInfo.Game).savefile.SFXVolume;
		PlaySound(NumberSound);
	}
}

defaultproperties
{

	Begin Object Class=SpriteComponent Name=Sprite
		Sprite=Texture2D'EditorResources.S_KPrismatic'
		HiddenGame=True
		AlwaysLoadOnClient=False
		AlwaysLoadOnServer=False
		SpriteCategoryName="Physics"
	End Object
	Components.Add(Sprite)
	Begin Object Class=ArrowComponent Name=ArrowComponent0
		ArrowColor=(R=255,G=64,B=64)
		bTreatAsASprite=True
		SpriteCategoryName="Physics"
	End Object
	Components.Add(ArrowComponent0)

	bCollideActors=false
	bHidden=True
	DrawScale=0.5
	bEdShouldSnap=true

	curValue=0
	desValue=7934


	NumberSound=SoundCue'Never_End_MAudio.Sounds.Beep_Cue'
	EnterRightSound=SoundCue'Never_End_MAudio.Sounds.Unlocked_Cue'
	EnterWrongSound=SoundCue'Never_End_MAudio.Sounds.Wrong_Cue'
}