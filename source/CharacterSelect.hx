package;

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
	var characterList:Array<String> = ['bf', 'bf-christmas', 'bf-pixel', 'meh', 'tricky', 'tricky-ex'];
	var characterName:Array<String> = [
		'Classic Boyfriend',
		'Christmas Boyfriend',
		'Pixel Boyfriend',
		'Mr. Meh',
		'Tricky',
		'Expurgation Tricky'
	];
	var characterCost:Array<Int> = [0, 100, 250, 500, 1000, 1500];
	var unlocked:Array<Bool> = [];

	var characters:FlxTypedGroup<FlxSprite>;

	var curSel:Int = 0;

	var coins:Int = 0;

	var name:FlxText;
	var cost:FlxText;

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

		bg = new FlxSprite().loadGraphic(Paths.image('charmenu/bars'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.screenCenter();
		add(bg);

		bg = new FlxSprite().loadGraphic(Paths.image('charmenu/glow'));
		bg.setGraphicSize(0, FlxG.height);
		bg.screenCenter();
		add(bg);

		unlocked = [
			for (i in 0...characterList.length)
				i == 0 ? true : false
		];

		characters = new FlxTypedGroup();

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
			ch.updateHitbox();

			ch.antialiasing = ClientPrefs.globalAntialiasing;

			if (character.endsWith('pixel'))
			{
				ch.antialiasing = false;
				ch.scale.set(6, 6);
				ch.updateHitbox();
			}

			ch.screenCenter();

			if (character == 'meh')
				ch.flipX = true;

			characters.add(ch);

			if (character != characterList[curSel])
				ch.visible = false;

			if (!unlocked[characterList.indexOf(character)])
				ch.color = FlxColor.BLACK;
		}

		add(characters);

		checkUnlocked();

		name = new FlxText(0, 0, FlxG.width, 'Placeholder', 48);
		cost = new FlxText(0, 0, FlxG.width, 'Placeholder', 32);
		add(name);
		add(cost);

		name.alignment = cost.alignment = CENTER;
		name.setFormat(Paths.font('impact.ttf'), 48, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		cost.setFormat(Paths.font('impact.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);

		cost.y = FlxG.height - cost.height - 10;
		name.y = cost.y - name.height - 5;

		updateTexts();
	}

	function updateTexts()
	{
		name.text = characterName[curSel];
		cost.text = unlocked[curSel] ? '' : 'Cost: ${characterCost[curSel]} Coins';
	}

	function checkUnlocked()
	{
		if (FlxG.save.data.bfsUnlocked == null)
			storeUnlocked();

		unlocked = FlxG.save.data.bfsUnlocked;
		coins = FlxG.save.data.coins;
	}

	function storeUnlocked()
	{
		FlxG.save.data.bfsUnlocked = unlocked;
		FlxG.save.data.coins = coins;
		FlxG.save.flush();
	}

	function changeSelection(amt:Int)
	{
		var char1 = characters.members[curSel];

		curSel += amt;

		if (curSel > characters.members.length - 1)
			curSel = 0;
		else if (curSel < 0)
			curSel = characters.members.length - 1;

		var char2 = characters.members[curSel];

		FlxTween.cancelTweensOf(char1);
		FlxTween.cancelTweensOf(char2);

		char2.visible = true;

		char1.screenCenter();
		char2.setPosition(amt > 0 ? FlxG.width : 0 - char2.width, FlxG.height + 50);

		FlxTween.tween(char1, {x: amt > 0 ? 0 - char1.width : FlxG.width, y: FlxG.height + 50}, .25, {
			ease: FlxEase.smootherStepIn,
			onComplete: function(twn:FlxTween)
			{
				char1.visible = false;
			}
		});

		FlxTween.tween(char2, {x: FlxG.width / 2 - char2.width / 2, y: FlxG.height / 2 - char2.height / 2}, .25, {
			ease: FlxEase.smootherStepOut,
		});

		updateTexts();
	}

	function select()
	{
		awaitingConfirm = false;
		selected = true;

		FlxG.save.data.curCharacter = characterList[curSel];
		characters.members[curSel].animation.play('up');
		updateTexts();

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			ss();
		});
	}

	function startBuy()
	{
		awaitingConfirm = true;
	}

	function completeBuy()
	{
		coins -= characterCost[curSel];
		unlocked[curSel] = true;

		storeUnlocked();
		select();
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
			ss();

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
	}

	function ss()
	{
		forEach(function(lol:FlxBasic)
		{
			lol.destroy();
			lol = null;
		});
		#if cpp
		cpp.NativeGc.run(true);
		#end

		FlxG.switchState(new MainMenuState());
	}
}
