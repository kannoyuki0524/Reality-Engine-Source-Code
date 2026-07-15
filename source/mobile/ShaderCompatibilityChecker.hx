package mobile;

import flixel.addons.display.FlxRuntimeShader;
import openfl.display.Shader;
import openfl.display.ShaderInput;
import openfl.display.ShaderParameter;
import openfl.utils.Assets;
import haxe.Json;
import sys.FileSystem;
import sys.io.File;

/**
 * Shader Compatibility Checker
 * 
 * 运行时检测Shader的GLES 2.0兼容性，并提供自动修复功能
 */
class ShaderCompatibilityChecker
{
	/** 已检测的shader缓存 */
	static var checkedShaders:Map<String, Bool> = new Map<String, Bool>();
	
	/** 兼容性报告 */
	public static var compatibilityReport:Map<String, CompatibilityInfo> = new Map<String, CompatibilityInfo>();
	
	/** 兼容性信息结构 */
	public static function getCompatibilityInfo(shaderPath:String):CompatibilityInfo
	{
		if (!compatibilityReport.exists(shaderPath))
		{
			compatibilityReport.set(shaderPath, new CompatibilityInfo(shaderPath));
		}
		return compatibilityReport.get(shaderPath);
	}
	
	/**
	 * 检查shader的兼容性
	 * @param shader shader对象
	 * @param shaderPath shader文件路径
	 * @return 是否兼容
	 */
	public static function checkCompatibility(shader:Shader, shaderPath:String):Bool
	{
		if (checkedShaders.exists(shaderPath))
		{
			return getCompatibilityInfo(shaderPath).isCompatible;
		}
		
		var info = getCompatibilityInfo(shaderPath);
		var isCompatible = true;
		
		try
		{
			// 检查vertex shader
			if (shader.glVertexSource != null)
			{
				var issues = checkVertexShader(shader.glVertexSource);
				for (issue in issues)
				{
					info.addIssue("vertex", issue);
					isCompatible = false;
				}
			}

			// 检查fragment shader
			if (shader.glFragmentSource != null)
			{
				var issues = checkFragmentShader(shader.glFragmentSource);
				for (issue in issues)
				{
					info.addIssue("fragment", issue);
					isCompatible = false;
				}
			}
			
			info.isCompatible = isCompatible;
			info.checkedAt = Date.now();
		}
		catch (e:Dynamic)
		{
			info.addIssue("system", 'Error checking compatibility: $e');
			info.isCompatible = false;
		}
		
		checkedShaders.set(shaderPath, isCompatible);
		return isCompatible;
	}
	
	/**
	 * 尝试修复不兼容的shader
	 * @param shader shader对象
	 * @param shaderPath shader文件路径（仅用于日志，可为任意标识符）
	 * @return 修复后的shader，如果无法修复返回null
	 */
	public static function tryFixShader(shader:Shader, shaderPath:String):Null<Shader>
	{
		var info = getCompatibilityInfo(shaderPath);

		if (info.isCompatible)
		{
			return shader; // 已经兼容，不需要修复
		}

		try
		{
			// 直接对 shader 源代码应用 GLES 2.0 转换（不从文件读取）
			// runtime shader 的源代码已在 shader.glFragmentSource / shader.glVertexSource 中
			var changed:Bool = false;
			if (shader.glFragmentSource != null)
			{
				var converted = GLES2ShaderConverter.applyGLES2Conversions(shader.glFragmentSource, shaderPath);
				if (converted != shader.glFragmentSource)
				{
					#if mobile
					try {
						var debugPath = "/storage/emulated/0/Android/data/me.reality.engine/files/debug_fragment.txt";
						var debugFile = sys.io.File.write(debugPath);
						debugFile.writeString(converted);
						debugFile.close();
					} catch(e:Dynamic) {}
					#end
					shader.glFragmentSource = converted;
					changed = true;
				}
			}
			if (shader.glVertexSource != null)
			{
				var converted = GLES2ShaderConverter.applyGLES2Conversions(shader.glVertexSource, shaderPath);
				if (converted != shader.glVertexSource)
				{
					shader.glVertexSource = converted;
					changed = true;
				}
			}

			if (changed)
			{
				info.fixedAt = Date.now();
				info.isFixed = true;
				// 标记需要重新编译
				@:privateAccess shader.__glSourceDirty = true;
				return shader;
			}
		}
		catch (e:Dynamic)
		{
			info.addIssue("fix", 'Failed to fix shader: $e');
		}

		return null;
	}
	
