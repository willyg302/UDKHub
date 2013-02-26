class RB_BigBlockActor extends Actor
    placeable;

var() array<BigBlock> BlockActors;
var bool bInCollision;

event PreBeginPlay()
{
	local int i,j;
	local RB_ConstraintActor temp;
	super.PreBeginPlay();
	for(i = 0; i < BlockActors.Length-1; i++)
	{
		for(j = i+1; j < BlockActors.Length; j++)
		{
			temp = Spawn(class'RB_ConstraintActorSpawnable',,, BlockActors[i].Location + (BlockActors[j].Location - BlockActors[i].Location)/2);
			temp.ConstraintSetup.LinearYSetup.bLimited = 1;
			temp.ConstraintSetup.LinearXSetup.bLimited = 1;
			temp.ConstraintSetup.LinearZSetup.bLimited = 1;
			temp.ConstraintSetup.bSwingLimited = true;
			temp.ConstraintSetup.Swing1LimitAngle = 0;
			temp.ConstraintSetup.Swing2LimitAngle = 0;
			temp.ConstraintSetup.bTwistLimited = true;
			temp.ConstraintSetup.TwistLimitAngle = 0;
			temp.InitConstraint(BlockActors[i], BlockActors[j]);
		}
	}
	for(i = 0; i < BlockActors.Length; i++)
	{
		BlockActors[i].BlockGroup = self;
	}
}

function SetCollisionTimer()
{
	bInCollision = true;
	SetTimer(0.25, false, 'ClearCollisionTimer');
}

function ClearCollisionTimer()
{
	bInCollision = false;
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

	bInCollision=false
}
