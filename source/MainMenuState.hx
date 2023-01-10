package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import editors.MasterEditorMenu;
import Achievements;

using StringTools;

typedef MenuChar =
{
	path:String,
	prefix:String,
	scale:Float
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.01 [DEV BUILD]'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var optionShit:Array<String> = ['story', 'freeplay', 'shop', 'extras', 'options', /* 'credits' */];

	var hankmenu:FlxSprite;
	var debugKeys:Array<FlxKey>;

	override function create()
	{
		if (FlxG.sound.music == null)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}
		else if (!FlxG.sound.music.playing)
			FlxG.sound.music.play();

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

		#if (flixel < "5.0.0")
		var bdrop:FlxBackdrop = new FlxBackdrop(Paths.image('mainmenu/scrollbg'), 1, 0, true, false);
		#else
		var bdrop:FlxBackdrop = new FlxBackdrop(Paths.image('mainmenu/scrollbg'), X);
		#end
		bdrop.scale.set(0.46, 0.46);
		bdrop.updateHitbox();
		bdrop.offset.y += 50;
		bdrop.velocity.x = 100;
		bdrop.antialiasing = ClientPrefs.globalAntialiasing;
		add(bdrop);
		bdrop.alive = false;

		hankmenu = new FlxSprite(-80).loadGraphic(Paths.image('mainmenu/bg'));
		hankmenu.scrollFactor.set();
		hankmenu.setGraphicSize(FlxG.width, FlxG.height);
		hankmenu.updateHitbox();
		hankmenu.screenCenter();
		hankmenu.antialiasing = ClientPrefs.globalAntialiasing;
		hankmenu.x = 0;
		hankmenu.y = 0;
		hankmenu.height = 1;
		add(hankmenu);
		hankmenu.alive = false;

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(50, (i * 130) + 60);

			switch(optionShit[i])
			{
				case 'story':
					menuItem.frames = Paths.getSparrowAtlas('mainmenu/buttons/' + optionShit[i]);
					menuItem.animation.addByPrefix('idle', 'Symbol 10000', 1, false);
					menuItem.animation.addByPrefix('selected', 'story slice0', 24, false);
					menuItem.animation.play('idle');
					menuItem.updateHitbox();

				default:
					menuItem.loadGraphic(Paths.image('mainmenu/buttons/${optionShit[i]}'));
					menuItem.updateHitbox();
			}

			menuItem.ID = i;
			menuItems.add(menuItem);

			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
		}
		
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Psych Engine v0.5.2h [HEAVILY CUSTOMIZED BUILD + CUSTOM INPUT SYSTEM]", 12);
		versionShit.scrollFactor.set();
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Madness Origins: The Hank Trilogy v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font("impact.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		if (FlxG.save.data.clownClicked != null && FlxG.save.data.clownClicked)
		{
			var trick:FlxSprite = new FlxSprite();
			trick.frames = Paths.getSparrowAtlas('mainmenu/tricky');
			trick.animation.addByPrefix('idle', 'Tricky0', 24);
			trick.animation.play('idle');
			trick.scale.set(.9, .9);
			trick.updateHitbox();
			trick.setPosition(FlxG.width - 200, 10);
			trick.antialiasing = ClientPrefs.globalAntialiasing;
			add(trick);
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
		FlxG.mouse.visible = true;
		openfl.system.System.gc();
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

		if (!selectedSomethin)
		{
			if (FlxG.keys.justPressed.C)
			{
				selectedSomethin = true;
				FlxG.switchState(new CreditsState());
			}
		
			if (FlxG.keys.justPressed.FOUR)
			{
				selectedSomethin = true;
				FlxG.switchState(new LoadingScreen(null, true));
			}
		
			if (FlxG.keys.justPressed.S)
			{
				selectedSomethin = true;
				FlxTransitionableState.skipNextTransOut = true;
				StageData.forceNextDirectory = 'minigame';
				FlxG.sound.music.fadeOut(1, 0, twn ->
				{
					FlxG.sound.music.stop();
					sanford.SAState.resetData();
					LoadingState.loadAndSwitchState(new sanford.SAState());
				});
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if ((controls.ACCEPT || FlxG.mouse.justPressed) && curSelected != menuItems.members.length)
			{
				var sel:Int = curSelected;
				if (optionShit[sel] == 'donate' || optionShit[sel] == 'story') // temp until story menu is finished
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.mouse.visible = false;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (sel == spr.ID)
						{
							if (spr.animation.getNameList().contains('selected'))
								spr.animation.play('selected');

							new FlxTimer().start(1, function(tmr:FlxTimer)
							{
								var daChoice:String = optionShit[sel];

								switch (daChoice)
								{
									// case 'story':
										// MusicBeatState.switchState(new StoryMenuState());
									case 'freeplay':
										MusicBeatState.switchState(new OSTMenu());
									case 'shop':
										MusicBeatState.switchState(new ShopState());
										// MusicBeatState.switchState(new LoadingScreen(null, true));
									case 'extras':
										MusicBeatState.switchState(new ExtrasState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									default:
										trace('clicked an unhandled button, $daChoice, curSelected $sel');
										FlxG.resetState();
								}
							});
						}
					});
				}
			}

			#if FLX_DEBUG
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

			menuItems.forEach(spr ->
			{
				if (!isSel && FlxG.mouse.overlaps(spr))
				{
					if (curSelected != spr.ID)
						changeItem(spr.ID);
					isSel = true;
				}
			});

			if (!isSel && curSelected != menuItems.members.length)
				changeItem(menuItems.members.length);
		}
	}

	function changeItem(newSel:Int = 0)
	{
		curSelected = newSel;

		trace(optionShit[newSel] + ' ${newSel}');

		menuItems.forEach(function(spr:FlxSprite)
		{
			if (spr.animation.getNameList().contains('idle'))
				spr.animation.play('idle');
			// spr.updateHitbox();
		});
	}
}
