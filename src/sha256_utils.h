//
//  sha256_utils.h
//  Errlog project client
//
//  Created by Sergey Chernov on 28.10.11.
//  Copyright (c) 2011 Thrift. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Sha256)

-(NSData*)sha256Digest;
-(NSString*)sha256hex;

@end

@interface NSData (Sha256)

-(NSData*)sha256Digest;
-(NSString*)sha256hex;

@end
