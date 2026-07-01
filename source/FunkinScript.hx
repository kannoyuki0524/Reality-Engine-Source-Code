package;
/** 
	Base class meant to be overridden so you can implement custom script types 
**/
class FunkinScript 
{
	public var scriptName:String;
	public var scriptType:String;

	/**
		Called to set a variable defined in the script
	**/
	public function set(variable:String, data:Dynamic):Void {}

	/**
		Called to get a variable defined in the script
	**/
	public function get(key:String):Dynamic { return key; }

	/**
		Called to call a function within the script
	**/
	public function call(func:String, ?args:Array<Dynamic>, ?extraVars:Map<String,Dynamic>):Dynamic {return func;}

	/**
		Called when the script should be stopped
	**/
	public function stop():Void {}

}

