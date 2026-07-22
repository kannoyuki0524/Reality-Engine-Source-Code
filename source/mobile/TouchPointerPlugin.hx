package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.touch.FlxTouch;
import flixel.math.FlxAngle;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.input.FlxPointer;
import flixel.util.FlxTimer;

// TODO: Replace all the touchBuddy littered around the game's code with the ACTUAL touchBuddy.
// Thnk u agua and toffee <3

/**
 * @author moondroidcoder
 * Tracks your touch points in your game.
 */
class TouchPointerPlugin extends FlxTypedSpriteGroup<TouchPointer>
{
  /**
   * Whether the plugin is enabled.
   */
  public static var enabled(default, set):Bool = true;

  /**
   * A singleton instance of the plugin.
   */
  public static var instance:TouchPointerPlugin = null;

  /**
   * A camera dedicated to displaying the pointers.
   */
  public static var pointerCamera:FunkinCamera;

  public function new()
  {
    super();
  }

  /**
   * Initializes the TouchPointerPlugin by creating a new camera and setting it up to be drawn on top of other elements.
   */
  public static function initialize():Void
  {
    pointerCamera = new FunkinCamera();
    pointerCamera.bgColor.alpha = 0;
    instance = new TouchPointerPlugin();
    instance.cameras = [pointerCamera];

    FlxG.cameras.add(pointerCamera, false);
    FlxG.plugins.drawOnTop = true;
    FlxG.plugins.addPlugin(instance);

    FlxG.cameras.cameraAdded.add(function(camera:FlxCamera)
    {
      var bro = cast camera;
      if (bro != pointerCamera && pointerCamera != null)
      {
        FlxG.cameras.remove(pointerCamera, false);
        FlxG.cameras.add(pointerCamera, false);
      }
    });

    FlxG.cameras.cameraRemoved.add(function(camera:FlxCamera)
    {
      var bro = cast camera;
      if (bro == pointerCamera)
      {
        if (!bro.exists) // The camera got destroyed, we make a new one!
        {
          instance.cameras = [pointerCamera = new FunkinCamera()];
          pointerCamera.bgColor.alpha = 0;
          pointerCamera.ID = FlxG.cameras.list.length - 1;
        }
      }
    });

    FlxG.signals.preStateSwitch.add(function()
    {
      //FlxG.mouse.visible = false;//FORCED LOL
      instance.removeAll(true);
    });

    FlxG.signals.postStateSwitch.add(function()
    {
      FlxG.cameras.add(pointerCamera, false);
      //FlxG.mouse.visible = false;//FORCED LOL
    });
  }

  public function CREATETOUCH(?toucher:FlxPointer){
      var IDS = 0;
      if (Std.isOfType(toucher, FlxTouch)){
        var touchh = cast toucher;
        IDS = touchh.touchPointID;
      }
    var pointer:TouchPointer = findPointerByTouchId(IDS);

      if (pointer == null)
      {
        pointer = recycle(TouchPointer);
        pointer.initialize(IDS);
        add(pointer);
      }

      pointer.updateFromTouch(toucher, pointerCamera);
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);
    FlxG.mouse.visible = false;//FORCED LOL
    for (touch in FlxG.touches.list)
    {
      if (touch == null) continue;

      if (touch.justPressed) removeAll(true);

      CREATETOUCH(touch);
    }
    #if desktop
    if (FlxG.mouse.pressed){
      if (FlxG.mouse.justPressed) {
        removeAll(true);
      }
      CREATETOUCH(FlxG.mouse);
    }
    #end
    for (pointer in members)
    {
      if (pointer == null || touchExists(pointer.touchId) #if desktop || FlxG.mouse.pressed #end) continue;
      if (pointer.touchId != -2)
      {
        pointer.alpha = 0.8;
        FlxTween.tween(pointer, {alpha: 0}, FlxG.random.float(0.6, 0.7), {
          ease: FlxEase.cubeIn,
          onComplete: function(_)
          {
            remove(pointer);
          }
        });
        pointer.touchId = -2;
      }
    }
  }

