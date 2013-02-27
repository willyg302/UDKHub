class IronsightWeapon extends UTWeapon abstract;

var bool bCanIronsight;
var float IronsightAlpha;
var float IronsightShiftPeriod;
var Vector IronsightPositionOffset;
var Rotator IronsightRotationOffset;

simulated event Tick(float DT)
{
	super.Tick(DT);
	if(bCanIronsight)
	{
		if(IronsightPawn(Instigator) != none && IronsightPawn(Instigator).bIronsight)
		{
			if(IronsightAlpha < 1.0)
				IronsightAlpha = FMin(1.0, IronsightAlpha + DT / IronsightShiftPeriod);
		}
		else if(IronsightAlpha > 0.0)
			IronsightAlpha = FMax(0.0, IronsightAlpha - DT / IronsightShiftPeriod);
	}
}

simulated event SetPosition(UDKPawn Holder)
{
	local Vector DrawOffset, ViewOffset, FinalSmallWeaponsOffset, FinalLocation;
	local EWeaponHand CurrentHand;
	local Rotator NewRotation, FinalRotation;
	local PlayerController PC;
	local Vector2D ViewportSize;
	local bool bIsWideScreen;

	if(!Holder.IsFirstPerson())
		return;
	CurrentHand = GetHand();

	// Hide the weapon if necessary
	if(bForceHidden || CurrentHand == HAND_Hidden)
	{
		Mesh.SetHidden(True);
		Holder.ArmsMesh[0].SetHidden(true);
		Holder.ArmsMesh[1].SetHidden(true);
		NewRotation = Holder.GetViewRotation();
		SetLocation(Instigator.GetPawnViewLocation() + (HiddenWeaponsOffset >> NewRotation));
		SetRotation(NewRotation);
		SetBase(Instigator);
		return;
	}
	if(bPendingShow)
	{
		SetHidden(false);
		bPendingShow = false;
	}
	Mesh.SetHidden(false);
	foreach LocalPlayerControllers(class'PlayerController', PC)
	{
		LocalPlayer(PC.Player).ViewportClient.GetViewportSize(ViewportSize);
		break;
	}
	bIsWideScreen = (ViewportSize.Y > 0.f) && (ViewportSize.X / ViewportSize.Y > 1.7);
	ViewOffset = PlayerViewOffset;
	FinalSmallWeaponsOffset = SmallWeaponsOffset;
	switch(CurrentHand)
	{
		case HAND_Left:
			Mesh.SetScale3D(default.Mesh.Scale3D * vect(1,-1,1));
			Mesh.SetRotation(rot(0,0,0) - default.Mesh.Rotation);
			if (ArmsAnimSet != None)
			{
				Holder.ArmsMesh[0].SetScale3D(Holder.default.ArmsMesh[0].Scale3D * vect(1,-1,1));
				Holder.ArmsMesh[1].SetScale3D(Holder.default.ArmsMesh[1].Scale3D * vect(1,-1,1));
			}
			ViewOffset.Y *= -1.0;
			FinalSmallWeaponsOffset.Y *= -1.0;
			break;
		case HAND_Centered:
			ViewOffset.Y = 0.0;
			FinalSmallWeaponsOffset.Y = 0.0;
			break;
		case HAND_Right:
			Mesh.SetScale3D(default.Mesh.Scale3D);
			Mesh.SetRotation(default.Mesh.Rotation);
			if (ArmsAnimSet != None)
			{
				Holder.ArmsMesh[0].SetScale3D(Holder.default.ArmsMesh[0].Scale3D);
				Holder.ArmsMesh[1].SetScale3D(Holder.default.ArmsMesh[1].Scale3D);
			}
			break;
		default: break;
	}
	if(bIsWideScreen)
	{
		ViewOffset += WideScreenOffsetScaling * FinalSmallWeaponsOffset;
		if(bSmallWeapons)
			ViewOffset += 0.7 * FinalSmallWeaponsOffset;
	}
	else if(bSmallWeapons)
	{
		ViewOffset += FinalSmallWeaponsOffset;
	}
	if(Holder.Controller == none)
	{
		DrawOffset = (ViewOffset >> Holder.GetBaseAimRotation()) + UTPawn(Holder).GetEyeHeight() * vect(0,0,1);
	}
	else
	{
		DrawOffset.Z = UTPawn(Holder).GetEyeHeight();
		DrawOffset += UTPawn(Holder).WeaponBob(BobDamping, JumpDamping);
		if(UTPlayerController(Holder.Controller) != none)
			DrawOffset += UTPlayerController(Holder.Controller).ShakeOffset >> Holder.Controller.Rotation;
		DrawOffset = DrawOffset + ( ViewOffset >> Holder.Controller.Rotation );
	}

	// IMPORTANT!
	AdjustWeaponDrawOffset( DrawOffset, Holder, CurrentHand );
	
	FinalLocation = Holder.Location + DrawOffset;
	SetLocation(FinalLocation);
	SetBase(Holder);
	if (ArmsAnimSet != None)
	{
		Holder.ArmsMesh[0].SetTranslation(DrawOffset);
		Holder.ArmsMesh[1].SetTranslation(DrawOffset);
	}
	NewRotation = (Holder.Controller == None) ? Holder.GetBaseAimRotation() : Holder.Controller.Rotation;
	if(Holder.Controller != none)
	{
		FinalRotation.Yaw = LagRot(NewRotation.Yaw & 65535, LastRotation.Yaw & 65535, MaxYawLag, 0);
		FinalRotation.Pitch = LagRot(NewRotation.Pitch & 65535, LastRotation.Pitch & 65535, MaxPitchLag, 1);
		FinalRotation.Roll = NewRotation.Roll;
	}
	else
	{
		FinalRotation = NewRotation;
	}

	// IMPORTANT!
	AdjustWeaponRotation( FinalRotation, Holder, CurrentHand );
	
	LastRotUpdate = WorldInfo.TimeSeconds;
	LastRotation = NewRotation;
	if(bIsWideScreen)
		FinalRotation += WidescreenRotationOffset;
	SetRotation(FinalRotation);
	if(ArmsAnimSet != none)
	{
		Holder.ArmsMesh[0].SetRotation(FinalRotation);
		Holder.ArmsMesh[1].SetRotation(FinalRotation);
	}
}

