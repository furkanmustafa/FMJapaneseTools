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

#import "FMJapaneseTools.h"

NSString* const FMJP_Kunrei;
NSString* const FMJP_Kunrei_h;
NSString* const FMJP_Hepburn;
NSString* const FMJP_Hepburn_h;

@implementation NSString (FMJPRomkan)

- (NSString*)japaneseStringConvertedToKatakana {
	return [FMJPRomkan.katakana stringFromRomajiString:[self japaneseStringConvertedToRomaji]];
}
- (NSString*)japaneseStringConvertedToHiragana {
	return [FMJPRomkan.hiragana stringFromRomajiString:[self japaneseStringConvertedToRomaji]];
}
- (NSString*)japaneseStringConvertedToRomaji {
	return [FMJPRomkan romajiStringFrom:self];
}

@end

@interface FMJPRomkan ()

@property (nonatomic, retain) NSMutableDictionary* romkan;
@property (nonatomic, retain) NSMutableDictionary* kanrom;
@property (nonatomic, retain) NSMutableArray* kunrei;
@property (nonatomic, retain) NSMutableArray* hepburn;

@property (nonatomic, retain) NSRegularExpression* rompat;
@property (nonatomic, retain) NSRegularExpression* kanpat;
@property (nonatomic, retain) NSRegularExpression* kunpat;
@property (nonatomic, retain) NSRegularExpression* heppat;

@property (nonatomic, retain) NSMutableDictionary* toHepburn;
@property (nonatomic, retain) NSMutableDictionary* toKunrei;

@end

#ifndef NSString_FMRegexTools

NSArray* FMJP_regexMatches(NSString* string, NSString* pattern);
NSString* FMJP_regexMatch(NSString* string, NSString* pattern);
NSString* FMJP_regexReplace(NSString* string, NSString* pattern, NSString* template);
#define regexMatches(string, pattern)				FMJP_regexMatches(string, pattern)
#define regexMatch(string, pattern)					FMJP_regexMatch(string, pattern)
#define regexReplace(string, pattern, template)		FMJP_regexReplace(string, pattern, template)

#else

#define regexMatches(string, pattern)				[string regexMatchesWithPattern:pattern]
#define regexMatch(string, pattern)					[string regexMatchWithPattern:pattern]
#define regexReplace(string, pattern, template)		[string replaceRegex:pattern usingTemplate:template]

#endif

#ifndef f
#define f(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#endif

@implementation FMJPRomkan

- (void)dealloc {
	self.romkan = nil;
	self.kanrom = nil;
	self.kunrei = nil;
	self.hepburn = nil;
	
	self.rompat = nil;
	self.kanpat = nil;
	self.kunpat = nil;
	self.heppat = nil;
	
	self.toHepburn = nil;
	self.toKunrei = nil;
    [super dealloc];
}

+ (FMJPRomkan*)katakana {
	static FMJPRomkan* FMJPKatakana;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		FMJPKatakana = FMJPRomkan.new;
		[FMJPKatakana importWithData:@{
			@"kunrei" : FMJP_Kunrei,
			@"hepburn" : FMJP_Hepburn,
			@"romkanFixes" : @{ @"du": @"ヅ", @"di": @"ヂ", @"fu": @"フ", @"ti": @"チ", @"wi": @"ウィ", @"we": @"ウェ", @"wo": @"ヲ" },
			@"toHepBurnFixes" : @{ @"ti": @"chi" }
		}];
	});
	return FMJPKatakana;
}
+ (FMJPRomkan*)hiragana {
	static FMJPRomkan* FMJPHiragana;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		FMJPHiragana = FMJPRomkan.new;
		[FMJPHiragana importWithData:@{
			@"kunrei" : FMJP_Kunrei_h,
			@"hepburn" : FMJP_Hepburn_h,
			@"romkanFixes" : @{ @"du": @"づ", @"di": @"ぢ", @"fu": @"ふ", @"ti": @"ち", @"wi": @"うぃ", @"we": @"うぇ", @"wo": @"を" },
			@"toHepBurnFixes" : @{ @"ti": @"chi" }
		}];
	});
	return FMJPHiragana;
}

