//
//  IPAInputController.m
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

#import "IPAInputController.h"
#import "IPAInputAppDelegate.h"

@implementation IPAInputController
@synthesize composedBuffer, originalBuffer, candidates;

- (id)initWithServer:(IMKServer*)server delegate:(id)delegate client:(id)inputClient
{
	[super initWithServer:server delegate:delegate client:inputClient];
	
	originalBuffer = [[NSMutableString alloc] init];
	composedBuffer = [[NSMutableString alloc] init];
	candidates = [[NSArray alloc] init];
	
	canConvert = NO;
	didConvert = NO;
	insertionIndex = 0;
	lastExactMatchIndex = 0;
	currentClient = inputClient;
	
	return self;
}

- (void)dealloc
{
	[originalBuffer release];
	[composedBuffer release];
	
	[super dealloc];
}

- (BOOL)inputText:(NSString*)string client:(id)sender
{
	if ([string length] == 0)
		return NO;
	
	unichar code = [string characterAtIndex:0];
	
	// NSLog(@"inputText: string = \"%@\" (U+%04X), didConvert = %d, canConvert = %d", string, code, canConvert, didConvert);
	
	if (code < 0x20)
	{
		if ([candidates count] > 0)
		{
			if (code == 0x1f)
			{
				return [self cycleCandidatesDown:sender];
			} else if (code == 0x1e) {
				return [self cycleCandidatesUp:sender];	
			}
		}
		
		if (code == 0x1c || code == 0x1d)
		{
			if ([composedBuffer length] > 0)
			{
				[self commitComposition:sender];
				return NO;
			}
		}
		
		return NO;
	}
	
	if (didConvert && [composedBuffer length] > 0)
	{
		[self commitComposition:sender];
	} else if (canConvert && [string isEqualToString:@" "]) {
		[self commitComposition:sender];
	} else if ([candidates count] > 0 && [string isEqualToString:@" "]) {
		[self showCandidates];
		return YES;
	}
	
	[self originalBufferAppend:string client:sender];

	return [self convert:string client:sender];
}

- (BOOL)didCommandBySelector:(SEL)selector client:(id)sender
{
    if ([self respondsToSelector:selector])
	{		
		if (selector == @selector(insertNewline:) ||
			selector == @selector(deleteBackward:))
		{
			if ([originalBuffer length] > 0)
			{
				[self performSelector:selector withObject:sender];
				return YES; 
			}			
		} else if (selector == @selector(insertTab:)) {
			if ([candidates count] > 0)
			{
				[self performSelector:selector withObject:sender];
				return YES; 
			}
		}
    }
	
	return NO;
}

- (void)insertNewline:(id)sender
{
	[self commitComposition:sender];	
}

- (void)deleteBackward:(id)sender
{	
	// NSLog(@"insertionIndex = %d, originalBuffer = \"%@\"", insertionIndex, originalBuffer);
	
	if (insertionIndex > 0 && insertionIndex <= [originalBuffer length])
	{
		insertionIndex--;
		[originalBuffer deleteCharactersInRange:NSMakeRange(insertionIndex, 1)];
		[self updateCandidates];
		[self convert:@"" client:sender];
	}
}

- (void)insertTab:(id)sender
{
	[self showCandidates];
}