simulated function AdjustWeaponDrawOffset(out vector DrawOffset, UDKPawn Holder, EWeaponHand CurrentHand)
{
	local Vector V;
	if(IronsightAlpha > 0)
	{
		V = IronsightPositionOffset;
		if(CurrentHand == HAND_Left)
			V.Y = -V.Y;
		DrawOffset += (V * IronsightAlpha) >> Holder.Controller.Rotation;
	}
}

simulated function AdjustWeaponRotation(out rotator DrawRotation, UDKPawn Holder, EWeaponHand CurrentHand)
{
	local Rotator R;
	local Vector X,Y,Z;
	if(IronsightAlpha > 0)
	{
		R = IronsightRotationOffset * IronsightAlpha;
		if(CurrentHand == HAND_Left)
		{
			R.Yaw = -R.Yaw;
			R.Roll = -R.Roll;
		}
		GetAxes(R, X, Y, Z);
		X = X >> DrawRotation;
		Y = Y >> DrawRotation;
		Z = Z >> DrawRotation;
		DrawRotation = OrthoRotation(X,Y,Z);
	}
}

simulated function Rotator GetAdjustedAim(Vector StartFireLoc)
{
	local Rotator R, BaseAim;
	local Vector X,Y,Z;
	if(IronsightAlpha > 0)
	{
		R = IronsightRotationOffset * IronsightAlpha;
		if(GetHand() == HAND_Left)
			R.Yaw = -R.Yaw;
		BaseAim = super.GetAdjustedAim(StartFireLoc);
		GetAxes(R, X, Y, Z);
		X = X >> BaseAim;
		Y = Y >> BaseAim;
		Z = Z >> BaseAim;
		return OrthoRotation(X,Y,Z);
	}
	return super.GetAdjustedAim(StartFireLoc);
}

// We don't want crosshairs when doing ironsights!
simulated function DrawWeaponCrosshair(Hud HUD)
{
	if(bCanIronsight && IronsightPawn(Instigator) != none && IronsightPawn(Instigator).bIronsight)
		return;
	super.DrawWeaponCrosshair(HUD);
}

defaultproperties
{
	bCanIronsight=true
	IronsightShiftPeriod=0.2
	IronsightPositionOffset=(X=-30,Y=-30,Z=12)
	IronsightRotationOffset=(Pitch=0,Yaw=0,Roll=0)
}
