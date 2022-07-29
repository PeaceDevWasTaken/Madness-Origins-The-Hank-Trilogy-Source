package sanford;

import flixel.FlxG;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.math.FlxPoint;
import flixel.math.FlxVelocity;
import sanford.Player.Weapon;

class Bullet extends FlxSprite
{
	public var speed:Int = 200;

	public var shoota:FlxObject;
	public var type:Weapon;

	/**More of an inaccuracy. this is used to randomize the firing angle for the enemies.**/
	public var accuracy:Int = 0;

	override public function new(parent:FlxObject, angle:Null<Float>, bulletType:Weapon = SHOTGUN, ?target:FlxSprite)
	{
		super(parent.x + parent.width / 2, parent.y + parent.height / 2);

		var gunSuffix:String = '';
		switch (bulletType)
		{
			case SHOTGUN:
				gunSuffix = '-SG';
				accuracy = 10;
			case AK:
				gunSuffix = '-AR';
				accuracy = 15;
			case ROCKET:
				gunSuffix = '-RL';
				accuracy = 20;

			default:
				trace('This might not be a gun, lol');
		}
		loadGraphic(Paths.image('bullet$gunSuffix'));

		x -= width / 2;
		y -= height / 2;

		shoota = parent;
		type = bulletType;

		if (Std.isOfType(parent, Enemy))
			speed = 100;

		var passedAngle:Float = 0;
		if (angle != null) // in order to randomize spread (shotgun)
			passedAngle = angle;

		if (target != null)
		{
			trace('tryna lerp dat shit.');
			var adjustedX = target.x - x;
			var adjustedY = target.y - y;
			var rCrossV = (adjustedX * target.velocity.y) - (adjustedY * target.velocity.x);
			var magR = Math.sqrt((adjustedX * adjustedX) + (adjustedY * adjustedY));
			var angleAdjust = FlxAngle.asDegrees(Math.asin(rCrossV / (speed * magR)));

			angle = angleAdjust + FlxAngle.angleBetween(this, target, true);
			if (passedAngle != 0)
				angle += passedAngle;

			var dist = FlxMath.distanceBetween(this, target);
			var pointThing = FlxVelocity.velocityFromAngle(angle, 1); // Should just be a ratio.
			var point = new FlxPoint(dist * pointThing.x, dist * pointThing.y);

			if (SAState.instance.tilemap.ray(getPosition(), point)) // If we can detect a wall in the way of where the player is going just shoot at the player
				angle = FlxAngle.angleBetween(this, target, true);

			angle += FlxG.random.int(-accuracy, accuracy);
		}

		if (gunSuffix == '-RL')
			this.angle = angle;

		var vel:FlxPoint = FlxVelocity.velocityFromAngle(angle, speed);
		velocity.set(vel.x, vel.y);

		blend = ADD;
	}

	var ticks:Float = 0;

	public var awaitingParticle:Bool = false;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!awaitingParticle)
			if ((ticks += elapsed) >= .075)
			{
				awaitingParticle = true;
				ticks = 0;
			}
	}
}
