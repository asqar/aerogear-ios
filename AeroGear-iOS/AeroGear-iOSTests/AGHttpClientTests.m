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
#import "AGHttpClient.h"

#import "AGPipeline.h"
#import "AGMockURLProtocol.h"

static NSString *const PROJECTS = @"[{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]},{\"id\":                 2,\"title\":\"Second Project\",\"style\":\"project-64-144-230\",\"tasks\":[]}]";

@interface AGHttpClientTests : SenTestCase

@end

@implementation AGHttpClientTests{
    BOOL _finishedFlag;
   
    AGHttpClient* _restClient;
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
    
    _restClient = [AGHttpClient clientFor:baseURL];
    _restClient.parameterEncoding = AFJSONParameterEncoding;
    
    _finishedFlag = NO;
}

-(void)tearDown {
    [NSURLProtocol unregisterClass:[AGMockURLProtocol class]];
    
    _restClient = nil;
    
    [super tearDown];
}

-(void)testHttpClientCreation {
    STAssertNotNil(_restClient, @"client should not be nil");
}

-(void) testGetProjects {
    [AGMockURLProtocol setResponseData:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];
    
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

@end