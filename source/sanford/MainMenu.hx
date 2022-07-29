package sanford;

import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import lime.app.Application;
import Discord.DiscordClient;
import Controls;

class MainMenu extends MusicBeatState
{
	public static var bgPoint:FlxPoint;

	var menuOptions:Array<String> = ['Play', 'Options', 'Quit'];
	var items:FlxTypedGroup<Text>;
	var coolThing:FlxSprite;
	var curSel:Int = 0;

	var fromTitle:Bool = false;

	override public function create()
	{
		super.create();

		// #if cpp
		// DiscordClient.changePresence('Browsing Menus', null, null, 'Diced Up!', null, null, false, true);
		// #end

		if (Sound.gameMus != null)
		{
			Sound.gameMus.stop();
			Sound.gameMus = null;
		}
		if (Sound.menuMusic == null)
			Sound.menuMusic = Sound.playMusic('menu');

		var bg:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.create(64, 64, 64 * 8, 64 * 8, true, 0xFF807feb, 0xFF6454ab).pixels);
		bg.velocity.set(30, 30);
		add(bg);
		if (bgPoint != null)
		{
			bg.setPosition(bgPoint.x, bgPoint.y);
			bgPoint = null;
			fromTitle = true;
		}

		var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		overlay.alpha = .4;
		add(overlay);
		var title = new FlxSprite().loadGraphic(Paths.image('DicedUpLogo'));

		title.scale.set(6, 6);
		title.updateHitbox();
		title.screenCenter(X);
		add(title);
		title.y = FlxG.height / 6 - title.height / 3;

		if (!fromTitle)
		{
			title.alpha = 0;
			FlxTween.tween(title, {'alpha': 1}, .5, {ease: FlxEase.smootherStepInOut});
		}
		items = new FlxTypedGroup();
		for (i in 0...menuOptions.length)
		{
			var newText:Text = new Text(0, 0, FlxG.width, menuOptions[i], 64);

			newText.y = title.y + title.height - 20 + (70 * i);
			newText.alignment = CENTER;
			newText.ID = i;
			items.add(newText);
		}
		coolThing = new FlxSprite().makeGraphic(FlxG.width, Math.ceil(items.members[0].height + 10), FlxColor.BLACK);
		add(coolThing);
		coolThing.alpha = 0.6;
		add(items);
		for (i in 0...items.length)
		{
			var spr = items.members[i];

			if (spr == null)
				return;
			spr.y += FlxG.height;
			FlxTween.tween(spr, {y: spr.y - FlxG.height}, .5, {startDelay: .05 * i, ease: FlxEase.smootherStepInOut});
		}
		coolThing.y = items.members[curSel].y + items.members[curSel].height / 2 - coolThing.height / 2;
		var version:String = 'v${Application.current.meta.get('version')}';

		var nightlyVer:String = Application.current.meta.get('nightly');

		if (nightlyVer != null && nightlyVer != '')
			version += '-${Application.current.meta.get('nightly')}';
		var versionText:Text = new Text(0, 0, FlxG.width, version, 32);
		versionText.alignment = CENTER;
		add(versionText);
		versionText.setPosition(0, FlxG.height - versionText.height - 10);

		if (fromTitle)
		{
			FlxG.camera.flash();
			Sound.play('slice');
		}
	}

	var selected:Bool = false;

	function retSel(sel:Int):Int
		return if (sel >= items.length) retSel(sel - items.length) else if (sel < 0) retSel(items.length + sel) else sel;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (controls.BACK)
			FlxG.switchState(new Intro());

		coolThing.y = FlxMath.lerp(coolThing.y, items.members[curSel].y + items.members[curSel].height / 2 - coolThing.height / 2, 0.4);

		if (controls.UI_UP_P)
			change(-1);
		if (controls.UI_DOWN_P)
			change(1);

		items.forEach(spr ->
		{
			if (spr.ID == curSel)
				spr.color = 0xFFffcc26;
			else
				spr.color = FlxColor.WHITE;
		});
		if (controls.ACCEPT && !selected)
			select(menuOptions[curSel]);
	}

	function change(by:Int = 0)
	{
		curSel = retSel(curSel + by);
		Sound.play('menuChange');
	}

	function select(selection:String)
	{
		Sound.play('menuSelect');
		switch (selection)
		{
			case 'Play':
				selected = true;
				SAState.resetData();

				if (Sound.menuMusic == null)
					Sound.menuMusic.fadeOut(.5);
				FlxG.camera.fade(FlxColor.BLACK, .5, false, () -> FlxG.switchState(new SAState()));
			case 'Options':
				openSubState(new Options());
			case 'Quit':
				StageData.forceNextDirectory = 'preload';
				LoadingState.loadAndSwitchState(new MainMenuState());

			default:
				trace('unhandled $selection');
				selected = false;
		}
	}
}
