//
//  TestService.m
//  BLEServiceBrowser
//
//  Created by Warren Dockerty on 03/06/2013.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import "TestService.h"

@implementation TestService
@synthesize title;
@synthesize uuid;

-(id)initWithParams:(NSString *)titleData uuidParam:(NSString *)uuidData
{
    self = [super init];
    title = titleData;
    uuid = uuidData;
    
    return self;
}

@end
