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
#import <OHHTTPStubs/OHHTTPStubs.h>

#import "AGHttpClient.h"
#import "AGPipeline.h"

static NSString *const PROJECTS = @"[{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]},{\"id\":                 2,\"title\":\"Second Project\",\"style\":\"project-64-144-230\",\"tasks\":[]}]";

void (^mockResponseTimeout)(NSData*, int, NSTimeInterval) = ^(NSData* data, int status, NSTimeInterval responseTime) {
	[OHHTTPStubs addRequestHandler:^(NSURLRequest *request, BOOL onlyCheck) {
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:status
                                        responseTime:responseTime
                                             headers:@{@"Content-Type": @"application/json; charset=utf-8"}];
        
	}];
};

void (^mockResponseStatus)(int) = ^(int status) {
    mockResponseTimeout([NSData data], status, 1);
};

void (^mockResponse)(NSData*) = ^(NSData* data) {
    mockResponseTimeout(data, 200, 1);
};

@interface AGHttpClientTests : SenTestCase

@end

// access the timer of the operation for the purpose of testing
@interface AFHTTPRequestOperation (Testing)
@property (nonatomic, retain) NSTimer* timer;
@end

@implementation AGHttpClientTests{
    BOOL _finishedFlag;
    
    AGHttpClient* _restClient;
}

-(void)setUp {
    [super setUp];
    
    NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];
    
    // Note: we set the timeout(sec) to a low level so that
    // we can test the timeout methods with adjusting response delay
    _restClient = [AGHttpClient clientFor:baseURL timeout:1];
    _restClient.parameterEncoding = AFJSONParameterEncoding;
    
    _finishedFlag = NO;
}

-(void)tearDown {
    // remove all handlers installed by test methods
    // to avoid any interference
    [OHHTTPStubs removeAllRequestHandlers];

    [super tearDown];
}

-(void)testHttpClientCreation {
    STAssertNotNil(_restClient, @"client should not be nil");
}

