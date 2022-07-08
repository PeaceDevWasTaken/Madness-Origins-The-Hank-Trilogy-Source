package;

import flixel.math.FlxMath;
import flixel.effects.particles.FlxEmitter;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.FlxBasic;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.util.FlxColor;

using StringTools;

class CharacterSelect extends MusicBeatState
{
	public static var characterList:Array<String> = [
		'bf',
		'bf-christmas',
		'bf-pixel',
		'meh',
		'twitter',
		'nerve',
		'tricky',
		'tricky-ex'
	];

	var characterName:Array<String> = [
		'Classic Boyfriend',
		'Christmas Boyfriend',
		'Pixel Boyfriend',
		'Mr. Meh',
		'Average Twitter User',
		'Exposed Nerve',
		'Tricky',
		'Expurgation Tricky'
	];

	public static var initScale:Array<Float> = [1, 1, 7.3, 1, 1, .65, 1.15, 1.15];

	var characterCost:Array<Int> = [0, 100, 250, 500, 750, 750, 1000, 1500];
	var unlocked:Array<Bool> = [];

	var characters:FlxTypedGroup<FlxSprite>;

	var curSel:Int = 0;

	var coins:Int = 0;
	var lerpCoin:Int = 0;
	var coinText:FlxText;

	var name:FlxText;
	var cost:FlxText;
	var confirmText:FlxText;

