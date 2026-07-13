package;

import sys.thread.Thread;
import sys.thread.Mutex;
import sys.thread.FixedThreadPool;
import Song.SwagSong;
import lime.app.Promise;
import lime.app.Future;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxState;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flixel.tweens.FlxTween;

import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import sys.FileSystem;
import StageData;
import flixel.ui.FlxBar;
import haxe.io.Path;
using StringTools;
typedef ListMeta = {
	var name:String;
	var type:String;
}

typedef PrecacheMeta = {
	var target:FlxState;
	var stopMusic:Bool;
	@:optional var directory:String;
}
#if cpp
@:headerCode('
#include <iostream>
#include <thread>
')
#end
class LoadingState extends MusicBeatState
{
	var images:Array<Null<String>> = [];
	var characters:Array<Null<String>> = [];
	var sounds:Array<Null<String>> = [];
	var songs:Array<Null<{id:String, name:String}>> = [];
	var musics:Array<Null<String>> = [];
	var totals:Int = 0;
	var currentProgress:Int = 0;
	var currentPrecacheState:Int = 0;
	var stopPrecache:Bool = false;
	var progressBar:FlxSprite;
	var progressBarBase:FlxSprite;
	var progressText:FlxText;
	var originalBitmapKeys:Map<String, String> = [];
	var requestedBitmaps:Map<String, BitmapData> = [];

	var states:Array<String> = ['Images', 'Sounds', 'Musics', 'End'];
	var menuID = -1;
	static var lastPrecacheMeta:PrecacheMeta = null;
	var currentMeta:PrecacheMeta = null;
	var mutex:Mutex;
	var threadPool:FixedThreadPool = null;
	var target:FlxState;
	var stopMusic:Bool;
	var directory:String;
	function new(?meta:PrecacheMeta)
	{
		super();
		if (meta == null) meta = lastPrecacheMeta;
		currentMeta = meta;
		LoadingState.lastPrecacheMeta = currentMeta;

		this.target = meta.target;
		this.stopMusic = meta.stopMusic;
		this.directory = (meta.directory == null) ? '' : meta.directory;
		
		var cl = Type.getClass(meta.target);
		var stateName = getShortClassName(cl);
		if (stateName == 'HScriptedState'){
			var bro = cast cl;
			stateName = bro.scriptName;
		}
		if (Paths.exists(Paths.getPath('precache/states/' + stateName + '.json', TEXT))){
			var list = Paths.getJson(Paths.getPath('precache/states/' + stateName + '.json', TEXT));
			var precacheList:Array<ListMeta> = cast Reflect.field(list, 'precache');
			for (assets in precacheList){
				catchAssets(assets);
			}
		}
		if (stateName == 'PlayState' && PlayState.SONG != null){
			getSongAssets(PlayState.SONG);
			states.insert(1, 'Characters');
			states.insert(2, 'Songs');
		}


		
		trace('IMAGES: ' + images);
		trace('SOUNDS: ' + sounds);
		trace('MUSICS: ' + musics);
		trace('CHARACTERS: ' + characters);
		trace('SONGS: ' + songs);
		
		mutex = new Mutex();
		#if MULTITHREADED_LOADING
		// Due to the Main thread and Discord thread, we decrease it by 2.
		var threadCount:Int = Std.int(Math.max(1, getCPUThreadsCount() - #if DISCORD_ALLOWED 2 #else 1 #end));
		threadPool = new FixedThreadPool(threadCount);
		#end

		totals = images.length + sounds.length + musics.length + songs.length + characters.length;
		trace('IN TOTAL: ' + totals);
	}
	
	function getSongAssets(SONG:SwagSong){
		var songName:String = Paths.formatToSongPath(SONG.song);
		var stageData = StageData.getStageFile(SONG.stage);

		songs.push({id:songData.song, name:'Inst'});
		if (songData.needsVoices)
		songs.push({id:songData.song, name:'Voices'});
		if (songData.player1 != null && songData.player1.length >= 1)
		characters.push(songData.player1);
		if (songData.player2 != null && songData.player2.length >= 1)
		characters.push(songData.player2);
		if (songData.gfVersion != null && songData.gfVersion.length >= 1)
		characters.push(songData.gfVersion);


		if (Reflect.hasField(stageData, 'precache')){
			var precacheList:Array<ListMeta> = cast Reflect.field(stageData, 'precache');
			for (assets in precacheList){
				catchAssets(assets);
			}
			if (Reflect.hasField(stageData, 'menuID'))
				menuID = Reflect.field(stageData, 'menuID');
		}

		if (Paths.exists(Paths.getPath('precache/songs/' + songName.toLowerCase() + '.json', TEXT))){
			var list = Paths.getJson(Paths.getPath('precache/songs/' + songName.toLowerCase() + '.json', TEXT));
			var precacheList:Array<ListMeta> = cast Reflect.field(list, 'precache');
			for (assets in precacheList){
				catchAssets(assets);
			}
			if (Reflect.hasField(list, 'menuID'))
				menuID = Reflect.field(list, 'menuID');
		}


		if (Paths.exists(Paths.getPath('data/' + songName + '/events.json', TEXT))){
			var event = Paths.getJson(Paths.getPath('data/' + songName + '/events.json', TEXT));
			if (event.song.events != null){
			eventsPrecache(event.song.events);
			}
		}

		if (SONG.events != null){
			eventsPrecache(SONG.events);
		}
	}
	function eventsPrecache(events:Array<Dynamic>){
		for (event in events){
			for (i in 0...event[1].length)
				{
					switch(event[1][i][0]){
						case 'Change Character':
							if (!characters.contains(event[1][i][2]))
							characters.push(event[1][i][2]);
					}
				}
			}
	}

	function catchAssets(asset:ListMeta){
		switch (asset.type){
			case "Song":
				var songName:String = Paths.formatToSongPath(asset.name);
				var songData = Song.loadFromJson(Paths.formatToSongPath(songName).toLowerCase(), CoolUtil.getDifficultyFilePath(), Paths.formatToSongPath(songName).toLowerCase());
				getSongAssets(songData);
			case "Image":
				images.push(asset.name);
			case "Character":
				characters.push(asset.name);
			case "Sound":
				sounds.push(asset.name);
			case "Music":
				musics.push(asset.name);
			case "Folder":
			for (folder in Paths.getFolders(asset.name)){
				if (Paths.exists(folder) && Paths.isDirectory(folder)){
					for (file in FileSystem.readDirectory(folder)) {
						if (StringTools.startsWith(asset.name,'images/')){
							if (StringTools.endsWith(file,'.png')){
								var sily = asset.name.substr(7) + '/' + file.substr(0, file.length - 4);
								images.push(sily);
							}
						}else if (StringTools.startsWith(asset.name,'music/')){
							if (StringTools.endsWith(file,'.ogg')){
								var sily = asset.name.substr(6) + '/'  + file.substr(0, file.length - 4);
								musics.push(sily);
							}
						}else if (StringTools.startsWith(asset.name,'sounds/')){
							if (StringTools.endsWith(file,'.ogg')){
								var sily = asset.name.substr(7) + '/'  + file.substr(0, file.length - 4);
								sounds.push(sily);
								
							}
						}
					}
				}
			}
		}
	}
	function getShortClassName(cl):String{
		if (cl == null) return '';
		var tar = Type.getClassName(cl).split('.');
		if (tar == null || tar.length <= 0)
			return Type.getClassName(cl);
		return tar.pop();
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		if (totals <= 0){
			trace('NO ASSETS IN NEED TO BE PRECACHED');
			onLoad();
			return;
		}
		var cl = Type.getClass(currentMeta.target);
		var stateName = getShortClassName(cl);
		if (stateName == 'HScriptedState'){
			var bro = cast cl;
			stateName = bro.scriptName;
		}
		var menuIma = StartupState.menuImages.copy();
		if (menuIma.length > 0){
			if (stateName != 'PlayState'){
				for (image in StartupState.playStateExcludes){
					if (menuIma.contains(image))
					menuIma.remove(image);
				}
			}
			if (menuID < 0){
				menuID = FlxG.random.int(0, menuIma.length - 1);
			}
		}else{
			menuIma = ['funkay'];
			menuID = 0;
		}
		var funkay = new FlxSprite(0, 0).loadGraphic(Paths.image(menuIma[menuID]));
		var baseW = funkay.frameWidth;
		var baseH = funkay.frameHeight;
		var scale = Math.max(FlxG.camera.width / baseW, FlxG.camera.height / baseH);
		funkay.color = FlxColor.GRAY;
		funkay.scale.set(scale, scale);
		funkay.updateHitbox();
		funkay.screenCenter();
		funkay.scrollFactor.set(0, 0);
		funkay.antialiasing = ClientPrefs.globalAntialiasing;
		add(funkay);

		progressBarBase = new FlxSprite().makeGraphic(FlxG.width, 10, 0xff333333);
		add(progressBarBase);
		progressBarBase.y = FlxG.height - progressBarBase.height;

		progressBar = new FlxSprite().makeGraphic(FlxG.width, 10, 0xff777777);
		add(progressBar);
		progressBar.y = FlxG.height - progressBar.height;
		progressBar.origin.set(0, 0);
		progressBar.scale.set(0, 1);

		progressText = new FlxText(0, 0, FlxG.width, 'Start Precaching....');
		progressText.setFormat(Paths.font('vcr.ttf'), 20, FlxColor.WHITE, 'right', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		progressText.y = progressBar.y - progressText.height;
		add(progressText);

		super.create();
		new FlxTimer().start(0.6,function(tmr:FlxTimer){
			precacheAssets();
		});
	}
	
	var timePassed:Float;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		timePassed += elapsed;
		var dots:String = '';
		switch(Math.floor(timePassed % 1 * 3))
		{
			case 0:
				dots = '.';
			case 1:
				dots = '..';
			case 2:
				dots = '...';
		}
		var statement = states[currentPrecacheState];
		for (key => bitmap in requestedBitmaps)
			{					
				if (bitmap != null){
					var fucker = Paths.returnGraphic(originalBitmapKeys.get(key), bitmap);
					originalBitmapKeys.remove(key);
					requestedBitmaps.remove(key);
				}
			}
			
		if (progressText != null){
			if (!stopPrecache && currentProgress == totals){
				stopPrecache = true;
				
				progressText.text = 'Done!';
				FlxTween.tween(progressText, {alpha: 0}, 1, {startDelay: 1, onComplete:function(twn:FlxTween){
					onLoad();
				}});
			}
			else if (currentProgress < totals)
			progressText.text = 'Precaching' + dots;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * 5 , 0, 1);

		if (progressBar != null)
		progressBar.scale.set(FlxMath.lerp(progressBar.scale.x, currentProgress / totals, lerpVal), 1);
	}
	
	function precacheAssets(){
		if (images.length > 0){
			for (image in images){
				threadPool.run(() -> {
					mutex.acquire();
					precacheImage(image);
					mutex.release();
					currentProgress += 1;
				});
			}
		}

		if (characters.length > 0){
			for (character in characters){
				threadPool.run(() -> {
					mutex.acquire();
					precacheCharacter(character);
					mutex.release();
					currentProgress += 1;
				});
			}
		}

		if (sounds.length > 0){
			for (sound in sounds){
				threadPool.run(() -> {
				mutex.acquire();
				Paths.sound(sound);
				mutex.release();
				currentProgress += 1;
				});
			}
		}

		if (musics.length > 0){
			for (music in musics){
				threadPool.run(() -> {
					mutex.acquire();
					Paths.music(music);
					mutex.release();
					currentProgress += 1;
				});
			}
		}

		if (songs.length > 0){
			for (song in songs){
					threadPool.run(() -> {
					mutex.acquire();
					Paths.track(song.id, song.name);
					mutex.release();
					currentProgress += 1;
				});
			}
		}
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}
	
	public static function loadNextDirectory()
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;
		StageData.forceNextDirectory = null;

		if(weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		trace('Setting asset folder to ' + directory);
		return directory;
	}


	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		var directory = loadNextDirectory();
		var meta = {target:target, stopMusic:stopMusic, directory:directory};
		return new LoadingState(meta);
	}
	
	
	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();
		
		MusicBeatState.switchState(target);
	}
	
	
	override function destroy()
	{
		if (threadPool != null) threadPool.shutdown();
		threadPool = null;
		mutex = null;
		super.destroy();
		
	}
	
	function precacheImage(key:String):Null<BitmapData>
	{
		try {
			var requestKey:String = 'images/$key';
			if(requestKey.lastIndexOf('.') < 0) requestKey += '.png';

			if (!Paths.currentTrackedAssets.exists(requestKey))
			{
				var file:String = Paths.getPath(requestKey, IMAGE);
				if (#if sys FileSystem.exists(file) || #end Assets.exists(file, IMAGE))
				{
					#if sys
					var bitmap:BitmapData = BitmapData.fromFile(file);
					#else
					var bitmap:BitmapData = Assets.getBitmapData(file, false);
					#end

					mutex.acquire();
					requestedBitmaps.set(file, bitmap);
					originalBitmapKeys.set(file, requestKey);
					mutex.release();
					return bitmap;
				}
				else trace('no such image $key exists');
			}

			return Paths.currentTrackedAssets.get(requestKey).bitmap;
		}
		catch(e:haxe.Exception)
		{
			trace('ERROR! fail on preloading image $key');
		}

		return null;
	}

	function precacheCharacter(char:String):Bool{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			var character:Dynamic = Paths.parseJson(Paths.getContent(path));
			if (character == null) return false;
			var isAnimateAtlas:Bool = false;
			var img:String = character.image;
			img = img.trim();
			#if flxanimate
			var animToFind:String = Paths.getPath('images/$img/Animation.json', TEXT);
			if (#if MODS_ALLOWED FileSystem.exists(animToFind) || #end Assets.exists(animToFind))
				isAnimateAtlas = true;
			#end

			if(!isAnimateAtlas)
			{
				var split:Array<String> = img.split(',');
				for (file in split)
				{
					precacheImage(file);
				}
			}
			#if flxanimate
			else
			{
				for (i in 0...10)
				{
					var st:String = '$i';
					if(i == 0) st = '';
	
					if(Paths.exists('images/$img/spritemap$st.png', IMAGE))
					{
						//trace('found Sprite PNG');
						precacheImage('$img/spritemap$st');
						break;
					}
				}
			}
			#end
	
			var name:String = 'icons/' + character.healthIcon;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + character.healthIcon;
			if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face';
			precacheImage(name);
			return true;
		}
		catch(e:haxe.Exception)
		{
			trace(e.details());
			return false;
		}
	}
	#if cpp
	@:functionCode('
		return std::thread::hardware_concurrency();
    	')
	@:noCompletion
    	public static function getCPUThreadsCount():Int
    	{
        	return -1;
    	}
    	#end
}
