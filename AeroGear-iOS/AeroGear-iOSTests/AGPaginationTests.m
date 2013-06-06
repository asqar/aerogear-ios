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

#import "AGRESTPipe.h"
#import "AGNSMutableArray+Paging.h"

static NSString *const RESPONSE_FIRST  = @"[{\"id\":1,\"color\":\"black\",\"brand\":\"BMW\"}]";
static NSString *const RESPONSE_SECOND = @"[{\"id\":2,\"color\":\"black\",\"brand\":\"FIAT\"}]";
static NSString *const RESPONSE_TWO_ITEMS = @"[{\"id\":1,\"color\":\"black\",\"brand\":\"BMW\"},{\"id\":2,\"color\":\"black\",\"brand\":\"FIAT\"}]";

//------- convienience blocks that handle mocking of http comm. -----------

static void (^mockResponseWithHeaders)(NSData*, int status, NSDictionary*) =
    ^(NSData* data, int status, NSDictionary* appendHeaders) {
    
    NSMutableDictionary* headers = [NSMutableDictionary
                                    dictionaryWithObject:@"application/json; charset=utf-8" forKey:@"Content-Type"];
    
    if (appendHeaders != nil)
        [headers addEntriesFromDictionary:appendHeaders];
    
    
	[OHHTTPStubs addRequestHandler:^(NSURLRequest *request, BOOL onlyCheck) {
        return [OHHTTPStubsResponse responseWithData:data
                                          statusCode:status
                                        responseTime:0
                                             headers:headers];
	}];
};

static void (^mockResponseStatus)(int) = ^(int status) {
    mockResponseWithHeaders([NSData data], status, nil);
};


static void (^mockResponse)(NSData*) = ^(NSData* data) {
    mockResponseWithHeaders(data, 200, nil);
};

//-------------------------------------------------------------------------

@interface AGPaginationTests : SenTestCase

@end

@implementation AGPaginationTests {
    BOOL _finishedFlag;
    
    id<AGPipe> _pipe;
}

