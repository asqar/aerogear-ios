/*
 * JBoss, Home of Professional Open Source.
 * Copyright Red Hat, Inc., and individual contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <SenTestingKit/SenTestingKit.h>
#import "AGRESTPipe.h"
#import "AGMockURLProtocol.h"

static NSString *const PROJECTS = @"[{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]},{\"id\":                 2,\"title\":\"Second Project\",\"style\":\"project-64-144-230\",\"tasks\":[]}]";

static NSString *const PROJECT = @"{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]}";

@interface AGRestAdapterTests : SenTestCase

@end

@implementation AGRestAdapterTests {
    BOOL _finishedFlag;
    
    id<AGPipe> _restPipe;
}

-(void)setUp {
    [super setUp];

    // register AGFakeURLProtocol to fake HTTP comm.
    [NSURLProtocol registerClass:[AGMockURLProtocol class]];
    [AGMockURLProtocol setStatusCode:200];
	[AGMockURLProtocol setHeaders:nil];
	[AGMockURLProtocol setResponseData:nil];
	[AGMockURLProtocol setError:nil];
    
    // set correct content-type otherwise AFNetworking
    // will complain because it expects JSON response
    [AGMockURLProtocol setHeaders:[NSDictionary
                                   dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"]];

    NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];
    
    AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
    [config setBaseURL:baseURL];
    [config setName:@"projects"];
    
    _restPipe = [AGRESTPipe pipeWithConfig:config];
}

-(void)tearDown {
    [NSURLProtocol unregisterClass:[AGMockURLProtocol class]];
    [AGMockURLProtocol setStatusCode:200];
	[AGMockURLProtocol setHeaders:nil];
	[AGMockURLProtocol setResponseData:nil];
	[AGMockURLProtocol setError:nil];
    
    [super tearDown];
}

-(void)testCreateRESTfulPipe {
    STAssertNotNil(_restPipe, @"pipe creation");
}

-(void)testPipeTypeProperty {
    STAssertEqualObjects(@"REST", _restPipe.type, @"verifying the (default) type");
}

-(void)testPipeURLProperty {
    STAssertEqualObjects([NSURL URLWithString:@"http://server.com/context/projects"], _restPipe.URL, @"verifying the given URL");
}

-(void)testRead {
    [AGMockURLProtocol setResponseData:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

    [_restPipe read:^(id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        _finishedFlag = YES;

    } failure:^(NSError *error) {
        _finishedFlag = YES;        
        STFail(@"should not fail");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testReadWithTimeout {
    [AGMockURLProtocol setResponseData:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_restPipe read:^(id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"should not fail");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testReadOneObjectWithStringArgument {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_restPipe read:@"1"
            success:^(id responseObject) {
                STAssertNotNil(responseObject, @"response should not be nil");
                _finishedFlag = YES;
                
            } failure:^(NSError *error) {
                _finishedFlag = YES;
                STFail(@"should not fail");
            }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testReadOneObjectWithIntegerArgument {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_restPipe read:[NSNumber numberWithInt:1]
            success:^(id responseObject) {
                STAssertNotNil(responseObject, @"response should not be nil");
                _finishedFlag = YES;
            } failure:^(NSError *error) {
                _finishedFlag = YES;
                STFail(@"should not fail");
            }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testReadOneObjectWithNil {
    [_restPipe read:nil
            success:^(id responseObject) {
                _finishedFlag = YES;
                STFail(@"should not successed");
                
            } failure:^(NSError *error) {
                _finishedFlag = YES;
            }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testSaveNew {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];

    [_restPipe save:project success:^(id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        STAssertEqualObjects(@"POST", [AGMockURLProtocol methodCalled], @"POST should have been called");
        _finishedFlag = YES;

    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"should not fail");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testSaveExisting {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"1", @"id", @"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];
    
    [_restPipe save:project success:^(id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        STAssertEqualObjects(@"PUT", [AGMockURLProtocol methodCalled], @"PUT should have been called");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"should not fail");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testRemove {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"1", @"id", @"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];

    
    [_restPipe remove:project success:^(id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        _finishedFlag = YES;

    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"should not fail");
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testNSNullValueOnSave {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    //fake Tag: id + title
    NSDictionary* fakeTag = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"id", @"Fake TAG", @"title", nil];
    
    [_restPipe save:fakeTag success:^(id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");        
        _finishedFlag = YES;
 
    } failure:^(NSError *error) {
        _finishedFlag = YES;        
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testNSNullValueOnRemove {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    //fake Tag: id + title
    NSDictionary* fakeTag = [NSDictionary dictionaryWithObjectsAndKeys:[NSNull null], @"id", @"Fake TAG", @"title", nil];
    
    [_restPipe remove:fakeTag success:^(id responseObject) {
        STFail(@"success not expected");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testRemoveNilValue {
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    [_restPipe remove:nil success:^(id responseObject) {
        STFail(@"success not expected");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testAccepts {
    STAssertTrue([AGRESTPipe accepts:@"REST"], @"type '%@' should be accepted", @"REST");
    [self assertNotAcceptedType: nil];
    [self assertNotAcceptedType: @"bogus"];
    [self assertNotAcceptedType:[@"REST" lowercaseString]];
}

-(void) assertNotAcceptedType:(NSString*) type {
    STAssertFalse([AGRESTPipe accepts:type], @"type '%@' should not be accepted", type);
}

@end
