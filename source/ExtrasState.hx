package;

#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;

using StringTools;

class ExtrasState extends MusicBeatState
{
	var optionShit:Array<String> = ['trophies\nand\nachievements', 'do not open', 'original soundtracks'];
	var curSelected:Int = 0;

	var bgs:FlxTypedGroup<FlxSprite>;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bgs = new FlxTypedGroup<FlxSprite>();
		add(bgs);

		var bgArray:Array<String> = [
			'left screen',
			'Lbar',
			'middle screen',
			'Rbar',
			'right screen'
		];

		for (i in 0...bgArray.length)
		{
			var bgItem:FlxSprite = new FlxSprite().loadGraphic(Paths.image('extra/${bgArray[i]}'));
			bgItem.setGraphicSize(0, 720);
			bgItem.updateHitbox();
			if (i > 0)
				bgItem.x = bgs.members[i-1].x + bgs.members[i-1].width;
			bgs.add(bgItem);

			bgItem.antialiasing = ClientPrefs.globalAntialiasing;
		}

		// for (i in 0...optionShit.length)
		// {

		// }

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		if (controls.ACCEPT)
		{
			if (FlxG.keys.pressed.SHIFT)
			{
				LoadingState.loadAndSwitchState(new ChartingState());
			}
			else
			{
				LoadingState.loadAndSwitchState(new PlayState());
			}
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = optionShit.length - 1;
		if (curSelected >= optionShit.length)
			curSelected = 0;
	}
}