	/**
	 * 检查vertex shader的兼容性
	 */
	static function checkVertexShader(vertexCode:String):Array<String>
	{
		var issues:Array<String> = [];
		
		// 检查版本号
		if (vertexCode.indexOf("#version 120") != -1 || vertexCode.indexOf("#version 150") != -1)
		{
			issues.push("Unsupported GLSL version");
		}
		
		// 检查是否使用了不支持的变量类型
		if (vertexCode.indexOf("in ") != -1)
		{
			issues.push("Using 'in' keyword (GLES 2.0 uses 'attribute')");
		}
		
		// 检查是否使用了不支持的函数
		if (vertexCode.indexOf("texture(") != -1)
		{
			issues.push("Using texture() function (should use texture2D())");
		}
		
		return issues;
	}
	
	/**
	 * 检查fragment shader的兼容性
	 */
	static function checkFragmentShader(fragmentCode:String):Array<String>
	{
		var issues:Array<String> = [];
		
		// 检查版本号
		if (fragmentCode.indexOf("#version 120") != -1 || fragmentCode.indexOf("#version 150") != -1)
		{
			issues.push("Unsupported GLSL version");
		}
		
		// 检查是否使用了不支持的函数
		var textureCalls = ~/texture\s*\(/g;
		if (textureCalls.match(fragmentCode))
		{
			issues.push("Using texture() function (should use texture2D())");
		}
		
		// 检查while循环
		var whileLoops = ~/while\s*\([^)]+\)/g;
		if (whileLoops.match(fragmentCode))
		{
			issues.push("Using while loop (may not be supported on GLES 2.0)");
		}
		
		// 检查float类型的for循环
		var floatForLoops = ~/for\s*\(\s*float\s+\w+\s*=/g;
		if (floatForLoops.match(fragmentCode))
		{
			issues.push("Using float type in for loop (should use int)");
		}
		
		// 检查uniform初始化
		var uniformInitializers = ~/uniform\s+\w+\s+\w+\s*=/g;
		if (uniformInitializers.match(fragmentCode))
		{
			issues.push("Uniform variable initialization not supported");
		}
		
		// 检查全局变量初始化
		var globalInitializers = ~/^[a-zA-Z_][a-zA-Z0-9_]*\s+[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*[^;]+;/gm;
		if (globalInitializers.match(fragmentCode))
		{
			issues.push("Global variable initialization may cause issues");
		}
		
		return issues;
	}
	
	/**
	 * 生成兼容性报告
	 */
	public static function generateReport():String
	{
		var report = "Shader Compatibility Report\n";
		report += "==========================\n\n";
		
		for (shaderPath in compatibilityReport.keys())
		{
			var info = compatibilityReport.get(shaderPath);
			report += 'Shader: $shaderPath\n';
			report += 'Status: ${info.isCompatible ? "Compatible" : "Not Compatible"}\n';
			
			if (info.isFixed)
			{
				report += "Fixed: ✓\n";
			}
			
			if (info.issues.length > 0)
			{
				report += "Issues:\n";
				for (issue in info.issues)
				{
					report += "  - $issue\n";
				}
			}
			
			report += "\n";
		}
		
		return report;
	}
	
	/**
	 * 清除缓存和报告
	 */
	public static function clear():Void
	{
		checkedShaders.clear();
		compatibilityReport.clear();
	}
}

/**
 * 兼容性信息
 */
class CompatibilityInfo
{
	public var shaderPath:String;
	public var isCompatible:Bool = true;
	public var isFixed:Bool = false;
	public var checkedAt:Date;
	public var fixedAt:Date;
	public var issues:Array<String> = [];
	
	public function new(shaderPath:String)
	{
		this.shaderPath = shaderPath;
		this.checkedAt = Date.now();
	}
	
	public function addIssue(type:String, issue:String):Void
	{
		issues.push('[$type] $issue');
		isCompatible = false;
	}
}