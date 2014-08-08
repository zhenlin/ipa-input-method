//
//  main.m
//  IPAInputMethod
//
//  Created by Low Zhen Lin on 18/01/2009.
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

#import <Cocoa/Cocoa.h>
#import <InputMethodKit/InputMethodKit.h>
#import "TableConversionEngine.h"

NSString * const connectionName = @"IPAInput_1_Connection";

IMKServer * server;
IMKCandidates * candidatesWindow = nil;

int main(int argc, char *argv[])
{
    
    NSString * identifier;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// NSLog(@"IPAInputMethod started.");
	
	identifier = [[NSBundle mainBundle] bundleIdentifier];
    server = [[IMKServer alloc] initWithName:connectionName bundleIdentifier:identifier];
	
	[NSBundle loadNibNamed:@"MainMenu" owner:[NSApplication sharedApplication]];
	
	candidatesWindow = [[IMKCandidates alloc] initWithServer:server panelType:kIMKSingleColumnScrollingCandidatePanel];
	
	[[NSApplication sharedApplication] run];
	
	[server release];
	[candidatesWindow release];
	
    [pool release];
    return 0;
}