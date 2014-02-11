//
//  main.m
//  TestProject
//
//  Created by Furkan Mustafa on 2/11/14.
//  Copyright (c) 2014 yonketa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMJapaneseTools.h"

int main(int argc, const char * argv[]) {
	@autoreleasepool {
	    
	    // insert code here...
		NSString* romajiTest = @"kore ha tesuto purojekuto desune.";
		NSString* kanaTest = @"そう　デスよね!";
		
	    NSLog(@"Hello, World!");
		NSLog(@" \t %@", [romajiTest japaneseStringConvertedToKatakana]);
		NSLog(@" \t %@", [romajiTest japaneseStringConvertedToHiragana]);
		NSLog(@" \t ---- ");
		NSLog(@" \t %@", [kanaTest japaneseStringConvertedToRomaji]);
		NSLog(@" \t %@", [kanaTest japaneseStringConvertedToKatakana]);
		NSLog(@" \t %@", [kanaTest japaneseStringConvertedToHiragana]);
		
	}
    return 0;
}