  /**
   * Finds a TouchPointer object in the members list by its touch ID.
   *
   * @param touchId The ID of the touch to find.
   * @return The TouchPointer object with the specified touch ID, or null if not found.
   */
  private function findPointerByTouchId(touchId:Int):TouchPointer
  {
    for (pointer in members)
    {
      if (pointer == null || pointer.touchId != touchId) continue;

      return pointer;
    }
    return null;
  }

  /**
   * Checks if a touch with the specified ID exists in the current touch list.
   *
   * @param touchId The ID of the touch to check for.
   * @return True if a touch with the specified ID exists, false otherwise.
   */
  private function touchExists(touchId:Int):Bool
  {
    for (touch in FlxG.touches.list)
    {
      if (touch.touchPointID != touchId) continue;

      return true;
    }
    return false;
  }

  @:noCompletion
  private static function set_enabled(value:Bool):Bool
  {
    if (instance != null)
    {
      instance.exists = instance.visible = instance.active = instance.alive = value;
    }

    return enabled = value;
  }

  public function removeAll(skipTween:Bool = false)
  {
    for (pointer in members)
    {
      if (pointer == null) continue;

      if (skipTween)
      {
        FlxTween.cancelTweensOf(pointer);
        remove(pointer);
        continue;
      }
      pointer.alpha = 0.8;
      FlxTween.tween(pointer, {alpha: 0}, FlxG.random.float(0.8, 1) * 0.5, {
        ease: FlxEase.quadIn,
        onComplete: function(_)
        {
          if (pointer != null)
          remove(pointer);
        }
      });
    }
  }
}

/**
 * Represents a touch pointer in the game.
 */
class TouchPointer extends FunkinSprite
{
  /**
   * Represents a touch pointer plugin.
   */
  public var touchId:Int = -1;

  /**
   * An internal point for grabbing the view position of the camera.
   * Useful for reducing point allocation.
   */
  private var viewPoint:FlxPoint;

  /**
   * Stores the last position of the touch pointer.
   */
  private var lastPosition:FlxPoint;

  /**
   * Constructor for the TouchPointerPlugin class.
   * Initializes the touch pointer graphic and sets the scroll factor.
   */
  public function new()
  {
    super();
    makeGraphic(16, 16, FlxColor.RED);
    scrollFactor.set(0, 0);
    viewPoint = FlxPoint.get();
    lastPosition = FlxPoint.get();
  }

  /**
   * Initializes the touch pointer object itself with the specified touch ID.
   * Loads the graphic for the touch pointer.
   *
   * @param touchId The ID of the touch event to initialize.
   */
  public function initialize(touchId:Int):Void
  {
    this.touchId = touchId;
    loadGraphic(Paths.image("michael"));
  }

  /**
   * Updates the position and angle of the touch pointer based on the given touch input.
   * Used in TouchPointerPlugin's update method.
   *
   * @param touch The FlxTouch object containing the current touch input data.
   * @param camera The FlxCamera to grab the touch's view position from.
   */
  public function updateFromTouch(touch:FlxPointer, camera:FlxCamera):Void
  {
    // Grab the view coordinates
    touch.getViewPosition(camera, viewPoint);

    // Update position
    x = viewPoint.x - width / 2;
    y = viewPoint.y - height / 2;

    if (camera.target != null)
    {
      x -= camera.target.x;
      y -= camera.target.y;
    }

    // Calculate angle if moving
    if (lastPosition.distanceTo(FlxPoint.weak(viewPoint.x, viewPoint.y)) > 3)
    {
      var angle = FlxAngle.angleBetweenPoint(this, lastPosition, true);
      this.angle = angle;
      loadGraphic(Paths.image("kevin"));
    }
    else
    {
      angle = 0;
      loadGraphic(Paths.image("michael"));
    }

    lastPosition.copyFrom(viewPoint);
  }

  override public function destroy():Void
  {
    viewPoint.put();
    lastPosition.put();
    super.destroy();
  }

  override public function loadGraphic(graphic:FlxGraphicAsset, animated = false, frameWidth = 0, frameHeight = 0, unique = false, ?key:String):FlxSprite
  {
    super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);
    color = 0xff6666e1;
    blend = "screen";
    return this;
  }
}
