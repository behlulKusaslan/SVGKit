//
//  SVGPathElement.m
//  SVGKit
//
//  Copyright Matt Rajca 2010-2011. All rights reserved.
//

#import "SVGPathElement.h"

#import "SVGUtils.h"
#import "SVGKPointsAndPathsParser.h"

#import "SVGElement_ForParser.h" // to resolve Xcode circular dependencies; in long term, parsing SHOULD NOT HAPPEN inside any class whose name starts "SVG" (because those are reserved classes for the SVG Spec)

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

@interface SVGPathElement ()

- (void) parseData:(NSString *)data;

@end

@implementation SVGPathElement

- (void)postProcessAttributesAddingErrorsTo:(SVGKParseResult *)parseResult
{
	[super postProcessAttributesAddingErrorsTo:parseResult];
	
	[self parseData:[self getAttribute:@"d"]];
}

- (void)parseData:(NSString *)data
{
	CGMutablePathRef path = CGPathCreateMutable();
    NSScanner* dataScanner = [NSScanner scannerWithString:data];
    SVGCurve lastCurve = [SVGKPointsAndPathsParser startingCurve];
    BOOL foundCmd;
    
    NSCharacterSet *knownCommands = [NSCharacterSet characterSetWithCharactersInString:@"MmLlCcVvHhAaSsQqTtZz"];
    NSString* command;
    
    do {
        
        command = nil;
        foundCmd = [dataScanner scanCharactersFromSet:knownCommands intoString:&command];
        
        if (command.length > 1) {
            // Take only one char (it can happen that multiple commands are consecutive, as "ZM" - so we only want to get the "Z")
            const NSUInteger tooManyChars = command.length-1;
            command = [command substringToIndex:1];
            [dataScanner setScanLocation:([dataScanner scanLocation] - tooManyChars)];
        }
        
        if (foundCmd) {
            if ([@"z" isEqualToString:command] || [@"Z" isEqualToString:command]) {
                lastCurve = [SVGKPointsAndPathsParser readCloseCommand:[NSScanner scannerWithString:command]
                                                                  path:path
                                                            relativeTo:lastCurve.p];
            } else {
                NSString* cmdArgs = nil;
                BOOL foundParameters = [dataScanner scanUpToCharactersFromSet:knownCommands
                                                                   intoString:&cmdArgs];
                
                if (foundParameters) {
                    NSString* commandWithParameters = [command stringByAppendingString:cmdArgs];
                    NSScanner* commandScanner = [NSScanner scannerWithString:commandWithParameters];
                    
                    if ([@"m" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readMovetoDrawtoCommandGroups:commandScanner
                                                                                       path:path
                                                                                 relativeTo:lastCurve.p
                                                                                 isRelative:TRUE];
                    } else if ([@"M" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readMovetoDrawtoCommandGroups:commandScanner
                                                                                       path:path
                                                                                 relativeTo:CGPointZero
                                                                                 isRelative:FALSE];
                    } else if ([@"l" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readLinetoCommand:commandScanner
                                                                           path:path
                                                                     relativeTo:lastCurve.p
                                                                     isRelative:TRUE];
                    } else if ([@"L" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readLinetoCommand:commandScanner
                                                                           path:path
                                                                     relativeTo:CGPointZero
                                                                     isRelative:FALSE];
                    } else if ([@"v" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readVerticalLinetoCommand:commandScanner
                                                                                   path:path
                                                                             relativeTo:lastCurve.p];
                    } else if ([@"V" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readVerticalLinetoCommand:commandScanner
                                                                                   path:path
                                                                             relativeTo:CGPointZero];
                    } else if ([@"h" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readHorizontalLinetoCommand:commandScanner
                                                                                     path:path
                                                                               relativeTo:lastCurve.p];
                    } else if ([@"H" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readHorizontalLinetoCommand:commandScanner
                                                                                     path:path
                                                                               relativeTo:CGPointZero];
                    } else if ([@"c" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readCurvetoCommand:commandScanner
                                                                            path:path
                                                                      relativeTo:lastCurve.p
                                                                      isRelative:TRUE];
                    } else if ([@"C" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readCurvetoCommand:commandScanner
                                                                            path:path
                                                                      relativeTo:CGPointZero
                                                                      isRelative:FALSE];
                    } else if ([@"s" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readSmoothCurvetoCommand:commandScanner
                                                                                  path:path
                                                                            relativeTo:lastCurve.p
                                                                         withPrevCurve:lastCurve
                                                                            isRelative:TRUE];
                    } else if ([@"S" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readSmoothCurvetoCommand:commandScanner
                                                                                  path:path
                                                                            relativeTo:CGPointZero
                                                                         withPrevCurve:lastCurve
                                                                            isRelative:FALSE];
                    } else if ([@"q" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readQuadraticCurvetoCommand:commandScanner
                                                                                     path:path
                                                                               relativeTo:lastCurve.p
                                                                               isRelative:TRUE];
                    } else if ([@"Q" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readQuadraticCurvetoCommand:commandScanner
                                                                                     path:path
                                                                               relativeTo:CGPointZero
                                                                               isRelative:FALSE];
                    } else if ([@"t" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readSmoothQuadraticCurvetoCommand:commandScanner
                                                                                           path:path
                                                                                     relativeTo:lastCurve.p
                                                                                  withPrevCurve:lastCurve];
                    } else if ([@"T" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readSmoothQuadraticCurvetoCommand:commandScanner
                                                                                           path:path
                                                                                     relativeTo:CGPointZero
                                                                                  withPrevCurve:lastCurve];
                    } else if ([@"a" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readEllipticalArcArguments:commandScanner
                                                                                    path:path
                                                                              relativeTo:lastCurve.p
                                                                              isRelative:TRUE];
                    }  else if ([@"A" isEqualToString:command]) {
                        lastCurve = [SVGKPointsAndPathsParser readEllipticalArcArguments:commandScanner
                                                                                    path:path
                                                                              relativeTo:CGPointZero
                                                                              isRelative:FALSE];
                    } else  {
                        SVGKitLogWarn(@"unsupported command %@", command);
                    }
                }
            }
        }
        
    } while (foundCmd);
	
    
	self.pathForShapeInRelativeCoords = path;
	CGPathRelease(path);
}

@end
