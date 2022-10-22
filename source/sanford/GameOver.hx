package sanford;

import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxStringUtil;
import sanford.SAState.RunData;
import Discord.DiscordClient;
import Controls;

class GameOver extends DefaultSubstate
{
	var runData:RunData;

	var menuOptions:Array<String> = ['Play Again', 'Exit to Menu'];
	var items:FlxTypedGroup<Text>;
	var coolThing:FlxSprite;
	var curSel:Int = 0;

	override public function new(runData:RunData)
	{
		super();
		canEsc = false;
		this.runData = runData;

		// #if cpp
		// DiscordClient.changePresence('Died on Floor ${runData.floor}.',
		// 	'Killed ${runData.kills} ${runData.kills != 1 ? 'enemies' : 'enemy'}, and survived for ${FlxStringUtil.formatTime(runData.timeAlive / 1000)}.',
		// 	null, null, null, null, false, true);
		// #end

		var youDied = new Text(0, 0, 0, 'Game Over', 96);
		youDied.setPosition(FlxG.width / 2 - youDied.width / 2, 30);

		var game = new Text(youDied.x, youDied.y, 0, 'Game', 96);
		var over = new Text(youDied.x + youDied.width, youDied.y, 0, 'Over', 96);
		over.x -= over.width;

		add(game);
		add(over);

		game.scale.set(2, 2);
		over.scale.set(2, 2);
		game.alpha = 0;
		over.alpha = 0;

		FlxTween.tween(game, {'alpha': 1, 'scale.x': 1, "scale.y": 1}, .25, {
			ease: FlxEase.smootherStepIn,
			onComplete: twn ->
			{
				subCam.shake(0.005, .25);
				Sound.play('diesplat1');
			},
			startDelay: .5
		});

		FlxTween.tween(over, {'alpha': 1, 'scale.x': 1, "scale.y": 1}, .25, {
			ease: FlxEase.smootherStepIn,
			onComplete: twn ->
			{
				subCam.shake(0.005, .25);
				Sound.play('diesplat1');
			},
			startDelay: 1.5
		});

		var alphaDelay:Float = 2.25;
		if (runData.deathCause != null)
		{
			var codText:String = 'You died to ${runData.deathCause}.';

			var cause:FlxText = new FlxText(0, 0, 0, codText, 28);
			cause.setBorderStyle(SHADOW, FlxColor.BLACK, 3, 1);
			cause.screenCenter(X);

			cause.y = 0 - cause.height - 100;
			FlxTween.tween(cause, {y: 30 + youDied.height + 5}, 1, {ease: FlxEase.smootherStepOut, startDelay: alphaDelay});
			add(cause);
			alphaDelay += 1.5;
		}
		var floorTxt = new Text(0, 0, FlxG.width, 'You made it to floor ${runData.floor}.', 48);
		floorTxt.alignment = CENTER;
		floorTxt.y = youDied.y + youDied.height + 100;
		add(floorTxt);
		lifetimeText = new Text(0, 0, FlxG.width, 'You survived for 0:0.', 48);
		lifetimeText.alignment = CENTER;
		lifetimeText.y = floorTxt.y + floorTxt.height + 40;
		add(lifetimeText);

		killsText = new Text(0, 0, FlxG.width, 'You killed 0 enemies.', 48);
		killsText.alignment = CENTER;
		killsText.y = lifetimeText.y + lifetimeText.height + 40;
		add(killsText);

		floorTxt.alpha = lifetimeText.alpha = killsText.alpha = 0;
		FlxTween.tween(floorTxt, {'alpha': 1}, .5, {ease: FlxEase.smootherStepInOut, startDelay: alphaDelay});
		FlxTween.tween(lifetimeText, {'alpha': 1}, .5, {ease: FlxEase.smootherStepInOut, startDelay: alphaDelay});
		FlxTween.tween(killsText, {'alpha': 1}, .5, {ease: FlxEase.smootherStepInOut, startDelay: alphaDelay});

		items = new FlxTypedGroup();

		for (i in 0...menuOptions.length)
		{
			var newText:Text = new Text(0, 0, FlxG.width, menuOptions[i], 32);
			newText.y = killsText.y + killsText.height + 50 + (60 * i);
			newText.alignment = CENTER;
			newText.ID = i;
			items.add(newText);
		}
		coolThing = new FlxSprite().makeGraphic(FlxG.width, Math.ceil(items.members[0].height + 5), FlxColor.BLACK);
		add(coolThing);
		coolThing.alpha = 0.6;
		add(items);
		for (i in 0...items.length)
		{
			var spr = items.members[i];
			if (spr == null)
				return;
			spr.y += FlxG.height;
			FlxTween.tween(spr, {y: spr.y - FlxG.height}, .5, {startDelay: alphaDelay + .6 + (.05 * i), ease: FlxEase.smootherStepInOut});
		}
		coolThing.y = items.members[curSel].y + items.members[curSel].height / 2 - coolThing.height / 2;

		subCam.fade(FlxColor.TRANSPARENT, .25, true);
	}

	var selected:Bool = false;

	function retSel(sel:Int):Int
		return if (sel >= items.length) retSel(sel - items.length) else if (sel < 0) retSel(items.length + sel) else sel;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
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

		if (killsText.alpha >= .25)
		{
			lerpLifetime = FlxMath.lerp(lerpLifetime, runData.timeAlive, 0.1);
			lerpKills = Math.ceil(FlxMath.lerp(lerpKills, runData.kills, .1));

			lifetimeText.text = 'You survived for ${FlxStringUtil.formatTime(lerpLifetime / 1000)}.';
			killsText.text = 'You killed $lerpKills ${lerpKills == 1 ? 'enemy' : 'enemies'}.';
		}
	}

	function change(by:Int = 0)
	{
		curSel = retSel(curSel + by);
		Sound.play('menuChange');
	}

	function select(selection:String)
	{
		selected = true;
		Sound.play('menuSelect');
		switch (selection)
		{
			case 'Play Again':
				SAState.resetData();
				FlxG.switchState(new SAState());

			case 'Exit to Menu':
				flixel.graphics.FlxGraphic.defaultPersist = false;
				StageData.forceNextDirectory = 'preload';
				FlxG.switchState(new MainMenuState());

			default:
				trace('unhandled $selection');
				selected = false;
		}
	}

	var lerpLifetime:Float = 0;
	var lifetimeText:Text;
	var killsText:Text;
	var lerpKills:Int = 0;
}
