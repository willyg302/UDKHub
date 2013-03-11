//=============================================================================
// UTMutator_PhysXWeapons
// Class which switches out weapons for their PhysX versions and addes a fluid drain
// The Weapons replacement code was taken from this forum http://forums.epicgames.com/threads/751721-Custom-Weapon-Replacing-Mutator
//=============================================================================

class UTMutator_PhysXWeapons extends UTMutator
	config(PhysXMod);

struct ReplacementInfo
{
	/** class name of the weapon we want to get rid of */
	var name OldClassName;
	/** fully qualified path of the class to replace it with */
	var string NewClassPath;
};

var config array<ReplacementInfo> WeaponsToReplace;
var UTDrain LevelDrain;

function PostBeginPlay()
{

	local UTGame Game;
	local int i, Index;

	Super.PostBeginPlay();

	// Replace default weapons
	Game = UTGame(WorldInfo.Game);
	if (Game != None)
	{
		for (i = 0; i < Game.DefaultInventory.length; i++)
		{
			if (Game.DefaultInventory[i] != None)
			{
				Index = WeaponsToReplace.Find('OldClassName', Game.DefaultInventory[i].Name);
				if (Index != INDEX_NONE)
				{
					`Log("Replacing" @ Game.DefaultInventory[i].Name @ "with" @ WeaponsToReplace[Index].NewClassPath);
					if (WeaponsToReplace[Index].NewClassPath == "")
					{
						// replace with nothing
						Game.DefaultInventory.Remove(i, 1);
						i--;
					}
					Game.DefaultInventory[i] = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[Index].NewClassPath, class'Class'));
				}
			}
		}
	}

	//Loading a custom drain for each level in order to catch any particles that might fall through the world.
	//Note: The custom drain meshes have the proper map offset locations in the asset so I will just spanwn at 0,0,0
	LevelDrain = Spawn(class'UTDrain',,,vect(0,0,0));

	if (WorldInfo.GetMapName() == "Deck")
	{
		LevelDrain.StaticMeshComponent.SetStaticMesh(StaticMesh'PhysX_Mutator_Common.Meshes.DeckFluidDrainMesh');
	}
	else if(WorldInfo.GetMapName() == "Necropolis") 
	{
		LevelDrain.StaticMeshComponent.SetStaticMesh(StaticMesh'PhysX_Mutator_Common.Meshes.NecropolisFluidDrainMesh');
	}
	//Note: If you create a new map and drain you could add an additional check here.

}

function bool CheckReplacement(Actor Other)
{

	local UTWeaponPickupFactory WeaponPickup;
	local UTWeaponLocker Locker;
	local int i, Index;

	WeaponPickup = UTWeaponPickupFactory(Other);
	if (WeaponPickup != None)
	{
		if (WeaponPickup.WeaponPickupClass != None)
		{
			Index = WeaponsToReplace.Find('OldClassName', WeaponPickup.WeaponPickupClass.Name);
			if (Index != INDEX_NONE)
			{
				if (WeaponsToReplace[Index].NewClassPath == "")
				{
					// replace with nothing
					return false;
				}
				WeaponPickup.WeaponPickupClass = class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[Index].NewClassPath, class'Class'));
				WeaponPickup.InitializePickup();
			}
		}
	}
	else
	{
		Locker = UTWeaponLocker(Other);
		if (Locker != None)
		{
			for (i = 0; i < Locker.Weapons.length; i++)
			{
				if (Locker.Weapons[i].WeaponClass != None)
				{
					Index = WeaponsToReplace.Find('OldClassName', Locker.Weapons[i].WeaponClass.Name);
					if (Index != INDEX_NONE)
					{
						if (WeaponsToReplace[Index].NewClassPath == "")
						{
							// replace with nothing
							Locker.ReplaceWeapon(i, None);
						}
						else
						{
							Locker.ReplaceWeapon(i, class<UTWeapon>(DynamicLoadObject(WeaponsToReplace[Index].NewClassPath, class'Class')));
						}
					}
				}
			}
		}
	}

	return true;
}

defaultproperties
{
	GroupNames[0]="WEAPONMOD"
}

