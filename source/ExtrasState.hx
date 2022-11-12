package;

import flixel.graphics.FlxGraphic;
import flixel.util.FlxGradient;
import flixel.util.FlxTimer;
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
	var optionShit:Array<String> = ['do not open', 'trophies__and__achievements', 'original soundtracks'];
	var curSelected:Int = 0;

	var cursorSprite:FlxSprite;

	var bgGrp:FlxTypedGroup<FlxSprite>;
	var textGrp:FlxTypedGroup<FlxText>;

	override function create()
	{		
		cursorSprite = new FlxSprite(FlxG.mouse.x,
			FlxG.mouse.y).makeGraphic(Std.int(FlxG.mouse.cursorContainer.width), Std.int(FlxG.mouse.cursorContainer.height), FlxColor.RED);
		cursorSprite.visible = false;

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bgGrp = new FlxTypedGroup<FlxSprite>();
		add(bgGrp);

		var bgArray:Array<String> = [
			'middle screen',
			'left screen',
			'right screen',
		];

		for (i in 0...bgArray.length)
		{
			var bgItem:FlxSprite = new FlxSprite();
			switch(bgArray[i])
			{
				case 'left screen':
					bgItem.loadGraphic(Paths.image('extra/left screen'));
					bgItem.y -= 20;
				case 'middle screen':
					bgItem = FlxGradient.createGradientFlxSprite(634, 746, [FlxColor.BLACK, FlxColor.fromRGB(20, 0, 0), FlxColor.fromRGB(130, 0, 0), FlxColor.RED], 13);
					bgItem.setPosition(310, -20);
				case 'right screen':
					bgItem.loadGraphic(Paths.image('extra/right screen'));
					bgItem.setPosition(FlxG.width - bgItem.width, -20);
			}
			bgItem.ID = i;
			bgGrp.add(bgItem);

			trace('bg added : id = ${bgItem.ID}, text = ${bgArray[i]}');

			bgItem.antialiasing = ClientPrefs.globalAntialiasing;
		}


		var lBar:FlxSprite = new FlxSprite(311, -20).loadGraphic(Paths.image('extra/Lbar'));
		add(lBar);
		var rBar:FlxSprite = new FlxSprite(740, -20).loadGraphic(Paths.image('extra/Rbar'));
		add(rBar);

		textGrp = new FlxTypedGroup<FlxText>();
		add(textGrp);

		add(cursorSprite);

		for (i in 0...optionShit.length)
		{
			var text:FlxText = new FlxText(0, 0, FlxG.width, optionShit[i].toUpperCase().replace('__', '\n'));
			text.setFormat(Paths.font("impact.ttf"), 32, FlxColor.WHITE, CENTER).screenCenter();
			switch(optionShit[i])
			{
				case 'do not open':
					text.screenCenter(X);
					text.y = 50;
				case 'trophies__and__achievements':
					text.screenCenter(X);
					text.x -= 400;
					text.y = 50;
				case 'original soundtracks':
					text.screenCenter(X);
					text.x += 400;
					text.y = 50;
			}
			text.ID = i;
			textGrp.add(text);
			trace('text added : id = ${text.ID}, text = ${optionShit[i]}, x = ${text.x}, y = ${text.y}');
		}

		super.create();

		FlxG.mouse.visible = true;
		Paths.clearUnusedMemory();
		FlxGraphic.defaultPersist = true; // need to keep them for the overlap checks
	}

	var selectedSomethin:Bool = false;
	override function update(elapsed:Float)
	{
		if (!selectedSomethin)
		{
			if (cursorSprite.x != FlxG.mouse.cursorContainer.x)
				cursorSprite.setPosition(FlxG.mouse.x, FlxG.mouse.y);

			if (controls.BACK)
			{
				FlxGraphic.defaultPersist = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				FlxGraphic.defaultPersist = false;
				
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));

				var daChoice:String = optionShit[curSelected];
				if (daChoice == 'trophies__and__achievements')
				{
					FlxTransitionableState.skipNextTransOut = true;
					StageData.forceNextDirectory = 'minigame';
					FlxG.sound.music.fadeOut(1, 0, twn ->
					{
						FlxG.sound.music.stop();
						sanford.SAState.resetData();
						LoadingState.loadAndSwitchState(new sanford.SAState());
					});
				}
				else
				{
					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						switch (daChoice)
						{
							case 'do not open':
								MusicBeatState.switchState(new MainMenuState());
							case 'original soundtracks':
								MusicBeatState.switchState(new OSTMenu());
							default:
								trace('clicked an unhandled button, $daChoice, curSelected $curSelected');
								FlxG.resetState();
						}
					});
				}

				/*
				bgGrp.forEach(function(spr:FlxSprite)
				{
					if (sel == spr.ID)
					{
						var daChoice:String = optionShit[sel];
						if (daChoice == 'trophies__and__achievements')
						{
							FlxTransitionableState.skipNextTransOut = true;
							StageData.forceNextDirectory = 'minigame';
							FlxG.sound.music.fadeOut(1, 0, twn ->
							{
								FlxG.sound.music.stop();
								sanford.SAState.resetData();
								LoadingState.loadAndSwitchState(new sanford.SAState());
							});
						}
						else
						{
							new FlxTimer().start(1, function(tmr:FlxTimer)
							{
								switch (daChoice)
								{
									case 'do not open':
										MusicBeatState.switchState(new MainMenuState());
									case 'original soundtracks':
										MusicBeatState.switchState(new OSTMenu());
									default:
										trace('clicked an unhandled button, $daChoice, curSelected $sel');
										FlxG.resetState();
								}
							});
						}
					}
				});
				*/
			}
		}

		super.update(elapsed);

		if (!selectedSomethin)
		{
			var isSel:Bool = false;
			bgGrp.forEach(spr ->
			{
				if (!isSel && FlxG.pixelPerfectOverlap(spr, cursorSprite, 100))
				{
					if (curSelected != spr.ID)
						changeItem(spr.ID);
					isSel = true;
				}
			});
		}
	}

	function changeItem(newSel:Int = 0)
	{
		curSelected = newSel;

		trace(optionShit[curSelected] + ' ' + curSelected);
		
		// textGrp.forEach(function(txt:FlxText)
		// {
		// 	if (txt.ID == curSelected)
		// 	{
		// 		txt.color = FlxColor.BLACK;
		// 		txt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.WHITE);
		// 	}
		// 	else
		// 	{
		// 		txt.color = FlxColor.WHITE;
		// 		txt.setBorderStyle(NONE, FlxColor.TRANSPARENT);
		// 	}
		// });
	}
}
