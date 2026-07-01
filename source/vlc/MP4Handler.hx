package vlc;

import haxe.Int64;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import hxvlc.flixel.FlxVideoSprite;
import flixel.FlxCamera;
import PlayState;
import haxe.Int64;

class MP4Handler extends FlxSpriteGroup
{
    
    #if VIDEOS_ALLOWED
    public static var instances:Array<MP4Handler> = [];

    public var finishCallback:Void->Void = null;
    public var videoSprite:FlxVideoSprite;

    private var videoName:String;
    private var alreadyDestroyed:Bool = false;
    private var shouldLoop:Bool;
    private var shouldResize:Bool;

    private var lastCamera:FlxCamera; 
    private var pausedTime:Int64 = 0;
    private var wasPaused:Bool = false;

    public function new(videoName:String, ?shouldLoop:Bool = false, ?shouldResize:Bool = false, ?startPlay:Bool = true)
    {
        super();

        this.videoName = videoName;
        this.shouldLoop = shouldLoop;
        this.shouldResize = shouldResize;

        var cam:FlxCamera;

        if (PlayState.instance != null && PlayState.instance.camOther != null) {
            cam = PlayState.instance.camOther;
        } else if (FlxG.cameras.list.length > 0) {
            cam = FlxG.cameras.list[FlxG.cameras.list.length - 1];
        } else {
            cam = null; 
        }

        if (cam != null) {
            cameras = [cam];
            scrollFactor.set();
        } else {
            trace("[MP4Handler] Warning: No camera available for video playback.");
        }

        lastCamera = cameras[0]; 

        var precacheSprite = new FlxVideoSprite();
        add(precacheSprite);

        precacheSprite.load(videoName);
        precacheSprite.play();
        precacheSprite.stop();

        videoSprite = new FlxVideoSprite();
        add(videoSprite);

        videoSprite.bitmap.onEndReached.add(finishVideo);

        var args = this.shouldLoop ? ['input-repeat=65535'] : null;
        videoSprite.load(videoName, args);
        if (startPlay)
        videoSprite.play();

        if (this.shouldResize)
        {
            videoSprite.bitmap.onFormatSetup.add(() -> resizeAndCenter());
        }

        instances.push(this);
    }

    private function resizeAndCenter():Void
    {
        if (videoSprite.frameWidth <= 0 || videoSprite.frameHeight <= 0)
            return;

        var cam = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;

        var baseW = videoSprite.frameWidth;
        var baseH = videoSprite.frameHeight;

        var scale = Math.max(cam.width / baseW, cam.height / baseH);

        videoSprite.scale.set(scale, scale);
        videoSprite.updateHitbox();
        videoSprite.screenCenter();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        var currentCam = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;

        if (currentCam != lastCamera)
        {
            lastCamera = currentCam;
            resizeAndCenter();
        }
    }

    public function finishVideo():Void
    {
        if (alreadyDestroyed) return;
        alreadyDestroyed = true;

        videoSprite.stop();

        if (finishCallback != null)
            finishCallback();

        destroy();
    }

    override public function destroy()
    {
        instances.remove(this);
        super.destroy();
    }

    public function pause():Void
    {
        if (videoSprite != null && videoSprite.bitmap.isPlaying)
        {
            pausedTime = videoSprite.bitmap.time; 
            wasPaused = true;
            videoSprite.pause();
        }
    }

    public function resume():Void
    {
        if (videoSprite != null)
        {
            videoSprite.resume();

            if (wasPaused)
            {
                var t = pausedTime;
                FlxG.signals.postUpdate.addOnce(() -> {
                    if (videoSprite != null)
                        videoSprite.bitmap.time = t;
                });

                wasPaused = false;
            }
        }
    }   

    public static function pauseAll():Void
    {
        for (v in instances)
            if (v != null && v.videoSprite != null)
                v.pause();
    }

    public static function resumeAll():Void
    {
        for (v in instances)
            if (v != null && v.videoSprite != null)
                v.resume();
    }
    #end
}
