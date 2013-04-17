//
//  sha256_utils.m
//  Errlog client
//
//  Created by Sergey Chernov on 28.10.11.
//  Copyright (c) 2011 Thrift. All rights reserved.
//

#import "sha256_utils.h"
#include "sha256.h"

@implementation NSString (Sha256)

-(NSData *)sha256Digest {
    uint8 *digest = malloc(SHA256_DIGEST_SIZE);
    sha256_context ctx;
    sha256_starts(&ctx);
    const char* str = [self cStringUsingEncoding:NSUTF8StringEncoding];
    sha256_update(&ctx, (uint8*) str, strlen(str));
    sha256_finish(&ctx, digest);
    return [NSData dataWithBytesNoCopy:digest length:SHA256_DIGEST_SIZE freeWhenDone:YES];
}

-(NSString *)sha256hex {
    NSMutableString *buffer = [NSMutableString stringWithCapacity:SHA256_DIGEST_SIZE*2];
    unsigned char *digest = (unsigned char*)[[self sha256Digest] bytes];
    for(NSUInteger i=0; i<SHA256_DIGEST_SIZE; i++ ) 
        [buffer appendFormat:@"%02x", *digest++ ];
    return buffer;
}

@end

@implementation NSData(Sha256)

-(NSData *)sha256Digest {
    uint8 *digest = malloc(SHA256_DIGEST_SIZE);
    sha256_context ctx;
    sha256_starts(&ctx);
    const char* str = [self bytes];
    sha256_update(&ctx, (uint8*) str, self.length);
    sha256_finish(&ctx, digest);
    return [NSData dataWithBytesNoCopy:digest length:SHA256_DIGEST_SIZE freeWhenDone:YES];
}

-(NSString *)sha256hex {
    NSMutableString *buffer = [NSMutableString stringWithCapacity:SHA256_DIGEST_SIZE*2];
    unsigned char *digest = (unsigned char*)[[self sha256Digest] bytes];
    for(NSUInteger i=0; i<SHA256_DIGEST_SIZE; i++ )
        [buffer appendFormat:@"%02x", *digest++ ];
    return buffer;
}

@end
