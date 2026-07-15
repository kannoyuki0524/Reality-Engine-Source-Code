package mobile;

import flixel.addons.display.FlxRuntimeShader;
import sys.io.File;
import sys.FileSystem;
import haxe.io.Path;
import MobileLog;

/**
 * Shader Preprocessor
 * 
 * 在游戏启动时自动处理所有shader文件，确保GLES 2.0兼容性
 */
class ShaderPreprocessor
{
	/** 已处理的shader缓存文件路径 */
	static var cacheFilePath:String = "shader_conversion_cache.json";
	
	/** 处理统计 */
	public static var stats: {
		totalFiles:Int,
		convertedFiles:Int,
		failedFiles:Int,
		skippedFiles:Int
	};
	
	static function __init__():Void
	{
		stats = {
			totalFiles: 0,
			convertedFiles: 0,
			failedFiles: 0,
			skippedFiles: 0
		};
	}
	
	/**
	 * 预处理所有shader文件
	 * @param shaderDirs 要处理的shader目录数组
	 * @return 是否成功处理
	 */
	public static function preprocessAll(shaderDirs:Array<String>):Bool
	{
		MobileLog.info("ShaderPreprocessor: Starting shader preprocessing...");
		
		// 加载缓存
		var cache = loadCache();
		
		// 重置统计
		stats = {
			totalFiles: 0,
			convertedFiles: 0,
			failedFiles: 0,
			skippedFiles: 0
		};
		
		// 处理每个目录
		for (dir in shaderDirs)
		{
			processDirectory(dir, cache);
		}
		
		// 保存缓存
		saveCache(cache);
		
		// 输出统计信息
		MobileLog.info("ShaderPreprocessor: Processing completed:");
		MobileLog.info("  Total files: ${stats.totalFiles}");
		MobileLog.info("  Converted files: ${stats.convertedFiles}");
		MobileLog.info("  Failed files: ${stats.failedFiles}");
		MobileLog.info("  Skipped files: ${stats.skippedFiles}");
		
		return stats.failedFiles == 0;
	}
	
	/**
	 * 处理单个目录
	 */
	static function processDirectory(dir:String, cache:Map<String, String>):Void
	{
		if (!FileSystem.exists(dir))
		{
			MobileLog.warning('ShaderPreprocessor: Directory not found: $dir');
			return;
		}
		
		MobileLog.info('ShaderPreprocessor: Processing directory: $dir');
		
		try
		{
			var files = FileSystem.readDirectory(dir);
			
			for (file in files)
			{
				var filePath = Path.join([dir, file]);
				
				if (FileSystem.isDirectory(filePath))
				{
					// 递归处理子目录
					processDirectory(filePath, cache);
				}
				else if (file.endsWith(".frag") || file.endsWith(".vert"))
				{
					// 处理shader文件
					processShaderFile(filePath, cache);
					stats.totalFiles++;
				}
			}
		}
		catch (e:Dynamic)
		{
			MobileLog.error('ShaderPreprocessor: Error processing directory $dir: $e');
		}
	}
	
	/**
	 * 处理单个shader文件
	 */
	static function processShaderFile(filePath:String, cache:Map<String, String>):Void
	{
		try
		{
			// 检查文件是否需要处理
			var fileModTime = FileSystem.stat(filePath).mtime.getTime();
			var cachedModTime = cache.exists(filePath) ? Std.parseInt(cache.get(filePath)) : 0;
			
			// 如果文件未修改，跳过处理
			if (fileModTime <= cachedModTime)
			{
				stats.skippedFiles++;
				MobileLog.debug('ShaderPreprocessor: Skipping unchanged file: $filePath');
				return;
			}
			
			// 读取文件内容
			var content = File.getContent(filePath);
			
			// 应用GLES 2.0转换
			var converted = GLES2ShaderConverter.applyGLES2Conversions(content, filePath);
			
			// 如果内容有变化，保存文件
			if (converted != content)
			{
				File.saveContent(filePath, converted);
				stats.convertedFiles++;
				MobileLog.info('ShaderPreprocessor: Converted shader: $filePath');
			}
			else
			{
				stats.skippedFiles++;
				MobileLog.debug('ShaderPreprocessor: No conversion needed: $filePath');
			}
			
			// 更新缓存
			cache.set(filePath, Std.string(fileModTime));
		}
		catch (e:Dynamic)
		{
			stats.failedFiles++;
			MobileLog.error('ShaderPreprocessor: Failed to process $filePath: $e');
		}
	}
	
	/**
	 * 加载缓存文件
	 */
	static function loadCache():Map<String, String>
	{
		try
		{
			if (FileSystem.exists(cacheFilePath))
			{
				var content = File.getContent(cacheFilePath);
				var data = Json.parse(content);
				return cast data;
			}
		}
		catch (e:Dynamic)
		{
			MobileLog.warning('ShaderPreprocessor: Failed to load cache: $e');
		}
		
		return new Map<String, String>();
	}
	
	/**
	 * 保存缓存文件
	 */
	static function saveCache(cache:Map<String, String>):Void
	{
		try
		{
			var data = [];
			for (key in cache.keys())
			{
				data.push({key: key, value: cache.get(key)});
			}
			
			var content = Json.stringify(data);
			File.saveContent(cacheFilePath, content);
		}
		catch (e:Dynamic)
		{
			MobileLog.error('ShaderPreprocessor: Failed to save cache: $e');
		}
	}
	
	/**
	 * 清除缓存
	 */
	public static function clearCache():Void
	{
		try
		{
			if (FileSystem.exists(cacheFilePath))
			{
				FileSystem.deleteFile(cacheFilePath);
				MobileLog.info('ShaderPreprocessor: Cache cleared');
			}
		}
		catch (e:Dynamic)
		{
			MobileLog.error('ShaderPreprocessor: Failed to clear cache: $e');
		}
	}
	
	/**
	 * 获取处理统计信息
	 */
	public static function getStats():Dynamic
	{
		return stats;
	}
}