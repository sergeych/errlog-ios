//
//  NSData+zlib.h
//  LifeMoments
//
//  Created by Сергей Чернов on 16.04.13.
//
//

#import <Foundation/Foundation.h>

@interface NSData (zlib)

- (NSData *)gzipInflate;
- (NSData *)gzipDeflate;

@end
