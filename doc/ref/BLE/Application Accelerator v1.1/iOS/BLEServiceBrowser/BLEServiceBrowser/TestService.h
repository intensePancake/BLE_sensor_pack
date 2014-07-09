//
//  TestService.h
//  BLEServiceBrowser
//
//  Created by Warren Dockerty on 03/06/2013.
//  Copyright (c) 2013 Bluetooth SIG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestService : NSObject
@property (strong, nonatomic) NSString *title;
@property (strong, nonatomic) NSString *uuid;

-(id)initWithParams:(NSString *)titleParam uuidParam:(NSString *)uuidData;

@end
