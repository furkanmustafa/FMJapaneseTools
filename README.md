FMJapaneseTools
===============

Japanese Language Tools for Cocoa / iOS

*Currently only does Hiragana <-> Katakana <-> Romaji conversion. It might do more in the future.*

Ported from: [python-romkan](https://github.com/soimort/python-romkan) which is ported from [ruby-romkan](http://0xcc.net/ruby-romkan/)

## Installing

Just copy `FMJapaneseTools` folder to your project.

Note: This project **doesn't** use arc. You'll need `-fno-objc-arc` for `FMJapaneseTools-Romkan.m`, [see here](http://stackoverflow.com/questions/6646052/how-can-i-disable-arc-for-a-single-file-in-a-project) if you need help.

## Usage

```obj-c
#import "FMJapaneseTools.h"

// ..
NSString* romajiTest = @"kore ha tesuto purojekuto desuyo.";
NSString* kanaTest = @"そう　デスよ!";

NSLog(@" \t %@", [romajiTest japaneseStringConvertedToKatakana]);
NSLog(@" \t %@", [romajiTest japaneseStringConvertedToHiragana]);
NSLog(@" \t ---- ");
NSLog(@" \t %@", [kanaTest japaneseStringConvertedToRomaji]);
NSLog(@" \t %@", [kanaTest japaneseStringConvertedToKatakana]);
NSLog(@" \t %@", [kanaTest japaneseStringConvertedToHiragana]);

```

See [License](LICENSE).
