package;

import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxSpriteGroup;

class PauseButton extends FlxSpriteGroup
{
    public var button:FunkinSprite;
    public var bg:FunkinSprite;

    public function new(X:Float, Y:Float)
    {
        super(X, Y);
        button = new FunkinSprite();
        button.frames = Paths.getSparrowAtlas("pauseButton");
        button.animation.addByIndices('idle', 'back', [0], "", 24, false);
        button.animation.addByIndices('hold', 'back', [5], "", 24, false);
        button.animation.addByIndices('confirm', 'back', [
        6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32
        ], "", 24, false);
        button.scale.set(0.8, 0.8);
        button.updateHitbox();
        button.animation.play("idle");

        bg = new FunkinSprite(0, 0, Paths.image("pauseCircle"));
        bg.scale.set(0.84, 0.8);
        bg.updateHitbox();
        bg.alpha = 0.1;

        add(bg);
        add(button);
        
        button.setPosition((X - button.width) - 35, Y);
        bg.x = ((button.x + (button.width / 2)) - (bg.width / 2));
        bg.y = ((button.y + (button.height / 2)) - (bg.height / 2));
    }

    var tadaTimer = null;
    public function ranTween(?fadeIn:Bool = true){ 
        if (tadaTimer != null) tadaTimer.cancel();
        FlxTween.cancelTweensOf(button);
        FlxTween.cancelTweensOf(bg);
        if (fadeIn){
        button.animation.play("idle", true);
        FlxTween.tween(button, {alpha: 1}, 0.25, {ease: FlxEase.quartOut});
        FlxTween.tween(bg, {alpha: 0.1}, 0.25, {ease: FlxEase.quartOut});
        }else{
        button.animation.play("confirm", true);
        bg.scale.set(0.84 * 1.4, 0.8 * 1.4);
        bg.alpha = 0.4;
        FlxTween.tween(bg.scale, {x: 0.84 * 0.8, y: 0.8 * 0.8}, 0.4, {ease: FlxEase.backInOut});
        FlxTween.tween(bg, {alpha: 0.000001}, 0.6, {ease: FlxEase.quartOut});
            tadaTimer = new FlxTimer().start(0.3, function(t:FlxTimer){
                FlxTween.tween(button, {alpha: 0.0001}, 0.6, {ease: FlxEase.quartOut});
                
            });
        }
    }
}