	override public function create()
	{
		super.create();

		if (FlxG.save.data.coins == null)
		{
			FlxG.save.data.coins = 0;
			FlxG.save.flush();
		}

		coins = FlxG.save.data.coins;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('charmenu/bg'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.screenCenter();
		add(bg);

		characters = new FlxTypedGroup();
		add(characters);

		bg = new FlxSprite().loadGraphic(Paths.image('charmenu/bars'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.screenCenter();
		add(bg);

		name = new FlxText(0, 0, FlxG.width, 'Placeholder', 48);
		cost = new FlxText(0, 0, FlxG.width, 'Placeholder', 32);
		add(name);
		add(cost);

		name.alignment = cost.alignment = CENTER;
		name.setFormat(Paths.font('impact.ttf'), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		cost.setFormat(Paths.font('impact.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

		cost.y = FlxG.height - cost.height - 10;
		name.y = cost.y - name.height - 5;

		bg = new FlxSprite().loadGraphic(Paths.image('charmenu/glow'));
		bg.setGraphicSize(0, FlxG.height);
		bg.screenCenter();
		add(bg);

		unlocked = [
			for (i in 0...characterList.length)
				i == 0 ? true : false
		];

		if (FlxG.save.data.curCharacter == null)
		{
			FlxG.save.data.curCharacter = 'bf';
			FlxG.save.flush();
		}
		curSel = characterList.indexOf(FlxG.save.data.curCharacter);

		for (character in characterList)
		{
			var ch:FlxSprite = new FlxSprite();
			ch.frames = Paths.getSparrowAtlas('BFchar/$character', 'preload');
			ch.animation.addByPrefix('idle', 'idle', 24, true);
			ch.animation.addByPrefix('up', 'up', 24, false);
			ch.animation.play('idle');

			ch.antialiasing = ClientPrefs.globalAntialiasing;

			if (character.endsWith('pixel'))
				ch.antialiasing = false;

			ch.scale.set(initScale[characterList.indexOf('character')], initScale[characterList.indexOf('character')]);
			ch.updateHitbox();
			ch.screenCenter();

			if (character == 'meh')
				ch.flipX = true;

			characters.add(ch);

			if (!unlocked[characterList.indexOf(character)])
				ch.color = FlxColor.BLACK;
		}

		checkUnlocked();

		updateTexts();

		changeSelection(0);

		var coinSpr:FlxSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('coin'));
		add(coinSpr);
		coinSpr.scale.set(0.25, 0.25);
		coinSpr.updateHitbox();
		coinSpr.setPosition(FlxG.width - 25 - coinSpr.width, 25);

		coinText = new FlxText(0, 0, coinSpr.x - 10, 'Placeholder', 32);
		coinText.setFormat(Paths.font('impact.ttf'), 32, FlxColor.WHITE, RIGHT, OUTLINE, FlxColor.BLACK);
		coinText.y = coinSpr.y + coinSpr.height / 2 - coinText.height / 2;
		add(coinText);

		confirmText = new FlxText(0, 0, FlxG.width - FlxG.width / 3,
			'Press ${ClientPrefs.keyBinds['accept'][0]} or ${ClientPrefs.keyBinds['accept'][1]} to confirm purchase.');
		add(confirmText);

		confirmText.alignment = CENTER;
		confirmText.setFormat(Paths.font('impact.ttf'), 64, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		confirmText.screenCenter();
		confirmText.visible = false;
	}

	function updateTexts()
	{
		name.text = unlocked[curSel] ? characterName[curSel] : '???';
		cost.text = unlocked[curSel] ? '' : 'Cost: ${characterCost[curSel]} Coins';
	}

	function checkUnlocked()
	{
		if (FlxG.save.data.bfsUnlocked == null)
			storeUnlocked();

		unlocked = FlxG.save.data.bfsUnlocked;
		coins = FlxG.save.data.coins; #if FLX_DEBUG coins = FlxG.random.int(999, 99999); #end
	}

	function storeUnlocked()
	{
		FlxG.save.data.bfsUnlocked = unlocked;
		FlxG.save.data.coins = coins;
		FlxG.save.flush();
	}

	function retLoopSel(sel:Int):Int
		return if (sel >= characters.members.length) retLoopSel(sel - characters.members.length) else if (sel < 0) retLoopSel(characters.members.length +
			sel) else sel;

	function changeSelection(amt:Int)
	{
		curSel = retLoopSel(curSel + amt);

		var leftChar = characters.members[retLoopSel(curSel - 1)];
		var newChar = characters.members[curSel];
		var rightChar = characters.members[retLoopSel(curSel + 1)];
		var outGoing = characters.members[retLoopSel(curSel + (amt < 0 ? 2 : -2))];

		characters.forEach(function(chr:FlxSprite)
		{
			chr.setPosition(FlxG.width, FlxG.height);
			FlxTween.cancelTweensOf(chr);
		});

		var leftTweenPos:FlxPoint = new FlxPoint((FlxG.width / 6) - (leftChar.width / 2), ((FlxG.height / 2) - (leftChar.height / 2)) + 50);
		var rightTweenPos:FlxPoint = new FlxPoint(((FlxG.width) - (FlxG.width / 6)) - (rightChar.width / 2),
			((FlxG.height / 2) - (rightChar.height / 2)) + 50);
		var midPos:FlxPoint = new FlxPoint(FlxG.width / 2 - newChar.width / 2, FlxG.height / 2 - newChar.height / 2);
		var offscreenPos:FlxPoint = new FlxPoint(amt < 0 ? FlxG.width : 0 - outGoing.width, FlxG.height);

		newChar.setPosition(amt > 0 ? ((FlxG.width) - (FlxG.width / 6)) - (newChar.width / 2) : (FlxG.width / 6) - (newChar.width / 2),
			amt > 0 ? ((FlxG.height / 2) - (newChar.height / 2)) + 50 : ((FlxG.height / 2) - (newChar.height / 2)) + 50);
		rightChar.setPosition(amt < 0 ? FlxG.width / 2 - rightChar.width / 2 : FlxG.width, amt < 0 ? FlxG.height / 2 - rightChar.height / 2 : FlxG.height);
		leftChar.setPosition(amt > 0 ? FlxG.width / 2 - leftChar.width / 2 : 0 - leftChar.width,
			amt > 0 ? FlxG.height / 2 - leftChar.height / 2 : FlxG.height);
		outGoing.setPosition(amt < 0 ? ((FlxG.width) - (FlxG.width / 6)) - (outGoing.width / 2) : (FlxG.width / 6) - (outGoing.width / 2),
			((FlxG.height / 2) - (outGoing.height / 2)) + 50);

		FlxTween.tween(newChar, {
			x: midPos.x,
			y: midPos.y,
			"scale.x": initScale[retLoopSel(curSel)] * 1,
			"scale.y": initScale[retLoopSel(curSel)] * 1
		}, .25, {ease: FlxEase.smootherStepInOut});
		FlxTween.tween(leftChar, {
			x: leftTweenPos.x,
			y: leftTweenPos.y,
			"scale.x": initScale[retLoopSel(curSel - 1)] * 0.6,
			"scale.y": initScale[retLoopSel(curSel - 1)] * 0.6
		}, .25, {ease: FlxEase.smootherStepInOut});
		FlxTween.tween(rightChar, {
			x: rightTweenPos.x,
			y: rightTweenPos.y,
			"scale.x": initScale[retLoopSel(curSel + 1)] * 0.6,
			"scale.y": initScale[retLoopSel(curSel + 1)] * 0.6
		}, .25, {ease: FlxEase.smootherStepInOut});
		FlxTween.tween(outGoing, {
			x: offscreenPos.x,
			y: offscreenPos.y,
			"scale.x": initScale[retLoopSel(curSel + (amt < 0 ? 2 : -2))] * 0.3,
			"scale.y": initScale[retLoopSel(curSel + (amt < 0 ? 2 : -2))] * 0.3
		}, .25, {ease: FlxEase.smootherStepInOut});

		if (unlocked[retLoopSel(curSel)])
			FlxTween.color(newChar, 0.25, newChar.color, FlxColor.WHITE, {ease: FlxEase.smootherStepInOut});
		if (unlocked[retLoopSel(curSel - 1)])
			FlxTween.color(leftChar, 0.25, leftChar.color, FlxColor.fromString('0xFF171717'), {ease: FlxEase.smootherStepInOut});
		if (unlocked[retLoopSel(curSel + 1)])
			FlxTween.color(rightChar, 0.25, rightChar.color, FlxColor.fromString('0xFF171717'), {ease: FlxEase.smootherStepInOut});
		FlxTween.color(outGoing, 0.25, outGoing.color, FlxColor.BLACK, {ease: FlxEase.smootherStepInOut});

		updateTexts();
	}

	function select(buy:Bool = false)
	{
		awaitingConfirm = false;
		selected = true;

		FlxG.save.data.curCharacter = characterList[curSel];
		characters.members[curSel].animation.play('up');
		updateTexts();

		new FlxTimer().start((buy ? 3 : 1), function(tmr:FlxTimer)
		{
			ss();
		});
	}

	function startBuy()
	{
		awaitingConfirm = true;
		confirmText.visible = true;
	}

	function completeBuy()
	{
		confirmText.visible = false;

		coins -= characterCost[curSel];
		unlocked[curSel] = true;
		storeUnlocked();

		var char = characters.members[curSel];
		FlxTween.color(char, .15, FlxColor.BLACK, FlxColor.WHITE, {
			ease: FlxEase.smootherStepIn,
			onComplete: function(twn:FlxTween)
			{
				select(true);

				var emitter:FlxEmitter = new FlxEmitter(FlxG.width / 2, FlxG.height / 2);
				add(emitter);
				emitter.loadParticles(Paths.image('coin'), 100, 0);
				emitter.scale.set(0.25, 0.25, 0.25, 0.25);
				emitter.angularVelocity.set(-150, 150);
				emitter.speed.set(100, 250);
				emitter.acceleration.set(0, 250, 0, 500);
				emitter.start(true);
			}
		});
	}

	function locked()
	{
		var urBroke:FlxText = new FlxText(0, 0, 0, 'Insufficient Coins.', 32);
		urBroke.setFormat(Paths.font('impact.ttf'), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		urBroke.screenCenter(X);
		urBroke.y = FlxG.height / 6;

		add(urBroke);

		new flixel.util.FlxTimer().start(2, function(timer:flixel.util.FlxTimer)
		{
			urBroke.destroy();
		});

		var spr:FlxSprite = characters.members[curSel];

		FlxTween.tween(spr, {x: FlxG.width / 2 - spr.width / 2 + 25}, 0.1, {
			ease: FlxEase.circIn,
			onComplete: function tween2(twn:FlxTween)
			{
				FlxTween.tween(spr, {x: FlxG.width / 2 - spr.width / 2 - 50}, 0.15, {
					ease: FlxEase.smootherStepInOut,
					onComplete: function tween3(twn:FlxTween)
					{
						FlxTween.tween(spr, {x: FlxG.width / 2 - spr.width / 2}, 0.1, {ease: FlxEase.circOut});
					}
				});
			}
		});
	}

	var awaitingConfirm:Bool = false;
	var selected:Bool = false;

	override public function update(elasped:Float)
	{
		super.update(elasped);

		if (controls.BACK)
			if (!awaitingConfirm)
				ss();
			else
			{
				awaitingConfirm = false;
				confirmText.visible = false;
			}

		if (!selected)
		{
			if (controls.UI_RIGHT_P)
				changeSelection(1);

			if (controls.UI_LEFT_P)
				changeSelection(-1);

			if (controls.ACCEPT)
				if (unlocked[curSel])
					select();
				else if (coins >= characterCost[curSel] && !awaitingConfirm)
					startBuy();
				else if (awaitingConfirm)
					completeBuy();
				else
					locked();
		}

		lerpCoin = Math.ceil(FlxMath.lerp(lerpCoin, coins, 0.25));
		coinText.text = '$lerpCoin';

		#if FLX_DEBUG
		if (FlxG.keys.justPressed.FOUR)
		{
			for (i in 0...unlocked.length)
				unlocked[i] = false;

			storeUnlocked();
		}
		#end
	}

	function ss()
	{
		forEach(function(lol:FlxBasic)
		{
			lol.destroy();
			lol = null;
		});

		Paths.clearUnusedMemory();
		Paths.clearStoredMemory();

		openfl.system.System.gc();

		LoadingState.loadAndSwitchState(new MainMenuState());
	}
}