-(void)testGetProjects {
    // install the mock:
    mockResponse([PROJECTS dataUsingEncoding:NSUTF8StringEncoding]);
    
    [_restClient getPath:@"projects" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        _finishedFlag = YES;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        _finishedFlag = YES;
        STFail(@"should not have failed");
        
    } ];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testPostSuccessAndTimeoutTimerIsNil {
    // install the mock:
    mockResponse([PROJECTS dataUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];
    
    [_restClient postPath:@"projects" parameters:project success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        STAssertNil(operation.timer, @"timer should be nil");
        _finishedFlag = YES;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        STFail(@"should not have been called");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}


-(void)testPostFailureAndTimeoutTimerIsNil {
    // install the mock:
    mockResponseStatus(404);
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];
    
    [_restClient postPath:@"projects" parameters:project success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        STFail(@"should not have been called");
        _finishedFlag = YES;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        STAssertNil(operation.timer, @"timer should be nil");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testPutSuccessAndTimeoutTimerIsNil {
    // install the mock:
    mockResponse([PROJECTS dataUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];
    
    [_restClient putPath:@"projects/0" parameters:project success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        STAssertNil(operation.timer, @"timer should be nil");
        _finishedFlag = YES;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        STFail(@"should not have been called");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testPutFailureAndTimeoutTimerIsNil {
    // install the mock:
    mockResponseStatus(404);
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];
    
    [_restClient putPath:@"projects/0" parameters:project success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        STFail(@"should not have been called");
        _finishedFlag = YES;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        STAssertNil(operation.timer, @"timer should be nil");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testMultiplePostWithTimeoutConnection {
    // install the mock:
    mockResponse([PROJECTS dataUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableDictionary* projectFirst = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                         @"project-161-58-58", @"style", nil];
    
    [_restClient postPath:@"projects" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        
        NSMutableDictionary* projectSecond = [NSMutableDictionary
                                              dictionaryWithObjectsAndKeys:@"Second Project", @"title",
                                              @"project-111-45-51", @"style", nil];
        // install the mock:
        mockResponseTimeout([PROJECTS dataUsingEncoding:NSUTF8StringEncoding], 200, 2 /* two secs delay*/);
        
        [_restClient postPath:@"projects" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            STFail(@"should not have been called");
            _finishedFlag = YES;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            STAssertNil(operation.timer, @"timer should be nil");
            STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
            _finishedFlag = YES;
            
        } ];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        _finishedFlag = YES;
        STFail(@"should not have been called");
        
    } ];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testPutWithTimeoutConnection {
    mockResponseTimeout([PROJECTS dataUsingEncoding:NSUTF8StringEncoding], 200, 2 /* two secs delay*/);
    
    NSMutableDictionary* project = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                    @"project-161-58-58", @"style", nil];
    
    [_restClient putPath:@"projects/0" parameters:project success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        STFail(@"should not have been called");
        _finishedFlag = YES;
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        STAssertNil(operation.timer, @"timer should be nil");
        STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
        _finishedFlag = YES;
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testMultiplePutWithTimeoutConnection {
    // install the mock:
    mockResponse([PROJECTS dataUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableDictionary* projectFirst = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                         @"project-161-58-58", @"style", nil];
    
    [_restClient putPath:@"projects/0" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        
        NSMutableDictionary* projectSecond = [NSMutableDictionary
                                              dictionaryWithObjectsAndKeys:@"1", @"id", @"Second Project", @"title",
                                              @"project-111-45-51", @"style", nil];
        
        // install the mock:
        mockResponseTimeout([PROJECTS dataUsingEncoding:NSUTF8StringEncoding], 200, 2 /* two secs delay*/);
        
        [_restClient putPath:@"projects/1" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            STFail(@"should not have been called");
            _finishedFlag = YES;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            STAssertNil(operation.timer, @"timer should be nil");
            STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
            _finishedFlag = YES;
            
        } ];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        _finishedFlag = YES;
        STFail(@"should not have been called");
        
    } ];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testPostThenPutWithTimeoutConnection {
    // install the mock:
    mockResponse([PROJECTS dataUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableDictionary* projectFirst = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                         @"project-161-58-58", @"style", nil];
    
    [_restClient postPath:@"projects" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        
        NSMutableDictionary* projectSecond = [NSMutableDictionary
                                              dictionaryWithObjectsAndKeys:@"1", @"id", @"Second Project", @"title",
                                              @"project-111-45-51", @"style", nil];
        
        // install the mock:
        mockResponseTimeout([PROJECTS dataUsingEncoding:NSUTF8StringEncoding], 200, 2 /* two secs delay*/);
        
        [_restClient putPath:@"projects/1" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            STFail(@"should not have been called");
            _finishedFlag = YES;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            STAssertNil(operation.timer, @"timer should be nil");
            STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
            _finishedFlag = YES;
            
        } ];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        _finishedFlag = YES;
        STFail(@"should not have been called");
        
    } ];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testPutThenPostWithTimeoutConnection {
    // install the mock:
    mockResponse([PROJECTS dataUsingEncoding:NSUTF8StringEncoding]);
    
    NSMutableDictionary* projectFirst = [NSMutableDictionary
                                         dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                         @"project-161-58-58", @"style", nil];
    
    [_restClient putPath:@"projects/0" parameters:projectFirst success:^(AFHTTPRequestOperation *operation, id responseObject) {
        STAssertNotNil(responseObject, @"response should not be nil");
        
        NSMutableDictionary* projectSecond = [NSMutableDictionary
                                              dictionaryWithObjectsAndKeys:@"Second Project", @"title",
                                              @"project-111-45-51", @"style", nil];
        
        // install the mock:
        mockResponseTimeout([PROJECTS dataUsingEncoding:NSUTF8StringEncoding], 200, 2 /* two secs delay*/);
        
        [_restClient postPath:@"projects" parameters:projectSecond success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            STFail(@"should not have been called");
            _finishedFlag = YES;
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            
            STAssertNil(operation.timer, @"timer should be nil");
            STAssertEquals(-1001, [error code], @"should be equal to code -1001 [request time out]");
            _finishedFlag = YES;
            
        } ];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        _finishedFlag = YES;
        STFail(@"should not have been called");
        
    } ];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

@end