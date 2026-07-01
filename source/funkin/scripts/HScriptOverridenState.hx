package funkin.scripts;
class HScriptOverridenState extends HScriptedState 
{
	public var parentClass:Class<MusicBeatState> = null;

	override function _startExtensionScript(folder:String, scriptName:String) 
		return;

	private function new(name:String = '', parentClass:Class<MusicBeatState>, scriptFullPath:String, args:Array<Dynamic> = null) 
	{
		if (parentClass == null || scriptFullPath == null) {
			trace("Uh oh!", parentClass, scriptFullPath);
			return;
		}

		this.parentClass = parentClass;
		
		super(name, scriptFullPath, [getShortClassName(parentClass) => parentClass], args);
	}

	static public function findClassOverride(cl:Class<MusicBeatState>, args:Array<Dynamic> = null):Null<HScriptOverridenState> 
	{
		var fullName = Type.getClassName(cl);
		for (filePath in Paths.getFolders("states"))
		{
			var fileName = 'override/$fullName.hscript';
			var fullPath = filePath + fileName;
			if (Paths.exists(fullPath))
				return new HScriptOverridenState(fullName, cl, fullPath, args);

			fileName = 'override/${getShortClassName(cl)}.hscript';
			fullPath = filePath + fileName;
			if (Paths.exists(fullPath))
				return new HScriptOverridenState(getShortClassName(cl), cl, fullPath, args);
		}

		return null;
	}

	static public function requestOverride(state:MusicBeatState, args:Array<Dynamic> = null):Null<HScriptOverridenState>
	{
		if (state != null && state.canBeScripted)
			return findClassOverride(Type.getClass(state), args);
		
		return null;
	}

	static public function fromAnother(state:HScriptOverridenState):Null<HScriptOverridenState>
	{
		return Paths.exists(state.scriptPath) ? new HScriptOverridenState(state.scriptName ,state.parentClass, state.scriptPath) : null;
	}

	inline private static function getShortClassName(cl):String{
		var tar = Type.getClassName(cl).split('.');
		if (tar == null || tar.length <= 0)
			return Type.getClassName(cl);
		return tar.pop();
	}

}
