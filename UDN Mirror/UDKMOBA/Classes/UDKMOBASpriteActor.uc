class UDKMOBASpriteActor extends Actor
	Placeable;

var() const SpriteComponent SpriteComponent;

defaultproperties
{
	Begin Object Class=SpriteComponent Name=MySpriteComponent
	End Object
	Components.Add(MySpriteComponent);
	SpriteComponent=MySpriteComponent;
}