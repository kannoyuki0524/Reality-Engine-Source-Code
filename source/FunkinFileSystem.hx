package;

import lime.utils.Assets;
import haxe.io.Path;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import haxe.Exception;
import openfl.media.Sound;
import lime.media.AudioBuffer;
import openfl.display.BitmapData;
import lime.graphics.Image;

#if android
import mobile.backend.StorageUtil;
#end

using StringTools;

@:access(lime.utils.Assets)
@:access(lime.utils.AssetLibrary)

class FunkinFileSystem
{
	static var limePathToLibrary:Null<Map<String, String>> = null;

	public static function populateLimeCache():Void
	{
		limePathToLibrary = new Map<String, String>();

		for (library => assetLibrary in Assets.libraries)
		{
			for (asset in assetLibrary.types.keys())
			{
				var directory:String = Path.addTrailingSlash(Path.directory(asset));

				if (!limePathToLibrary.exists(asset))
					limePathToLibrary.set(asset, library);

				if (!limePathToLibrary.exists(directory))
					limePathToLibrary.set(directory, library);
			}
		}
	}

	public static function invalidateLimeCache():Void
	{
		limePathToLibrary = null;
	}

	public static function validateLimeCache():Void
	{
		if (limePathToLibrary == null)
		{
			populateLimeCache();
		}
	}

	/**
	 * The game root directory on the device's external storage.
	 * All persistent user data lives in this folder:
	 *   .RealityEngine/mods/   — mod folders
	 *   .RealityEngine/saves/  — save data
	 *   .RealityEngine/replays/— replays
	 *   .RealityEngine/modsList.txt
	 *
	 * On first launch, if the directory does not exist, it is created and
	 * (optionally) seeded from any pre-bundled assets.
	 */
	public static inline function getGameRoot():String
	{
		#if android
		return StorageUtil.getExternalStorageDirectory();
		#elseif mobile
		return Sys.getCwd();
		#else
		return '';
		#end
	}

	/**
	 * Returns an absolute path for the input. On Android, relative paths that
	 * are not bundled APK assets (i.e. not under assets/) are remapped to the
	 * external storage game root because FileSystem does not always honour
	 * Sys.setCwd on that platform. Already-absolute or "library:file" paths
	 * pass through unchanged.
	 */
	public static function getAbsolutePath(path:String):String
	{
		#if android
		if (path != null && path.length > 0 && !Path.isAbsolute(path) && path.indexOf(':') == -1 && !path.startsWith('assets/'))
		{
			return Path.addTrailingSlash(getGameRoot()) + path;
		}
		#end
		return path;
	}

	public static function getText(path:String):Null<String>
	{
		var content:Null<String> = null;

		try
		{
			#if android
			// On Android, relative paths must be remapped to the external storage
			// root, since FileSystem.exists() does not honour Sys.setCwd on
			// internal /data/user/0/... directories.
			path = getAbsolutePath(path);
			#end

			if (fromLime(path, false))
			{
				var fullPath:String = formatLimePath(path);
				content = Assets.getText(fullPath);

				if (content == null)
				{
					throw new Exception("Lime returned `null` when getting the text. This should not happen!");
				}
			}
			#if sys
			else if(FileSystem.exists(path))
			{
				content = File.getContent(path);
			}
			#end
		}
		catch(e:Exception)
		{
			trace('Failed to get the contents of "${path}". More info:\n${e.details()}');
			content = null;
		}

		return content;
	}

	public static function getContent(path:String):Null<String>
	{
		return getText(path);
	}

	public static function getSound(path:String):Null<Sound>
	{
		var sound:Null<Sound> = null;

		try
		{
			#if android
			path = getAbsolutePath(path);
			#end

			var buffer:Null<AudioBuffer> = null;

			if (fromLime(path, false))
			{
				var fullPath:String = formatLimePath(path);
				buffer = Assets.getAudioBuffer(fullPath, false);

				if (buffer == null)
				{
					throw new Exception("Lime returned `null` when getting the audio buffer. This should not happen!");
				}
			}
			#if sys
			else if(FileSystem.exists(path))
			{
				buffer = AudioBuffer.fromFile(path);
			}
			#end

			if (buffer != null)
			{
				sound = Sound.fromAudioBuffer(buffer);
			}
		}
		catch(e:Exception)
		{
			trace('Failed to get the sound from "${path}". More info:\n${e.details()}');
			sound = null;
		}

		return sound;
	}

