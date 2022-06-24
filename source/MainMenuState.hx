package;

import flixel.util.FlxTimer;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

typedef MenuChar =
{
	path:String,
	prefix:String,
	scale:Float
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = 'H.A.N.K'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = ['options', 'bfs', 'story', 'freeplay'];

	var charList:Array<MenuChar> = [
		{path: "ded_bf", prefix: 'died bf', scale: 1},
		{path: "sheriff", prefix: 'Sariff', scale: 1.25},
		{path: "Auditor", prefix: 'Grunt idle', scale: 1.15},
		{path: "GruntDead", prefix: 'Grunt idle', scale: 1.25},
		{path: "Zombie", prefix: 'Grunt idle', scale: 1.25},
		{path: "grunt", prefix: 'Grunt idle', scale: 1.25},
		{path: "skellytricky", prefix: 'Grunt idle', scale: 1},
		{path: "menu_grunt2", prefix: 'Grunt idle', scale: 1.25},
		{path: "menu_scrapeface", prefix: 'Grunt idle', scale: 1.25}
	];

	var magenta:FlxSprite;
	var hankmenu:FlxSprite;
	var movingbgidiots:FlxSprite;
	var grunt:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	override function create()
	{
		FlxG.mouse.visible = true;

		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));

		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0 - (0 * (optionShit.length - 0)), 0);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 0.45));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.alive = false;

		movingbgidiots = new FlxSprite(-80);
		movingbgidiots.frames = Paths.getSparrowAtlas('mainmenu/Ugly_mofos');
		movingbgidiots.animation.addByPrefix('idle', 'movin dudes0', 24, false);
		movingbgidiots.scrollFactor.set(0, yScroll);
		movingbgidiots.setGraphicSize(Std.int(movingbgidiots.width * 1.6));
		movingbgidiots.updateHitbox();
		movingbgidiots.screenCenter();
		movingbgidiots.antialiasing = ClientPrefs.globalAntialiasing;
		movingbgidiots.x = -1800;
		movingbgidiots.y = -1535;
		movingbgidiots.height = 1;
		add(movingbgidiots);
		movingbgidiots.alive = false;

		var randomChar:Int = FlxG.random.int(0, charList.length - 1);
		grunt = new FlxSprite(-80);
		grunt.frames = Paths.getSparrowAtlas('mainmenu/chars/${charList[randomChar].path}');
		grunt.animation.addByPrefix('idle', charList[randomChar].prefix, 24, false);

		grunt.scale.set(charList[randomChar].scale, charList[randomChar].scale);
		grunt.updateHitbox();
		grunt.screenCenter();
		grunt.antialiasing = ClientPrefs.globalAntialiasing;
		grunt.setPosition(75, 215);
		switch (charList[randomChar].path)
		{
			case 'ded_bf':
				grunt.x -= 75;

			case 'Auditor':
				grunt.x -= 50;
				grunt.y -= 100;

			case 'grunt':
				grunt.y -= 100;

			case 'skellytricky':
				grunt.x -= 120;
				grunt.y -= 200;

			case 'menu_grunt2':
				grunt.x -= 50;
				grunt.y -= 100;
		}

		add(grunt);

		hankmenu = new FlxSprite(-80).loadGraphic(Paths.image('mainmenuOG'));
		hankmenu.scrollFactor.set(0, yScroll);
		hankmenu.setGraphicSize(Std.int(hankmenu.width * 0.45));
		hankmenu.updateHitbox();
		hankmenu.screenCenter();
		hankmenu.antialiasing = ClientPrefs.globalAntialiasing;
		hankmenu.x = 0;
		hankmenu.y = 0;
		hankmenu.height = 1;
		add(hankmenu);
		hankmenu.alive = false;

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 0.45));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		add(magenta);

		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		var spr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('mainmenu/select_screen'));
		spr.setPosition(480, 123);
		add(spr);
		spr.alive = false;

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;

			menuItem.frames = Paths.getSparrowAtlas('mainmenu/buttons/' + optionShit[i]);
			menuItem.animation.addByIndices('idle', 'select ${optionShit[i]}', [0], "", 24);
			menuItem.animation.addByPrefix('selected', 'select ${optionShit[i]}', 12, false);
			menuItem.animation.play('idle');
			menuItem.updateHitbox();

			switch (optionShit[i])
			{
				case 'options':
					menuItem.setPosition(650, 245);
				case 'bfs':
					menuItem.setPosition(520, 265);
				case "story":
					menuItem.setPosition(730, 200);
				case "freeplay":
					menuItem.setPosition(940, 135);
			}

			menuItem.ID = i;
			menuItems.add(menuItem);

			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			// menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
		}

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
		{
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2]))
			{ // It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement()
	{
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		grunt.animation.play('idle');

		movingbgidiots.animation.play('idle');

		#if FLX_DEBUG
		if (FlxG.keys.justPressed.FOUR)
			FlxG.switchState(new CharacterSelect());
		#end
		if (!selectedSomethin)
		{
			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if ((controls.ACCEPT || FlxG.mouse.justPressed) && curSelected != menuItems.members.length)
			{
				var sel:Int = curSelected;
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.mouse.visible = false;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					/*if (ClientPrefs.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false); */

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							/*FlxTween.tween(spr, {alpha: 0}, 0.4, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});*/ // do nothing
						}
						else
						{
							spr.animation.play('selected');
							// FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							new FlxTimer().start(1, function(tmr:FlxTimer)
							{
								var daChoice:String = optionShit[sel];

								switch (daChoice)
								{
									case 'bfs':
										MusicBeatState.switchState(new CharacterSelect());
									case 'story':
										MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new FreeplayState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
									default:
										trace('clicked an unhandled button, $daChoice, curSelected $sel');
										FlxG.resetState();
								}
							});
						}
					});
				}
			}

			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);

		if (!selectedSomethin)
		{
			var isSel:Bool = false;

			menuItems.forEach(function(spr:FlxSprite)
			{
				if (FlxG.mouse.overlaps(spr) && curSelected != spr.ID)
				{
					changeItem(spr.ID);
					isSel = true;
				}
			});

			if (!isSel)
				changeItem(menuItems.members.length);
		}
	}

	function changeItem(newSel:Int = 0)
	{
		curSelected = newSel;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			// spr.updateHitbox();
		});
	}
}
