package;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.graphics.frames.FlxAtlasFrames;
import animate.FlxAnimateFrames;
import animate.FlxAnimate;
import animate.internal.RenderTexture;
import openfl.display3D.textures.TextureBase;
import funkin.graphics.framebuffer.FixedBitmapData;
import funkin.graphics.framebuffer.FunkinFilterRenderer;
import openfl.filters.BitmapFilter;
import flixel.tweens.FlxTween;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import openfl.display.BitmapData;
import flixel.math.FlxRect;
import flixel.math.FlxPoint;
import flixel.math.FlxMatrix;
import flixel.graphics.frames.FlxFrame;
import animate.internal.SymbolItem;
import flixel.system.FlxAssets.FlxGraphicAsset;
import animate.internal.elements.Element;
import animate.internal.elements.AtlasInstance;
import animate.internal.elements.SymbolInstance;
import flixel.util.FlxColor;
using StringTools;
/*
 *  I'm lazy lol, Most codes credits to nightmare vision!!!
 *  https://github.com/NMVTeam/NightmareVision/source/funkin/objects/FunkinSprite.hx
*/
@:nullSafety
@:access(animate.FlxAnimateController)
class FunkinSprite extends FlxAnimate
{
	/**
   * The filters array to be applied to the sprite.
   */
 	public var filters(default, set):Null<Array<BitmapFilter>> = null;


	var filterRenderer:FunkinFilterRenderer;
	var filtered:Bool = false;
	var filterOffsets:Array<Float> = [0, 0];
	/**
	 *	Animation offsets
	 * 
	 * applied through `playAnim`
	 */
	public final animOffsets:Map<String, Array<Float>> = [];
	
	/**
	 * The current sprite offset.
	 * 
	 * This offset is transformed by scale, angle and skew (whenever applicable) when drawing the sprite and is applied regardless of the current animation.
	 */
	public final spriteOffset:FlxPoint = FlxPoint.get();
	
	/**
	 * The current animation offset.
	 * 
	 * This offset is transformed by scale, angle and skew (whenever applicable) when drawing the sprite.
	 */
	public final animOffset:FlxPoint = FlxPoint.get();
	
	/**
	 * Base scale for sprite / animation offsets.
	 */
	public final baseScale:FlxPoint = FlxPoint.get(1, 1);
	
	/**
	 * If true, animation offsets will scale with the sprite.
	 */
	public var scalableOffsets:Bool = true;
	
	/**
	 * If true, animation offsets will rotate with the sprite.
	 */
	public var rotatableOffsets:Bool = true;
	
	/**
	 * If true, animation offsets will skew with the sprite.
	 */
	public var skewableOffsets:Bool = true;
	
	/**
	 * Corrects this sprite's animation offsets when it's flipped.
	 * 
	 * (incomplete saaave me saaave me)
	 */
	public var correctFlippedOffsets:Bool = false;
	
	/**
	 * If `false`, playAnim will no longer function
	 * 
	 * used by `playAnimForDuration`'s `force` arguement.
	 */
	public var canPlayAnimations:Bool = true;

