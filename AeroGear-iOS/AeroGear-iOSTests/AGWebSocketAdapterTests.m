/*
 * JBoss, Home of Professional Open Source
 * Copyright 2012, Red Hat, Inc., and individual contributors
 * by the @authors tag. See the copyright.txt in the distribution for a
 * full listing of individual contributors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <SenTestingKit/SenTestingKit.h>
#import "AGWebSocketAdapter.h"

@interface AGWebSocketAdapterTests : SenTestCase

@end

@implementation AGWebSocketAdapterTests{
    BOOL _finishedFlag;
}

-(void) testWebSocketAdapter {
    
    AGWebSocketAdapter* wsa = [AGWebSocketAdapter pipeForURL:[NSURL URLWithString:@"ws://echo.websocket.org"] authModule:nil];
    
    NSDictionary* object = [NSDictionary dictionaryWithObjectsAndKeys:@"Mark", @"firstname", nil];
    
    // handlers for 'receiving' and 'on error':
    [wsa read:^(id responseObject) {
        NSLog(@"\n\n=======> %@", responseObject);
    } failure:^(NSError *error) {
        NSLog(@"=======> %@", error);
    }];

    // callbacks are not really needed on 'send'..
    [wsa save:object success:nil failure:nil];
    
    
    
    ///// QUESTION: close.... otherwise the damn socket is up, 4ewa 
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
    
    

}

@end