- (BOOL)cycleCandidatesUp:(id)sender
{
	NSString * candidate = [candidates objectAtIndex:0];
	
	if (! [candidate isEqualToString:composedBuffer])
	{
		self.candidates = [[[NSArray arrayWithObject:[candidates lastObject]] arrayByAddingObjectsFromArray:[candidates subarrayWithRange:NSMakeRange(0, [candidates count] - 1)]] arrayByAddingObject: [NSString stringWithString:composedBuffer]];
	} else if ([candidates count] > 1) {
		self.candidates = [[NSArray arrayWithObject:[candidates lastObject]] arrayByAddingObjectsFromArray:[candidates subarrayWithRange:NSMakeRange(0, [candidates count] - 1)]];
	} else {
		return NO;
	}
	
	[composedBuffer setString:[candidates objectAtIndex:0]];
	[sender setMarkedText:composedBuffer selectionRange:NSMakeRange(insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
	canConvert = YES;
	didConvert = YES;
	
	return YES;
}

- (BOOL)cycleCandidatesDown:(id)sender
{
	NSString * candidate = [candidates objectAtIndex:0];
	
	if (! [candidate isEqualToString:composedBuffer])
	{
		self.candidates = [candidates arrayByAddingObject:[NSString stringWithString:composedBuffer]];
	} else if ([candidates count] > 1) {
		self.candidates = [[candidates subarrayWithRange:NSMakeRange(1, [candidates count] - 1)] arrayByAddingObject:candidate];
	} else {
		return NO;
	}
	
	[composedBuffer setString:[candidates objectAtIndex:0]];
	[sender setMarkedText:composedBuffer selectionRange:NSMakeRange(insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
	canConvert = YES;
	didConvert = YES;
	
	return YES;
}

- (void)originalBufferAppend:(NSString*)string client:(id)sender
{
	if (originalBuffer)
		[originalBuffer appendString:string];
	else
		originalBuffer = [[NSMutableString stringWithString:string] retain];
	
	insertionIndex++;
	// [sender setMarkedText:originalBuffer selectionRange:NSMakeRange(0, [originalBuffer length]) replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
	
	[self updateCandidates];
}

- (void)updateCandidates
{
	self.candidates = [[(IPAInputAppDelegate *)[NSApp delegate] conversionEngine] candidates:originalBuffer];
	
	// NSLog(@"%d candidates for \"%@\"", [candidates count], originalBuffer);
	
	extern IMKCandidates * candidatesWindow;
	if (candidatesWindow)
	{
		if ([candidates count] == 0)
		{
			[candidatesWindow hide];
		} else if ([candidatesWindow isVisible]) {
			[candidatesWindow updateCandidates];
		}
	}
}

- (NSArray*)candidates:(id)sender
{
	return candidates;
}

- (void)candidateSelectionChanged:(NSAttributedString*)candidateString
{
	[composedBuffer setString:[candidateString string]];
	
	[currentClient setMarkedText:[candidateString string] selectionRange:NSMakeRange(insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];

	canConvert = YES;
}

- (void)showCandidates
{
	extern IMKCandidates * candidatesWindow;
	if (candidatesWindow && [candidates count] > 0)
	{
		NSInteger vertical = [[NSUserDefaults standardUserDefaults] integerForKey:@"verticalCandidate"];
		
		if (vertical) 
			[candidatesWindow setPanelType:kIMKSingleColumnScrollingCandidatePanel];
		else 
			[candidatesWindow setPanelType:kIMKSingleRowSteppingCandidatePanel];
		
		[candidatesWindow updateCandidates];
		[candidatesWindow show:kIMKLocateCandidatesBelowHint];
	}
}

- (void)hideCandidates
{
	extern IMKCandidates * candidatesWindow;
	if (candidatesWindow)
	{
		[candidatesWindow hide];
	}
}

- (void)endSession:(id)sender
{
	[sender setMarkedText:@"" selectionRange:NSMakeRange(0, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
	
	self.composedBuffer = [NSMutableString string];
	self.originalBuffer = [NSMutableString string];
	self.candidates = [[NSArray alloc] init];
	
	insertionIndex = 0;
	lastExactMatchIndex = 0;
	canConvert = NO;
	didConvert = NO;
}

- (void)commitComposition:(id)sender
{
	NSString * text = composedBuffer;
	
	if (composedBuffer == nil || [composedBuffer length] == 0)
		text = originalBuffer;
	
	[sender insertText:text replacementRange:NSMakeRange(NSNotFound, NSNotFound)];
	
	[self endSession:sender];
}

- (BOOL)convert:(NSString *)trigger client:(id)sender
{	
	BOOL handled = NO;
	
	TableConversionEngine * conversionEngine = [[(IPAInputAppDelegate *)[NSApp delegate] conversionEngine] retain];
	
	canConvert = NO;
	didConvert = NO;
	
	if ([originalBuffer length] > 0)
	{
		if ([candidates count] == 0)
		{
			if ([composedBuffer length] > 0)
			{
				if (lastExactMatchIndex + 1 == insertionIndex) {
					[self commitComposition:sender];
					return [self inputText:trigger client:sender];
				} else if (lastExactMatchIndex == 0) {
					[self commitComposition:sender];
					return [self inputText:trigger client:sender];
				} else {
					NSUInteger lastInputUnitIndex = 0;
					NSUInteger lastOutputUnitIndex = 0; 
					BOOL didConvertLastUnit = NO;
					
					NSString * newComposedBuffer = [[conversionEngine convert:originalBuffer lastInputUnitIndex:&lastInputUnitIndex lastOutputUnitIndex:&lastOutputUnitIndex didConvertLastUnit:&didConvertLastUnit] retain];
					
					if (lastInputUnitIndex == 0 && didConvertLastUnit == NO)
					{
						[self commitComposition:sender];
						return [self inputText:trigger client:sender];
					}
					
					NSString * nextInput = [originalBuffer substringWithRange:NSMakeRange(lastInputUnitIndex, [originalBuffer length] - lastInputUnitIndex)];
					[composedBuffer setString:[newComposedBuffer substringToIndex:lastOutputUnitIndex]];
					//NSLog(@"lastInputUnitIndex = %d, lastOutputUnitIndex = %d, nextInput = \"%@\", composedBuffer = \"%@\"", lastInputUnitIndex, lastOutputUnitIndex, nextInput, composedBuffer);

					//[originalBuffer setString:[originalBuffer substringToIndex:lastUnconvertedIndex]];
					[newComposedBuffer release];
					[self commitComposition:sender];
					
					[self originalBufferAppend:nextInput client:sender];
					return [self convert:trigger client:sender];
				}
			} else {
				[self endSession:sender];
				return NO;
			}
		} else {
			handled = YES;
			
			canConvert = YES;
			
			if ([conversionEngine.keys indexOfObject:originalBuffer] != NSNotFound)
			{
				[composedBuffer setString:[candidates objectAtIndex:0]];
				[sender setMarkedText:composedBuffer selectionRange:NSMakeRange(insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
				
				lastExactMatchIndex = insertionIndex;
				
				if ([candidates count] == 1)
				{
					[self hideCandidates];
					didConvert = YES;
				}
			} else {
				[composedBuffer setString:[conversionEngine convert:originalBuffer]];
				[sender setMarkedText:composedBuffer selectionRange:NSMakeRange(insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
				
				handled = YES;
			}
		}
	} else {
		[composedBuffer setString:@""];
		[sender setMarkedText:composedBuffer selectionRange:NSMakeRange(insertionIndex, 0) replacementRange:NSMakeRange(NSNotFound,NSNotFound)];
	}
	
	[conversionEngine release];
	
	// NSLog(@"originalBuffer = \"%@\" \ncomposedBuffer = \"%@\"", originalBuffer, composedBuffer);
	
	return YES;
}

@end