- (void)importWithData:(NSDictionary*)data {
	self.romkan = NSMutableDictionary.dictionary;
	self.kanrom = NSMutableDictionary.dictionary;
	
	NSArray* pairs = [data[@"kunrei"] componentsSeparatedByString:@"|"];
	pairs = [pairs arrayByAddingObjectsFromArray:[data[@"hepburn"] componentsSeparatedByString:@"|"]];
	for (int i = 0; i < pairs.count - 1; i+=2) {
		_kanrom[pairs[i]] = pairs[i + 1];
		_romkan[pairs[i + 1]] = pairs[i];
	}
	
	[_romkan addEntriesFromDictionary:data[@"romkanFixes"]];
	
	NSComparator lengthComparator = ^NSComparisonResult(NSString* obj1, NSString* obj2) {
		if (obj1.length > obj2.length) return NSOrderedAscending;
		if (obj2.length > obj1.length) return NSOrderedDescending;
		return NSOrderedSame;
	};
	
	NSString* pattern = [[_romkan.allKeys sortedArrayUsingComparator:lengthComparator] componentsJoinedByString:@"|"];
	
	self.rompat = [NSRegularExpression regularExpressionWithPattern:pattern
															options:NSRegularExpressionDotMatchesLineSeparators
															  error:nil];
	
	pattern = [[_kanrom.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
		NSInteger res = (obj2.length > obj1.length) - (obj2.length < obj1.length);
		if (res == 0) {
			res = ([_kanrom[obj2] length] > [_kanrom[obj1] length]) - ([_kanrom[obj2] length] < [_kanrom[obj1] length]);
		}
		if (res == 1) return NSOrderedDescending;
		if (res == -1) return NSOrderedAscending;
		return NSOrderedSame;
	}] componentsJoinedByString:@"|"];
	
	self.kanpat = [NSRegularExpression regularExpressionWithPattern:pattern
															options:NSRegularExpressionDotMatchesLineSeparators
															  error:nil];

	pairs = [data[@"kunrei"] componentsSeparatedByString:@"|"];
	self.kunrei = NSMutableArray.array;
	for (int i = 0; i < pairs.count - 1; i+=2)
		[_kunrei addObject:pairs[i+1]];
	[self.kunrei sortedArrayUsingComparator:lengthComparator];
	self.kunpat = [NSRegularExpression regularExpressionWithPattern:[self.kunrei componentsJoinedByString:@"|"]
															options:NSRegularExpressionDotMatchesLineSeparators
															  error:nil];
		
	pairs = [data[@"hepburn"] componentsSeparatedByString:@"|"];
	self.hepburn = NSMutableArray.array;
	for (int i = 0; i < pairs.count - 1; i+=2)
		[_hepburn addObject:pairs[i+1]];
	[self.hepburn sortedArrayUsingComparator:lengthComparator];
	self.heppat = [NSRegularExpression regularExpressionWithPattern:[self.hepburn componentsJoinedByString:@"|"]
															options:NSRegularExpressionDotMatchesLineSeparators
															  error:nil];
	
	self.toHepburn = NSMutableDictionary.dictionary;
	self.toKunrei = NSMutableDictionary.dictionary;
	
	for (int i = 0; i < _toHepburn.count - 1; i++) {
		_toHepburn[_kunrei[i]] = _hepburn[i];
		_toKunrei[_hepburn[i]] = _kunrei[i];
	}
	
	// little update
	[_toHepburn addEntriesFromDictionary:data[@"toHepBurnFixes"]];
}

