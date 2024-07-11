#import "CSSStyleDeclaration.h"

#import "CSSValue.h"
#import "CSSValueList.h"
#import "CSSPrimitiveValue.h"

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#import "CocoaLumberjack.h"
#import "SVGKDefine.h"

// These macro is only used inside framework project, does not expose to public header and effect user's define

#define SVGKIT_LOG_CONTEXT 556

#define SVGKitLogError(frmt, ...)   LOG_MAYBE(NO,                LOG_LEVEL_DEF, DDLogFlagError,   SVGKIT_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define SVGKitLogWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagWarning, SVGKIT_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define SVGKitLogInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagInfo,    SVGKIT_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define SVGKitLogDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagDebug,   SVGKIT_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define SVGKitLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, LOG_LEVEL_DEF, DDLogFlagVerbose, SVGKIT_LOG_CONTEXT, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#if DEBUG
static const int ddLogLevel = DDLogLevelVerbose;
#else
static const int ddLogLevel = DDLogLevelWarning;
#endif

#if SVGKIT_MAC
#define NSStringFromCGRect(rect) NSStringFromRect(rect)
#define NSStringFromCGSize(size) NSStringFromSize(size)
#define NSStringFromCGPoint(point) NSStringFromPoint(point)
#endif
#endif

@interface CSSStyleDeclaration()

@property(nonatomic,strong) NSMutableDictionary* internalDictionaryOfStylesByCSSClass;

@end

@implementation CSSStyleDeclaration

@synthesize internalDictionaryOfStylesByCSSClass;

@synthesize cssText = _cssText;
@synthesize length;
@synthesize parentRule;


- (id)init
{
    self = [super init];
    if (self) {
        self.internalDictionaryOfStylesByCSSClass = [NSMutableDictionary dictionary];
    }
    return self;
}

#define MAX_ACCUM 256
#define MAX_NAME 256

/** From spec:
 
 "The parsable textual representation of the declaration block (excluding the surrounding curly braces). Setting this attribute will result in the parsing of the new value and resetting of all the properties in the declaration block including the removal or addition of properties."
 */
-(void)setCssText:(NSString *)newCSSText
{
	_cssText = newCSSText;
	
	/** and now post-process it, *as required by* the CSS/DOM spec... */
	NSMutableDictionary* processedStyles = [self NSDictionaryFromCSSAttributes:_cssText];
	
	self.internalDictionaryOfStylesByCSSClass = processedStyles;
  
}

-(NSMutableDictionary *) NSDictionaryFromCSSAttributes: (NSString *)css {
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	NSCharacterSet* trimChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
	
	const char *cstr = [css UTF8String];
	size_t len = strlen(cstr);
	
	char name[MAX_NAME];
	bzero(name, MAX_NAME);
	
	char accum[MAX_ACCUM];
	bzero(accum, MAX_ACCUM);
	
	size_t accumIdx = 0;
	
	for (size_t n = 0; n <= len; n++) {
		char c = cstr[n];
		
		if (c == ':') {
			strncpy(name, accum, MAX_NAME);
			name[accumIdx] = '\0';
			
			bzero(accum, MAX_ACCUM);
			accumIdx = 0;
			
			continue;
		}
		else if (c == ';' || c == '\0') {
            if( accumIdx > 0 ) //if there is a ';' and '\0' to end the style, avoid adding an empty key-value pair
            {
                accum[accumIdx] = '\0';
                
                NSString *keyString = [[NSString stringWithUTF8String:name]
									   stringByTrimmingCharactersInSet:trimChars];
				NSString *cssValueString = [[NSString stringWithUTF8String:accum]
											stringByTrimmingCharactersInSet:trimChars];
				
				CSSValue *cssValue;
				if( [cssValueString rangeOfString:@" "].length > 0 )
					cssValue = [[CSSValueList alloc] init];
				else
					cssValue = [[CSSPrimitiveValue alloc] init];
				cssValue.cssText = cssValueString; // has the side-effect of parsing, if required
				
                [dict setObject:cssValue
                         forKey:keyString];
                
                bzero(name, MAX_NAME);
				
                bzero(accum, MAX_ACCUM);
                accumIdx = 0;
            }
			
			continue;
		}
		
		accum[accumIdx++] = c;
		if (accumIdx >= MAX_ACCUM) {
			SVGKitLogWarn(@"Buffer ovverun while parsing style sheet - skipping");
			return dict;
		}
	}
	
	return dict;
}

-(NSString*) getPropertyValue:(NSString*) propertyName
{
	CSSValue* v = [self getPropertyCSSValue:propertyName];
	
	if( v == nil )
		return nil;
	else
		return v.cssText;
}

-(CSSValue*) getPropertyCSSValue:(NSString*) propertyName
{
	return [self.internalDictionaryOfStylesByCSSClass objectForKey:propertyName];
}

-(NSString*) removeProperty:(NSString*) propertyName
{
	NSString* oldValue = [self getPropertyValue:propertyName];
	[self.internalDictionaryOfStylesByCSSClass removeObjectForKey:propertyName];
	return oldValue;
}

-(NSString*) getPropertyPriority:(NSString*) propertyName
{
	NSAssert(FALSE, @"CSS 'property priorities' - Not supported");
	
	return nil;
}

-(void) setProperty:(NSString*) propertyName value:(NSString*) value priority:(NSString*) priority
{
	NSAssert(FALSE, @"CSS 'property priorities' - Not supported");
}

-(NSString*) item:(long) index
{
	/** this is stupid slow, but until Apple *can be bothered* to add a "stable-order" dictionary to their libraries, this is the only sensibly easy way of implementing this method */
	NSArray* sortedKeys = [[self.internalDictionaryOfStylesByCSSClass allKeys] sortedArrayUsingSelector:@selector(compare:)];
	CSSValue* v = [sortedKeys objectAtIndex:index];
	return v.cssText;
}

-(NSString *)description
{
	return [NSString stringWithFormat:@"CSSStyleDeclaration: dictionary(%@)", self.internalDictionaryOfStylesByCSSClass];
}

@end
