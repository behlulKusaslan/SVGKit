#import "SVGRect.h"
#import "Foundation/Foundation.h"

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

BOOL SVGRectIsInitialized( SVGRect rect )
{
	return rect.x != -1 || rect.y != -1 || rect.width != -1 || rect.height != -1;
}

SVGRect SVGRectUninitialized( void )
{
	return SVGRectMake( -1, -1, -1, -1 );
}

SVGRect SVGRectMake( float x, float y, float width, float height )
{
	SVGRect result = { x, y, width, height };
	return result;
}

CGRect CGRectFromSVGRect( SVGRect rect )
{
	CGRect result = CGRectMake(rect.x, rect.y, rect.width, rect.height);
	
	return result;
}

CGSize CGSizeFromSVGRect( SVGRect rect )
{
	CGSize result = CGSizeMake( rect.width, rect.height );
	
	return result;
}

NSString * NSStringFromSVGRect( SVGRect rect ) {
    CGRect cgRect = CGRectFromSVGRect(rect);
#if SVGKIT_MAC
    return NSStringFromRect(cgRect);
#else
    return NSStringFromCGRect(cgRect);
#endif
}
