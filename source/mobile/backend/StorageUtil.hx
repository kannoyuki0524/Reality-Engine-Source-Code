package mobile.backend;

import lime.system.System as LimeSystem;
import lime.app.Application;
import haxe.io.Path;
import haxe.io.Bytes;
import mobile.MobileLog;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if android
import android.content.Context as AndroidContext;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.os.Build.VERSION as AndroidVersion;
import android.os.Build.VERSION_CODES as AndroidVersionCode;
#end

class StorageUtil
{
	#if sys
	public static final rootDir:String = LimeSystem.applicationStorageDirectory;

	#if android
	public static inline function getCustomStoragePath():String
		return AndroidContext.getExternalFilesDir() + '/storageModes.txt';
	#end

	public static inline function getStorageDirectory():String
		return #if android
			Path.addTrailingSlash(AndroidContext.getExternalFilesDir())
		#elseif ios
			LimeSystem.documentsDirectory
		#else
			Sys.getCwd()
		#end;

	#if android
	public static var currentExternalStorageDirectory:String;

	public static function initExternalStorageDirectory():String
	{
		var daPath:String = '';

		if (!FileSystem.exists(rootDir + 'storagetype.txt'))
			File.saveContent(rootDir + 'storagetype.txt', 'EXTERNAL_DATA');

		var curStorageType:String = File.getContent(rootDir + 'storagetype.txt');
		if (curStorageType == 'EXTERNAL' || curStorageType == 'EXTERNAL_MEDIA' || curStorageType == 'EXTERNAL_OBB')
		{
			curStorageType = 'EXTERNAL_DATA';
			File.saveContent(rootDir + 'storagetype.txt', curStorageType);
		}

		switch (curStorageType)
		{
			case 'EXTERNAL':
				// AndroidEnvironment.getExternalStorageDirectory() is deprecated
				// in API 30+ and will throw SecurityException for apps targeting
				// newer SDKs. Try it, but fall back to the per-package dir on failure.
				try {
					var extRoot:String = AndroidEnvironment.getExternalStorageDirectory();
					if (extRoot != null && extRoot.length > 0) {
						daPath = extRoot + '/.' + Application.current.meta.get('file');
					} else {
						daPath = AndroidContext.getExternalFilesDir() + '/.' + Application.current.meta.get('file');
					}
				} catch (e:Dynamic) {
					trace('EXTERNAL storage unavailable, falling back to EXTERNAL_DATA: $e');
					daPath = AndroidContext.getExternalFilesDir() + '/.' + Application.current.meta.get('file');
				}
			case 'EXTERNAL_OBB':
				daPath = AndroidContext.getObbDir();
			case 'EXTERNAL_MEDIA':
				daPath = AndroidEnvironment.getExternalStorageDirectory() + '/Android/media/' + Application.current.meta.get('packageName');
			case 'EXTERNAL_DATA':
				daPath = AndroidContext.getExternalFilesDir();
			default:
				daPath = AndroidContext.getExternalFilesDir() + '/.' + Application.current.meta.get('file');
		}

		daPath = Path.addTrailingSlash(daPath);
		currentExternalStorageDirectory = daPath;

		try
		{
			if (!FileSystem.exists(getStorageDirectory()))
				FileSystem.createDirectory(getStorageDirectory());
		}
		catch (e:Dynamic)
		{
			trace('Failed to create storage directory: $e');
			CoolUtil.showPopUp('Please create directory to\n${getStorageDirectory()}\nPress OK to close the game', "Error!");
			lime.system.System.exit(1);
		}

		try
		{
			if (!FileSystem.exists(getExternalStorageDirectory() + 'mods'))
				FileSystem.createDirectory(getExternalStorageDirectory() + 'mods');
		}
		catch (e:Dynamic)
		{
			trace('Failed to create mods directory: $e');
			CoolUtil.showPopUp('Please create directory to\n${getExternalStorageDirectory()}mods\nPress OK to close the game', "Error!");
			lime.system.System.exit(1);
		}

		return daPath;
	}

	public static function getExternalStorageDirectory():String
	{
		return currentExternalStorageDirectory != null ? currentExternalStorageDirectory : getStorageDirectory();
	}

	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
		{
			AndroidPermissions.requestPermissions([
				'READ_MEDIA_IMAGES',
				'READ_MEDIA_VIDEO',
				'READ_MEDIA_AUDIO',
				'READ_MEDIA_VISUAL_USER_SELECTED'
			]);
		}
		else
		{
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);
		}
		
		if (!AndroidEnvironment.isExternalStorageManager())
		{
			if (AndroidVersion.SDK_INT >= AndroidVersionCode.S)
				AndroidSettings.requestSetting('REQUEST_MANAGE_MEDIA');
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}
	}

	public static function chmod(permissions:Int, fullPath:String):Void
	{
		#if sys
		var process = new sys.io.Process('chmod', ['-R', '${permissions}', fullPath]);
		if (process.exitCode() == 0)
			trace('Successfully set permissions (${permissions}) for ${fullPath}');
		else
		{
			var errorOutput = process.stderr.readAll().toString();
			trace('Failed to set permissions for ${fullPath}. Exit code: ${process.exitCode()}, Error: ${errorOutput}');
		}
		process.close();
		#end
	}

	public static function copySpesificFileFromAssets(filePathInAssets:String, copyTo:String, ?changeable:Bool = false):Void
	{
		try
		{
			if (openfl.Assets.exists(filePathInAssets))
			{
				var fileData:Bytes = openfl.Assets.getBytes(filePathInAssets);
				if (fileData != null)
				{
					if (FileSystem.exists(copyTo) && changeable)
					{
						var existingFileData:Bytes = File.getBytes(copyTo);
						if (existingFileData != fileData && existingFileData != null)
							File.saveBytes(copyTo, fileData);
					}
					else if (!FileSystem.exists(copyTo))
						File.saveBytes(copyTo, fileData);

					trace('Copied: $filePathInAssets -> $copyTo');
				}
				else
				{
					var textData = openfl.Assets.getText(filePathInAssets);
					if (textData != null)
					{
						if (FileSystem.exists(copyTo) && changeable)
						{
							var existingTxtData = File.getContent(copyTo);
							if (existingTxtData != textData && existingTxtData != null)
								File.saveContent(copyTo, textData);
						}
						else if (!FileSystem.exists(copyTo))
							File.saveContent(copyTo, textData);
						trace('Copied (text): $filePathInAssets -> $copyTo');
					}
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('Error copying file $filePathInAssets: $e');
		}
	}
	#end

	public static function saveContent(fileName:String, fileData:String):Void
	{
		var folder:String = FunkinFileSystem.getGameRoot() + 'saves/';
		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);
			File.saveContent(folder + fileName, fileData);
		}
		catch (e:Dynamic)
		{
			trace('Failed to save $fileName: $e');
		}
	}
	#end
}