package;

import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
    public var sprTracker:FlxSprite;
    private var isOldIcon:Bool = false;
    private var isPlayer:Bool = false;
    private var char:String = '';
    private var iconOffsets:Array<Float> = [0, 0];

    public function new(char:String = 'bf', isPlayer:Bool = false)
    {
        super();
        this.isPlayer = isPlayer;
        changeIcon(char);
        scrollFactor.set();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        if (sprTracker != null)
            setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
    }

    public function swapOldIcon() {
        isOldIcon = !isOldIcon;
        changeIcon(isOldIcon ? 'bf-old' : 'bf');
    }

    public function changeIcon(char:String) {
        if(this.char == char) return;

        var name:String = 'icons/' + char;
        if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-' + char;
        if(!Paths.fileExists('images/' + name + '.png', IMAGE)) name = 'icons/icon-face';
        
        var file:Dynamic = Paths.image(name);
        loadGraphic(file); 

        var frameSize:Int = (width % 150 == 0 && width >= 300) ? 150 : Math.floor(height);
        var cols:Int = Math.floor(width / frameSize);
        var rows:Int = Math.floor(height / frameSize);

        loadGraphic(file, true, frameSize, frameSize);
        
        iconOffsets[0] = (frameSize - 150) / 2;
        iconOffsets[1] = (frameSize - 150) / 2;
        updateHitbox();

        this.char = char;
        antialiasing = !char.endsWith('-pixel') && ClientPrefs.globalAntialiasing;

        if (rows > 1) {
            var normalFrames:Array<Int> = [];
            var loseFrames:Array<Int> = [];
            var winFrames:Array<Int> = [];

            for (i in 0...rows) {
                var rowStart = i * cols;
                normalFrames.push(rowStart);
                if (cols > 1) loseFrames.push(rowStart + 1);
                if (cols > 2) winFrames.push(rowStart + 2);
            }

            animation.add('normal', normalFrames, 12, true, isPlayer);
            animation.add('lose', loseFrames.length > 0 ? loseFrames : normalFrames, 12, true, isPlayer);
            animation.add('win', winFrames.length > 0 ? winFrames : normalFrames, 12, true, isPlayer);
            animation.play('normal');
        } else {
            var frames:Array<Int> = [0, (cols > 1 ? 1 : 0), (cols > 2 ? 2 : 0)];
            animation.add(char, frames, 0, false, isPlayer);
            animation.play(char);
        }
    }

    override function updateHitbox()
    {
        super.updateHitbox();
        offset.set(iconOffsets[0], iconOffsets[1]);
    }

    public function getCharacter():String return char;
}