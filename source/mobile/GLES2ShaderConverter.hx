package mobile;

import sys.io.File;
import sys.FileSystem;
import mobile.MobileLog;
using StringTools;

class GLES2ShaderConverter
{
	static final MAX_LOOP_ITERATIONS:Int = 256;

	public static var conversionCount:Int = 0;

	public static function convertToGLES2(shaderPath:String):Null<String>
	{
		if (!FileSystem.exists(shaderPath))
		{
			MobileLog.error('GLES2ShaderConverter: Shader file not found: $shaderPath');
			return null;
		}

		try
		{
			var content = File.getContent(shaderPath);
			return applyGLES2Conversions(content, shaderPath);
		}
		catch (e:Dynamic)
		{
			MobileLog.error('GLES2ShaderConverter: Failed to convert $shaderPath: $e');
			return null;
		}
	}

	public static function applyGLES2Conversions(content:String, filePath:String):String
	{
		if (content == null || content.length == 0)
			return content;

		var original = content;

		content = removeVersionDirectives(content);

		content = removeLayoutQualifiers(content);

		content = convertInOutQualifiers(content, filePath);

		content = fixIResolutionMacro(content);

		content = removeUniformInitializers(content);

		content = fixGlobalVariableInitializers(content);

		content = fixGlobalScopeAssignments(content);

		content = convertIntLiteralsToFloat(content);

		content = convertWhileLoops(content);

		content = convertTextureCalls(content);

		content = convertFloatForLoops(content);

		content = convertFragmentOutput(content);

		if (content != original)
		{
			conversionCount++;
		}

		return content;
	}

	public static function resetCount():Void
	{
		conversionCount = 0;
	}

	static function removeVersionDirectives(content:String):String
	{
		var regex = ~/#version\s+\d+(\s+\w+)?\s*\r?\n?/g;
		return regex.replace(content, "");
	}

