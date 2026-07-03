package mobile.android;

#if android
import lime.system.JNI;

class AndroidRPC
{
	private static var _init:Dynamic = null;
	private static var _update:Dynamic = null;
	private static var _shutdown:Dynamic = null;

	public static function initialize():Void
	{
		if (_init == null)
			_init = JNI.createStaticMethod("arkoselabs/utils/KizzyHelper", "initialize", "()V");

		try { _init(); }
		catch (e:Dynamic) { trace("JNI Init Error: " + e); }
	}

	public static function update(title:String, artist:String, ?imagePath:String):Void
	{
		if (_update == null)
			_update = JNI.createStaticMethod("arkoselabs/utils/KizzyHelper", "updateStatus", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V");

		try { _update(title, artist, imagePath); }
		catch (e:Dynamic) { trace("JNI Update Error: " + e); }
	}

	public static function shutdown():Void
	{
		if (_shutdown == null)
			_shutdown = JNI.createStaticMethod("arkoselabs/utils/KizzyHelper", "shutdown", "()V");

		try { _shutdown(); }
		catch (e:Dynamic) { trace("JNI Shutdown Error: " + e); }
	}
}
#end