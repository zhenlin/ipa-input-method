//
//  TableConversionEngine.m
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

#import "TableConversionEngine.h"


@implementation TableConversionEngine
@synthesize dictionary, keys;

NSInteger compareKeys(id s1, id s2, void *context)
{
    int l1 = [s1 length];
    int l2 = [s2 length];
	
    if (l1 < l2)
        return NSOrderedAscending;
    else if (l1 > l2)
        return NSOrderedDescending;
    else
        return [s1 compare: s2];
}

- (id)initWithDictionary:(NSDictionary *)dict
{
	[super init];
	dictionary = [dict retain];
	
	maxKeyLen = 1;
	keys = [[[dictionary allKeys] sortedArrayUsingFunction:compareKeys context:nil] retain];
	
	maxKeyLen = [[keys lastObject] length];
	
	return self;
}

- (id)initWithDictionaries:(NSArray *)dicts
{
	NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
	
	for (NSDictionary * d in dicts)
	{
		for (NSString * k in d)
		{
			id o = [d objectForKey:k];
			id object = [dict objectForKey:k];
			if (object == nil)
			{
				[dict setObject:o forKey:k];
			} else if ([object isKindOfClass:[NSArray class]]) {
				[dict setObject:[object arrayByAddingObject:o] forKey:k];	
			} else {
				[dict setObject:[NSArray arrayWithObjects:object, o, nil] forKey:k];
			}
		}
	}
	
	return [self initWithDictionary:[NSDictionary dictionaryWithDictionary:[dict autorelease]]];	
}

- (void)dealloc
{
	[dictionary release];
	[keys release];
	
	[super dealloc];
}

- (NSArray *)candidates:(NSString *)input
{
	NSUInteger len = [input length];
	
	if (len == 0)
		return [NSArray array];
	
	NSMutableArray * list = [[NSMutableArray alloc] init];
	
	for (NSString * k in keys)
	{
		if ([k length] < len)
			continue;
		
		if ([input isEqualToString:[k substringToIndex:len]])
		{
			id candidate = [dictionary objectForKey:k];
			if ([candidate isKindOfClass:[NSArray class]])
				[list addObjectsFromArray:candidate];
			else
				[list addObject:candidate];
		}
	}
	
	NSMutableArray * candidates = [[NSMutableArray alloc] init];

	for (NSString * candidate in list)
	{
		if ([candidates indexOfObjectIdenticalTo:candidate] == NSNotFound)
			[candidates addObject:candidate];
	}
	
	[list release];
	
	return [NSArray arrayWithArray:[candidates autorelease]];
}

- (NSString *)convert:(NSString *)input
{
	return [self convert:input lastInputUnitIndex:NULL lastOutputUnitIndex:NULL didConvertLastUnit:NULL];
}

- (NSString *)convert:(NSString *)input lastInputUnitIndex:(NSUInteger *)pLastInputUnitIndex lastOutputUnitIndex:(NSUInteger *)pLastOutputUnitIndex didConvertLastUnit:(BOOL *)pDidConvertLastUnit
{
	NSUInteger inputLen = [input length];
	
	NSUInteger loc = 0;
	NSUInteger len = maxKeyLen;
	
	NSUInteger lastInputUnitIndex = 0;
	NSUInteger lastOutputUnitIndex = 0;
	BOOL didConvertLastUnit = NO;
	
	if (inputLen < maxKeyLen)
		len = inputLen;
		
	NSMutableString * output = [[NSMutableString alloc] init];
	
	while (loc < inputLen)
	{
		while (len > 0 && [dictionary objectForKey:[input substringWithRange:NSMakeRange(loc, len)]] == nil)
		{
			len--;
		}
				
		if (len == 0)
		{
			len = 1;
			if (didConvertLastUnit)
			{
				lastInputUnitIndex = loc;
				lastOutputUnitIndex = [output length];
			}
			didConvertLastUnit = NO;
		} else {
			lastInputUnitIndex = loc;
			lastOutputUnitIndex = [output length];
			
			didConvertLastUnit = YES;
		}
		
		NSString * key = [input substringWithRange:NSMakeRange(loc, len)];
		id result;
		
		if (didConvertLastUnit)
		{
			result = [dictionary objectForKey:key];
		} else {
			result = key;
		}
		
		NSString * candidate;
		
		if ([result isKindOfClass:[NSArray class]])
			candidate = [(NSArray *)result objectAtIndex:0];
		else
			candidate = result;
		
		[output	appendString:candidate];
		
		loc += len;
		len = inputLen - loc;
		if (len > maxKeyLen)
			len = maxKeyLen;
	}
	
	if (pLastInputUnitIndex)
		*pLastInputUnitIndex = lastInputUnitIndex;
	
	if (pLastOutputUnitIndex)
		*pLastOutputUnitIndex = lastOutputUnitIndex;
	
	if (pDidConvertLastUnit)
		*pDidConvertLastUnit = didConvertLastUnit;
	
	return [NSString stringWithString:[output autorelease]];
}

@end