+ (NSString*)normalize_double_n:(NSString*)string {
	string = [string stringByReplacingOccurrencesOfString:@"nn" withString:@"n"];
	string = regexReplace(string, @"n'([^aiueoyn]|$)", @"n$1");
	return string;
}
- (NSString*)stringFromRomajiString:(NSString*)string {
	string = string.lowercaseString;
	string = [self.class normalize_double_n:string];
	
	string = [self romkanReplace:string];
    return string;
}
- (NSString*)romkanReplace:(NSString*)string {
	NSArray* matches = [_rompat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	while (matches.count) {
		NSTextCheckingResult* result = matches[0];
		NSString* matched = [string substringWithRange:result.range];
		string = [string stringByReplacingCharactersInRange:result.range withString:_romkan[matched]];
		matches = [_rompat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	}
	
    return string;
}
- (NSString*)kanromReplace:(NSString*)string {
	NSArray* matches = [_kanpat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	while (matches.count) {
		NSTextCheckingResult* result = matches[0];
		NSString* matched = [string substringWithRange:result.range];
		string = [string stringByReplacingCharactersInRange:result.range withString:_kanrom[matched]];
		matches = [_kanpat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	}
	return string;
}

- (NSString*)hepburnReplace:(NSString*)string {
	NSArray* matches = [_kunpat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	while (matches.count) {
		NSTextCheckingResult* result = matches[0];
		NSString* matched = [string substringWithRange:result.range];
		string = [string stringByReplacingCharactersInRange:result.range withString:_toHepburn[matched]];
		matches = [_kunpat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	}
	return string;
}
- (NSString*)kunreiReplace:(NSString*)string {
	NSArray* matches = [_heppat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	while (matches.count) {
		NSTextCheckingResult* result = matches[0];
		NSString* matched = [string substringWithRange:result.range];
		string = [string stringByReplacingCharactersInRange:result.range withString:_toKunrei[matched]];
		matches = [_heppat matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	}
	return string;
}

+ (NSString*)hepburnStringFrom:(NSString*)kanaString {
	NSString* string = [FMJPRomkan.katakana kanromReplace:kanaString];
	string = [FMJPRomkan.hiragana kanromReplace:string];
	string = regexReplace(string, @"n'([^aiueoyn]|$)", @"n$1");
	
	// If unmodified, it's a Kunrei-shiki Romaji -- convert it to a Hepburn Romaji
	if ([string isEqualToString:kanaString]) {
		string = string.lowercaseString;
		string = [self.class normalize_double_n:string];
		string = [FMJPRomkan.katakana hepburnReplace:string];
	}
	return string;
}

+ (NSString*)kunreiStringFrom:(NSString*)kanaString {
	NSString* string = [FMJPRomkan.katakana kanromReplace:kanaString];
	string = [FMJPRomkan.hiragana kanromReplace:string];
	string = regexReplace(string, @"n'([^aiueoyn]|$)", @"n$1");
	
	// If unmodified, it's a Hepburn Romaji Romaji -- convert it to a Kunrei-shiki Romaji
	// If modified, it's also a Hepburn Romaji Romaji -- convert it to a Kunrei-shiki Romaji
	string = string.lowercaseString;
	string = [self.class normalize_double_n:string];
	string = [FMJPRomkan.katakana kunreiReplace:string];
	
	return string;
}
+ (NSString*)romajiStringFrom:(NSString*)kanaString {
	NSString* string = [FMJPRomkan.katakana kanromReplace:kanaString];
	string = [FMJPRomkan.hiragana kanromReplace:string];
	string = regexReplace(string, @"n'([^aiueoyn]|$)", @"n$1");
	string = [string stringByReplacingOccurrencesOfString:@"n'n" withString:@"nn"];
	return string;
}
+ (NSString*)checkConsonant:(NSString*)string {
	string = string.lowercaseString;
	return regexMatch(string, @"^[ckgszjtdhfpbmyrwxn]+$");
}
+ (NSString*)checkVowel:(NSString*)string {
	string = string.lowercaseString;
	return regexMatch(string, @"^[aeiou]+$");
}
- (NSArray*)expandConsonant:(NSString*)consonantString {
	consonantString = consonantString.lowercaseString;
    NSMutableArray* matches = NSMutableArray.array;
	for (NSString* mora in _romkan.keyEnumerator) {
		if (!regexMatch(mora, f(@"^%@.$", consonantString))) continue;
		[matches addObject:mora];
	}
	[matches sortUsingSelector:@selector(compare:)];
	return matches;
}


@end

#pragma mark - Regex Functions

#ifndef NSString_FMRegexTools // in case you don't have NSString+FMRegexTools

NSArray* FMJP_regexMatches(NSString* string, NSString* pattern) {
	NSError *error = NULL;
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
																		   options:NSRegularExpressionDotMatchesLineSeparators
																			 error:&error];
	if (error) {
		NSLog(@"ERROR IN REGEX : %@ | %@", [error localizedFailureReason], [error localizedDescription]);
		return nil;
	}
	NSArray* results = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
	NSMutableArray* strResults = [NSMutableArray array];
	for (NSTextCheckingResult* r in results) {
		for (int i=0; i<r.numberOfRanges; i++) {
			if (r.numberOfRanges>1 && i == 0) continue;
			if ([r rangeAtIndex:i].length <= 0) continue;
			[strResults addObject:[string substringWithRange:[r rangeAtIndex:i]]];
		}
	}
	if (strResults.count==0) return nil;
	return strResults;
}
NSString* FMJP_regexMatch(NSString* string, NSString* pattern) {
	NSArray* matches = FMJP_regexMatches(string, pattern);
	
	if (matches.count==0) return nil;
	return matches.lastObject;
}
NSString* FMJP_regexReplace(NSString* string, NSString* pattern, NSString* template) {
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
																		   options:NSRegularExpressionCaseInsensitive
																			 error:&error];
	if (error)
		return nil;
	return [regex stringByReplacingMatchesInString:string
										   options:0
											 range:NSMakeRange(0, string.length)
									  withTemplate:template];
}

#endif

#pragma mark - Data

NSString* const FMJP_Kunrei = @"ァ|xa|ア|a|ィ|xi|イ|i|ゥ|xu|ウ|u|ヴ|vu|ヴァ|va|ヴィ|vi|ヴェ|ve|ヴォ|vo|ェ|xe|エ|e|ォ|xo|オ|o|カ|ka|ガ|ga|キ|ki|キャ|kya|キュ|kyu|キョ|kyo|ギ|gi|ギャ|gya|ギュ|gyu|ギョ|gyo|ク|ku|グ|gu|ケ|ke|ゲ|ge|コ|ko|ゴ|go|サ|sa|ザ|za|シ|si|シャ|sya|シュ|syu|ショ|syo|シェ|sye|ジ|zi|ジャ|zya|ジュ|zyu|ジョ|zyo|ス|su|ズ|zu|セ|se|ゼ|ze|ソ|so|ゾ|zo|タ|ta|ダ|da|チ|ti|チャ|tya|チュ|tyu|チョ|tyo|ヂ|di|ヂャ|dya|ヂュ|dyu|ヂョ|dyo|ティ|ti|ッ|xtu|ッヴ|vvu|ッヴァ|vva|ッヴィ|vvi|ッヴェ|vve|ッヴォ|vvo|ッカ|kka|ッガ|gga|ッキ|kki|ッキャ|kkya|ッキュ|kkyu|ッキョ|kkyo|ッギ|ggi|ッギャ|ggya|ッギュ|ggyu|ッギョ|ggyo|ック|kku|ッグ|ggu|ッケ|kke|ッゲ|gge|ッコ|kko|ッゴ|ggo|ッサ|ssa|ッザ|zza|ッシ|ssi|ッシャ|ssya|ッシュ|ssyu|ッショ|ssyo|ッシェ|ssye|ッジ|zzi|ッジャ|zzya|ッジュ|zzyu|ッジョ|zzyo|ッス|ssu|ッズ|zzu|ッセ|sse|ッゼ|zze|ッソ|sso|ッゾ|zzo|ッタ|tta|ッダ|dda|ッチ|tti|ッティ|tti|ッチャ|ttya|ッチュ|ttyu|ッチョ|ttyo|ッヂ|ddi|ッヂャ|ddya|ッヂュ|ddyu|ッヂョ|ddyo|ッツ|ttu|ッヅ|ddu|ッテ|tte|ッデ|dde|ット|tto|ッド|ddo|ッドゥ|ddu|ッハ|hha|ッバ|bba|ッパ|ppa|ッヒ|hhi|ッヒャ|hhya|ッヒュ|hhyu|ッヒョ|hhyo|ッビ|bbi|ッビャ|bbya|ッビュ|bbyu|ッビョ|bbyo|ッピ|ppi|ッピャ|ppya|ッピュ|ppyu|ッピョ|ppyo|ッフ|hhu|ッフュ|ffu|ッファ|ffa|ッフィ|ffi|ッフェ|ffe|ッフォ|ffo|ッブ|bbu|ップ|ppu|ッヘ|hhe|ッベ|bbe|ッペ|ppe|ッホ|hho|ッボ|bbo|ッポ|ppo|ッヤ|yya|ッユ|yyu|ッヨ|yyo|ッラ|rra|ッリ|rri|ッリャ|rrya|ッリュ|rryu|ッリョ|rryo|ッル|rru|ッレ|rre|ッロ|rro|ツ|tu|ヅ|du|テ|te|デ|de|ト|to|ド|do|ドゥ|du|ナ|na|ニ|ni|ニャ|nya|ニュ|nyu|ニョ|nyo|ヌ|nu|ネ|ne|ノ|no|ハ|ha|バ|ba|パ|pa|ヒ|hi|ヒャ|hya|ヒュ|hyu|ヒョ|hyo|ビ|bi|ビャ|bya|ビュ|byu|ビョ|byo|ピ|pi|ピャ|pya|ピュ|pyu|ピョ|pyo|フ|hu|ファ|fa|フィ|fi|フェ|fe|フォ|fo|フュ|fu|ブ|bu|プ|pu|ヘ|he|ベ|be|ペ|pe|ホ|ho|ボ|bo|ポ|po|マ|ma|ミ|mi|ミャ|mya|ミュ|myu|ミョ|myo|ム|mu|メ|me|モ|mo|ャ|xya|ヤ|ya|ュ|xyu|ユ|yu|ョ|xyo|ヨ|yo|ラ|ra|リ|ri|リャ|rya|リュ|ryu|リョ|ryo|ル|ru|レ|re|ロ|ro|ヮ|xwa|ワ|wa|ウィ|wi|ヰ|wi|ヱ|we|ウェ|we|ヲ|wo|ウォ|wo|ン|n|ン|n'|ディ|dyi|ー|-|チェ|tye|ッチェ|ttye|ジェ|zye";

NSString* const FMJP_Kunrei_h = @"ぁ|xa|あ|a|ぃ|xi|い|i|ぅ|xu|う|u|う゛|vu|う゛ぁ|va|う゛ぃ|vi|う゛ぇ|ve|う゛ぉ|vo|ぇ|xe|え|e|ぉ|xo|お|o|か|ka|が|ga|き|ki|きゃ|kya|きゅ|kyu|きょ|kyo|ぎ|gi|ぎゃ|gya|ぎゅ|gyu|ぎょ|gyo|く|ku|ぐ|gu|け|ke|げ|ge|こ|ko|ご|go|さ|sa|ざ|za|し|si|しゃ|sya|しゅ|syu|しょ|syo|じ|zi|じゃ|zya|じゅ|zyu|じょ|zyo|す|su|ず|zu|せ|se|ぜ|ze|そ|so|ぞ|zo|た|ta|だ|da|ち|ti|ちゃ|tya|ちゅ|tyu|ちょ|tyo|ぢ|di|ぢゃ|dya|ぢゅ|dyu|ぢょ|dyo|っ|xtu|っう゛|vvu|っう゛ぁ|vva|っう゛ぃ|vvi|っう゛ぇ|vve|っう゛ぉ|vvo|っか|kka|っが|gga|っき|kki|っきゃ|kkya|っきゅ|kkyu|っきょ|kkyo|っぎ|ggi|っぎゃ|ggya|っぎゅ|ggyu|っぎょ|ggyo|っく|kku|っぐ|ggu|っけ|kke|っげ|gge|っこ|kko|っご|ggo|っさ|ssa|っざ|zza|っし|ssi|っしゃ|ssya|っしゅ|ssyu|っしょ|ssyo|っじ|zzi|っじゃ|zzya|っじゅ|zzyu|っじょ|zzyo|っす|ssu|っず|zzu|っせ|sse|っぜ|zze|っそ|sso|っぞ|zzo|った|tta|っだ|dda|っち|tti|っちゃ|ttya|っちゅ|ttyu|っちょ|ttyo|っぢ|ddi|っぢゃ|ddya|っぢゅ|ddyu|っぢょ|ddyo|っつ|ttu|っづ|ddu|って|tte|っで|dde|っと|tto|っど|ddo|っは|hha|っば|bba|っぱ|ppa|っひ|hhi|っひゃ|hhya|っひゅ|hhyu|っひょ|hhyo|っび|bbi|っびゃ|bbya|っびゅ|bbyu|っびょ|bbyo|っぴ|ppi|っぴゃ|ppya|っぴゅ|ppyu|っぴょ|ppyo|っふ|hhu|っふぁ|ffa|っふぃ|ffi|っふぇ|ffe|っふぉ|ffo|っぶ|bbu|っぷ|ppu|っへ|hhe|っべ|bbe|っぺ|ppe|っほ|hho|っぼ|bbo|っぽ|ppo|っや|yya|っゆ|yyu|っよ|yyo|っら|rra|っり|rri|っりゃ|rrya|っりゅ|rryu|っりょ|rryo|っる|rru|っれ|rre|っろ|rro|つ|tu|づ|du|て|te|で|de|と|to|ど|do|な|na|に|ni|にゃ|nya|にゅ|nyu|にょ|nyo|ぬ|nu|ね|ne|の|no|は|ha|ば|ba|ぱ|pa|ひ|hi|ひゃ|hya|ひゅ|hyu|ひょ|hyo|び|bi|びゃ|bya|びゅ|byu|びょ|byo|ぴ|pi|ぴゃ|pya|ぴゅ|pyu|ぴょ|pyo|ふ|hu|ふぁ|fa|ふぃ|fi|ふぇ|fe|ふぉ|fo|ぶ|bu|ぷ|pu|へ|he|べ|be|ぺ|pe|ほ|ho|ぼ|bo|ぽ|po|ま|ma|み|mi|みゃ|mya|みゅ|myu|みょ|myo|む|mu|め|me|も|mo|ゃ|xya|や|ya|ゅ|xyu|ゆ|yu|ょ|xyo|よ|yo|ら|ra|り|ri|りゃ|rya|りゅ|ryu|りょ|ryo|る|ru|れ|re|ろ|ro|ゎ|xwa|わ|wa|ゐ|wi|ゑ|we|を|wo|ん|n|ん|n'|でぃ|dyi|ー|-|ちぇ|tye|っちぇ|ttye|じぇ|zye";

NSString* const FMJP_Hepburn = @"ァ|xa|ア|a|ィ|xi|イ|i|ゥ|xu|ウ|u|ヴ|vu|ヴァ|va|ヴィ|vi|ヴェ|ve|ヴォ|vo|ェ|xe|エ|e|ォ|xo|オ|o|カ|ka|ガ|ga|キ|ki|キャ|kya|キュ|kyu|キョ|kyo|ギ|gi|ギャ|gya|ギュ|gyu|ギョ|gyo|ク|ku|グ|gu|ケ|ke|ゲ|ge|コ|ko|ゴ|go|サ|sa|ザ|za|シ|shi|シャ|sha|シュ|shu|ショ|sho|シェ|she|ジ|ji|ジャ|ja|ジュ|ju|ジョ|jo|ス|su|ズ|zu|セ|se|ゼ|ze|ソ|so|ゾ|zo|タ|ta|ダ|da|チ|chi|チャ|cha|チュ|chu|チョ|cho|ヂ|di|ヂャ|dya|ヂュ|dyu|ヂョ|dyo|ティ|ti|ッ|xtsu|ッヴ|vvu|ッヴァ|vva|ッヴィ|vvi|ッヴェ|vve|ッヴォ|vvo|ッカ|kka|ッガ|gga|ッキ|kki|ッキャ|kkya|ッキュ|kkyu|ッキョ|kkyo|ッギ|ggi|ッギャ|ggya|ッギュ|ggyu|ッギョ|ggyo|ック|kku|ッグ|ggu|ッケ|kke|ッゲ|gge|ッコ|kko|ッゴ|ggo|ッサ|ssa|ッザ|zza|ッシ|sshi|ッシャ|ssha|ッシュ|sshu|ッショ|ssho|ッシェ|sshe|ッジ|jji|ッジャ|jja|ッジュ|jju|ッジョ|jjo|ッス|ssu|ッズ|zzu|ッセ|sse|ッゼ|zze|ッソ|sso|ッゾ|zzo|ッタ|tta|ッダ|dda|ッチ|cchi|ッティ|tti|ッチャ|ccha|ッチュ|cchu|ッチョ|ccho|ッヂ|ddi|ッヂャ|ddya|ッヂュ|ddyu|ッヂョ|ddyo|ッツ|ttsu|ッヅ|ddu|ッテ|tte|ッデ|dde|ット|tto|ッド|ddo|ッドゥ|ddu|ッハ|hha|ッバ|bba|ッパ|ppa|ッヒ|hhi|ッヒャ|hhya|ッヒュ|hhyu|ッヒョ|hhyo|ッビ|bbi|ッビャ|bbya|ッビュ|bbyu|ッビョ|bbyo|ッピ|ppi|ッピャ|ppya|ッピュ|ppyu|ッピョ|ppyo|ッフ|ffu|ッフュ|ffu|ッファ|ffa|ッフィ|ffi|ッフェ|ffe|ッフォ|ffo|ッブ|bbu|ップ|ppu|ッヘ|hhe|ッベ|bbe|ッペ|ppe|ッホ|hho|ッボ|bbo|ッポ|ppo|ッヤ|yya|ッユ|yyu|ッヨ|yyo|ッラ|rra|ッリ|rri|ッリャ|rrya|ッリュ|rryu|ッリョ|rryo|ッル|rru|ッレ|rre|ッロ|rro|ツ|tsu|ヅ|du|テ|te|デ|de|ト|to|ド|do|ドゥ|du|ナ|na|ニ|ni|ニャ|nya|ニュ|nyu|ニョ|nyo|ヌ|nu|ネ|ne|ノ|no|ハ|ha|バ|ba|パ|pa|ヒ|hi|ヒャ|hya|ヒュ|hyu|ヒョ|hyo|ビ|bi|ビャ|bya|ビュ|byu|ビョ|byo|ピ|pi|ピャ|pya|ピュ|pyu|ピョ|pyo|フ|fu|ファ|fa|フィ|fi|フェ|fe|フォ|fo|フュ|fu|ブ|bu|プ|pu|ヘ|he|ベ|be|ペ|pe|ホ|ho|ボ|bo|ポ|po|マ|ma|ミ|mi|ミャ|mya|ミュ|myu|ミョ|myo|ム|mu|メ|me|モ|mo|ャ|xya|ヤ|ya|ュ|xyu|ユ|yu|ョ|xyo|ヨ|yo|ラ|ra|リ|ri|リャ|rya|リュ|ryu|リョ|ryo|ル|ru|レ|re|ロ|ro|ヮ|xwa|ワ|wa|ウィ|wi|ヰ|wi|ヱ|we|ウェ|we|ヲ|wo|ウォ|wo|ン|n|ン|n'|ディ|di|ー|-|チェ|che|ッチェ|cche|ジェ|je";

NSString* const FMJP_Hepburn_h = @"ぁ|xa|あ|a|ぃ|xi|い|i|ぅ|xu|う|u|う゛|vu|う゛ぁ|va|う゛ぃ|vi|う゛ぇ|ve|う゛ぉ|vo|ぇ|xe|え|e|ぉ|xo|お|o|か|ka|が|ga|き|ki|きゃ|kya|きゅ|kyu|きょ|kyo|ぎ|gi|ぎゃ|gya|ぎゅ|gyu|ぎょ|gyo|く|ku|ぐ|gu|け|ke|げ|ge|こ|ko|ご|go|さ|sa|ざ|za|し|shi|しゃ|sha|しゅ|shu|しょ|sho|じ|ji|じゃ|ja|じゅ|ju|じょ|jo|す|su|ず|zu|せ|se|ぜ|ze|そ|so|ぞ|zo|た|ta|だ|da|ち|chi|ちゃ|cha|ちゅ|chu|ちょ|cho|ぢ|di|ぢゃ|dya|ぢゅ|dyu|ぢょ|dyo|っ|xtsu|っう゛|vvu|っう゛ぁ|vva|っう゛ぃ|vvi|っう゛ぇ|vve|っう゛ぉ|vvo|っか|kka|っが|gga|っき|kki|っきゃ|kkya|っきゅ|kkyu|っきょ|kkyo|っぎ|ggi|っぎゃ|ggya|っぎゅ|ggyu|っぎょ|ggyo|っく|kku|っぐ|ggu|っけ|kke|っげ|gge|っこ|kko|っご|ggo|っさ|ssa|っざ|zza|っし|sshi|っしゃ|ssha|っしゅ|sshu|っしょ|ssho|っじ|jji|っじゃ|jja|っじゅ|jju|っじょ|jjo|っす|ssu|っず|zzu|っせ|sse|っぜ|zze|っそ|sso|っぞ|zzo|った|tta|っだ|dda|っち|cchi|っちゃ|ccha|っちゅ|cchu|っちょ|ccho|っぢ|ddi|っぢゃ|ddya|っぢゅ|ddyu|っぢょ|ddyo|っつ|ttsu|っづ|ddu|って|tte|っで|dde|っと|tto|っど|ddo|っは|hha|っば|bba|っぱ|ppa|っひ|hhi|っひゃ|hhya|っひゅ|hhyu|っひょ|hhyo|っび|bbi|っびゃ|bbya|っびゅ|bbyu|っびょ|bbyo|っぴ|ppi|っぴゃ|ppya|っぴゅ|ppyu|っぴょ|ppyo|っふ|ffu|っふぁ|ffa|っふぃ|ffi|っふぇ|ffe|っふぉ|ffo|っぶ|bbu|っぷ|ppu|っへ|hhe|っべ|bbe|っぺ|ppe|っほ|hho|っぼ|bbo|っぽ|ppo|っや|yya|っゆ|yyu|っよ|yyo|っら|rra|っり|rri|っりゃ|rrya|っりゅ|rryu|っりょ|rryo|っる|rru|っれ|rre|っろ|rro|つ|tsu|づ|du|て|te|で|de|と|to|ど|do|な|na|に|ni|にゃ|nya|にゅ|nyu|にょ|nyo|ぬ|nu|ね|ne|の|no|は|ha|ば|ba|ぱ|pa|ひ|hi|ひゃ|hya|ひゅ|hyu|ひょ|hyo|び|bi|びゃ|bya|びゅ|byu|びょ|byo|ぴ|pi|ぴゃ|pya|ぴゅ|pyu|ぴょ|pyo|ふ|fu|ふぁ|fa|ふぃ|fi|ふぇ|fe|ふぉ|fo|ぶ|bu|ぷ|pu|へ|he|べ|be|ぺ|pe|ほ|ho|ぼ|bo|ぽ|po|ま|ma|み|mi|みゃ|mya|みゅ|myu|みょ|myo|む|mu|め|me|も|mo|ゃ|xya|や|ya|ゅ|xyu|ゆ|yu|ょ|xyo|よ|yo|ら|ra|り|ri|りゃ|rya|りゅ|ryu|りょ|ryo|る|ru|れ|re|ろ|ro|ゎ|xwa|わ|wa|ゐ|wi|ゑ|we|を|wo|ん|n|ん|n'|でぃ|dyi|ー|-|ちぇ|che|っちぇ|cche|じぇ|je";
