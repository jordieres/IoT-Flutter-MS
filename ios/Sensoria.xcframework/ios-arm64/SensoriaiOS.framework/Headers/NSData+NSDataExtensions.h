//
//  NSData+NSDataExtensions.h
//  SensoriaLab
//
//  Created by Ryan Goce on 9/16/14.
//  Copyright (c) 2014 Sensoria Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

float accelToFloat(int proto, int range, uint16_t s);
float byteToGs(Byte b);

@interface NSData (NSDataExtensions)

-(double)doubleInLocation:(int)location;
-(float)floatInLocation:(int)location;
-(int)intInLocation:(int)location;
-(short)shortInLocation:(int)location;
-(Byte)byteInLocation:(int)location;
-(Byte)byteInLocation:(int)location bitPos:(size_t) bitpos bitLen:(size_t) bitlen;
-(int) read24bit:(int) pos;
-(NSString *)hexadecimalString;
-(const uint8_t *)toUnsafePointer;

@end
