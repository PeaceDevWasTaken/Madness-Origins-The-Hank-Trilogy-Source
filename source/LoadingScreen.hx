package;

import Song.SwagSong;
#if sys
import sys.FileSystem;
#end
import flixel.system.FlxAssets;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.ui.FlxBar;
import flixel.FlxSprite;

using StringTools;

class LoadingScreen extends MusicBeatState
{
	var coolBar:FlxBar;
	var loading:FlxText;
	var ticks:Float = 0;

	var load:Array<String> = [];
	var totalLoad:Int = 0;
	var loaded:Int = 0;

	var players:Array<String> = []; // characters we need to load
	var songName:String; // so we can load inst/vocal
	var charSelect:Bool; // whether we are loading into character select

	var coolFolder:String;

	final lock = new sys.thread.Lock();

	override public function new(?song:SwagSong, ?charSelect:Bool)
	{
		super();
		if (song != null)
		{
			players[0] = song.player1;
			players[1] = song.player2;
			songName = song.song.toLowerCase().replace(' ', '-');

			switch (songName)
			{
				case 'origins' | 'uprising':
					coolFolder = 'assets/shared/images/bruhbg/';
			}
		}
		else if (charSelect != null)
			this.charSelect = charSelect;
	}

	override public function create()
	{
		super.create();

		#if !target.threaded // What are you doing
		if (charSelect)
			FlxG.switchState(new CharacterSelect());
		else
			FlxG.switchState(new PlayState());
		#else
		FlxAssets.FONT_DEFAULT = 'impact.ttf';

		coolBar = new FlxBar(40, FlxG.height - 100, LEFT_TO_RIGHT, FlxG.width - 80, 60);
		coolBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		add(coolBar);

		var bfRun = new FlxSprite();
		bfRun.frames = Paths.getSparrowAtlas('loading/BofendLoading');
		bfRun.animation.addByPrefix('run', 'lil guy', 18);
		bfRun.animation.play('run');
		add(bfRun);
		bfRun.setPosition(60, coolBar.y - bfRun.height - 10);

		loading = new FlxText(0, 0, 0, 'LOADING', 64);
		loading.setPosition(bfRun.x + bfRun.width + 30, coolBar.y - loading.height - 10);
		add(loading);

		var weekFolder:String = Paths.currentLevel;
		var pathShit:String = 'assets/${weekFolder != null ? '$weekFolder/' : ''}images/';

		var foldersToLoad:Array<String> = [];

		if (charSelect)
			foldersToLoad = ['assets/images/BFchar/', 'assets/images/charmenu/'];
		else
			foldersToLoad = [pathShit];

		sys.thread.Thread.create(() -> update(1 / ClientPrefs.framerate));

		sys.thread.Thread.create(() ->
		{
			trace('Asset grab thread started');
			for (folder in foldersToLoad)
				for (file in FileSystem.readDirectory(FileSystem.absolutePath(folder)))
				{
					if (!file.endsWith(".png") && !file.endsWith('.mp3') && !file.endsWith('.ogg')) // Allow images and sounds to be loaded
						continue;

					file = file.replace(' ', '_');
					@:privateAccess // I can access that private field cache baby
					if (!load.contains(folder + file) && !FlxG.bitmap._cache.exists(folder + file))
						load.push(folder + file);
				}
			if (players[0] != null)
			{
				load.push(Paths.getPath('images/${cast haxe.Json.parse(lime.utils.Assets.getText(Paths.getPreloadPath('characters/${players[0]}.json'))).image}.png',
					IMAGE));
				load.push(Paths.getPath('images/${cast haxe.Json.parse(lime.utils.Assets.getText(Paths.getPreloadPath('characters/${players[1]}.json'))).image}.png',
					IMAGE));
				load.push(Paths.getPath('images/icons/icon-${cast haxe.Json.parse(lime.utils.Assets.getText(Paths.getPreloadPath('characters/${players[0]}.json'))).healthicon}.png',
					IMAGE));
				load.push(Paths.getPath('images/icons/icon-${cast haxe.Json.parse(lime.utils.Assets.getText(Paths.getPreloadPath('characters/${players[1]}.json'))).healthicon}.png',
					IMAGE));
			}

			if (songName != null)
			{
				load.push('assets/songs/$songName/Inst');
				load.push('assets/songs/$songName/Voices');
			}

			totalLoad = load.length;
			lock.release();
		});

		sys.thread.Thread.create(() ->
		{
			lock.wait();
			trace('Asset loading thread started');

			for (item in load)
			{
				if (weekFolder != null && item.contains(weekFolder) && !item.contains('$weekFolder:')) // just to make sure this was found in the library and not something ripped from preload
					item = '${weekFolder != null ? '$weekFolder:' : ''}$item';
				if (item.endsWith('.png'))
					FlxG.bitmap.add(item, false, item);
				else
					FlxG.sound.cache(item);
				loaded++;

				coolBar.value = (loaded / totalLoad) * 100;

				if (coolBar.value >= 100)
					if (charSelect)
						FlxG.switchState(new CharacterSelect());
					else
						FlxG.switchState(new PlayState());
			}
		});
		#end
	}

	var numPeriodsLol:Int = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if ((ticks += elapsed) > .5)
		{
			ticks = 0;
			numPeriodsLol++;
			if (numPeriodsLol % 4 == 0)
				loading.text = 'LOADING';
			else
				loading.text += '.';
		}
	}
}
