//
//  FMJapaneseTools.h
//  https://github.com/furkanmustafa/FMJapaneseTools
//
//  Created by Furkan Mustafa on 2/11/14.
//  Copyleft. No warranties.
//
//	This library if ported from: https://github.com/soimort/python-romkan
//	 .. which is ported from: http://0xcc.net/ruby-romkan/
//

#import <Foundation/Foundation.h>

@interface NSString (FMJPRomkan)

- (NSString*)japaneseStringConvertedToKatakana;
- (NSString*)japaneseStringConvertedToHiragana;
- (NSString*)japaneseStringConvertedToRomaji;

@end

@interface FMJPRomkan : NSObject

+ (FMJPRomkan*)katakana;
+ (FMJPRomkan*)hiragana;

- (NSString*)stringFromRomajiString:(NSString*)string;

+ (NSString*)hepburnStringFrom:(NSString*)kanaString;
+ (NSString*)kunreiStringFrom:(NSString*)kanaString;
+ (NSString*)romajiStringFrom:(NSString*)kanaString;
+ (NSString*)checkConsonant:(NSString*)string;
+ (NSString*)checkVowel:(NSString*)string;

- (NSArray*)expandConsonant:(NSString*)consonantString;

@end