	static function removeLayoutQualifiers(content:String):String
	{
		var regex = ~/layout\s*\([^)]*\)\s*/g;
		return regex.replace(content, "");
	}

	static function convertInOutQualifiers(content:String, filePath:String):String
	{
		var isVertex = filePath != null && (filePath.endsWith(".vert") || filePath.indexOf("vertex") != -1);
		var isFragment = filePath != null && (filePath.endsWith(".frag") || filePath.indexOf("fragment") != -1);

		if (!isVertex && !isFragment)
		{
			isFragment = content.indexOf("gl_FragColor") != -1 || content.indexOf("fragColor") != -1;
			isVertex = !isFragment;
		}

		if (!isVertex && !isFragment)
			return content;

		var lines = content.split("\n");
		var output:Array<String> = [];

		for (line in lines)
		{
			if (isVertex)
			{
				var vertexRegex = ~/^(\s*)(in|out)\s+((?:highp\s+|mediump\s+|lowp\s+)?\w+)/;
				if (vertexRegex.match(line))
				{
					var indent = vertexRegex.matched(1);
					var qualifier = vertexRegex.matched(2);
					var rest = vertexRegex.matched(3);
					var replacement = (qualifier == "in") ? "attribute" : "varying";
					var lineRest = line.substr(vertexRegex.matched(0).length);
					output.push('$indent$replacement $rest$lineRest');
					continue;
				}
			}
			else if (isFragment)
			{
				var fragRegex = ~/^(\s*)in\s+((?:highp\s+|mediump\s+|lowp\s+)?\w+)/;
				if (fragRegex.match(line))
				{
					var indent = fragRegex.matched(1);
					var rest = fragRegex.matched(2);
					var lineRest = line.substr(fragRegex.matched(0).length);
					output.push('${indent}varying $rest$lineRest');
					continue;
				}
			}

			output.push(line);
		}

		return output.join("\n");
	}

	static function fixIResolutionMacro(content:String):String
	{
		var localDecl = ~/vec2\s+iResolution\s*=/;
		if (!localDecl.match(content))
			return content;

		var macroRegex = ~/#define\s+iResolution\s+vec3\s*\([^)]*\)\s*\r?\n?/g;
		return macroRegex.replace(content, "");
	}

	static function removeUniformInitializers(content:String):String
	{
		var regex = ~/(uniform\s+(?:highp|mediump|lowp\s+)?\w+\s+\w+)\s*=\s*[^;]+;/g;
		return regex.replace(content, "$1;");
	}

	static function fixGlobalVariableInitializers(content:String):String
	{
		var lines = content.split("\n");
		var output:Array<String> = [];
		var mainAssignments:Array<String> = [];
		var braceDepth = 0;

		var glslTypes = "(float|int|bool|vec2|vec3|vec4|mat2|mat3|mat4|ivec2|ivec3|ivec4|bvec2|bvec3|bvec4)";

		var floatTypes = ["float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4"];

		for (line in lines)
		{
			var trimmed = StringTools.trim(line);

			for (i in 0...line.length)
			{
				var ch = line.charAt(i);
				if (ch == "{") braceDepth++;
				else if (ch == "}") braceDepth--;
			}

			var hasBrace = line.indexOf("{") != -1 || line.indexOf("}") != -1;
			if (braceDepth == 0 && !hasBrace && isGlobalVarDecl(trimmed, glslTypes))
			{
				var declRegex = new EReg("^\\s*" + glslTypes + "\\s+(\\w+)\\s*=\\s*(.+);\\s*$", "");
				if (declRegex.match(trimmed))
				{
					var type = declRegex.matched(1);
					var name = declRegex.matched(2);
					var initializer = declRegex.matched(3);
					var leading = getLeadingWhitespace(line);

				output.push('${leading}$type $name;');

				var convertedInit = initializer;
				if (floatTypes.indexOf(type) != -1)
				{
					convertedInit = convertIntLiteralSafe(initializer);
				}
				mainAssignments.push('$name = $convertedInit;');
					continue;
				}
			}

			output.push(line);
		}

		if (mainAssignments.length == 0)
			return output.join("\n");

		var result = output.join("\n");
		var injection = "\n    " + mainAssignments.join("\n    ");

		var mainRegex = ~/void\s+(?:main|mainImage)\s*\([^)]*\)\s*\{/g;
		if (mainRegex.match(result))
		{
			var matched = mainRegex.matched(0);
			result = mainRegex.replace(result, matched + injection + "\n");
		}
		else
		{
			MobileLog.warn("GLES2ShaderConverter: main()/mainImage() not found, appending assignments at end");
			result += "\n" + mainAssignments.join("\n") + "\n";
		}

		return result;
	}

	static function fixGlobalScopeAssignments(content:String):String
	{
		var lines = content.split("\n");

		var globalVars = new Map<String, String>();
		var scanBraceDepth = 0;
		var glslTypes = "(float|int|bool|vec2|vec3|vec4|mat2|mat3|mat4|ivec2|ivec3|ivec4|bvec2|bvec3|bvec4)";
		for (line in lines)
		{
			for (i in 0...line.length)
			{
				var ch = line.charAt(i);
				if (ch == "{") scanBraceDepth++;
				else if (ch == "}") scanBraceDepth--;
			}

			if (scanBraceDepth == 0)
			{
				var trimmed = StringTools.trim(line);
				var declRegex = new EReg("^\\s*" + glslTypes + "\\s+(\\w+)\\s*;", "");
				if (declRegex.match(trimmed))
				{
					var type = declRegex.matched(1);
					var name = declRegex.matched(2);
					if (!isReservedKeyword(name))
						globalVars.set(name, type);
				}
			}
		}

		var floatTypes = ["float", "vec2", "vec3", "vec4", "mat2", "mat3", "mat4"];

		var output:Array<String> = [];
		var movedAssignments:Array<String> = [];
		var braceDepth = 0;

		for (line in lines)
		{
			var trimmed = StringTools.trim(line);

			for (i in 0...line.length)
			{
				var ch = line.charAt(i);
				if (ch == "{") braceDepth++;
				else if (ch == "}") braceDepth--;
			}

			var hasBrace = line.indexOf("{") != -1 || line.indexOf("}") != -1;

			if (braceDepth == 0 && !hasBrace && trimmed.length > 0)
			{
				if (trimmed.charAt(0) == "#" || trimmed.indexOf("//") == 0)
				{
					output.push(line);
					continue;
				}

				var assignRegex = ~/^(\w+)\s*=\s*([^;]+);\s*$/;
				if (assignRegex.match(trimmed))
				{
					var name = assignRegex.matched(1);
					var value = assignRegex.matched(2);

					if (globalVars.exists(name))
					{
						var type = globalVars.get(name);
						var convertedValue = value;
						if (floatTypes.indexOf(type) != -1)
						{
							convertedValue = convertIntLiteralSafe(value);
						}
						movedAssignments.push('$name = $convertedValue;');
						continue;
					}
				}
			}

			output.push(line);
		}

		if (movedAssignments.length == 0)
			return output.join("\n");

		var result = output.join("\n");
		var injection = "\n    " + movedAssignments.join("\n    ");

		var mainRegex = ~/void\s+(?:main|mainImage)\s*\([^)]*\)\s*\{/g;
		if (mainRegex.match(result))
		{
			var matched = mainRegex.matched(0);
			result = mainRegex.replace(result, matched + injection + "\n");
		}
		else
		{
			MobileLog.warn("GLES2ShaderConverter: fixGlobalScopeAssignments - main()/mainImage() not found");
			result += "\n" + movedAssignments.join("\n") + "\n";
		}

		return result;
	}

	static function convertWhileLoops(content:String):String
	{
		var result = content;
		var counter = 0;
		var maxPasses = 50;

		while (maxPasses-- > 0)
		{
			var whilePos = findKeyword(result, "while", 0);
			if (whilePos == -1)
				break;

			var parenStart = findNextChar(result, whilePos + 5, "(");
			if (parenStart == -1)
				break;

			var parenEnd = findMatching(result, parenStart, "(", ")");
			if (parenEnd == -1)
				break;

			var condition = result.substr(parenStart + 1, parenEnd - parenStart - 1);

			var braceStart = findNextChar(result, parenEnd + 1, "{");
			if (braceStart == -1)
				break;

			var braceEnd = findMatching(result, braceStart, "{", "}");
			if (braceEnd == -1)
				break;

			var body = result.substr(braceStart + 1, braceEnd - braceStart - 1);

			var loopVar = '_gles2_w$counter';
			counter++;

			var converted = 'for(int $loopVar = 0; $loopVar < $MAX_LOOP_ITERATIONS; $loopVar++)\n{\nif(!($condition)) break;\n$body\n}';

			result = result.substr(0, whilePos) + converted + result.substr(braceEnd + 1);
		}

		return result;
	}

	static function convertTextureCalls(content:String):String
	{
		if (content.indexOf("#define texture") != -1)
			return content;

		var regex = ~/texture\s*\(/g;
		return regex.replace(content, "texture2D(");
	}

	static function convertFloatForLoops(content:String):String
	{
		var regex = ~/for\s*\(\s*float\s+(\w+)\s*=\s*(\d+\.?\d*)\s*;\s*\1\s*(<=?|>=?)\s*(\d+\.?\d*)\s*;\s*\1\s*\+=\s*(\d+\.?\d*)\s*\)/g;

		return regex.map(content, function(ereg:EReg):String
		{
			var name = ereg.matched(1);
			var startVal = parseNumber(ereg.matched(2));
			var endVal = parseNumber(ereg.matched(4));
			var stepVal = parseNumber(ereg.matched(5));

			if (stepVal == 0)
				return ereg.matched(0);

			if (startVal == 0 && stepVal == 1.0)
			{
				var iterations = Math.floor(endVal / stepVal);
				if (iterations <= 0)
					iterations = 1;
				return 'for(int $name = 0; $name < $iterations; $name++)';
			}

			return ereg.matched(0);
		});
	}

	static function convertFragmentOutput(content:String):String
	{
		var outVarNames:Array<String> = [];
		var outDeclRegex = ~/out\s+\w+\s+(\w+)\s*;/g;
		var result = outDeclRegex.map(content, function(ereg:EReg):String
		{
			var name = ereg.matched(1);
			if (name != "gl_FragColor" && outVarNames.indexOf(name) == -1)
				outVarNames.push(name);
			return "";
		});

		for (name in outVarNames)
		{
			var assignRegex = new EReg("\\b" + name + "\\s*=", "g");
			result = assignRegex.replace(result, "gl_FragColor =");
		}

		return result;
	}

	static function convertIntLiteralsToFloat(content:String):String
	{
		var result = content;

		var ctorRegex = ~/\b(vec[234]|mat[234]|float)\s*\(([^)]*)\)/g;
		result = ctorRegex.map(result, function(ereg:EReg):String
		{
			var type = ereg.matched(1);
			var args = ereg.matched(2);
			var convertedArgs = convertIntLiteralsInExpression(args);
			return '$type($convertedArgs)';
		});

		var declAssignRegex = ~/\b(float|vec[234]|mat[234])\s+(\w+)\s*=\s*([^;]+);/g;
		result = declAssignRegex.map(result, function(ereg:EReg):String
		{
			var type = ereg.matched(1);
			var name = ereg.matched(2);
			var expr = ereg.matched(3);
			if (expr.indexOf("==") != -1 || expr.indexOf("!=") != -1
				|| expr.indexOf("<=") != -1 || expr.indexOf(">=") != -1)
				return ereg.matched(0);
			var convertedExpr = convertIntLiteralSafe(expr);
			return '$type $name = $convertedExpr;';
		});

		var floatVarNames = new Map<String, Bool>();
		var scanRegex = ~/\b(float|vec[234]|mat[234])\s+(\w+)/g;
		var scanContent = result;
		while (scanRegex.match(scanContent))
		{
			var name = scanRegex.matched(2);
			if (name != "main" && !isReservedKeyword(name))
				floatVarNames.set(name, true);
			var matchPos = scanRegex.matchedPos();
			scanContent = scanContent.substr(matchPos.pos + matchPos.len);
		}

		for (varName in floatVarNames.keys())
		{
			var name = varName;
			var assignPattern = "(^|[^\\w])" + varName + "\\s*=(?!=)\\s*([^;]+);";
			var assignRegex = new EReg(assignPattern, "g");
			result = assignRegex.map(result, function(ereg:EReg):String
			{
				var prefix = ereg.matched(1);
				var expr = ereg.matched(2);
				var convertedExpr = convertIntLiteralSafe(expr);
				return '$prefix$name = $convertedExpr;';
			});
		}

		for (varName in floatVarNames.keys())
		{
			var name = varName;
			var cmpPattern = "(^|[^\\w])" + varName + "\\s*(==|!=|<=|>=|<|>)\\s*(\\d+)([^\\d.])";
			var cmpRegex = new EReg(cmpPattern, "g");
			result = cmpRegex.map(result, function(ereg:EReg):String
			{
				var prefix = ereg.matched(1);
				var op = ereg.matched(2);
				var num = ereg.matched(3);
				var after = ereg.matched(4);
				return '$prefix$name $op $num.0$after';
			});

			var revCmpPattern = "(^|[^\\w.])(\\d+)\\s*(==|!=|<=|>=|<|>)\\s*" + varName + "([^\\w])";
			var revCmpRegex = new EReg(revCmpPattern, "g");
			result = revCmpRegex.map(result, function(ereg:EReg):String
			{
				var prefix = ereg.matched(1);
				var num = ereg.matched(2);
				var op = ereg.matched(3);
				var after = ereg.matched(4);
				return '$prefix$num.0 $op $name$after';
			});
		}

		return result;
	}

	static function convertIntLiteralSafe(expr:String):String
	{
		if (expr == null || expr.length == 0)
			return expr;

		var result = new StringBuf();
		var i = 0;
		var len = expr.length;

		while (i < len)
		{
			var ch = expr.charAt(i);

			if ((ch >= "a" && ch <= "z") || (ch >= "A" && ch <= "Z") || ch == "_")
			{
				var start = i;
				while (i < len)
				{
					var c = expr.charAt(i);
					if ((c >= "a" && c <= "z") || (c >= "A" && c <= "Z")
						|| (c >= "0" && c <= "9") || c == "_")
						i++;
					else
						break;
				}
				result.add(expr.substr(start, i - start));
				continue;
			}

			if (ch >= "0" && ch <= "9")
			{
				var start = i;

				if (ch == "0" && i + 1 < len
					&& (expr.charAt(i + 1) == "x" || expr.charAt(i + 1) == "X"))
				{
					i += 2;
					while (i < len && isHexDigit(expr.charAt(i))) i++;
					result.add(expr.substr(start, i - start));
					continue;
				}

				var hasDot = false;
				var hasExp = false;

				while (i < len && isDigit(expr.charAt(i))) i++;

				if (i < len && expr.charAt(i) == ".")
				{
					hasDot = true;
					i++;
					while (i < len && isDigit(expr.charAt(i))) i++;
				}

				if (i < len && (expr.charAt(i) == "e" || expr.charAt(i) == "E"))
				{
					hasExp = true;
					i++;
					if (i < len && (expr.charAt(i) == "+" || expr.charAt(i) == "-")) i++;
					while (i < len && isDigit(expr.charAt(i))) i++;
				}

				if (i < len && (expr.charAt(i) == "f" || expr.charAt(i) == "F"))
				{
					i++;
				}

				var numStr = expr.substr(start, i - start);

				var prevIdx = start - 1;
				while (prevIdx >= 0 && isWhitespace(expr.charAt(prevIdx))) prevIdx--;
				var isArrayIndex = prevIdx >= 0 && expr.charAt(prevIdx) == "[";

				if (!hasDot && !hasExp && !isArrayIndex)
				{
					result.add(numStr + ".0");
				}
				else
				{
					result.add(numStr);
				}
				continue;
			}

			result.add(ch);
			i++;
		}

		return result.toString();
	}

	static function convertAllIntLiteralsInExpr(expr:String):String
	{
		var result = new StringBuf();
		var i = 0;
		var len = expr.length;
		while (i < len)
		{
			var ch = expr.charAt(i);

			if (isIdentStart(ch))
			{
				var start = i;
				while (i < len && isAlphaIdent(expr.charAt(i))) i++;
				result.add(expr.substr(start, i - start));
				continue;
			}

			if (isDigit(ch))
			{
				var start = i;

				if (ch == "0" && i + 1 < len && (expr.charAt(i + 1) == "x" || expr.charAt(i + 1) == "X"))
				{
					i += 2;
					while (i < len && isHexDigit(expr.charAt(i))) i++;
					result.add(expr.substr(start, i - start));
					continue;
				}

				var hasDot = false;
				var hasExp = false;
				while (i < len && isDigit(expr.charAt(i))) i++;
				if (i < len && expr.charAt(i) == ".")
				{
					hasDot = true;
					i++;
					while (i < len && isDigit(expr.charAt(i))) i++;
				}
				if (i < len && (expr.charAt(i) == "e" || expr.charAt(i) == "E"))
				{
					hasExp = true;
					i++;
					if (i < len && (expr.charAt(i) == "+" || expr.charAt(i) == "-")) i++;
					while (i < len && isDigit(expr.charAt(i))) i++;
				}
				if (i < len && (expr.charAt(i) == "f" || expr.charAt(i) == "F")) i++;

				var numStr = expr.substr(start, i - start);
				var prevIdx = start - 1;
				while (prevIdx >= 0 && isWhitespace(expr.charAt(prevIdx))) prevIdx--;
				var isArrayIndex = prevIdx >= 0 && expr.charAt(prevIdx) == "[";

				if (!hasDot && !hasExp && !isArrayIndex)
				{
					var pureIntRegex = ~/^\d+$/;
					var checkStr = numStr;
					if (pureIntRegex.match(checkStr))
						result.add(numStr + ".0");
					else
						result.add(numStr);
				}
				else
				{
					result.add(numStr);
				}
				continue;
			}

			result.add(ch);
			i++;
		}

		return result.toString();
	}

	static function isReservedKeyword(s:String):Bool
	{
		var keywords = ["attribute", "const", "uniform", "varying", "break", "continue",
			"do", "for", "while", "if", "else", "in", "out", "return", "void", "true",
			"false", "bool", "int", "uint", "float", "double", "vec2", "vec3", "vec4",
			"mat2", "mat3", "mat4", "sampler2D", "samplerCube", "struct", "precision",
			"highp", "mediump", "lowp", "discard", "main"];
		return keywords.indexOf(s) != -1;
	}

	static function convertIntLiteralsInExpression(expr:String):String
	{
		var parts = splitTopLevelArgs(expr);
		var result:Array<String> = [];
		for (part in parts)
		{
			var trimmed = StringTools.trim(part);
			var intRegex = ~/^-?\d+$/;
			if (intRegex.match(trimmed) && trimmed.indexOf(".") == -1)
			{
				result.push(trimmed + ".0");
			}
			else
			{
				result.push(part);
			}
		}
		return parts.length > 0 ? joinArgs(parts, result) : expr;
	}

	static function splitTopLevelArgs(expr:String):Array<String>
	{
		var args:Array<String> = [];
		var depth = 0;
		var start = 0;
		for (i in 0...expr.length)
		{
			var ch = expr.charAt(i);
			if (ch == "(") depth++;
			else if (ch == ")") depth--;
			else if (ch == "," && depth == 0)
			{
				args.push(expr.substr(start, i - start));
				start = i + 1;
			}
		}
		args.push(expr.substr(start));
		return args;
	}

	static function joinArgs(original:Array<String>, converted:Array<String>):String
	{
		return converted.join(",");
	}

	static function convertIntInFloatAssignment(line:String):String
	{
		var floatDeclRegex = ~/\bfloat\s+\w+\s*=\s*([^;]+);/;
		if (floatDeclRegex.match(line))
		{
			var expr = floatDeclRegex.matched(1);
			var convertedExpr = convertIntLiteralsInArithmeticExpr(expr);
			return StringTools.replace(line, expr, convertedExpr);
		}

		var assignRegex = ~/(\w+)\s*=\s*([^;]+);/;
		if (assignRegex.match(line))
		{
			var expr = assignRegex.matched(2);
			if (expr.indexOf(".") != -1 || expr.indexOf("float(") != -1)
			{
				var convertedExpr = convertIntLiteralsInArithmeticExpr(expr);
				return StringTools.replace(line, expr, convertedExpr);
			}
		}

		return line;
	}

	static function convertIntLiteralsInArithmeticExpr(expr:String):String
	{
		if (expr.indexOf(".") == -1 && expr.toLowerCase().indexOf("float(") == -1
			&& expr.indexOf("vec") == -1 && expr.indexOf("sin") == -1
			&& expr.indexOf("cos") == -1 && expr.indexOf("tan") == -1
			&& expr.indexOf("sqrt") == -1 && expr.indexOf("pow") == -1
			&& expr.indexOf("abs") == -1 && expr.indexOf("min") == -1
			&& expr.indexOf("max") == -1 && expr.indexOf("mix") == -1
			&& expr.indexOf("length") == -1 && expr.indexOf("normalize") == -1)
			return expr;

		var result = new StringBuf();
		var i = 0;
		var len = expr.length;
		while (i < len)
		{
			var ch = expr.charAt(i);

			if (isIdentStart(ch))
			{
				var start = i;
				while (i < len && isAlphaIdent(expr.charAt(i))) i++;
				result.add(expr.substr(start, i - start));
				continue;
			}

			if (isDigit(ch))
			{
				var start = i;
				if (ch == "0" && i + 1 < len && (expr.charAt(i + 1) == "x" || expr.charAt(i + 1) == "X"))
				{
					i += 2;
					while (i < len && isHexDigit(expr.charAt(i))) i++;
					result.add(expr.substr(start, i - start));
					continue;
				}

				var hasDot = false;
				var hasExp = false;
				while (i < len && isDigit(expr.charAt(i))) i++;
				if (i < len && expr.charAt(i) == ".")
				{
					hasDot = true;
					i++;
					while (i < len && isDigit(expr.charAt(i))) i++;
				}
				if (i < len && (expr.charAt(i) == "e" || expr.charAt(i) == "E"))
				{
					hasExp = true;
					i++;
					if (i < len && (expr.charAt(i) == "+" || expr.charAt(i) == "-")) i++;
					while (i < len && isDigit(expr.charAt(i))) i++;
				}
				if (i < len && (expr.charAt(i) == "f" || expr.charAt(i) == "F")) i++;

				var numStr = expr.substr(start, i - start);
				if (!hasDot && !hasExp)
				{
					var pureIntRegex = ~/^\d+$/;
					if (pureIntRegex.match(numStr))
						result.add(numStr + ".0");
					else
						result.add(numStr);
				}
				else
				{
					result.add(numStr);
				}
				continue;
			}

			result.add(ch);
			i++;
		}

		return result.toString();
	}

	static function isDigit(ch:String):Bool
	{
		return ch >= "0" && ch <= "9";
	}

	static function isHexDigit(ch:String):Bool
	{
		return (ch >= "0" && ch <= "9") || (ch >= "a" && ch <= "f") || (ch >= "A" && ch <= "F");
	}

	static function isWhitespace(ch:String):Bool
	{
		return ch == " " || ch == "\t" || ch == "\n" || ch == "\r";
	}

	static function isIntDeclaration(content:String, prevIdx:Int):Bool
	{
		if (prevIdx < 0) return false;

		var idx = prevIdx;

		while (idx >= 0 && (content.charAt(idx) == "=" || content.charAt(idx) == "+" || content.charAt(idx) == "-" || content.charAt(idx) == "*" || content.charAt(idx) == "/" || content.charAt(idx) == "%")) idx--;
		while (idx >= 0 && isWhitespace(content.charAt(idx))) idx--;

		while (idx >= 0 && isAlphaIdent(content.charAt(idx))) idx--;

		while (idx >= 0 && isWhitespace(content.charAt(idx))) idx--;

		var typeEnd = idx + 1;
		var typeStart = typeEnd;
		while (typeStart > 0 && isAlphaIdent(content.charAt(typeStart - 1))) typeStart--;
		var typeName = content.substr(typeStart, typeEnd - typeStart);

		return typeName == "int" || typeName == "uint";
	}

	static function findKeyword(s:String, keyword:String, start:Int):Int
	{
		var pos = start;
		while (pos < s.length)
		{
			var idx = s.indexOf(keyword, pos);
			if (idx == -1)
				return -1;

			if (idx > 0 && isAlphaIdent(s.charAt(idx - 1)))
			{
				pos = idx + 1;
				continue;
			}

			var afterIdx = idx + keyword.length;
			if (afterIdx < s.length && isAlphaIdent(s.charAt(afterIdx)))
			{
				pos = idx + 1;
				continue;
			}

			return idx;
		}
		return -1;
	}

	static function findMatching(s:String, openPos:Int, openChar:String, closeChar:String):Int
	{
		var depth = 0;
		var i = openPos;
		while (i < s.length)
		{
			var ch = s.charAt(i);
			if (ch == openChar)
			{
				depth++;
			}
			else if (ch == closeChar)
			{
				depth--;
				if (depth == 0)
					return i;
			}
			i++;
		}
		return -1;
	}

	static function findNextChar(s:String, start:Int, target:String):Int
	{
		var i = start;
		while (i < s.length)
		{
			var ch = s.charAt(i);
			if (ch == target)
				return i;
			if (ch != " " && ch != "\t" && ch != "\n" && ch != "\r")
				return -1;
			i++;
		}
		return -1;
	}

	static function isAlphaIdent(ch:String):Bool
	{
		return (ch >= "a" && ch <= "z")
			|| (ch >= "A" && ch <= "Z")
			|| (ch >= "0" && ch <= "9")
			|| ch == "_";
	}

	static function isIdentStart(ch:String):Bool
	{
		return (ch >= "a" && ch <= "z")
			|| (ch >= "A" && ch <= "Z")
			|| ch == "_";
	}

	static function isConstantExpression(expr:String):Bool
	{
		var trimmed = StringTools.trim(expr);

		var commentIdx = trimmed.indexOf("//");
		if (commentIdx != -1)
			trimmed = trimmed.substr(0, commentIdx);
		trimmed = StringTools.trim(trimmed);

		if (trimmed.length == 0)
			return true;

		var constructors = ["vec2", "vec3", "vec4", "mat2", "mat3", "mat4",
			"ivec2", "ivec3", "ivec4", "bvec2", "bvec3", "bvec4",
			"float", "int", "bool", "true", "false"];
		for (c in constructors)
		{
			trimmed = StringTools.replace(trimmed, c, " ");
		}

		for (i in 0...trimmed.length)
		{
			var ch = trimmed.charAt(i);
			if (!((ch >= "0" && ch <= "9")
				|| ch == "." || ch == "+" || ch == "-"
				|| ch == "*" || ch == "/" || ch == "("
				|| ch == ")" || ch == "," || ch == " "
				|| ch == "\t"))
			{
				return false;
			}
		}
		return true;
	}

	static function isGlobalVarDecl(trimmed:String, types:String):Bool
	{
		if (trimmed.length == 0)
			return false;
		if (trimmed.charAt(0) == "#")
			return false;
		if (trimmed.indexOf("//") == 0)
			return false;

		var qualifiers = ["uniform", "const", "attribute", "varying", "void",
			"return", "if", "else", "for", "while", "do", "break", "continue",
			"discard", "struct", "precision", "in", "out", "inout"];
		for (q in qualifiers)
		{
			if (trimmed.indexOf(q) == 0)
			{
				var afterQ = q.length;
				if (afterQ >= trimmed.length)
					return false;
				if (!isAlphaIdent(trimmed.charAt(afterQ)))
					return false;
			}
		}

		var regex = new EReg("^\\s*" + types + "\\s+\\w+\\s*=", "");
		return regex.match(trimmed);
	}

	static function getLeadingWhitespace(line:String):String
	{
		var i = 0;
		while (i < line.length)
		{
			var ch = line.charAt(i);
			if (ch != " " && ch != "\t")
				break;
			i++;
		}
		return line.substr(0, i);
	}

	static function parseNumber(s:String):Float
	{
		return Std.parseFloat(s);
	}
}
