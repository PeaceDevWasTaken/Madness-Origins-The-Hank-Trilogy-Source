package sanford;

import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class RandomSubstate extends DefaultSubstate
{
	var floor:Int;

	var dice:FlxTypedGroup<Dice>;

	var ticks:Float = 0;

	public var rollers:Array<String> = ['Bonus Hearts', 'Extra Damage', 'Fire Rate Mult.', 'Speed Bonus', 'Grace Period'];

	var nextUnlock:Int = 0;
	var unlockFloors:Array<Int> = [5, 15, 20]; // unlock SG at 5, etc

	override public function new(floor:Int, enemies:Int)
	{
		super();
		if (FlxG.save.data.unlockedWeapon != 3)
			nextUnlock = unlockFloors[FlxG.save.data.unlockedWeapon];

		this.floor = floor;

		if (nextUnlock == floor - 1) // just beat the required floor
		{
			FlxG.save.data.unlockedWeapon++;
			FlxG.save.flush();
		}

		FlxG.camera.fade(FlxColor.BLACK, .5, true);

		var title = new Text(0, 0, FlxG.width, 'Floor $floor', 96);
		title.alignment = CENTER;
		add(title);

		title.y = FlxG.height / 6 - title.height / 2;

		dice = new FlxTypedGroup();
		add(dice);
		var diceRolls:Int = Math.ceil(floor / 3);
		if (diceRolls > 6)
			diceRolls = 6;

		var slice:Int = Std.int(FlxG.width / (diceRolls + 1)); // should be segment of space per die
		var maxWidth:Int = Math.ceil(FlxG.width / 4);

		for (i in 0...diceRolls)
			dice.add(new Dice((slice * (i + 1)), title.y + title.height + 30, i, slice, maxWidth, enemies, this));

		canEsc = false;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!dice.members[dice.members.length - 1].rolling)
			if ((ticks += elapsed) >= 1 && !done)
				for (i in 0...dice.members.length)
				{
					done = true;
					FlxTween.tween(dice.members[i], {y: FlxG.height + 100}, 1, {
						ease: FlxEase.backInOut,
						startDelay: .15 * i,
						onComplete: twn ->
						{
							if (i == dice.members.length - 1)
								close();
						}
					});
				}
	}

	var done:Bool = false;
}

class Dice extends FlxTypedSpriteGroup<FlxSprite>
{
	public var die:FlxSprite;

	var numberTxt:Text;

	public var labelTxt:Text;

	public var rolling:Bool = true;

	override public function new(x:Float, y:Float, i:Int, slice:Int, maxWidth:Int, enemies:Int, daState:RandomSubstate)
	{
		super(x, y, 0);
		die = new FlxSprite().loadGraphic(Paths.image('diceSpin'), true, 64, 64);
		die.animation.add('sit', [0]);
		die.animation.add('spin', [for (i in 1...10) i], 8, false);
		die.animation.add('done', [10]);
		die.animation.play("sit");
		die.setGraphicSize(FlxG.width);
		die.updateHitbox();
		while (die.width > (maxWidth < slice ? slice - slice / 3 : maxWidth))
		{
			die.scale.x -= .05;
			die.scale.y -= .05;
			die.updateHitbox();
		}

		die.x -= die.width / 2;
		die.y += 100;

		add(die);
		switch (i)
		{
			case 0:
				roll('Enemies', die, i, enemies);

			default:
				var daRoll:String = daState.rollers[FlxG.random.int(0, daState.rollers.length - 1)];
				roll(daRoll, die, i, enemies);
				daState.rollers.remove(daRoll);
		}
	}

	function roll(label:String, die:FlxSprite, delay:Int, enemies:Int)
	{
		labelTxt = new Text(0, 0, die.width * .65, label, 48);
		labelTxt.alignment = CENTER;
		add(labelTxt);
		labelTxt.setPosition(die.x + die.width / 2 - labelTxt.width / 2, die.y - labelTxt.height + 10);

		new FlxTimer().start(1 + .25 * delay, tmr ->
		{
			die.animation.play('spin');
			Sound.play('diceRolling');
			die.animation.finishCallback = name ->
			{
				die.animation.play('done');
				numberTxt = new Text(0, 0, 0, delay != 0 ? '${FlxG.random.int(1, 3)}' : '$enemies', 96);
				add(numberTxt);

				numberTxt.setPosition(die.x + (31 * die.scale.x) - numberTxt.width / 2, die.y + (22 * die.scale.y) - numberTxt.height / 2);
				numberTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);

				switch (label)
				{
					case 'Bonus Hearts':
						SAState.resetStuff.health = SAState.resetStuff.health + Std.parseInt(numberTxt.text);

					case 'Extra Damage': SAState.resetStuff.damageBuff = Std.parseInt(numberTxt.text);

					case 'Movement Speed Bonus': SAState.resetStuff.speed = Std.parseInt(numberTxt.text);

					case 'Grace Period': SAState.resetStuff.iframes = Std.parseInt(numberTxt.text);

					case 'Fire Rate Mult.':
						SAState.resetStuff.fireRate = (Std.parseInt(numberTxt.text) + 1);
						numberTxt.text = '${Std.parseInt(numberTxt.text) + 1}';
				}

				rolling = false;
				SAState.ssCB = () -> SAState.instance.setHealth(SAState.resetStuff.health);
			};
		});
	}
}