-(void)setUp {
    [super setUp];
    
    AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
    [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
    [config setName:@"cars"];
    
    [config setPageConfig:^(id<AGPageConfig> pageConfig) {
        [pageConfig setNextIdentifier:@"AG-Links-Next"];
        [pageConfig setPreviousIdentifier:@"AG-Links-Previous"];
        [pageConfig setMetadataLocation:@"header"];
    }];

    _pipe = [AGRESTPipe pipeWithConfig:config];
}

-(void)tearDown {
    // remove all handlers installed by test methods
    // to avoid any interference
    [OHHTTPStubs removeAllRequestHandlers];

    [super tearDown];
}

-(void)testCreateRESTfulPipe {
    STAssertNotNil(_pipe, @"pipe creation");
}

-(void)testNext {
    // set the mocked response for the first page
    mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                            200,
                            @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=1&limit=1]"});
    
    __block NSMutableArray *pagedResultSet;

    [_pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {
        pagedResultSet = responseObject;  // page 1
        
        // hold the "id" from the first page, so that
        // we can match with the result when we move
        // to the next page down in the test.
        NSString *car_id = [self extractCarId:responseObject];
        
        // set the mocked response for the second page
        mockResponse([RESPONSE_SECOND dataUsingEncoding:NSUTF8StringEncoding]);

        // move to the next page
        [pagedResultSet next:^(id responseObject) {
            
            STAssertFalse([car_id isEqualToString:[self extractCarId:responseObject]], @"id's should not match.");
            
            _finishedFlag = YES;
            
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            STFail(@"%@", error);
        }];
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"%@", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testPreviousFromFirstPage {
    // set the mocked response for the first page
    mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                            200,
                            @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=1&limit=1]"});

    __block NSMutableArray *pagedResultSet;
    
    // fetch the first page
    [_pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {
        pagedResultSet = responseObject;  // page 1
        
        // simulate "Bad Request" as in the case of AGController
        // when you try to move back from the first page
        mockResponseStatus(400);
        
        // move back to an invalid page
        [pagedResultSet previous:^(id responseObject) {
            _finishedFlag = YES;
            
            STFail(@"should not have called");
            
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            
            // Note: "failure block" was called here
            // because we were at the first page and we
            // requested to go previous, that is to a non
            // existing page ("AG-Links-Previous" indentifier
            // was missing from the headers response and we
            // got a 400 http error).
            //
            // Note that this is not always the case, cause some
            // remote apis can send back either an empty list or
            // list with results, instead of throwing an error(see GitHub integration testcase)
        }];
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"%@", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testMoveNextAndPrevious {
    // set the mocked response for the first page
    mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                            200,
                            @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=1&limit=1]"});
    
    __block NSMutableArray *pagedResultSet;

    // fetch the first page
    [_pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]}
                  success:^(id responseObject) {
        pagedResultSet = responseObject;  // page 1
        
        // hold the "car id" from the first page, so that
        // we can match with the result when we move
        // to the next page down in the test.
        NSString *car_id = [self extractCarId:responseObject];
        
        mockResponseWithHeaders([RESPONSE_SECOND dataUsingEncoding:NSUTF8StringEncoding],
                                200,
                                @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=2&limit=1]",
                                  @"AG-Links-Previous":@"http://server.com/context/?color=black&offset=0&limit=1]"});
        
        // move to the second page
        [pagedResultSet next:^(id responseObject) {

            // set the mocked response for the first page again
            mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                                    200,
                                    @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=1&limit=1]"});

            // move backwards (aka. page 1)
            [pagedResultSet previous:^(id responseObject) {
                
                STAssertEqualObjects(car_id, [self extractCarId:responseObject], @"id's must match.");
                
                _finishedFlag = YES;
            } failure:^(NSError *error) {
                _finishedFlag = YES;
                STFail(@"%@", error);
            }];
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            STFail(@"%@", error);
        }];
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"%@", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testParameterProvider {
    // the default parameter provider
    AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
    [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];    
    [config setName:@"cars"];
    [config setPageConfig:^(id<AGPageConfig> pageConfig) {
        [pageConfig setNextIdentifier:@"AG-Links-Next"];
        [pageConfig setPreviousIdentifier:@"AG-Links-Previous"];
        [pageConfig setParameterProvider:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]}];
        [pageConfig setMetadataLocation:@"header"];
    }];
    
    _pipe = [AGRESTPipe pipeWithConfig:config];
    
    mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                            200,
                            @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=1&limit=1]"});

    [_pipe readWithParams:nil success:^(id responseObject) {

            STAssertTrue([responseObject count] == 1, @"size should be one.");

            // set the mocked response for the first page
            mockResponse([RESPONSE_TWO_ITEMS dataUsingEncoding:NSUTF8StringEncoding]);
        
        // override the results per page from parameter provider
        [_pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:2]} success:^(id responseObject) {
            
            STAssertTrue([responseObject count] == 2, @"size should be two.");
            
           _finishedFlag = YES;
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            STFail(@"%@", error);
        }];
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"%@", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testBogusNextIdentifier {
  AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
    [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];        
    [config setName:@"cars"];
    [config setPageConfig:^(id<AGPageConfig> pageConfig) {
        [pageConfig setMetadataLocation:@"header"];
        // wrong setting:
        [pageConfig setNextIdentifier:@"foo"];

    }];
    
    _pipe = [AGRESTPipe pipeWithConfig:config];
    
    // set the mocked response for the first page
    mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                            200,
                            @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=1&limit=1]",
                            @"AG-Links-Previous":@"http://server.com/context/?color=black&offset=0&limit=1]"});

    __block NSMutableArray *pagedResultSet;
    
    [_pipe readWithParams:@{@"color" : @"black", @"offset" : @"0", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {
        
        pagedResultSet = responseObject;
        
        // simulate "Bad Request" as in the case of AGController
        // because the nextIdentifier is invalid ("foo" instead of "AG-Links-Next")
        mockResponseStatus(400);
        
        [pagedResultSet next:^(id responseObject) {
            
            STFail(@"should not have called");
            
            _finishedFlag = YES;
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            
            // Note: failure is called cause the next identifier
            // is invalid so we can't move to the next page
            
        }];
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"%@", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testBogusPreviousIdentifier {
    AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
    [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
    [config setName:@"cars"];
    [config setPageConfig:^(id<AGPageConfig> pageConfig) {
        [pageConfig setMetadataLocation:@"header"];
        // wrong setting:
        [pageConfig setPreviousIdentifier:@"foo"];
    }];
    
    _pipe = [AGRESTPipe pipeWithConfig:config];
    
    // set the mocked response for the first page
    mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                            200,
                            @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=3&limit=1]",
                            @"AG-Links-Previous":@"http://server.com/context/?color=black&offset=1&limit=1]"});

    
    __block NSMutableArray *pagedResultSet;
    
    [_pipe readWithParams:@{@"color" : @"black", @"offset" : @"2", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {
        
        pagedResultSet = responseObject;
        
        // simulate "Bad Request" as in the case of AGController
        // because the previousIdentifier is invalid ("foo" instead of "AG-Links-Previous")
        mockResponseStatus(400);
        
        [pagedResultSet next:^(id responseObject) {
            
            STFail(@"should not have called");
            
            _finishedFlag = YES;
        } failure:^(NSError *error) {
            _finishedFlag = YES;
            
            // Note: failure is called cause the previoys identifier
            // is invalid so we can't move to the previous page
            
        }];
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"%@", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

-(void)testBogusMetadataLocation {
    AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
    [config setBaseURL:[NSURL URLWithString:@"http://server.com/context/"]];
    [config setName:@"cars"];
    [config setPageConfig:^(id<AGPageConfig> pageConfig) {
        // wrong setting:
        [pageConfig setMetadataLocation:@"body"];
    }];

    _pipe = [AGRESTPipe pipeWithConfig:config];
    
    __block NSMutableArray *pagedResultSet;

    // set the mocked response for the first page
    mockResponseWithHeaders([RESPONSE_FIRST dataUsingEncoding:NSUTF8StringEncoding],
                            200,
                            @{@"AG-Links-Next":@"http://server.com/context/?color=black&offset=3&limit=1]",
                            @"AG-Links-Previous":@"http://server.com/context/?color=black&offset=1&limit=1]"});

    
    [_pipe readWithParams:@{@"color" : @"black", @"offset" : @"2", @"limit" : [NSNumber numberWithInt:1]} success:^(id responseObject) {
        
        pagedResultSet = responseObject;

        // simulate "Bad Request" as in the case of AGController
        // because the metadata to extract next Identifiers
        // are located in the "headers" not in the "body"
        // as set in the config.
        mockResponseStatus(400);

        [pagedResultSet next:^(id responseObject) {
            
            STFail(@"should not have called");
            
            _finishedFlag = YES;
        } failure:^(NSError *error) {
            _finishedFlag = YES;
        }];
        
    } failure:^(NSError *error) {
        _finishedFlag = YES;
        STFail(@"%@", error);
    }];
    
    // keep the run loop going
    while(!_finishedFlag) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

// helper method to extract the "car id" from the result set
-(NSString*)extractCarId:(NSArray*) responseObject {
    return [[[responseObject objectAtIndex:0] objectForKey:@"id"] stringValue];
}

@end
