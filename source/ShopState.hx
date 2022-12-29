package;

import flixel.FlxG;
import flixel.FlxSprite;

class ShopState extends MusicBeatState
{
    override function create()
    {
        var bg:FlxSprite = new FlxSprite();
        bg.frames = Paths.getSparrowAtlas('shop/shop_background');
        bg.animation.addByPrefix('idle', 'background', 24);
        bg.animation.play('idle');
        bg.setGraphicSize(FlxG.width);
        bg.updateHitbox();
        bg.antialiasing = ClientPrefs.globalAntialiasing;
        add(bg);

        var clown:FlxSprite = new FlxSprite();
        clown.frames = Paths.getSparrowAtlas('shop/shop_tricky');
        clown.animation.addByPrefix('idle', 'trickerhimself', 24);
        clown.animation.play('idle');
        clown.setGraphicSize(FlxG.width);
        clown.updateHitbox();
        clown.antialiasing = ClientPrefs.globalAntialiasing;
        add(clown);

        var foreground:FlxSprite = new FlxSprite().loadGraphic(Paths.image('shop/shop_foreground'));
        foreground.setGraphicSize(FlxG.width);
        foreground.updateHitbox();
        foreground.antialiasing = ClientPrefs.globalAntialiasing;
        add(foreground);

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (controls.BACK)
            MusicBeatState.switchState(new MainMenuState());

        super.update(elapsed);
    }
}