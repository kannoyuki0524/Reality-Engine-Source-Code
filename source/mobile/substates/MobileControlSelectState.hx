package mobile.substates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import mobile.MobileButton;
import mobile.objects.FunkinMobilePad;
import mobile.objects.FunkinHitbox;
import ClientPrefs;
import flixel.group.FlxGroup;

class MobileControlSelectState extends MusicBeatSubstate
{
	var styleList:Array<String> = ['classic', 'classic-right', 'hitbox', 'custom button'];
	var styleNames:Array<String> = ['Classic', 'Classic Right', 'Hitbox', 'Custom Button'];
	var curStyle:Int = 0;

	var previewPad:FunkinMobilePad;
	var previewHitbox:FunkinHitbox;

	var previewLayer:FlxGroup;
	var uiLayer:FlxGroup;

	var styleTexts:FlxTypedGroup<FlxText>;
	var descText:FlxText;
	var saveBtn:FlxButton;
	var resetBtn:FlxButton;

	var dragging:Bool = false;
	var dragButton:MobileButton;
	var dragOffsetX:Float = 0;
	var dragOffsetY:Float = 0;

	public function new()
	{
		controls.isInSubstate = true;
		super();
	}

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		previewLayer = new FlxGroup();
		add(previewLayer);

		uiLayer = new FlxGroup();
		add(uiLayer);

