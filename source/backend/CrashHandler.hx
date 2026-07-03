package backend;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import CoolUtil;
#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if mobile
import mobile.MobileLog;
import mobile.backend.StorageUtil;
#end

using StringTools;

/**
 * Crash Handler.
 * Catches both Haxe-level and C++ critical errors, logs them, and shows a popup.
 * Based on Psych-Extended-Online-dev's implementation.
 */
class CrashHandler
{
	public static function init():Void
	{
		try {
			openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
			#if cpp
			untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
			#elseif hl
			hl.Api.setErrorHandler(onCriticalError);
			#end
		} catch(e:Dynamic) {
			trace('Failed to init CrashHandler: $e');
		}
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = Std.string(e.error);
		if (Std.isOfType(e.error, Error))
		{
			var err = cast(e.error, Error);
			m = '${err.message}';
		}
		else if (Std.isOfType(e.error, ErrorEvent))
		{
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		var stack = haxe.CallStack.exceptionStack();
		var stackLabelArr:Array<String> = [];
		for (e in stack)
		{
			switch (e)
			{
				case CFunction:
					stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c):
					stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		var stackLabel:String = stackLabelArr.join('\n');

		#if sys
		saveErrorMessage('Haxe Error: $m\n\nStack:\n$stackLabel');
		#end
		#if mobile
		MobileLog.error('Haxe Error: $m\nStack:\n$stackLabel');
		#end

		try {
			CoolUtil.showPopUp('$m\n\n$stackLabel', "Error!");
		} catch(e2:Dynamic) {
			trace('Could not show popup: $e2');
		}
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}

	#if cpp
	private static function onCriticalError(message:Dynamic):Void
	{
		var log:Array<String> = [];
		log.push('CRITICAL C++ ERROR: ' + Std.string(message));
		try {
			log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));
		} catch(e:Dynamic) {
			log.push('(Could not get stack trace)');
		}

		var fullMsg:String = log.join('\n');

		#if sys
		saveErrorMessage(fullMsg);
		#end
		#if mobile
		MobileLog.error(fullMsg);
		#end

		try {
			CoolUtil.showPopUp(fullMsg, "Critical Error!");
		} catch(e:Dynamic) {
			trace('Could not show popup: $e');
		}
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}
	#elseif hl
	private static function onCriticalError(message:Dynamic):Void
	{
		var log:Array<String> = [];
		log.push('CRITICAL HL ERROR: ' + Std.string(message));
		try {
			log.push(haxe.CallStack.toString(haxe.CallStack.exceptionStack(true)));
		} catch(e:Dynamic) {
			log.push('(Could not get stack trace)');
		}

		var fullMsg:String = log.join('\n');

		#if sys
		saveErrorMessage(fullMsg);
		#end

		try {
			CoolUtil.showPopUp(fullMsg, "Critical Error!");
		} catch(e:Dynamic) {
			trace('Could not show popup: $e');
		}
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
		lime.system.System.exit(1);
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		try {
			#if android
			var folder:String = StorageUtil.getStorageDirectory() + 'logs/';
			#else
			var folder:String = Sys.getCwd() + 'logs/';
			#end

			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			var filename:String = 'crash_' + Date.now().toString().replace(' ', '_').replace(':', '-') + '.txt';
			File.saveContent(folder + filename, message);
		}
		catch (e:Dynamic)
		{
			trace('Couldn\'t save error message: $e');
		}
	}
	#end
}