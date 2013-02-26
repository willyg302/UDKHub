class GlobalMapData extends Object;

//Track is the music track in main library to play on this level

struct MapData
{
	var string Title;
	var string Description1, Description2;
	var int MaxPoints;
	var int Track;
};

/**
 * ABOUT POINTS:
 * MaxPoints is points you would earn if you finished the level in 0 seconds, 0 deaths, 0 restarts.
 * For every second, we minus 1 point
 * For every death, we minus 10 points
 * Points actually earned is clamped to the interval (0, MaxPoints)
 * 
 * Restarts are subtracted from the total points, since we cannot apply them on a per-level basis.
 * Each restart subtracts 25 points.
 */

var array<MapData> MapArray;

defaultproperties
{
	MapArray.Add((Title="Warm Up",Description1="Before you can walk, you must",Description2="first learn how to roll",MaxPoints=105,Track=0))
	MapArray.Add((Title="The Stars",Description1="Sometimes the hardest part is not",Description2="finding your goal but reaching it",MaxPoints=115,Track=0))
	MapArray.Add((Title="Bigger",Description1="Size is relative, you say?",Description2="Oddly enough, so is relativity",MaxPoints=120,Track=0))
	MapArray.Add((Title="Open Sesame",Description1="I can only show you the door - you",Description2="are the one who must walk through it",MaxPoints=110,Track=1))
	MapArray.Add((Title="Polarity",Description1="A magnet without a north and a south",Description2="isn't very much fun at all",MaxPoints=115,Track=0))

	MapArray.Add((Title="Hurdles",Description1="If only the way to the finish",Description2="was always straight and clear",MaxPoints=150,Track=0))
	MapArray.Add((Title="The Hourglass",Description1="Tip an hourglass on its side",Description2="and time will never run out",MaxPoints=115,Track=0))
	MapArray.Add((Title="Shuttle Run",Description1="Left or right: the right choice",Description2="is best left as an exercise",MaxPoints=130,Track=0))
	MapArray.Add((Title="All Things Pass",Description1="Death is no more than passing from",Description2="one room into another",MaxPoints=180,Track=0))
	MapArray.Add((Title="Minefield",Description1="Video Game Fact #10110:",Description2="You can't respawn in real life",MaxPoints=500,Track=1))

	MapArray.Add((Title="The Incinerator",Description1="A long way to the bottom is even",Description2="longer when you can't touch the sides",MaxPoints=180,Track=1))
	MapArray.Add((Title="Inner Circle",Description1="The greatest safeguards fall to the one",Description2="who's willing to open every door",MaxPoints=130,Track=0))
	MapArray.Add((Title="Flip Side",Description1="You'll never see a coin land with",Description2="both sides up at the same time",MaxPoints=120,Track=0))
	MapArray.Add((Title="Around the World",Description1="No matter how small the world is,",Description2="going around it is still a big journey",MaxPoints=200,Track=0))
	MapArray.Add((Title="Isolation",Description1="To be truly alone is to leave",Description2="no way for others to reach you",MaxPoints=180,Track=0))

	MapArray.Add((Title="Big Brother",Description1="Just because it's like you",Description2="doesn't mean it likes you",MaxPoints=120,Track=0))
	MapArray.Add((Title="Charon",Description1="What kills you can also help you",Description2="if you know how to use it well",MaxPoints=120,Track=0))
	MapArray.Add((Title="Universal Constant",Description1="You can try all you want, but",Description2="some things just never change",MaxPoints=130,Track=0))
	MapArray.Add((Title="The Tumbler",Description1="What's locked away is still there",Description2="even if it's hidden too deep to see",MaxPoints=130,Track=0))
	MapArray.Add((Title="Roomception",Description1="Is this what will be your doom:",Description2="but a room within a room?",MaxPoints=500,Track=1))

	MapArray.Add((Title="Tug of War",Description1="Some paths only open when",Description2="another path is closed",MaxPoints=140,Track=0))
	MapArray.Add((Title="Five",Description1="six, seven, and eight, halved",Description2="plus none does thirteen make",MaxPoints=150,Track=1))
	MapArray.Add((Title="Teamwork",Description1="Help another to reach the top",Description2="and you shall reach it yourself",MaxPoints=130,Track=0))
	MapArray.Add((Title="Bear Trap",Description1="Sometimes the key to freedom lies",Description2="in the very thing you feel trapped by",MaxPoints=160,Track=0))
	MapArray.Add((Title="Gentle Giant",Description1="Think before you move, for others",Description2="may not tread so lightly",MaxPoints=150,Track=1))

	MapArray.Add((Title="The Seesaw",Description1="When neither end looks appealing,",Description2="it's best to start in the middle",MaxPoints=200,Track=0))
	MapArray.Add((Title="Holes",Description1="A hole is not truly a hole",Description2="unless it can be filled",MaxPoints=150,Track=0))
	MapArray.Add((Title="Single-Edged Sword",Description1="If it doesn't work but should,",Description2="you're probably doing it wrong",MaxPoints=160,Track=1))
	MapArray.Add((Title="Kill Zone",Description1="The best protection against fire is",Description2="never touching it in the first place",MaxPoints=170,Track=0))
	MapArray.Add((Title="Guardian Angel",Description1="Maybe the thing that catches your fall",Description2="is only there because you put it there",MaxPoints=500,Track=1))

	MapArray.Add((Title="The Friend",Description1="A friend is there to help you",Description2="even when no one else will",MaxPoints=115,Track=0))
	MapArray.Add((Title="Pecking Order",Description1="It is generally accepted that the better",Description2="members of society should go first",MaxPoints=130,Track=0))
	MapArray.Add((Title="Fatal Flaw",Description1="What doesn't kill you didn't",Description2="do a very good job",MaxPoints=130,Track=0))
	MapArray.Add((Title="Jigsaw",Description1="No piece is too perfect to",Description2="fit into the bigger picture",MaxPoints=150,Track=0))
	MapArray.Add((Title="Door Stopper",Description1="Sometimes the opening need only be",Description2="wide enough for you to slip through",MaxPoints=200,Track=0))

	MapArray.Add((Title="Reverse Osmosis",Description1="Thinking backwards is a great skill,",Description2="but so is thinking upside-down",MaxPoints=150,Track=0))
	MapArray.Add((Title="Terminal Velocity",Description1="Another fact of life: the higher they",Description2="reach, the faster they'll fall",MaxPoints=160,Track=0))
	MapArray.Add((Title="Bunny Hopping",Description1="A few thoughtful, small steps are",Description2="usually better than a giant leap",MaxPoints=160,Track=1))
	MapArray.Add((Title="Konami",Description1="A, B, Select, Start, and up is",Description2="wrong in case you didn't know",MaxPoints=180,Track=0))
	MapArray.Add((Title="Space Junk",Description1="Don't be afraid to rely on others",Description2="who can do what you cannot do",MaxPoints=500,Track=1))

	MapArray.Add((Title="Unwelcome Help",Description1="Life always seems to take a pause",Description2="when you want to get there fast",MaxPoints=140,Track=0))
	MapArray.Add((Title="Shotgunned",Description1="The greatest rewards in life",Description2="often come from being reckless",MaxPoints=180,Track=0))
	MapArray.Add((Title="Bullet Time",Description1="Slow and steady has no advantage",Description2="if there is no race to be won",MaxPoints=140,Track=0))
	MapArray.Add((Title="Parasites",Description1="Like dark is to light, there is no",Description2="help without also some hurt",MaxPoints=160,Track=0))
	MapArray.Add((Title="Inseparable",Description1="How many walls would you tear down",Description2="to reach the thing you want most?",MaxPoints=155,Track=0))

	MapArray.Add((Title="Deja Vu",Description1="It's not about if it happened before,",Description2="it's about why it's happening again",MaxPoints=140,Track=0))
	MapArray.Add((Title="Containment",Description1="As long as there's one way out,",Description2="someone's guaranteed to find it",MaxPoints=250,Track=0))
	MapArray.Add((Title="Double Take",Description1="If at first it seems wrong, why",Description2="would a second look make it right?",MaxPoints=200,Track=1))
	MapArray.Add((Title="Leap of Faith",Description1="The only reason we know we can fly",Description2="is because someone first dared to try",MaxPoints=250,Track=0))
	MapArray.Add((Title="The Keypad",Description1="Luck's got nothing to do with success;",Description2="the few who succeed just don't give up",MaxPoints=500,Track=1))

	MapArray.Add((Title="The End",Description1="A wise woman once said, everything",Description2="that has a beginning has an end",MaxPoints=0,Track=0))
}
