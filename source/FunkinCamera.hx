package;

import flixel.FlxCamera;
import flixel.math.FlxMath;
class FunkinCamera extends FlxCamera
{
    public var defaultCamZoom:Float = 1;
    public var zoomScaleX:Float = 1;
    public var zoomScaleY:Float = 1;
    public var cameraSpeed:Float = 1;
    public var useLerp:Bool = false;
    public var camZoomingMult:Float = 1.0;
	public var camZoomingDecay:Float = 1.0;
    override function set_zoom(Zoom:Float):Float
        {
            zoom = (Zoom == 0) ? defaultCamZoom : Zoom;
            setScale(zoom * zoomScaleX, zoom * zoomScaleY);
            return zoom;
        }
    override public function update(elapsed:Float):Void
        {
            if (useLerp){
            var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * cameraSpeed), 0, 1);
            zoom = FlxMath.lerp(
                defaultCamZoom,
                zoom,
                lerpVal
            );
            }
            super.update(elapsed);
        }
}
