package funkin.scripts;
class HScriptedState extends MusicBeatState 
{
    public var scriptPath:String;
    public var scriptName:String;
    public function new(stateName:String, statePath:String, ?scriptVars:Map<String, Dynamic>,args:Array<Dynamic> = null)
        {
            super(false); // false because the whole point of this state is its scripted lol
            scriptPath = statePath;
            scriptName = stateName;
            if (args == null){
                args = [];
            }
            var vars = _getScriptDefaultVars();

            if (scriptVars != null) {
                for (k => v in scriptVars)
                    vars[k] = v;
            }
            _extensionScript = new FunkinHScript(stateName, statePath, true, scriptVars, false);
            _extensionScript.set("this", this);
            _extensionScript.set("add", this.add);
            _extensionScript.set("remove", this.remove);
            _extensionScript.set("insert", this.insert);
            _extensionScript.set("members", this.members);
            _extensionScript.set("refresh", this.refresh);
            _extensionScript.call("new", args);
        }

	static public function fromFile(name:String, ?scriptVars, args:Array<Dynamic> = null)
	{
		for (filePath in Paths.getFolders("states"))
		{
			var fullPath = filePath + '$name.hscript';
			if (Paths.exists(fullPath))
				return new HScriptedState(name, fullPath, scriptVars, args);
		}

		return null;
	}
    
	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
		{
			if (_extensionScript != null){
				_extensionScript.call('getEvent',[id,sender,data,params]);
			}
		}
    
}