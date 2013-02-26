class MobileMenuToggleButton extends MobileMenuButton;

function ToggleButton()
{
	bIsHighlighted = !bIsHighlighted;
}

function bool IsPressed()
{
	return bIsHighlighted;
}	

function Close()
{
	bIsHighlighted = false;
}

function Open()
{
	bIsHighlighted = true;
}

function RenderObject(canvas Canvas, float DeltaTime)
{
	local int Idx;
	local LinearColor DrawColor;


	Idx = (bIsHighlighted) ? 1 : 0;
	Canvas.SetPos(OwnerScene.Left + Left, OwnerScene.Top + Top);
	Drawcolor = ImageColor;
	Drawcolor.A *= Opacity * OwnerScene.Opacity;
	Canvas.DrawTile(Images[Idx], Width, Height,ImagesUVs[Idx].U, ImagesUVs[Idx].V, ImagesUVs[Idx].UL, ImagesUVs[Idx].VL, DrawColor);

	RenderCaption(Canvas);
}