		var title:FlxText = new FlxText(0, 10, FlxG.width, 'Mobile Control');
		title.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, CENTER);
		title.scrollFactor.set();
		uiLayer.add(title);

		styleTexts = new FlxTypedGroup<FlxText>();
		uiLayer.add(styleTexts);

		for (i in 0...styleList.length)
		{
			var text:FlxText = new FlxText(20, 60 + i * 40, 0, styleNames[i]);
			text.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, LEFT);
			text.ID = i;
			text.scrollFactor.set();
			styleTexts.add(text);
		}

		descText = new FlxText(0, FlxG.height - 100, FlxG.width, '');
		descText.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.GRAY, CENTER);
		descText.scrollFactor.set();
		uiLayer.add(descText);

		saveBtn = new FlxButton(FlxG.width / 2 - 80, FlxG.height - 45, 'Save', onSave);
		saveBtn.label.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE);
		saveBtn.scrollFactor.set();
		saveBtn.visible = false;
		uiLayer.add(saveBtn);

		resetBtn = new FlxButton(FlxG.width / 2 + 20, FlxG.height - 45, 'Reset', onReset);
		resetBtn.label.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE);
		resetBtn.scrollFactor.set();
		resetBtn.visible = false;
		uiLayer.add(resetBtn);

		var backBtn:FlxButton = new FlxButton(FlxG.width - 100, 10, 'Back', onBack);
		backBtn.label.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE);
		backBtn.scrollFactor.set();
		uiLayer.add(backBtn);

		curStyle = styleList.indexOf(ClientPrefs.curMobileControl);
		if (curStyle < 0) curStyle = 0;
		updateUI();
		showPreview();

		super.create();
	}

	function updateUI()
	{
		for (text in styleTexts)
		{
			if (text.ID == curStyle)
			{
				text.color = FlxColor.YELLOW;
				text.scale.set(1.1, 1.1);
			}
			else
			{
				text.color = FlxColor.WHITE;
				text.scale.set(1.0, 1.0);
			}
		}

		var isCustom = (styleList[curStyle] == 'custom button');
		saveBtn.visible = isCustom;
		resetBtn.visible = isCustom;

		descText.text = switch (styleList[curStyle])
		{
			case 'classic': 'Pad on the left side (default position)';
			case 'classic-right': 'Pad on the right side (default position)';
			case 'hitbox': 'Hitbox style (default position)';
			case 'custom button': 'Drag buttons to adjust, then press Save';
			default: '';
		};
	}

	function showPreview()
	{
		clearPreview();

		var style = styleList[curStyle];

		if (style == 'hitbox')
		{
			previewHitbox = new FunkinHitbox(null, true);
			previewHitbox.scrollFactor.set();
			previewHitbox.alpha = 1.0;
			for (hint in previewHitbox.hints)
			{
				hint.onDown.callback = null;
				hint.onUp.callback = null;
				hint.onOut.callback = null;
				hint.alpha = 1.0;
				if (hint.hintUp != null) hint.hintUp.alpha = 1.0;
				if (hint.hintDown != null) hint.hintDown.alpha = 1.0;
			}
			previewLayer.add(previewHitbox);
		}
		else
		{
			previewPad = new FunkinMobilePad('FULL', 'NONE');
			previewPad.scrollFactor.set();
			for (group in previewPad.buttons)
				for (btn in group)
					btn.alpha = 1.0;

			switch (style)
			{
				case 'classic':
					// default position
				case 'classic-right':
					for (btn in previewPad.buttons[0])
						btn.x = FlxG.width - 312 + btn.x;
				case 'custom button':
					for (name => pos in ClientPrefs.mobilePad)
					{
						var btn = previewPad.getButton('button' + name.charAt(0).toUpperCase() + name.substring(1).toLowerCase());
						if (btn != null)
						{
							btn.x = pos[0];
							btn.y = pos[1];
						}
					}
			}

			previewLayer.add(previewPad);
		}
	}

	function clearPreview()
	{
		if (previewPad != null)
		{
			previewLayer.remove(previewPad);
			previewPad = FlxDestroyUtil.destroy(previewPad);
		}
		if (previewHitbox != null)
		{
			previewLayer.remove(previewHitbox);
			previewHitbox = FlxDestroyUtil.destroy(previewHitbox);
		}
	}

	function onSave()
	{
		ClientPrefs.curMobileControl = styleList[curStyle];
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('confirmMenu'));
		close();
	}

	function onReset()
	{
		ClientPrefs.mobilePad = [
			"UP" => [105, 372],
			"LEFT" => [0, 477],
			"RIGHT" => [207, 477],
			"DOWN" => [105, 585]
		];
		showPreview();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function onBack()
	{
		if (styleList[curStyle] != 'custom button')
		{
			ClientPrefs.curMobileControl = styleList[curStyle];
			ClientPrefs.saveSettings();
		}
		close();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.BACK)
		{
			onBack();
			return;
		}

		if (controls.UI_UP_P) changeStyle(-1);
		if (controls.UI_DOWN_P) changeStyle(1);

		if (controls.ACCEPT && styleList[curStyle] != 'custom button')
		{
			onSave();
			return;
		}

		if (FlxG.mouse.justPressed)
		{
			for (text in styleTexts)
			{
				if (FlxG.mouse.overlaps(text))
				{
					if (curStyle != text.ID)
					{
						curStyle = text.ID;
						updateUI();
						showPreview();
						FlxG.sound.play(Paths.sound('scrollMenu'));
					}
				}
			}
		}

		if (styleList[curStyle] == 'custom button' && previewPad != null)
			handleDragging();
	}

	function changeStyle(dir:Int)
	{
		curStyle = FlxMath.wrap(curStyle + dir, 0, styleList.length - 1);
		updateUI();
		showPreview();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function handleDragging()
	{
		if (FlxG.mouse.justPressed)
		{
			for (group in previewPad.buttons)
			{
				for (btn in group)
				{
					if (FlxG.mouse.overlaps(btn))
					{
						dragging = true;
						dragButton = btn;
						dragOffsetX = FlxG.mouse.x - btn.x;
						dragOffsetY = FlxG.mouse.y - btn.y;
						break;
					}
				}
				if (dragging) break;
			}
		}

		if (dragging && dragButton != null)
		{
			if (FlxG.mouse.pressed)
			{
				dragButton.x = FlxMath.bound(FlxG.mouse.x - dragOffsetX, 0, FlxG.width - dragButton.width);
				dragButton.y = FlxMath.bound(FlxG.mouse.y - dragOffsetY, 0, FlxG.height - dragButton.height);
			}

			if (FlxG.mouse.justReleased)
			{
				var btnName = dragButton.name;
				if (btnName != null && btnName.indexOf('button') == 0)
				{
					var key = btnName.substring(6).toUpperCase();
					ClientPrefs.mobilePad.set(key, [dragButton.x, dragButton.y]);
				}
				dragging = false;
				dragButton = null;
			}
		}
	}

	override function destroy()
	{
		clearPreview();
		controls.isInSubstate = false;
		super.destroy();
	}
}