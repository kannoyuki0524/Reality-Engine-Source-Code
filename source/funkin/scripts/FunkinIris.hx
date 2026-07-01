package funkin.scripts;

import crowplexus.iris.Iris;
import crowplexus.iris.utils.Ansi;
import crowplexus.hscript.proxy.ProxyType;
import crowplexus.hscript.proxy.ProxyReflect;
import haxe.ds.StringMap;
import crowplexus.hscript.*;
import crowplexus.hscript.Expr;
import crowplexus.iris.ErrorSeverity;
import crowplexus.iris.IrisConfig;
import crowplexus.iris.utils.UsingEntry;

class FunkinIris extends Iris
{
    public var errorIgnoreList:Array<String> = [];
    private var errorLizedMap:Map<String,Bool> = new Map<String,Bool>();
    public function executeFunc(fun: String, ?args: Array<Dynamic>, ?parentObject:Any, ?extraVars:Map<String, Dynamic>, ?skipTrace:Bool = false): IrisCall {
		if (interp == null) {
			#if IRIS_DEBUG
			trace("[Iris:call()]: " + interpErrStr + ", so functions cannot be called.");
			#end
			return null;
		}

		if (args == null)
			args = [];

        if (parentObject != null) {
			if (extraVars == null)
				extraVars = [];
			extraVars.set("this", parentObject);
		}

		var prevVals:Map<String, Dynamic> = null;

		if (extraVars != null) {
			prevVals = [];

			for (key in extraVars.keys()) {
				prevVals.set(key, get(key)); // Store original values of variables that are being overwritten
				set(key, extraVars.get(key));
			}
		}
        
		// fun-ny
		var ny: Dynamic = interp.directorFields.get(fun); // function signature
		var isFunction: Bool = false;
        var returnVal:IrisCall = null;
        var errorTriggered:Bool = false;
        if (!errorLizedMap.exists(fun)) errorLizedMap.set(fun, errorTriggered);
        errorTriggered = errorLizedMap.get(fun);
		try {
			isFunction = ny != null && ny.type == "func" && Reflect.isFunction(ny.value);
			if (!isFunction){
				errorTriggered = true;
				errorLizedMap.set(fun, errorTriggered);
				return returnVal;
			}
			// throw "Variable not found or not callable, for \"" + fun + "\"";

			final ret = Reflect.callMethod(parentObject, ny.value, args);
            returnVal = {funName: fun, signature: ny, returnValue: ret};
		}
		// @formatter:off
		#if hscriptPos
		catch (e:Expr.Error) {
            if (interp.directorFields.exists(fun) && !skipTrace && !errorTriggered) {
			Iris.error(Printer.errorToString(e, false), this.interp.posInfos());
            errorTriggered = true;
			errorLizedMap.set(fun, errorTriggered);
            }
		}
		#end
		catch(e) {
            if (interp.directorFields.exists(fun) && !skipTrace && !errorTriggered) {
			var pos = isFunction ? this.interp.posInfos() : Iris.getDefaultPos(this.name);
			Iris.error(Std.string(e), pos);
            errorTriggered = true;
			errorLizedMap.set(fun, errorTriggered);
            }
		}

        if (prevVals != null) {
			for (key => val in prevVals)
				set(key, val);
		}
		// @formatter:on
		return returnVal;
	}
}