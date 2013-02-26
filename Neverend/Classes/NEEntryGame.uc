class NEEntryGame extends NEGame;

var AudioComponent MenuMusic;

function AssignMusic()
{
	CurrentMusic = MenuMusic;
	CurrentMusicMobile = "Menu";
	CurrentMusicMultiplier = CurrentMusic.VolumeMultiplier;
	StartMusic();
}

defaultproperties
{
	bIsEntryGame = true;
	Begin Object Class=AudioComponent Name=MenuMusicComp
		SoundCue=SoundCue'Never_End_MAudio.Music.Menu_Music_Cue'
	End Object
	MenuMusic = MenuMusicComp
}