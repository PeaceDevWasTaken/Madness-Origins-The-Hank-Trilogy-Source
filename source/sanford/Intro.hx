package sanford;

import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxPoint;
import sanford.Text;
import Controls;

class Intro extends MusicBeatState
{
	var logo:FlxSprite;

	var daParent:FlxSprite;
	var text:Text;
	var bg:FlxBackdrop;

	override public function create()
	{
		super.create();

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.mouse.visible = false;
		if (Sound.menuMusic == null)
			Sound.menuMusic = Sound.playMusic('menu');

		bg = new FlxBackdrop(FlxGridOverlay.create(64, 64, 64 * 8, 64 * 8, true, 0xFF807feb, 0xFF6454ab).pixels);
		bg.velocity.set(30, 30);
		add(bg);

		var overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = .4;
		add(overlay);

		logo = new FlxSprite().loadGraphic(Paths.image('main_logo'));
		add(logo);

		while (logo.width >= FlxG.width - FlxG.width / 3)
		{
			logo.scale.x -= .05;
			logo.scale.y -= .05;
			logo.updateHitbox();
		}
		text = new Text(0, 0, logo.width, '', 64);
		text.alignment = CENTER;
		text.screenCenter(X);
		add(text);
		logo.screenCenter();
		daParent = logo;

		var haxeLogo = new FlxSprite().loadGraphic(Paths.image('logo'));
		add(haxeLogo);
		haxeLogo.scale.set(3, 3);
		haxeLogo.updateHitbox();
		haxeLogo.visible = false;
		haxeLogo.y = FlxG.height + 10;

		FlxTween.tween(logo, {y: FlxG.height + logo.height}, 1, {
			startDelay: (16.69 / 2) - 1,
			ease: FlxEase.backInOut,
			onComplete: twn ->
			{
				daParent = haxeLogo;
				haxeLogo.visible = true;
				haxeLogo.screenCenter(X);

				text.text = 'Made with HaxeFlixel';
			}
		});
		FlxTween.tween(haxeLogo, {y: FlxG.height / 2 - haxeLogo.height / 2}, 1, {startDelay: (16.26 / 2), ease: FlxEase.backInOut});
		FlxTween.tween(haxeLogo, {y: FlxG.height + haxeLogo.height}, 1, {startDelay: 15.65 - 1, ease: FlxEase.backInOut});

		FlxG.camera.fade(FlxColor.BLACK, .5, true);

		daTime = new FlxTimer().start(16.20, tmr -> doSwitch());
	}

	var daTime:FlxTimer;

	var tick:Float = 0;
	var switching:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (daParent != null)
			text.y = daParent.y - text.height - 20;

		if (controls.ACCEPT && !switching)
			doSwitch();
	}

	function doSwitch()
	{
		FlxG.camera.stopFX();
		switching = true;

		if (daTime != null)
			if (daTime.active)
				daTime.cancel();

		MainMenu.bgPoint = new FlxPoint(bg.x, bg.y);
		FlxG.switchState(new MainMenu());
		Sound.menuMusic.play(true, 16.69 * 1000);
	}
}
