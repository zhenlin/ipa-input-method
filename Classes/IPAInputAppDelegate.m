//
//  IPAInputAppDelegate.m
//  IPAInputMethod
//
//  Created by Low Zhen Lin on 01/02/2009.
//  Copyright © 2009 Low Zhen Lin. 
//
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "IPAInputAppDelegate.h"


@implementation IPAInputAppDelegate
@synthesize conversionEngine, menu;

- (void)awakeFromNib
{
	NSString * dictsPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"Contents/Resources/InputDictionaries.plist"];
	NSDictionary * dicts = [[NSDictionary dictionaryWithContentsOfFile:dictsPath] retain];
	
	// [dicts writeToFile:@"/Users/lowzl/Desktop/InputDictionaries.plist" atomically:NO];
	
	conversionEngine = [[TableConversionEngine alloc] initWithDictionaries:[dicts allValues]];
	
	// [conversionEngine.dictionary writeToFile:@"/Users/lowzl/Desktop/Dictionary.plist" atomically:NO]; 
	
	// NSLog(@"%@", [conversionEngine convert:@"@\"r\\A.wy.u \"Sip | \"Si.nA.kA~ | \"A.e.E.nAx \"SE.A.t_Se.Ok \"h\\E.zO` | @\"nA.e.E.nAx \"SE.A.t_Se.O.kA \"lA.hA \"kA:.h\\At | @\"nA.e.E.nAx \"mE:.xA.tA \"zA.mA @~ \"t_sA:.lo || \"e:.lA.n1 \"A.p\\e.E.n{ @.wo:\"p\\A:.xA:.se.A \"mES.S{ | \"ES: \"lAh \"h\\el @.x@r\\\"wE.Z1 \"A.p\\e.E.nA.xA e:l\"li~ As\"?E:.xO~"]);
	
	/*
	NSUInteger a, b;
	BOOL c;
	NSString * s = [conversionEngine convert:@"ts\\a" lastInputUnitIndex:&a lastOutputUnitIndex:&b didConvertLastUnit:&c];
	
	NSLog(@"lastInputUnitIndex = %d, lastOutputUnitIndex = %d, didConvertLastUnit = %d \noutput = \"%@\"", a, b, c, s);
	*/
	
	NSMenuItem * preferences = [menu itemWithTag:1];
	
	if (preferences)
	{
		[preferences setAction:@selector(showPreferences:)];
	}
}

- (void)dealloc
{
	[conversionEngine release];
	[super dealloc];
}

@end