	public static function getBitmapData(path:String):Null<BitmapData>
	{
		var bitmap:Null<BitmapData> = null;

		try
		{
			#if android
			path = getAbsolutePath(path);
			#end

			var image:Null<Image> = null;

			if (fromLime(path, false))
			{
				var fullPath:String = formatLimePath(path);
				image = Assets.getImage(fullPath, false);

				if (image == null)
				{
					throw new Exception("Lime returned `null` when getting the image. This should not happen!");
				}
			}
			#if sys
			else if(FileSystem.exists(path))
			{
				image = Image.fromFile(path);
			}
			#end

			if (image != null)
			{
				bitmap = BitmapData.fromImage(image);
			}
		}
		catch(e:Exception)
		{
			trace('Failed to get the bitmap from "${path}". More info:\n${e.details()}');
			bitmap = null;
		}

		return bitmap;
	}

	public static function readDirectory(path:String, ?recursive:Bool = false):Array<String>
	{
		#if android
		path = getAbsolutePath(path);
		#end

		validateLimeCache();

		if (limePathToLibrary == null)
			throw new Exception("Lime Cache is null while validated! This should not happen!");

		if (fromLime(path, true))
		{
			var parent:String = Path.addTrailingSlash(path);
			var parentLibrary:Null<String> = limePathToLibrary.get(parent);

			return [for (path => library in limePathToLibrary)
			{
				if (library != parentLibrary || !path.startsWith(parent))
					continue;

				var file:String = path.substring(parent.length);

				if(file.length == 0)
					continue;

				if(!recursive && Path.directory(file).length > 0)
					continue;

				formatLimePath(file, parentLibrary);
			}];
		}
		else
		{
			var parent:String = Path.removeTrailingSlashes(path);

			var searchDirectory:(?directory:Null<String>)->Array<String> = (?d:Null<String>) -> [];

			searchDirectory = (?directory:Null<String>) -> {
				var toReturn:Array<String> = [];

				var joinedDirectory:String = Path.join([parent, directory]);
				for (file in FileSystem.readDirectory(joinedDirectory))
				{
					var fullPath:String = Path.join([joinedDirectory, file]);
					var path:String = Path.join([directory, file]);

					if (FileSystem.isDirectory(fullPath))
					{
						if (!recursive)
							continue;

						for(file in searchDirectory(path))
							toReturn.push(file);
					}
					else if (!toReturn.contains(path))
					{
						toReturn.push(path);
					}
				}

				return toReturn;
			};

			return searchDirectory();
		}
	}

	public static function fromLime(path:String, ?directory:Null<Bool> = null):Bool
	{
		validateLimeCache();

		if (limePathToLibrary == null)
			throw new Exception("Lime Cache is null while validated! This should not happen!");

		var symbolName:String = path.substring(path.indexOf(':') + 1);

		if (directory != null)
		{
			var asset:String = (directory == true ? Path.addTrailingSlash : Path.removeTrailingSlashes)(symbolName);
			return limePathToLibrary.exists(asset);
		}
		else
		{
			if (limePathToLibrary.exists(Path.addTrailingSlash(symbolName)))
				return true;

			if (limePathToLibrary.exists(Path.removeTrailingSlashes(symbolName)))
				return true;

			return false;
		}
	}

	public static function formatLimePath(path:String, ?library:Null<String> = null):String
	{
		if(library != null)
		{
			validateLimeCache();

			if (limePathToLibrary == null)
				throw new Exception("Lime Cache is null while validated! This should not happen!");
		}

		var symbolName:String = path.substring(path.indexOf(':') + 1);
		if (library == null) library = limePathToLibrary.get(symbolName);

		if(library == null || library == 'default')
			return symbolName;

		return library + ':' + symbolName;
	}

	public static function exists(path:String):Bool
	{
		#if android
		path = getAbsolutePath(path);
		#end

		if (fromLime(path))
			return true;

		return FileSystem.exists(path);
	}
}
