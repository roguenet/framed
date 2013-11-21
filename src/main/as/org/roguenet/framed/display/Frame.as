package org.roguenet.framed.display {

import aspire.util.Log;

import flash.geom.Point;

import flashbang.components.DisplayComponent;
import flashbang.core.AppMode;
import flashbang.core.GameObject;
import flashbang.util.Listeners;

import org.roguenet.framed.style.Styles;
import org.roguenet.framed.style.StyleSheet;

import react.BoolValue;
import react.BoolView;

import starling.display.DisplayObject;

public class Frame extends AppMode implements HasLayout {
    public static function resolveStyles (comp :HasLayout) :Styles {
        var frame :Frame = findFrame(comp);
        return frame == null ? null : frame._sheet.resolve(comp.classes);
    }

    public static function createStyleDisplay (comp :HasLayout, name :String) :DisplayObject {
        var frame :Frame = findFrame(comp);
        return frame == null ? null : frame._sheet.createStyleDisplay(name);
    }

    public static function resolveInherited (comp :HasLayout, name :String) :* {
        if (comp is Frame) return null;
        var styles :Styles = resolveStyles(comp);
        if (!styles.isUndefined(name)) return styles[name];
        if (comp.container == null) {
            log.warning("Asked for inherited style of container without a parent", "comp", comp,
                "name", name);
            return null;
        }
        return resolveInherited(comp.container, name);
    }

    public function Frame (sheet :StyleSheet, size :Point) {
        _sheet = sheet;
        _size = size;
    }

    public function get classes () :Vector.<String> { return null; }
    public function get styles () :Styles { return null; }
    public function get absoluteLayout () :Boolean { return false; }
    public function get top () :int { return 0; }
    public function get right () :int { return 0; }
    public function get bottom () :int { return 0; }
    public function get left () :int { return 0; }
    public function get inline () :Boolean { return false; }

    public function get isValid () :BoolView { return _isValid; }
    public function get regs () :Listeners { return _regs; }

    public function get container () :HasLayout { return null; }
    public function set container (value :HasLayout) :void {
        throw new Error("Frame cannot be contained!")
    }

    public function get component () :HasLayout { return _component; }
    public function set component (value :HasLayout) :void {
        if (_component != null) {
            if (_component is GameObject) removeObject(GameObject(_component));
            _component.container = null;
        }
        _component = value;
        if (_component is GameObject)
            addObject(GameObject(_component), _component is DisplayComponent ? modeSprite : null);
        _component.regs.add(_component.isValid.connect(function (isValid :Boolean) :void {
            if (value == _component && !isValid) _isValid.value = false;
        }));
        _component.container = this;
        _isValid.value = false;
    }

    public function layout (availableSpace :Point) :Point {
        if (_isValid.value) return null;
        if (_component == null) {
            _isValid.value = true;
            return null;
        }

        var size :Point = _component.layout(_size);
        _isValid.value = true;
        return size;
    }

    override protected function update (dt :Number) :void {
        super.update(dt);

        var compSize :Point = layout(null);
        if (compSize != null && _component is DisplayComponent) {
            var disp :DisplayObject = DisplayComponent(_component).display;
            disp.x = (_size.x - compSize.x) / 2;
            disp.y = (_size.y - compSize.y) / 2;
        }
    }

    protected static function findFrame (comp :HasLayout) :Frame {
        while (comp != null && !(comp is Frame)) comp = comp.container;
        return comp == null ? null : Frame(comp);
    }

    protected var _sheet :StyleSheet;
    protected var _isValid :BoolValue = new BoolValue(true);
    protected var _size :Point = new Point();
    protected var _component :HasLayout;

    private static const log :Log = Log.getLog(Frame);
}
}
