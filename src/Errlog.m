//
//  ErrlogPacker.m
//  LifeMoments
//
//  Created by Сергей Чернов on 16.04.13.
//
//

#import "Errlog.h"
#import "JSON.h"
#import "NSData+zlib.h"
#import "sha256_utils.h"
#import "Errlog_internals.h"
#import "Base64.h"
#include <sys/types.h>
#include <sys/sysctl.h>

enum {
    kSeverityTrace = 1,
    kSeverityNotFound = 49,
    kSeverityWarning = 50,
    kSeverityError = 100,
    kSeverityStats = 1001
};

#define REPORT_URL ([NSURL URLWithString: @"http://errorlog.co/reports/log"])

static Errlog* me;
static NSURL* reportUrl;


@interface Errlog() {
    NSString *accontId, *applicationName;
    NSData   *accountSecret;
    NSString *instanceId;
    NSUserDefaults *defs;
    
    NSDate *sessionStartedAt;
    
    NSString *platform;
    NSString *sysVersion;
}

+(void)bufferException:(NSException*)exception;

@end

static void onUncaughtException(NSException *exception) {
    [Errlog bufferException: exception];
}

@implementation Errlog

+(void)load {
    reportUrl = REPORT_URL;
}

+(void)setUrl:(NSURL *)url {
    reportUrl = url;
}

+(void)useToken:(NSString *)token application:(NSString *)name {
    [Errlog useAccountId:[token substringToIndex:32] secret:[token substringFromIndex:32] application:name];
}

+(void)useAccountId:(NSString *)accId secret:(NSString *)accSecret application:(NSString *)name {
    me = [[Errlog alloc] initWithAccountId:accId secret:accSecret application:name];
}

+(Errlog*)instance {
    return me;
}

-(id)initWithAccountId:(NSString *)accId secret:(NSString *)accSecret application:(NSString*) name{
    self = [super init];
    if( self ) {
        accontId = accId;
        accountSecret = [accSecret base64DecodedData];
        applicationName = name;
        
        // Instance id
        defs = [NSUserDefaults standardUserDefaults];
        instanceId = [defs stringForKey:@"__errlog_instance_id"];
        if( !instanceId ) {
            CFUUIDRef theUUID = CFUUIDCreate(NULL);
            instanceId = (NSString*) CFBridgingRelease(CFUUIDCreateString(NULL, theUUID));
            CFRelease(theUUID);
        }
        [defs setObject:instanceId forKey:@"__errlog_instance_id"];
        NSLog(@"Errlog instance id is: %@", instanceId);
        
        sysVersion = [UIDevice currentDevice].systemVersion;
        
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        platform = [NSString stringWithUTF8String:machine];
        free(machine);
        
        NSLog(@"System version: %@", sysVersion);
        NSLog(@"Platform %@", platform);
        /*
         if ([platform isEqualToString:@"iPhone1,1"])    return @"iPhone 1G";
         if ([platform isEqualToString:@"iPhone1,2"])    return @"iPhone 3G";
         if ([platform isEqualToString:@"iPhone2,1"])    return @"iPhone 3GS";
         if ([platform isEqualToString:@"iPhone3,1"])    return @"iPhone 4";
         if ([platform isEqualToString:@"iPhone3,3"])    return @"Verizon iPhone 4";
         if ([platform isEqualToString:@"iPhone4,1"])    return @"iPhone 4S";
         if ([platform isEqualToString:@"iPod1,1"])      return @"iPod Touch 1G";
         if ([platform isEqualToString:@"iPod2,1"])      return @"iPod Touch 2G";
         if ([platform isEqualToString:@"iPod3,1"])      return @"iPod Touch 3G";
         if ([platform isEqualToString:@"iPod4,1"])      return @"iPod Touch 4G";
         if ([platform isEqualToString:@"iPad1,1"])      return @"iPad";
         if ([platform isEqualToString:@"iPad2,1"])      return @"iPad 2 (WiFi)";
         if ([platform isEqualToString:@"iPad2,2"])      return @"iPad 2 (GSM)";
         if ([platform isEqualToString:@"iPad2,3"])      return @"iPad 2 (CDMA)";
         if ([platform isEqualToString:@"i386"])         return @"Simulator";
         if ([platform isEqualToString:@"x86_64"])       return @"Simulator";
         */
        // Catch exceptions
        NSSetUncaughtExceptionHandler(&onUncaughtException);
     
        NSMutableDictionary *lastError = [[defs objectForKey:@"__errlog_last_error"] mutableCopy];
        if( lastError ) {
            NSLog(@"!! Last error: %@", lastError);
            lastError[@"severity"] = @(kSeverityError);
            [self report:lastError];
            [defs removeObjectForKey:@"__errlog_last_error"];
        }
        // Subscribe to events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:nil object:nil];
        [defs synchronize];
    }
    return self;
}

+(void)bufferException:(NSException *)exception {
    NSDictionary *data = @{ @"exception_class": NSStringFromClass([exception class]), @"stack": [exception callStackSymbols], @"text": exception.reason };
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs setObject:data forKey:@"__errlog_last_error"];
    [defs synchronize];
}

+(void)exception:(NSException *)exception data:(NSDictionary *)_data {
    NSMutableDictionary *data = [_data mutableCopy];
    data[@"exception_class"] = NSStringFromClass([exception class]);
    data[@"stack"] = [exception callStackSymbols];
    data[@"text"] = exception.reason;
    data[@"severity"] = @(kSeverityError);
    [me report:data];    
}

