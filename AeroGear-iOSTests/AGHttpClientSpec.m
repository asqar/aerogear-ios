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

#import <Kiwi/Kiwi.h>
#import <objc/message.h>
#import "AGHttpClient.h"
#import "AGMultipart.h"
#import "AGHTTPMockHelper.h"
#import "AGRestAuthentication.h"
#import "AGRestAuthzModule.h"

// expose private methods of AGHttpClient for the purpose of testing
@interface AGHttpClient (Testing)

- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                                                  error:(NSError **) error;
@end

SPEC_BEGIN(AGHttpClientSpec)
/*
    describe(@"AGHttpClient", ^{

        NSString * const PROJECTS = @"[{\"id\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[]}, {\"id\":2,\"title\":\"Second Project\",\"style\":\"project-64-144-230\",\"tasks\":[]}]";

        __block BOOL finishedFlag;

        context(@"when newly created", ^{

            __block AGHttpClient* _restClient = nil;

            beforeEach(^{

                NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];

                _restClient = [AGHttpClient clientFor:baseURL];
            });

            afterEach(^{
                // remove all handlers installed by test methods
                // to avoid any interference
                [AGHTTPMockHelper clearAllMockedRequests];

                finishedFlag = NO;
            });

            it(@"should not be nil", ^{

                [_restClient shouldNotBeNil];
            });

            it(@"should successfully perform GET", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                [_restClient GET:@"projects" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
                    [responseObject shouldNotBeNil];

                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                } ];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"should successfully create multipart request with a combined multipart and params", ^{
                // create dummy NSData to send
                NSData *data = [@"Lorem ipsum dolor sit amet," dataUsingEncoding:NSUTF8StringEncoding];

                AGFileDataPart *part = [[AGFileDataPart alloc] initWithFileData:data name:@"file" fileName:@"file.txt" mimeType:@"text/plain"];

                // construct the payload with the file added
                NSDictionary *dict = @{@"key": @"value",@"secondkey": @"secondvalue",  @"file":part};

                NSError *error;
                NSURLRequest *request = [_restClient multipartFormRequestWithMethod:@"POST" path:@"foo" parameters:dict error:&error];

                // an error shouldn't not have occurred
                [error shouldBeNil];

                // access body stream
                NSInputStream *stream = request.HTTPBodyStream;

                // access body parts
                NSArray *parts = [stream valueForKeyPath:@"HTTPBodyParts"];

                // should match the number of params set
                [[theValue(parts.count) should] equal:theValue(3)];

                // should contain the params set
                [[[parts[0] valueForKeyPath:@"body"] should] equal:[@"value" dataUsingEncoding:NSUTF8StringEncoding]];
                [[[parts[1] valueForKeyPath:@"body"] should] equal:[@"secondvalue" dataUsingEncoding:NSUTF8StringEncoding]];
                [[[parts[2] valueForKeyPath:@"body"] should] equal:part.data];
            });
        });

        context(@"timeout should be honoured", ^{

            NSInteger const TIMEOUT_ERROR_CODE = -1001;

            __block AGHttpClient* _restClient = nil;

            beforeEach(^{
                NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];

                // Note: we set the timeout(sec) to a low level so that
                // we can test the timeout methods with adjusting response delay
                _restClient = [AGHttpClient clientFor:baseURL timeout:1];
            });

            afterEach(^{
                // remove all handlers installed by test methods
                // to avoid any interference
                [AGHTTPMockHelper clearAllMockedRequests];

                finishedFlag = NO;
            });

            it(@"when performing PUT", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                        status:200
                                   requestTime:2]; // two secs delay

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient PUT:@"projects/0" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {
                    // nope

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                    finishedFlag = YES;
                }];

                // NOTE:
                /// we set kiwi's shouldEventually to 5 secs > 2 secs of the simulated timeout
                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing POST", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                        status:200
                                   requestTime:2]; // two secs delay

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient POST:@"projects" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {
                    // nope

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                    finishedFlag = YES;
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing successive POST's and the second one timeouts", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient POST:@"projects" parameters:projectFirst success:^(NSURLSessionDataTask *task, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient POST:@"projects" parameters:projectSecond success:^(NSURLSessionDataTask *task, id responseObject) {
                        // nope
                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing successive PUT's and the second one timeouts", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient PUT:@"projects/0" parameters:projectFirst success:^(NSURLSessionDataTask *task, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"1", @"id", @"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    // install the mock:
                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient PUT:@"projects/1" parameters:projectSecond success:^(NSURLSessionDataTask *task, id responseObject) {
                        // nope

                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing POST then PUT and PUT timeouts", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient POST:@"projects" parameters:projectFirst success:^(NSURLSessionDataTask *task, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"1", @"id", @"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    // install the mock:
                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient PUT:@"projects/1" parameters:projectSecond success:^(NSURLSessionDataTask *task, id responseObject) {
                        // nope
                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing PUT then POST and POST timeouts", ^{

                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* projectFirst = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient PUT:@"projects/0" parameters:projectFirst success:^(NSURLSessionDataTask *task, id responseObject) {
                    [responseObject shouldNotBeNil];

                    NSMutableDictionary* projectSecond = [NSMutableDictionary
                            dictionaryWithObjectsAndKeys:@"Second Project", @"title",
                                                         @"project-111-45-51", @"style", nil];

                    // install the mock:
                    [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                            status:200
                                       requestTime:2]; // two secs delay

                    [_restClient POST:@"projects" parameters:projectSecond success:^(NSURLSessionDataTask *task, id responseObject) {
                        // nope
                    } failure:^(NSURLSessionDataTask *task, NSError *error) {
                        [[theValue(error.code) should] equal:theValue(TIMEOUT_ERROR_CODE)];
                        finishedFlag = YES;
                    } ];

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });
        });

        context(@"should honour authentication headers", ^{

            __block AGHttpClient* _restClient = nil;

            beforeEach(^{
                NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];

                AGRestAuthentication *authModulde = [[AGRestAuthentication alloc] init];
                // use KVC to set fictitious authentication
                [authModulde setValue:@{@"Authentication" : @"foo"} forKey:@"authTokens"];

                _restClient = [AGHttpClient clientFor:baseURL timeout:60 sessionConfiguration:nil authModule:authModulde authzModule:nil];
            });

            afterEach(^{
                // remove all handlers installed by test methods
                // to avoid any interference
                [AGHTTPMockHelper clearAllMockedRequests];

                finishedFlag = NO;
            });

            it(@"when performing GET", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                [_restClient GET:@"projects" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Authentication"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                } ];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing PUT", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient PUT:@"projects/0" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Authentication"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope

                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });


            it(@"when performing PUT (multipart upload)", ^{
                [AGHTTPMockHelper mockResponseStatus:200];

                // create a dummy file to send

                // access support directory
                NSURL *tmpFolder = [[NSFileManager defaultManager]
                        URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];

                // write a file
                NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
                [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];

                // construct the payload with the file added
                NSDictionary *parameters = @{@"somekey": @"somevalue", @"file":file};

                // upload
                [_restClient PUT:@"projects/0" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Authentication"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
                // remove dummy file
                [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
            });

            it(@"when performing POST", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient POST:@"projects" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Authentication"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing POST (multipart upload)", ^{
                [AGHTTPMockHelper mockResponseStatus:200];

                // create a dummy file to send

                // access support directory
                NSURL *tmpFolder = [[NSFileManager defaultManager]
                        URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];

                // write a file
                NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
                [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];

                // construct the payload with the file added
                NSDictionary *parameters = @{@"somekey": @"somevalue", @"file":file};

                // upload
                [_restClient POST:@"projects" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Authentication"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
                // remove dummy file
                [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
            });

            it(@"when performing DELETE", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient DELETE:@"projects/0" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Authentication"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope

                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });
        });

        context(@"should honour authorization headers", ^{

            __block AGHttpClient* _restClient = nil;

            beforeEach(^{
                NSURL* baseURL = [NSURL URLWithString:@"http://server.com/context/"];

                AGRestAuthzModule *authzModulde = [[AGRestAuthzModule alloc] init];
                // use KVC to set fictitious authorization headers
                [authzModulde setValue:@{@"Token" : @"foo"} forKey:@"accessTokens"];

                _restClient = [AGHttpClient clientFor:baseURL timeout:60 sessionConfiguration:nil authModule:nil authzModule:authzModulde];
            });

            afterEach(^{
                // remove all handlers installed by test methods
                // to avoid any interference
                [AGHTTPMockHelper clearAllMockedRequests];

                finishedFlag = NO;
            });

            it(@"when performing GET", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                [_restClient GET:@"projects" parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Token"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                } ];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing PUT", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient PUT:@"projects/0" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Token"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope

                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });

            it(@"when performing PUT (multipart upload)", ^{
                [AGHTTPMockHelper mockResponseStatus:200];

                // create a dummy file to send

                // access support directory
                NSURL *tmpFolder = [[NSFileManager defaultManager]
                        URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];

                // write a file
                NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
                [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];

                // construct the payload with the file added
                NSDictionary *parameters = @{@"somekey": @"somevalue", @"file":file};

                // upload
                [_restClient PUT:@"projects/0" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Token"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
                // remove dummy file
                [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
            });

            it(@"when performing POST", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient POST:@"projects" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Token"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });


            it(@"when performing POST (multipart upload)", ^{
                [AGHTTPMockHelper mockResponseStatus:200];

                // create a dummy file to send

                // access support directory
                NSURL *tmpFolder = [[NSFileManager defaultManager]
                        URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];

                // write a file
                NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
                [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];

                // construct the payload with the file added
                NSDictionary *parameters = @{@"somekey": @"somevalue", @"file":file};

                // upload
                [_restClient POST:@"projects" parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Token"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope
                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
                // remove dummy file
                [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
            });

            it(@"when performing DELETE", ^{
                [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

                NSMutableDictionary* project = [NSMutableDictionary
                        dictionaryWithObjectsAndKeys:@"0", @"id", @"First Project", @"title",
                                                     @"project-161-58-58", @"style", nil];

                [_restClient DELETE:@"projects/0" parameters:project success:^(NSURLSessionDataTask *task, id responseObject) {

                    [task.originalRequest.allHTTPHeaderFields[@"Token"] shouldNotBeNil];
                    finishedFlag = YES;

                } failure:^(NSURLSessionDataTask *task, NSError *error) {
                    // nope

                }];

                [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            });
        });
    });
*/
SPEC_END