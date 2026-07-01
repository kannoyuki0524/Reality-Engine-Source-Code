package mobile;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

/**
 * Simple mobile error logging utility.
 * Writes crash/error logs to the app's storage directory for debugging.
 */
class MobileLog
{
	#if sys
	public static var logPath(get, null):String;
	static function get_logPath():String
	{
		if (logPath == null)
		{
			try {
				logPath = mobile.backend.StorageUtil.getStorageDirectory() + 'logs/';
				if (!FileSystem.exists(logPath))
					FileSystem.createDirectory(logPath);
			} catch(e:Dynamic) {
				// Fallback: use internal storage
				logPath = lime.system.System.applicationStorageDirectory + 'logs/';
				try {
					if (!FileSystem.exists(logPath))
						FileSystem.createDirectory(logPath);
				} catch(e2:Dynamic) {}
			}
		}
		return logPath;
	}

	public static function log(message:String, ?tag:String = 'INFO'):Void
	{
		try {
			var timestamp:String = Date.now().toString();
			var logEntry:String = '[$timestamp] [$tag] $message\n';
			
			var logFile:String = logPath + 'mobile_' + Date.now().getDate() + '.log';
			try {
				if (FileSystem.exists(logFile))
				{
					var existing = File.getContent(logFile);
					File.saveContent(logFile, existing + logEntry);
				}
				else
				{
					File.saveContent(logFile, logEntry);
				}
			} catch(e:Dynamic) {
				var fallbackPath = lime.system.System.applicationStorageDirectory + 'crash_' + Date.now().getTime() + '.log';
				try {
					File.saveContent(fallbackPath, logEntry);
				} catch(e2:Dynamic) {}
			}
		} catch(e:Dynamic) {
			trace('[MobileLog] $tag: $message');
		}
	}

	public static function error(message:String, ?stack:String):Void
	{
		var fullMsg = message;
		if (stack != null && stack.length > 0)
			fullMsg += '\nStack: ' + stack;
		log(fullMsg, 'ERROR');
		trace('[MobileLog ERROR] $message');
	}

	public static function warn(message:String):Void
	{
		log(message, 'WARN');
		trace('[MobileLog WARN] $message');
	}

	public static function info(message:String):Void
	{
		log(message, 'INFO');
		trace('[MobileLog] $message');
	}
	#else
	public static function log(message:String, ?tag:String = 'INFO'):Void
	{
		trace('[$tag] $message');
	}
	public static function error(message:String, ?stack:String):Void
	{
		trace('[ERROR] $message');
	}
	public static function warn(message:String):Void
	{
		trace('[WARN] $message');
	}
	public static function info(message:String):Void
	{
		trace('[INFO] $message');
	}
	#end
}