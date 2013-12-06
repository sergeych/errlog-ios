//
//  ErrlogPacker.h
//  LifeMoments
//
//  Created by Сергей Чернов on 16.04.13.
//
//

#import <Foundation/Foundation.h>

// Use instead NSLog, best override with define
#define NSLog(...) ELLog(__VA_ARGS__)

void ELLog(NSString *format, ...);

@interface Errlog : NSObject

/** 
 * Initialize the Errlog engine.
 *
 * Call it eary in your appdelegate. Note that including errlog.h will redefine NSLog
 * so log will be collected and reported.
 */
+(void)useToken:(NSString*)token application:(NSString*)name;

+(void)trace:(NSString*)text data:(NSDictionary*)data;
+(void)warning:(NSString*)text data:(NSDictionary*)data;
+(void)error:(NSString*)text data:(NSDictionary*)data;
+(void)exception:(NSException*)exception data:(NSDictionary*)data;

/**
 * Report an event with a given name and optional dictionary with data, can be null.
 */
+(void)event:(NSString*)name data:(NSDictionary*)data;

// Following are internal methods that are not intended for direct use

+(void)useAccountId:(NSString*) accId secret:(NSString*)accSecret application:(NSString*)name;
+(void) setUrl:(NSURL*)url;
+(Errlog*) instance;

-(id)initWithAccountId:(NSString*)accId secret:(NSString*)accSecret application:(NSString*)name;

-(NSData*)pack:(NSDictionary*)payload;
-(NSDictionary*)unpack:(NSData*)data;


@end
