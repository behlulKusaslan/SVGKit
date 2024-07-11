#import "SVGKSourceLocalFile.h"
#import "CocoaLumberjack.h"

#ifdef __OBJC__
#import <Foundation/Foundation.h>
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

@interface SVGKSourceLocalFile()
@property (nonatomic, readwrite) BOOL wasRelative;
@end

@implementation SVGKSourceLocalFile


-(NSString *)keyForAppleDictionaries
{
	return self.filePath;
}

+(uint64_t) sizeInBytesOfFilePath:(NSString*) filePath
{
	NSError* errorReadingFileAttributes;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	NSDictionary* atts = [fileManager attributesOfItemAtPath:filePath error:&errorReadingFileAttributes];
	
	if( atts == nil )
		return -1;
	else
		return atts.fileSize;
}

+ (SVGKSourceLocalFile*)sourceFromFilename:(NSString*)p {
	NSInputStream* stream = [NSInputStream inputStreamWithFileAtPath:p];
	//DO NOT DO THIS: let the parser do it at last possible moment (Apple has threading problems otherwise!) [stream open];
	
	SVGKSourceLocalFile* s = [[SVGKSourceLocalFile alloc] initWithInputSteam:stream];
	s.filePath = p;
	s.approximateLengthInBytesOr0 = [self sizeInBytesOfFilePath:p];
	
	return s;
}

+ (SVGKSourceLocalFile *)internalSourceAnywhereInBundle:(NSBundle *)bundle usingName:(NSString *)name
{
    NSParameterAssert(name != nil);
    
    /** Apple's File APIs are very very bad and require you to strip the extension HALF the time.
     
     The other HALF the time, they fail unless you KEEP the extension.
     
     It's a mess!
     */
    NSString *newName = [name stringByDeletingPathExtension];
    NSString *extension = [name pathExtension];
    if ([@"" isEqualToString:extension]) {
        extension = @"svg";
    }
    
    /** First, try to find it in the project BUNDLE (this was HARD CODED at compile time; can never be changed!) */
    NSString *pathToFileInBundle = nil;
    
    if( bundle != nil )
    {
        pathToFileInBundle = [bundle pathForResource:newName ofType:extension];
    }
    
    /** Second, try to find it in the Documents folder (this is where Apple expects you to store custom files at runtime) */
    NSString* pathToFileInDocumentsFolder = nil;
    NSString* pathToDocumentsFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if( pathToDocumentsFolder != nil )
    {
        pathToFileInDocumentsFolder = [[pathToDocumentsFolder stringByAppendingPathComponent:newName] stringByAppendingPathExtension:extension];
        if( [[NSFileManager defaultManager] fileExistsAtPath:pathToFileInDocumentsFolder])
            ;
        else
            pathToFileInDocumentsFolder = nil; // couldn't find a file there
    }
    
    if( pathToFileInBundle == nil
       && pathToFileInDocumentsFolder == nil )
    {
        SVGKitLogWarn(@"[%@] MISSING FILE (not found in App-bundle, not found in Documents folder), COULD NOT CREATE DOCUMENT: filename = %@, extension = %@", [self class], newName, extension);
        return nil;
    }
    
    /** Prefer the Documents-folder version over the Bundle version (allows you to have a default, and override at runtime) */
    SVGKSourceLocalFile* source = [SVGKSourceLocalFile sourceFromFilename: pathToFileInDocumentsFolder == nil ? pathToFileInBundle : pathToFileInDocumentsFolder];
    
    return source;
}

+ (SVGKSourceLocalFile *)internalSourceAnywhereInBundleUsingName:(NSString *)name
{
    return [self internalSourceAnywhereInBundle:[NSBundle mainBundle] usingName:name];
}

-(id)copyWithZone:(NSZone *)zone
{
	id copy = [super copyWithZone:zone];
	
	if( copy )
	{	
		/** clone bits */
		[copy setFilePath:[self.filePath copy]];
		[copy setWasRelative:self.wasRelative];
		
		/** Finally, manually intialize the input stream, as required by super class */
		[copy setStream:[NSInputStream inputStreamWithFileAtPath:self.filePath]];
	}
	
	return copy;
}

- (SVGKSource *)sourceFromRelativePath:(NSString *)relative {
    NSString *absolute = ((NSURL*)[NSURL URLWithString:relative relativeToURL:[NSURL fileURLWithPath:self.filePath]]).path;
    if ([[NSFileManager defaultManager] fileExistsAtPath:absolute])
	{
       SVGKSourceLocalFile* result = [SVGKSourceLocalFile sourceFromFilename:absolute];
		result.wasRelative = true;
		return result;
	}
    return nil;
}

-(NSString *)description
{
	BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.filePath];
	return [NSString stringWithFormat:@"File: %@%@\"%@\" (%llu bytes)", self.wasRelative? @"(relative) " : @"", fileExists?@"":@"NOT FOUND!  ", self.filePath, self.approximateLengthInBytesOr0 ];
}


@end
