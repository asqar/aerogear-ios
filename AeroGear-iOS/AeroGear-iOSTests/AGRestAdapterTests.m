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

static NSString *const PROJECTS = @"[{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]},{\"id\": 2,\"title\":\"Second Project\",\"style\":\"project-64-144-230\",\"tasks\":[]}]";

static NSString *const PROJECT = @"{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]}";

static NSString *const TASKS = @"[{\"id\":10,\"title\":\"A Task\",\"description\":\"empty descr\",\"date\":\"2013-04-24\"}, {\"id\":11,\"title\":\"A second Task\",\"description\":\"empty descr\",\"date\":\"2013-02-12\"}]";

static NSString *const TASK = @"{\"id\":10,\"title\":\"A Task\",\"description\":\"empty descr\",\"date\":\"2013-04-24\"}";

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

    // set correct content-type otherwise AFNetworking
    // will complain because it expects JSON response
    [AGMockURLProtocol setHeaders:[NSDictionary
                                   dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"]];

    NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];
    
    AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
    [config setBaseURL:baseURL];
    [config setName:@"projects"];
    [config setTimeout:1]; // this is just for testing of testSaveWithTimeout
    
    _restPipe = [AGRESTPipe pipeWithConfig:config];
}

-(void)tearDown {
    // reset http mock state so it is not propagated to other tests
    [AGMockURLProtocol setStatusCode:200];
	[AGMockURLProtocol setResponseData:nil];
	[AGMockURLProtocol setError:nil];
    [AGMockURLProtocol setResponseDelay:0];
    [AGMockURLProtocol setHeaders:nil];
    // finally, unregister it from the runtime
    [NSURLProtocol unregisterClass:[AGMockURLProtocol class]];

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

-(void)testSaveWithTimeout {
    // here we simulate POST
    // for iOS 5 and iOS 6 the timeout should be honoured correctly
    // regardless of the iOS 5 bug 
    
    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];

    
    // simulate delay in response
    // Note that pipe has been default configured for a timeout in 1 sec
    // here we simulate a delay of 2 sec
    [AGMockURLProtocol setResponseDelay:2];
    
    [_restPipe save:project success:^(id responseObject) {
        STFail(@"%@", @"should NOT have been called");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
        _finishedFlag = YES;

    }];
 
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testSaveExistingWithTimeout {
    // here we simulate PUT
    // for iOS 5 and iOS 6 the timeout should be honoured correctly
    // regardless of the iOS 5 bug

    [AGMockURLProtocol setResponseData:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"1", @"id", @"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];
    
    
    // simulate delay in response
    // Note that pipe has been default configured for a timeout in 1 sec
    // here we simulate a delay of 2 sec
    [AGMockURLProtocol setResponseDelay:2];
    
    [_restPipe save:project success:^(id responseObject) {
        STFail(@"%@", @"should NOT have been called");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
        _finishedFlag = YES;
        
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testCancel {
    NSDate *startTime = [NSDate date];
    
    [AGMockURLProtocol setResponseData:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];
    
    // simulate delay in response
    [AGMockURLProtocol setResponseDelay:2];
    
    [_restPipe read:^(id responseObject) {
        STFail(@"success should not have been called");
        _finishedFlag = YES;
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"failure should not have been called");
    }];
    
    // cancel the request
    // Note that no callbacks will be called after this
    [_restPipe cancel];

    // wait until either _finishedFlag is set to true (e.g. test failed)
    // or timeout expired (no need to wait for more than the timeout set on the pipe) 
    while (!_finishedFlag && [startTime timeIntervalSinceNow] > -1)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
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


-(void)testReadNestedObject {
    [AGMockURLProtocol setResponseData:[TASK dataUsingEncoding:NSUTF8StringEncoding]];
    
    // read a nested TASK for a given PROJECT.
    // /project/1/tasks/10
    [_restPipe read:@"1"
            resourcePath:@"tasks/10"
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

-(void)testReadAllNestedObjects {
    [AGMockURLProtocol setResponseData:[TASKS dataUsingEncoding:NSUTF8StringEncoding]];
    
    // read all nested TASK's for a given PROJECT.
    // /project/1/tasks
    [_restPipe read:@"1"
       resourcePath:@"tasks"
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

-(void)testSaveNewNestedObject {
    [AGMockURLProtocol setResponseData:[TASK dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* task = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"A task", @"title",
                                    @"empty descr", @"description",
                                    @"2013-04-24", @"date", nil];
    
    
    [_restPipe save:task
       resourcePath:@"1/tasks"
            success:^(id responseObject) {
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

-(void)testSaveExistingNestedObject {
    [AGMockURLProtocol setResponseData:[TASK dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* task = [NSMutableDictionary
                                 dictionaryWithObjectsAndKeys:@"10", @"id", @"A task", @"title",
                                 @"empty descr", @"description",
                                 @"2013-04-24", @"date", nil];
    
    
    [_restPipe save:task
       resourcePath:@"1/tasks"
            success:^(id responseObject) {
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

-(void)testRemoveNestedObject {
    [AGMockURLProtocol setResponseData:[TASK dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSMutableDictionary* task = [NSMutableDictionary
                                 dictionaryWithObjectsAndKeys:@"10", @"id", @"A task", @"title",
                                 @"empty descr", @"description",
                                 @"2013-04-24", @"date", nil];
    
    
    [_restPipe remove:task
                resourcePath:@"1/tasks"
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
