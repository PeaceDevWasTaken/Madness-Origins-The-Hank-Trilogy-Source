package freestyle;
import lime.net.URIParser;
import flixel.FlxG;
import flixel.FlxBasic as YourMother;
import haxe.ds.StringMap;
import openfl.ui.Keyboard;

class Controls extends YourMother {

    /** Controls class used in Freestyle Engine. 
    * With permision granted through RapperGF#8391
    * 
    * Permision is hereby granted through This mod and its subsidaries allowed use
    * of this code without distibution to other sources.
    * Released under the APACHE License.
    *
    * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
    * IN THE SOFTWARE.
    * 
    * @author RapperGF
    **/

    public static var controlEvents:Array<String> = [];
    
    static final keyCodes:Map<Int, String> =
    [
        65  => "A",
        66  => "B",
        67  => "C",
        68  => "D",
        69  => "E",
        70  => "F",
        71  => "G",
        72  => "H",
        73  => "I",
        74  => "J",
        75  => "K",
        76  => "L",
        77  => "M",
        78  => "N",
        79  => "O",
        80  => "P",
        81  => "Q",
        82  => "R",
        83  => "S",
        84  => "T",
        85  => "U",
        86  => "V",
        87  => "W",
        88  => "X",
        89  => "Y",
        90  => "Z",
        48  => "0",
        49  => "1",
        50  => "2",
        51  => "3",
        52  => "4",
        53  => "5",
        54  => "6",
        55  => "7",
        56  => "8",
        57  => "9",
        33  => "Page Up",
        34  => "Page Down",
        36  => "Home",
        35  => "End",
        45  => "Insert",
        27  => "Escape",
        189 => "-",
        187 => "+",
        46  => "Delete",
        8   => "Backspace",
        219 => "[",
        221 => "]",
        220 => "\\",
        20  => "Caps Lock",
        186 => ";",
        222 => "\"",
        13  => "Enter",
        16  => "Shift",
        188 => ",",
        190 => ".",
        191 => "/",
        192 => "`",
        17  => "Ctrl",
        18  => "Alt",
        32  => "Space",
        38  => "Up",
        40  => "Down",
        37  => "Left",
        39  => "Right",
        9   => "Tab",
        301 => "Print Screen",
        112 => "F1",
        113 => "F2",
        114 => "F3",
        115 => "F4",
        116 => "F5",
        117 => "F6",
        118 => "F7",
        119 => "F8",
        120 => "F9",
        121 => "F10",
        122 => "F11",
        123 => "F12",
        96  => "Numpad 0",
        97  => "Numpad 1",
        98  => "Numpad 2",
        99  => "Numpad 3",
        100 => "Numpad 4",
        101 => "Numpad 5",
        102 => "Numpad 6",
        103 => "Numpad 7",
        104 => "Numpad 8",
        105 => "Numpad 9",
        109 => "Numpad -",
        107 => "Numpad +",
        110 => "Numpad .",
        106 => "Numpad *"
    ];

    static final left:Array<flixel.input.keyboard.FlxKey> = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left'));
    final down:Array<flixel.input.keyboard.FlxKey> = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down'));
    final up:Array<flixel.input.keyboard.FlxKey> = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up'));
    final right:Array<flixel.input.keyboard.FlxKey> = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'));

    static var actions:StringMap<Array<Null<Int>>> =  // rebindable keys
    [
        "left"     => [Keyboard.LEFT, Keyboard.D],
        "down"     => [Keyboard.DOWN, Keyboard.F],
        "up"     => [Keyboard.UP, Keyboard.J],
        "right"    => [Keyboard.RIGHT, Keyboard.K],
        "confirm"   => [Keyboard.ENTER, null],
        "back"      => [Keyboard.ESCAPE, null],
        "shift"     => [Keyboard.SHIFT, null],
    ];

    inline public static function getKeyID(key:Int){
        var action = getActionFromKey(key);
        var binds = ["left","down","up","right"];
        var dir = binds.indexOf(action);
        trace(left);
        //var dir = -1;
        /*switch (action) {
            case "left":
                dir = 0;
            case "down":
                dir = 1;
            case "up":
                dir = 2;
            case "right":
                dir = 3;
        }*/
        return dir;
    }

    public static function getActionFromKey(key:Int):Null<String> {
        for (actionName => actionKeys in actions)
        {
            for (actionKey in actionKeys)
            {
                if (key == actionKey)
                    return actionName;
            }
        }
        
        return null;
    }
}