-(void)handleNotification:(NSNotification*) notification {
    NSString *name = notification.name;
    if( [name isEqualToString:UIApplicationDidBecomeActiveNotification] ) {
        sessionStartedAt = [NSDate new];
        NSNumber *last = [defs objectForKey:@"__errlog_last_session"];
        if( !last ) {
            NSLog(@"There is no last session to report");
        }
        else {
            NSLog(@"Report last session time: %@", last);
        }
        [self report: @{ @"action": @"session_started" }];
        [Errlog trace:@"Started!" data:nil];
    }
    else if( [name isEqualToString:UIApplicationWillResignActiveNotification] ) {
        NSTimeInterval sessionTime = -[sessionStartedAt timeIntervalSinceNow];
        NSLog(@"Session time was: %g", sessionTime);
        [defs setObject:@(sessionTime) forKey:@"__errlog_last_session"];
        [defs synchronize];
    }
}

-(NSData *)pack:(NSDictionary *)payload {
    NSMutableData *buffer = [NSMutableData new];
    [buffer appendBytes:"\x01" length:1];
    NSData *encodedPayload = [[[payload JSONRepresentation] dataUsingEncoding:NSUTF8StringEncoding] gzipDeflate];
    [buffer appendData: encodedPayload];
    
    // Sign
    NSMutableData *tmp = [encodedPayload mutableCopy];
    [tmp appendData:accountSecret];
    [buffer appendData: [tmp sha256Digest]];
    
    return buffer;
}

-(NSDictionary*) unpack:(NSData*) data {
    const BytePtr bytes = (BytePtr) data.bytes;
    if( bytes[0] != 1 )
        [NSException raise: @"Errlog" format: @"Invalid block type: %d", bytes[0]];
    NSUInteger data_length = data.length - 1 - 32;
    NSData *compressed = [data subdataWithRange:NSMakeRange(1, data_length)];
    
    // Check signature
    NSData *signature = [data subdataWithRange:NSMakeRange(data_length+1, 32)];
    if( signature.length != 32 )
        [NSException raise: @"Errlog" format:@"Invalid block fomrmat, signature part length %d (should be 32)", signature.length];
    
    NSMutableData *tmp = [compressed mutableCopy];
    [tmp appendData:accountSecret];
    if( ![[tmp sha256Digest] isEqualToData:signature] ) {
        NSLog(@"!** Errlog: signatore mismatch");
        return nil;
    }
    
    return [[[NSString alloc] initWithData:[compressed gzipInflate] encoding:NSUTF8StringEncoding] JSONValue];
}

-(void)reportLog:(NSString*)text severity:(NSUInteger)severity data:(NSDictionary*)_data {
    NSMutableDictionary * data = _data ? [_data mutableCopy] : [NSMutableDictionary new];
    data[@"severity"] = @(severity);
    data[@"text"] = text;
    [self report: data];
}

+(void)trace:(NSString *)text data:(NSDictionary *)data {
    [me reportLog:text severity:kSeverityTrace data:data];
}

+(void)warning:(NSString *)text data:(NSDictionary *)data {
    [me reportLog:text severity:kSeverityWarning data:data];
}

+(void)error:(NSString *)text data:(NSDictionary *)data {
    [me reportLog:text severity:kSeverityError data:data];
}

static const char *guidChars = "1234567890_-qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM";

static NSString* RandomId(NSUInteger length) {
    static unsigned gclen;
    if( !gclen ) {
        gclen = strlen(guidChars);
        srand(clock());
    }
    char* buffer = (char*)malloc(length+1), *p = buffer;
    
    for(unsigned i=length; i>0; i--) *p++ = guidChars[rand() % gclen];
    
    return [[NSString alloc] initWithBytesNoCopy:buffer length:length encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

-(void)report:(NSDictionary*) _data {
    
    NSDictionary *params = @{ @"app_id": accontId };
    
    NSMutableDictionary *data = [_data mutableCopy];
    data[@"platform"] = @"ios";
    data[@"hardware"] = platform;
    data[@"os_version"] = sysVersion;
    data[@"instance_id"] = instanceId;
    data[@"application"] = applicationName;
    
    if( !data[@"severity"] )
        data[@"severity"] = @(kSeverityStats);
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:reportUrl
                                                           cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval:54.0];
    
    request.HTTPMethod = @"POST";
    
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"charset=utf-8" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request addValue:@"gzip" forHTTPHeaderField:@"Accepts-Encoding"];
    
    
    NSMutableData* body = [NSMutableData data];
    
    NSString* boundary = RandomId(64);
    
    [request setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary] forHTTPHeaderField:@"Content-Type"];
    NSData *boundaryData = [[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding];
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [body appendData:boundaryData];
        [body appendData: [[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@\r\n", key, obj] dataUsingEncoding:NSUTF8StringEncoding]];
    }];
    
    [body appendData:boundaryData];
    NSData *binaryData = [self pack:data];
    
    [body appendData: [@"Content-Disposition: form-data; name=\"file\"; filename=\"report.bin\"\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData: binaryData];
    [body appendData: [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setValue:[NSString stringWithFormat:@"%d", [body length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body];
    
    NSLog(@" ERRLOG >>> ");
    
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue currentQueue]
                           completionHandler:^(NSURLResponse *response, NSData *rdata, NSError *error) {
                               if( error ) {
                                   NSLog(@" <<< Errlog ERROR");
                               }
                               else
                                   NSLog(@" <<< Errlog OK (%d)", [rdata length]);
                               
                           }];
    
}

@end
