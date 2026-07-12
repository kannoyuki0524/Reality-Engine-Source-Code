package;

import animateatlas.AtlasFrameMaker;
import flixel.math.FlxPoint;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import openfl.geom.Rectangle;
import flixel.math.FlxRect;
import haxe.xml.Access;
import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import haxe.io.Bytes;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;

import flash.media.Sound;

using StringTools;

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements',
		'states',
		'substates'
	];
	#end

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;
	static public function setCurrentLevel(name:String) currentLevel = name.toLowerCase();
	public static function getPath(file:String, ?type:AssetType, ?library:Null<String> = null, ?ignoreMods:Bool = false)
	{
		#if MODS_ALLOWED
		if (ignoreMods != true){
			var modPath:String = Paths.modFolders(file);
			if (Paths.exists(modPath))
				return modPath;
		}
		#end

		if (library != null)
			return getLibraryPath(file, library);

		var levelPath:String = '';
		if (currentLevel != null)
		{
			if(currentLevel != 'shared') {
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}

		}

		levelPath = getLibraryPathForce(file, "shared");
		if (OpenFlAssets.exists(levelPath, type))
			return levelPath;

		return getPreloadPath(file);
	}

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getPreloadPath(file:String = '')
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}
	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}
	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function video(key:String,?ext:String = '')
	{
		#if MODS_ALLOWED
		if (ext == '' || ext == null) ext = VIDEO_EXT;
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	static public function sound(key:String, ?library:String):Null<Sound>
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Null<Sound>
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function track(song:String, ?fileName:String = ''):Any
	{
		var songKey:String = '${formatToSongPath(song)}/' + fileName;
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function voices(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		var voices = returnSound('songs', songKey);
		return voices;
	}

	inline static public function inst(song:String):Any
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound('songs', songKey);
		return inst;
	}

	inline static public function image(key:String, ?library:String, ?allowGPU:Bool = true):FlxGraphic
	{
		key = 'images/$key.png';
		// streamlined the assets process morevar bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		var returnAsset:FlxGraphic = returnGraphic(key, null, library);
		return returnAsset;
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, ignoreMods);
		return Paths.getContent(path);
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	inline static public function exists(path:String, ?type:AssetType):Bool
	{
		return FileSystem.exists(path) || OpenFlAssets.exists(path, type);
	}

	inline static public function getContent(path:String):Null<String>{
		
		return FileSystem.exists(path) ? File.getContent(path) : (OpenFlAssets.exists(path) ? OpenFlAssets.getText(path) : null);

	}
	
	inline static public function isDirectory(path:String):Bool{
		return FileSystem.exists(path) && FileSystem.isDirectory(path);
	}
	
	static public function getJson(path:String):Null<Dynamic>
	{
		var ret:Null<Dynamic> = null;
		try{
			var raw = Paths.getContent(path);
			if (raw != null)
				ret = haxe.Json.parse(raw);
		}catch(e){
			haxe.Log.trace('$path: $e', null);
		}

		return ret;
	}
		
	static public function parseJson(raw:String):Null<Dynamic>
	{
		var ret:Null<Dynamic> = null;
		try{
			if (raw != null)
				ret = haxe.Json.parse(raw);
		}catch(e){
			haxe.Log.trace('$e', null);
		}

		return ret;
	}
	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if(FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) {
			return true;
		}
		#end

		if(OpenFlAssets.exists(getPath(key, type))) {
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var xmlExists:Bool = false;

		var xml:String = modsXml(key);
		if(Paths.exists(xml)) xmlExists = true;

		return FlxAtlasFrames.fromSparrow(imageLoaded, (xmlExists ? Paths.getContent(xml) : getPath('images/$key' + '.xml', TEXT, library)));
		#else
		return FlxAtlasFrames.fromSparrow(imageLoaded, getPath('images/$key' + '.xml', TEXT, library));
		#end
	}


	inline static public function getPackerAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		#if MODS_ALLOWED
		var txtExists:Bool = false;

		var txt:String = modsXml(key);
		if(Paths.exists(txt)) txtExists = true;
		
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, (txtExists ? Paths.getContent(txt) : getPath('images/$key' + '.txt', TEXT, library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, getPath('images/$key' + '.txt', TEXT, library));
		#end
	}

	inline static public function formatToSongPath(path:String) {
		var invalidChars = ~/[~&\\;:<>#]/;
		var hideChars = ~/[.,'"%?!]/;

		var path = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	

	inline static public function getFolders(dir:String, ?modsOnly:Bool = false){
		#if !MODS_ALLOWED
		return [Paths.getPreloadPath('$dir/')];
		
		#else
		var foldersToCheck:Array<String> = [];

		if(!modsOnly)
			foldersToCheck.push(Paths.getPreloadPath('$dir/'));

		foldersToCheck.insert(0, Paths.mods('$dir/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/$dir/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/$dir/'));

		return foldersToCheck;
		#end
	}
	
	inline static public function getMergeFolders(dir:String = '', ?modsOnly:Bool = false):Array<String>{
		#if !MODS_ALLOWED
		return [Paths.getPreloadPath()];
		
		#else
		var foldersToCheck:Array<String> = [];

		if(!modsOnly)
			foldersToCheck.push(Paths.getPreloadPath());

		foldersToCheck.insert(0, Paths.mods());
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/'));

		for(mod in Paths.getGlobalMods())
			foldersToCheck.insert(0, Paths.mods(mod + '/'));

		return foldersToCheck;
		#end
	}
	
	
	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedBytes:Map<String, Bytes> = [];
	public static function returnBytes(key:String, ?library:String) {
		var file:String = Paths.getPath(key, IMAGE, library);
		#if MODS_ALLOWED
		if(FileSystem.exists(file)) {
			return File.getBytes(file);
		}
		#end

		if (OpenFlAssets.exists(file)) {
			return OpenFlAssets.getBytes(file);
		}

		trace('Bitmap not found: $file | key: $key');
		return null;
	}

	public static function returnGraphic(key:String, ?bitmap:BitmapData, ?library:String, ?allowGPU:Bool = true):FlxGraphic {
		if (bitmap == null)
		{
			var file:String = getPath(key, IMAGE, library, false);
			#if MODS_ALLOWED
			if (FileSystem.exists(file))
				bitmap = BitmapData.fromFile(file);
			else #end if (OpenFlAssets.exists(file, IMAGE))
				bitmap = OpenFlAssets.getBitmapData(file);

			if (bitmap == null)
			{
				trace('oh no its returning null NOOOO ($file)');
				return null;
			}
		}

		if (allowGPU && ClientPrefs.cacheOnGPU && bitmap.image != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	public static function freeGraphicsFromMemory()
	{
		trace('RELOADING GRAPHICS...');

		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			if (spr == null) return;
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if (grp != null)
				{
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if (gfx != null)
				{
					protectedGfx.push(gfx);
				}
			}
		}
		
		if (FlxG.state != null)
		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					currentTrackedAssets.remove(key); // and remove the key from local cache map
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];
	
	public static function returnSoundPath(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			return file;
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		return gottenPath;
	}

	public static function returnSound(path:String, key:String, ?library:String) {
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);
		if(FileSystem.exists(file)) {
			if(!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end
		// I hate this so god damn much
		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		// trace(gottenPath);
		if(!currentTrackedSounds.exists(gottenPath)){
                     
		var folder:String = '';
		if(path == 'songs') folder = 'songs:';
		#if MODS_ALLOWED
			#if mobile
			if (OpenFlAssets.exists(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)))
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			else
			#end
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
		#else
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(folder + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
		
		#end
                             }
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	static public function getAtlas(key:String, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded = image(key, library, allowGPU);

		var myTxt:Dynamic = getPath('images/$key.txt', TEXT, library);
		if(Paths.exists(myTxt, TEXT))
		{
			#if MODS_ALLOWED
			return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, Paths.getContent(myTxt));
			#else
			return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, file('images/$key.txt', TEXT, library));
			#end
		}
		else
		{
			var myJson:Dynamic = getPath('images/$key.json', TEXT, library);
			if(Paths.exists(myJson, TEXT))
			{
				#if MODS_ALLOWED
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, (Paths.exists(myJson) ? Paths.getContent(myJson) : myJson));
				#else
				return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, file('images/$key.json', TEXT, library));
				#end
			}
		}
		return getSparrowAtlas(key, library);
	}
	
	static public function getMultiAtlas(keys:Array<String>, ?library:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), library, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	#if MODS_ALLOWED
	inline static public function mods(key:String = '') {
		return FunkinFileSystem.getAbsolutePath('mods/') + key;
	}

	inline static public function modsFont(key:String) {
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String) {
		return modFolders('data/' + key + '.json');
	}

	inline static public function modsVideo(key:String) {
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String) {
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String) {
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String) {
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String) {
		return modFolders('images/' + key + '.txt');
	}

	static public function modFolders(key:String) {
		if(currentModDirectory != null && currentModDirectory.length > 0) {
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if(FunkinFileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for(mod in getGlobalMods()){
			var fileToCheck:String = mods(mod + '/' + key);
			if(FunkinFileSystem.exists(fileToCheck))
				return fileToCheck;

		}
		return 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods()
		return globalMods;

	static public function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		var path:String = 'modsList.txt';
		if(FunkinFileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path);
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if(Paths.exists(path)) {
						try{
							var rawJson:String = Paths.getContent(path);
							if(rawJson != null && rawJson.length > 0) {
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if(global)globalMods.push(dat[0]);
							}
						} catch(e:Dynamic){
							trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String> {
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if(FunkinFileSystem.exists(modsFolder)) {
			for (folder in sys.FileSystem.readDirectory(modsFolder)) {
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
