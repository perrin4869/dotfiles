# rofi-pass-modi
Rofi modi to copy passwords to clipboard from password store
## Usage
Pass arguments through command line
```
rofi -show pass -modi pass:./rofi-pass-modi
```
or append to ```.config/rofi/config```
```
rofi.modi: 	pass:/<dir-to-rofi-pass-modi>/rofi-pass-modi
```