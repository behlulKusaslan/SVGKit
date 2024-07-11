#import "SVGClipPathElement.h"

#import "CALayerWithChildHitTest.h"

#import "SVGHelperUtilities.h"

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

@implementation SVGClipPathElement

@synthesize clipPathUnits;
@synthesize transform; // each SVGElement subclass that conforms to protocol "SVGTransformable" has to re-synthesize this to work around bugs in Apple's Objective-C 2.0 design that don't allow @properties to be extended by categories / protocols

- (void)postProcessAttributesAddingErrorsTo:(SVGKParseResult *)parseResult {
    [super postProcessAttributesAddingErrorsTo:parseResult];
    
    NSError *error = [NSError errorWithDomain:@"SVGKit" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                         @"<clipPath> found in SVG. May render incorrectly with SVGKFastImageView due to Apple bug in CALayer .mask rendering.", NSLocalizedDescriptionKey,
                                                                         nil]];
    [parseResult addParseErrorRecoverable:error];
    
    clipPathUnits = SVG_UNIT_TYPE_USERSPACEONUSE;
    
    NSString *units = [self getAttribute:@"clipPathUnits"];
    if( units != nil && units.length > 0 ) {
        if( [units isEqualToString:@"userSpaceOnUse"] )
            clipPathUnits = SVG_UNIT_TYPE_USERSPACEONUSE;
        else if( [units isEqualToString:@"objectBoundingBox"] )
            clipPathUnits = SVG_UNIT_TYPE_OBJECTBOUNDINGBOX;
        else {
            SVGKitLogWarn(@"Unknown clipPathUnits value %@", units);
            NSError *error = [NSError errorWithDomain:@"SVGKit" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                 [NSString stringWithFormat:@"Unknown clipPathUnits value %@", units], NSLocalizedDescriptionKey,
                                                                                 nil]];
            [parseResult addParseErrorRecoverable:error];
        }
    }
}

- (CALayer *) newLayer
{
    
    CALayer* _layer = [CALayerWithChildHitTest layer];
    
    [SVGHelperUtilities configureCALayer:_layer usingElement:self];
    
    return _layer;
}

- (void)layoutLayer:(CALayer *)layer toMaskLayer:(CALayer *)maskThis
{
    // null rect union any other rect will return the other rect
    CGRect mainRect = CGRectNull;
    
    /** make mainrect the UNION of all sublayer's frames (i.e. their individual "bounds" inside THIS layer's space) */
    for ( CALayer *currentLayer in [layer sublayers] )
    {
        mainRect = CGRectUnion(mainRect, currentLayer.frame);
    }
    
    /** Changing THIS layer's frame now means all DIRECT sublayers are offset by too much (because when we change the offset
     of the parent frame (this.frame), Apple *does not* shift the sublayers around to keep them in same place.
     
     NB: there are bugs in some Apple code in Interface Builder where it attempts to do exactly that (incorrectly, as the API
     is specifically designed NOT to do this), and ... Fails. But in code, thankfully, Apple *almost* never does this (there are a few method
     calls where it appears someone at Apple forgot how their API works, and tried to do the offsetting automatically. "Paved
     with good intentions...".
     */
    if (CGRectIsNull(mainRect))
    {
        // TODO what to do when mainRect is null rect? i.e. no sublayer or all sublayers have null rect frame
    } else {
        for (CALayer *currentLayer in [layer sublayers])
            currentLayer.frame = CGRectOffset(currentLayer.frame, -mainRect.origin.x, -mainRect.origin.y);
    }
    
    // unless we're working in bounding box coords, subtract the owning layer's origin
    if( self.clipPathUnits == SVG_UNIT_TYPE_USERSPACEONUSE )
        mainRect = CGRectOffset(mainRect, -maskThis.frame.origin.x, -maskThis.frame.origin.y);
    layer.frame = mainRect;
}

@end
