package mobile;

import haxe.Json;
import haxe.io.Path;
import flixel.util.FlxSave;
import openfl.utils.Assets;
import flixel.FlxG;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

enum ButtonModes
{
	ACTION;
	DPAD;
	HITBOX;
}

class MobileConfig
{
	public static var actionModes:Map<String, MobileButtonsData> = new Map();
	public static var dpadModes:Map<String, MobileButtonsData> = new Map();
	public static var hitboxModes:Map<String, CustomHitboxData> = new Map();
	public static var mobileFolderPath:String = 'mobile/';
	public static var save:FlxSave;

	public static function init(saveName:String, savePath:String, mobilePath:String = 'mobile/', folders:Array<Array<Dynamic>>)
	{
		save = new FlxSave();
		save.bind(saveName, savePath);
		if (mobilePath != null && mobilePath != '') 
			mobileFolderPath = mobilePath.endsWith('/') ? mobilePath : mobilePath + '/';

		for (folder in folders)
		{
			switch (folder[1])
			{
				case ACTION:
					readDirectory(mobileFolderPath + folder[0], actionModes, ACTION);
				case DPAD:
					readDirectory(mobileFolderPath + folder[0], dpadModes, DPAD);
				case HITBOX:
					readDirectory(mobileFolderPath + folder[0], hitboxModes, HITBOX);
			}
		}
	}

	static function readDirectory(folder:String, map:Dynamic, mode:ButtonModes)
	{
		folder = folder.contains(':') ? folder.split(':')[1] : folder;

		#if sys
		try {
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (Path.extension(file) == 'json')
					{
						var fullPath = Path.join([folder, file]);
						var str = File.getContent(fullPath);
						processJson(str, Path.withoutExtension(file), map, mode);
					}
				}
			}
		} catch(e:Dynamic) {
			FlxG.log.warn('Failed to read directory $folder: $e');
		}
		#end

		var assetsFolder = folder.startsWith('assets/') ? folder : 'assets/' + folder;
		for (asset in Assets.list().filter(a -> a.startsWith(assetsFolder) && Path.extension(a) == 'json'))
		{
			var str = Assets.getText(asset);
			var name = Path.withoutExtension(Path.withoutDirectory(asset));
			processJson(str, name, map, mode);
		}
	}

	static function processJson(str:String, name:String, map:Dynamic, mode:ButtonModes)
	{
		try
		{
			if (mode == HITBOX)
			{
				var json:CustomHitboxData = cast Json.parse(str);
				map.set(name, json);
			}
			else
			{
				var json:MobileButtonsData = cast Json.parse(str);
				map.set(name, json);
			}
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('Failed to parse mobile config: $name - $e');
		}
	}
}

typedef MobileButtonsData =
{
	buttons:Array<ButtonsData>
}

typedef CustomHitboxData =
{
	hints:Array<HitboxData>,
	none:Array<HitboxData>,
	single:Array<HitboxData>,
	double:Array<HitboxData>,
	triple:Array<HitboxData>,
	quad:Array<HitboxData>
}

typedef HitboxData =
{
	button:String,
	buttonIDs:Array<String>,
	buttonUniqueID:Dynamic,
	x:Dynamic,
	y:Dynamic,
	width:Dynamic,
	height:Dynamic,
	position:Array<Float>,
	scale:Array<Int>,
	color:String,
	returnKey:String,
	extraKeyMode:Null<Int>,
	topPosition:Array<Float>,
	topScale:Array<Int>,
	topColor:String,
	topReturnKey:String,
	topExtraKeyMode:Null<Int>,
	middlePosition:Array<Float>,
	middleScale:Array<Int>,
	middleColor:String,
	middleReturnKey:String,
	middleExtraKeyMode:Null<Int>,
	bottomPosition:Array<Float>,
	bottomScale:Array<Int>,
	bottomColor:String,
	bottomReturnKey:String,
	bottomExtraKeyMode:Null<Int>
}

typedef ButtonsData =
{
	button:String,
	buttonIDs:Array<String>,
	buttonUniqueID:Dynamic,
	graphic:String,
	position:Array<Null<Float>>,
	color:String,
	scale:Null<Float>,
	returnKey:String
}