	public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:FlxGraphicAsset, ?settings:FlxAnimateSettings)
	{
		super(x, y, simpleGraphic, settings);

		filterRenderer = new FunkinFilterRenderer(this);
	}
	
	/**
	 * @return A list of all the animations this sprite has available.
	 */
	public function listAnimations():Array<String>
	{
		var frameLabels:Array<String> = getFrameLabelList();
		var animationList:Array<String> = this.animation?.getNameList() ?? [];

		return frameLabels.concat(animationList);
	}

	/**
	 * TEXTURE ATLAS-EXCLUSIVE FUNCTIONS
	 * These functions only work if the sprite's texture is an Adobe Animate texture atlas.
	 * Calling these functions on non-texture atlases will do nothing.
	 */
	/**
	 * Gets a list of frame labels from the default timeline.
	 */
	public function getFrameLabelList():Array<String>
	{
		if (!this.anim.hasAnimateAtlas)
		{
		trace('WARNING: getFrameLabelList() only works on texture atlases!');
		return [];
		}

		var foundLabels:Array<String> = [];
		var mainTimeline:Null<animate.internal.Timeline> = this.library.timeline;

		for (layer in mainTimeline.layers)
		{
		@:nullSafety(Off)
		for (frame in layer.frames)
		{
			if (frame.name.rtrim() != '')
			{
			foundLabels.push(frame.name);
			}
		}
		}

		return foundLabels;
	}

	/**
	 * Gets a frame label by its name.
	 * @param name The name of the frame label to retrieve.
	 * @return The frame label, or null if it doesn't exist.
	 */
	public function getFrameLabel(name:String, ?timeline:animate.internal.Timeline):Null<animate.internal.Frame>
	{
		if (!this.anim.hasAnimateAtlas)
		{
		trace('WARNING: getFrameLabel() only works on texture atlases!');
		return null;
		}

		for (layer in (timeline ?? this.timeline).layers)
		{
		@:nullSafety(Off)
		for (frame in layer.frames)
		{
			if (frame.name == name)
			{
			return frame;
			}
		}
		}

		return null;
	}

	/**
	 * Returns the default symbol in the atlas.
	 */
	public function getDefaultSymbol():String
	{
		if (!this.anim.hasAnimateAtlas)
		{
		trace('WARNING: getDefaultSymbol() only works on texture atlases!');
		return '';
		}

		return library.timeline.name;
	}

	/**
	 * Replaces the graphic of a symbol in the atlas.
	 * @param symbol The symbol to replace.
	 * @param graphic The new graphic to use.
	 * @param adjustScale Whether to adjust the scale of new frame to match the old one.
	 */
	public function replaceSymbolGraphic(symbol:String, ?graphic:Null<FlxGraphicAsset>, ?adjustScale:Bool = true):Void
	{
		if (!this.anim.hasAnimateAtlas)
		{
		trace('WARNING: replaceSymbolGraphic() only works on texture atlases!');
		return;
		}

		var elements:Array<Element> = getSymbolElements(symbol);

		for (element in elements)
		{
		var atlasInstance:AtlasInstance = element.toAtlasInstance();
		var frame:Null<FlxFrame> = graphic != null ? FlxG.bitmap.add(graphic).imageFrame.frame : null;

		atlasInstance.replaceFrame(frame, adjustScale);
		element = atlasInstance;
		}
	}

	/**
	 * Returns the first element of a symbol in the atlas.
	 * @param symbol The symbol to get elements from.
	 * @return The first element of the symbol. WARNING: Can be null.
	 */
	public function getFirstElement(symbol:String):Null<Element>
	{
		if (!this.anim.hasAnimateAtlas)
		{
		trace('WARNING: getFirstElement() only works on texture atlases!');
		return null;
		}

		var symbolElements:Array<Element> = getSymbolElements(symbol);
		return symbolElements.length > 0 ? symbolElements[0] : null;
	}

	/**
	 * Returns the elements of a symbol in the atlas.
	 * @param symbol The symbol to get elements from.
	 */
	public function getSymbolElements(symbol:String):Array<Element>
	{
		if (!this.anim.hasAnimateAtlas)
		{
		trace('WARNING: getSymbolElements() only works on texture atlases!');
		return [];
		}

		var symbolInstance:Null<SymbolItem> = this.library.getSymbol(symbol);

		if (symbolInstance == null)
		{
		throw 'Symbol not found in atlas: ${symbol}';
		return [];
		}

		var elements:Array<Element> = symbolInstance.timeline.getElementsAtIndex(0);

		if (elements?.length == 0)
		{
		trace('WARNING: No Atlas Elements found for "$symbol" symbol.');
		}

		return elements ?? [];
	}

	/**
	 * Scales an element by a certain multiplier.
	 * @param element The element to scale.
	 * @param scale The scale multiplier.
	 * @param positionOffset The offset to apply to `tx` and `ty` after scaling.
	 * (Or in other words, the position of the element.)
	 */
	public function scaleElement(element:Element, scale:Float, positionOffset:Float = 0, scaleEverything:Bool = false):Void
	{
		if (!this.anim.hasAnimateAtlas)
		{
		trace('WARNING: scaleElement() only works on texture atlases!');
		return;
		}

		var elementMatrix:FlxMatrix = element.matrix;

		if (scaleEverything)
		{
		elementMatrix.scale(scale, scale);
		return;
		}

		var symbolInstance:SymbolInstance = element.parentFrame.convertToSymbol(0, 1);
		var transformPoint:FlxPoint = symbolInstance.transformationPoint;

		elementMatrix.a += scale;
		elementMatrix.d += scale;

		elementMatrix.tx -= transformPoint.x * scale;
		elementMatrix.ty -= transformPoint.y * scale;

		elementMatrix.tx -= positionOffset;
		elementMatrix.ty -= positionOffset;
	}

	/**
	 * Acts similarly to `makeGraphic`, but with improved memory usage,
	 * at the expense of not being able to paint onto the resulting sprite.
	 *
	 * @param width The target width of the sprite.
	 * @param height The target height of the sprite.
	 * @param color The color to fill the sprite with.
	 * @return This sprite, for chaining.
	 */
	public function makeSolidColor(width:Int, height:Int, color:FlxColor = FlxColor.WHITE):FunkinSprite
	{
		// Create a tiny solid color graphic and scale it up to the desired size.
		var graphic:FlxGraphic = FlxG.bitmap.create(2, 2, color, false, 'solid#${color.toHexString(true, false)}');
		frames = graphic.imageFrame;
		scale.set(width / 2.0, height / 2.0);
		updateHitbox();

		return this;
	}

	/**
	 * Create a new FunkinSprite with a static texture.
	 * @param x The starting X position.
	 * @param y The starting Y position.
	 * @param key The key of the texture to load.
	 * @return The new FunkinSprite.
	 */
	public static function create(x:Float = 0.0, y:Float = 0.0, key:String):FunkinSprite
	{
		var sprite:FunkinSprite = new FunkinSprite(x, y);
		sprite.loadAtlas(key);
		return sprite;
	}
	
	/**
	 * Loads frames onto the sprite
	 * 
	 * It can load multiple sparrow, packer, and texture atlases simultaneously.
	 * 
	 * This is the recommended way to load frames for a bopper
	 * @param path the image path to the frames. For multiple, split the path with `,` For texture atlas, Provide the path to the folder.
	 * 
	 * @return this `Bopper` instance. Useful for chaining
	 */
	public function loadAtlas(path:String):FunkinSprite
	{
		final splitPath = path.split(',');
		
		var framesFound:Array<FlxAtlasFrames> = [];
		
		var containsFlxAnimate:Bool = false;
		
		for (path in splitPath)
		{
			path = path.trim();
			
			final isAtlasSprite = Paths.exists(Paths.getPath('images/$path/Animation.json'));
			if (isAtlasSprite)
			{
				var atlas = FlxAnimateFrames.fromAnimate(Paths.getPath('images/$path'), null, null, null, false, {cacheOnLoad: true});
				if (atlas != null)
				{
					// unsure if flxanimate messes with the buffer or not but if it does then drop this
					if (ClientPrefs.cacheOnGPU && atlas.parent.bitmap != null) atlas.parent.bitmap.disposeImage();
					
					containsFlxAnimate = true;
					
					framesFound.push(atlas);
				}
			}
			else
			{
				var atlas = Paths.getAtlas(path);
				
				if (atlas != null) framesFound.push(atlas);
			}
		}
		
		if (framesFound.length != 0)
		{
			if (containsFlxAnimate) // a bit hacky workaround.. we cant keep use cached bitmaps in multi collection // look into this later
			{
				for (collection in framesFound)
				{
					if (Paths.currentTrackedAssets.exists(collection.parent.key))
					{
						Paths.currentTrackedAssets.remove(collection.parent.key);
					}
					
					collection.parent.persist = false;
				}
			}
			@:nullSafety(Off)
			this.frames = FlxAnimateFrames.combineAtlas(framesFound);
		}
		
		return this;
	}
	
	/**
	 * Ensures a anim exists before playing
	 * 
	 * If there is no anim but there is a suffix, it will strip the suffix and try again
	 * 
	 * If still fails, `Null` is returned.
	 */
	public function correctAnimationName(animName:String):Null<String> // from base game !
	{
		if (hasAnim(animName)) return animName;
		
		// strip any post fix
		if (animName.lastIndexOf('-') != -1)
		{
			final correctedName = animName.substring(0, animName.lastIndexOf('-'));
			return correctAnimationName(correctedName);
		}
		
		return null;
	}
	
	/**
	 * Use over `animation.play`
	 */
	@:inheritDoc(flixel.animation.FlxAnimationController.play)
	public function playAnim(animToPlay:String, isForced:Bool = false, isReversed:Bool = false, frame:Int = 0):Void
	{
		if (!canPlayAnimations) return;
		
		final correctedAnim = correctAnimationName(animToPlay);
		
		if (correctedAnim == null) return;
		
		animation.play(correctedAnim, isForced, isReversed, frame);
		
		setOffsets(correctedAnim);
	}

	public function setOffsets(anim:String = 'idle')
	{
		final animationOffsets = animOffsets.get(anim);
		
		if (animationOffsets != null)
		{
			animOffset.set(animationOffsets[0], animationOffsets[1]);
			
			if (correctFlippedOffsets)
			{
				final scaleXFactor:Float = scalableOffsets ? scale.x : 1.0;
				final scaleYFactor:Float = scalableOffsets ? scale.y : 1.0;
				
				if (flipX) animOffset.x = ((frameWidth * scaleXFactor) - width) - animOffset.x;
				
				if (flipY) animOffset.y = ((frameHeight * scaleYFactor) - height) - animOffset.y;
			}
		}
	}
	
	final forcedAnimationTimer:FlxTimer = new FlxTimer();
	
	/**
	 * Plays a animation for a given amount of time and will `dance` when it is done
	 * @param forced If true, the character will not play any other animation until the duration is complete
	 */
	public function playAnimForDuration(animToPlay:String, duration:Float = 0.6, forced:Bool = false)
	{
		if (forced) canPlayAnimations = true;
		playAnim(animToPlay, true);
		
		if (forced) canPlayAnimations = false;
		forcedAnimationTimer.start(duration, tmr -> {
			if (forced) canPlayAnimations = true;
			// dance();
		});
	}
	
	/**
	 * Helper function to quickly set an anim offset
	 */
	public function addOffset(anim:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets[anim] = [x, y];
	}
	
	/**
	 * Helper function add a animation by prefix. It will attempt to add by `frame label`, `symbol`, then `prefix`
	 */
	@:inheritDoc(flixel.animation.FlxAnimationController.addByPrefix)
	public function addAnimByPrefix(name:String, prefix:String, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (library != null && anim.findFrameLabelIndices(prefix).length > 0)
		{
			anim.addByFrameLabel(name, prefix, fps, looping, flipX, flipY);
		}
		else if (checkLibraryForSymbol(library, prefix))
		{
			anim.addBySymbol(name, prefix, fps, looping, flipX, flipY);
		}
		else
		{
			animation.addByPrefix(name, prefix, fps, looping, flipX, flipY);
		}
	}
	
	/**
	 * Helper function add a animation by indices. It will attempt to add by `frame label`, `symbol`, then `prefix`
	 */
	@:inheritDoc(flixel.animation.FlxAnimationController.addByIndices)
	public function addAnimByIndices(name:String, prefix:String, indices:Array<Int>, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (library != null && anim.findFrameLabelIndices(prefix).length > 0)
		{
			anim.addByFrameLabelIndices(name, prefix, indices, fps, looping, flipX, flipY);
		}
		else if (checkLibraryForSymbol(library, prefix))
		{
			anim.addBySymbolIndices(name, prefix, indices, fps, looping, flipX, flipY);
		}
		else
		{
			animation.addByIndices(name, prefix, indices, '', fps, looping, flipX, flipY);
		}
	}
	
	@:access(animate.FlxAnimateFrames)
	static function checkLibraryForSymbol(atlasLibrary:FlxAnimateFrames, symbolName:String) // exists symbol doesnt check additional collections so heres my workaround.
	{
		if (atlasLibrary == null) return false;
		
		if (atlasLibrary.existsSymbol(symbolName)) return true;
		
		for (collection in atlasLibrary.addedCollections)
		{
			if (collection.dictionary.exists(symbolName)) return true;
		}
		
		return false;
	}
	
	// these funcs primarily exist for compat reasons
	
	public inline function getAnimName():String return isAnimNull() ? '' : animation.curAnim.name;
	
	public inline function hasAnim(anim:String):Bool return animation.exists(anim);
	
	public inline function isAnimNull():Bool return animation.curAnim == null;
	
	public inline function isAnimFinished():Bool return isAnimNull() ? false : animation.curAnim.finished;
	
	public inline function pauseAnim():Void animation.pause();
	
	public inline function resumeAnim():Void animation.resume();
	
	public inline function getAnimNumFrames():Int return isAnimNull() ? 0 : animation.curAnim.numFrames;
	
	public var animCurFrame(get, set):Int;
	
	inline function get_animCurFrame():Int return isAnimNull() ? 0 : animation.curAnim.curFrame;
	
	inline function set_animCurFrame(value:Int):Int return isAnimNull() ? 0 : (animation.curAnim.curFrame = value);
	
	public inline function removeAnim(anim:String):Void
	{
		animation.remove(anim);
		animOffsets.remove(anim);
	}
	
	public inline function finishAnim():Void
	{
		if (isAnimNull()) return;
		
		animation.finish();
	}
	
	public inline function stopAnim():Void
	{
		if (isAnimNull()) return;
		
		animation.stop();
	}
	
	public override function destroy():Void
	{
		_transformedAnimOffset.put();
		spriteOffset.put();
		animOffset.put();
		filterRenderer.destroy();
    	FlxTween.cancelTweensOf(this);
		super.destroy();
	}
	
	var _transformedAnimOffset:FlxPoint = FlxPoint.get();
	
	override function checkRenderTexture():Bool
	{
		// Forcefully enable render texture when we have filters.
		if (filters != null && filters.length > 0) return true;

		return super.checkRenderTexture();
	}

	function set_filters(value:Null<Array<BitmapFilter>>):Null<Array<BitmapFilter>>
	{
		if (filters != value) _renderTextureDirty = true;
		filters = value;
		return value;
	}

	override public function draw():Void
	{
		for (filter in filters ?? [])
		{
		@:privateAccess
		if (filter.__renderDirty) _renderTextureDirty = true;
		}

		super.draw();
	}

	#if (flixel >= "6.1.0")
	override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
	#else
	override function drawComplex(camera:FlxCamera):Void
	#end
	{
		#if (flixel < "6.1.0") final frame = this._frame; #end
		final willUseRenderTexture = checkRenderTexture();
		final matrix = this._matrix;

		frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		prepareDrawMatrix(matrix, camera);

		if (willUseRenderTexture)
		{
			var bounds:Array<Int> = [Math.ceil(frame.frame.width), Math.ceil(frame.frame.height)];
			if (_renderTexture == null) _renderTexture = new RenderTexture(bounds[0], bounds[1]);

			if (_renderTextureDirty)
			{
				_renderTexture.init(bounds[0], bounds[1]);
				_renderTexture.drawToCamera((camera, mat) ->
				{
				camera.drawPixels(frame, framePixels, mat, null, null, antialiasing, null);
				});

				_renderTexture.render();

				filterRenderer.applyFilters();
				_renderTextureDirty = false;
			}

			if (filtered)
			{
				matrix.translate(filterOffsets[0], filterOffsets[1]);
				camera.drawPixels(filterRenderer.graphic?.imageFrame.frame, null, matrix, colorTransform, blend, antialiasing, shader);
			}
			else
			{
				camera.drawPixels(_renderTexture.graphic.imageFrame.frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
			}
		}
		else
		{
		camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
		}
	}

	override function prepareDrawMatrix(matrix:flixel.math.FlxMatrix, camera:FlxCamera):Void
	{
		super.prepareDrawMatrix(matrix, camera);
		
		transformSpriteOffset(_transformedAnimOffset);
		if (isPixelPerfectRender(camera)) _transformedAnimOffset.floor();
		
		matrix.translate(-_transformedAnimOffset.x, -_transformedAnimOffset.y);
	}
	
	override function drawAnimate(camera:FlxCamera):Void
	{
		final willUseRenderTexture = checkRenderTexture();
		final matrix = _matrix;
		matrix.identity();

		@:privateAccess
		var bounds = timeline._bounds;
		if (!willUseRenderTexture) matrix.translate(-bounds.x, -bounds.y);

		prepareAnimateMatrix(matrix, camera, bounds);

		if (renderStage) drawStage(camera);

		timeline.currentFrame = animation.frameIndex;

		#if !flash
		if (willUseRenderTexture)
		{
		if (_renderTexture == null) _renderTexture = new RenderTexture(Math.ceil(bounds.width), Math.ceil(bounds.height));

		if (_renderTextureDirty)
		{
			_renderTexture.init(Math.ceil(bounds.width), Math.ceil(bounds.height));
			_renderTexture.drawToCamera((camera, matrix) ->
			{
			matrix.translate(-bounds.x, -bounds.y);
			timeline.draw(camera, matrix, null, null, antialiasing, null);
			});
			_renderTexture.render();

			filterRenderer.applyFilters();
			_renderTextureDirty = false;
		}

		if (filtered)
		{
			matrix.translate(filterOffsets[0], filterOffsets[1]);
			camera.drawPixels(filterRenderer.graphic?.imageFrame.frame, null, matrix, colorTransform, blend, antialiasing, shader);
		}
		else
		{
			camera.drawPixels(_renderTexture.graphic.imageFrame.frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
		}
		}
		else
		#end
		{
		timeline.draw(camera, matrix, colorTransform, blend, antialiasing, shader);
		}
  	}

	inline function transformSpriteOffset(?point:FlxPoint):FlxPoint
	{
		point ??= FlxPoint.weak();
		
		point.set(spriteOffset.x + animOffset.x, spriteOffset.y + animOffset.y);
		
		if (scalableOffsets) point.scale(scale.x / baseScale.x, scale.y / baseScale.y);
		
		if (rotatableOffsets && FlxMath.mod(angle, 360) > 0) point.rotateByDegrees(angle);
		
		if (skewableOffsets && (skew.x != 0 || skew.y != 0))
		{
			final pX:Float = point.x, pY:Float = point.y;
			
			point.x += (pY * Math.tan(skew.x / 180 * Math.PI));
			point.y += (pX * Math.tan(skew.y / 180 * Math.PI));
		}
		
		return point;
	}
	
	override function clone():FunkinSprite
	{
		final spr = new FunkinSprite();
		
		spr.frames = this.frames;
		spr.animation.copyFrom(this.animation);
		
		for (key in this.animOffsets.keys())
		{
			var offsets = this.animOffsets.get(key);
			@:nullSafety(Off)
			spr.animOffsets.set(key, offsets);
		}
		
		spr.spriteOffset.copyFrom(this.spriteOffset);
		spr.baseScale.copyFrom(this.baseScale);
		spr.scale.copyFrom(this.scale);
		spr.updateHitbox();
		
		return spr;
	}
}
