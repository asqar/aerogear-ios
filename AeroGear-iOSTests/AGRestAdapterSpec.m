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
#import "AGRESTPipe.h"
#import "AGMultipart.h"
#import "AGTestModel.h"
#import "AGHTTPMockHelper.h"

SPEC_BEGIN(AGRestAdapterSpec)

describe(@"AGRestAdapter", ^{

    // mocked json responses
    NSString * const PROJECTS = @"[{\"recId\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\",\"tasks\":[{\"recId\":1, \"title\":\"task1\", \"descr\":\"a task\", \"dueDate\":\"2014-01-01\", \"tags\":[{\"title\":\"tag1\"}]}]},{\"id\":2,\"title\":\"Second Project\",\"style\":\"project-64-144-230\",\"tasks\":[{\"recId\":2, \"title\":\"task2\", \"descr\":\"another task\", \"dueDate\":\"2014-01-02\", \"tags\":[{\"title\":\"tag2\"}]}]}]";
    NSString * const PROJECT = @"{\"recId\":1,\"title\":\"First Project\",\"style\":\"project-161-58-58\"}";
    
    __block BOOL finishedFlag = NO;
    
    context(@"when newly created", ^{

        __block AGRESTPipe* restPipe = nil;
        
        beforeEach(^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com"]];

            restPipe = [AGRESTPipe pipe:[Project class] config:config];
        });

        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];

            finishedFlag = NO;
        });

        it(@"should not be nil", ^{
            [restPipe shouldNotBeNil];
        });
        
        it(@"should have an expected url", ^{
            [[restPipe.URL should] equal:[NSURL URLWithString:@"http://server.com/project"]];
        });

        it(@"should have an expected type", ^{
            [[restPipe.type should] equal:@"REST"];
        });

        it(@"should successfully read", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]];

            [restPipe read:^(id responseObject) {
                [responseObject shouldNotBeNil];

                // should have correct size
                [[theValue([responseObject count]) should] equal:theValue(2)];
                // should have correctly deserialized
                [[responseObject[0] should] beKindOfClass:[Project class]];

                finishedFlag = YES;

            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should successfully save (POST)", ^{
            [AGHTTPMockHelper mockResponseStatus:201];

            Project *project = [[Project alloc] init];
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe save:project success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"POST"];
                finishedFlag = YES;

            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should successfully save (PUT)", ^{
            [AGHTTPMockHelper mockResponseStatus:200];

            Project *project = [[Project alloc] init];
            project.recId = @1;
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe save:project success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"PUT"];
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should successfully remove (DELETE)", ^{
            [AGHTTPMockHelper mockResponseStatus:200];

            Project *project = [[Project alloc] init];
            project.recId = @1;
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe remove:project success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"DELETE"];
                finishedFlag = YES;

            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should read an object with integer argument", ^{
            [AGHTTPMockHelper mockResponse:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];

            [restPipe read:@1
                    success:^(id responseObject) {
                        [responseObject shouldNotBeNil];
                        finishedFlag = YES;

                    } failure:^(NSError *error) {
                        // nope
                    }
            ];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should fail to read an object with nil argument", ^{
            [restPipe read:nil
                    success:^(id responseObject) {
                        // nope
                    } failure:^(NSError *error) {
                        finishedFlag = YES;
                    }
            ];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"should fail to remove an object with nil argument", ^{
            [AGHTTPMockHelper mockResponse:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]];

            [restPipe remove:nil success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                finishedFlag = YES;
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"should accept valid types", ^{
            [[theValue([AGRESTPipe accepts:@"REST"]) should] equal:theValue(YES)];
            // TODO more types as we add
        });
        
        it(@"should not accept invalid types", ^{
            [[theValue([AGRESTPipe accepts:nil]) should] equal:theValue(NO)];
            [[theValue([AGRESTPipe accepts:@"bogus"]) should] equal:theValue(NO)];
            // REST lowercase should not be accepted
            [[theValue([AGRESTPipe accepts:@"rest"]) should] equal:theValue(NO)];
        });
    });

    context(@"cancel should be honoured", ^{

        __block AGRESTPipe* restPipe = nil;

        beforeEach(^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com"]];

            restPipe = [AGRESTPipe pipe:[Project class] config:config];
        });

        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];

            finishedFlag = NO;
        });

        it(@"on read (GET)", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:[PROJECTS dataUsingEncoding:NSUTF8StringEncoding]
                                    status:200
                               requestTime:2]; // two secs delay


            [restPipe read:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorCancelled)];
                finishedFlag = YES;
            }];

            [restPipe cancel];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"on save (POST)", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]
                                    status:200
                               requestTime:2]; // two secs delay

            Project *project = [[Project alloc] init];
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe save:project success:^(id responseObject) {
                // nope

            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorCancelled)];
                finishedFlag = YES;
            }];

            [restPipe cancel];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"on save (PUT)", ^{
            [AGHTTPMockHelper mockResponse:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]
                                    status:200
                               requestTime:2]; // two secs delay

            Project *project = [[Project alloc] init];
            project.recId = @1;
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe save:project success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorCancelled)];
                finishedFlag = YES;
            }];

            [restPipe cancel];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"on remove (DELETE)", ^{
            [AGHTTPMockHelper mockResponse:[PROJECT dataUsingEncoding:NSUTF8StringEncoding]
                                    status:200
                               requestTime:2]; // two secs delay

            Project *project = [[Project alloc] init];
            project.recId = @1;
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe remove:project success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorCancelled)];
                finishedFlag = YES;
            }];

            [restPipe cancel];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
    });

    context(@"timeout should be honoured", ^{
        
        __block AGRESTPipe* restPipe = nil;
        
        beforeEach(^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com"]];

            // Note: we set the timeout(sec) to a low level so that
            // we can test the timeout methods with adjusting response delay
            [config setTimeout:1];
            
            restPipe = [AGRESTPipe pipe:[Project class] config:config];
        });
        
        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];
            
            finishedFlag = NO;
        });

        it(@"on read (GET)", ^{
            // install the mock:
            [AGHTTPMockHelper mockResponse:nil
                                    status:200
                               requestTime:2]; // two secs delay


            [restPipe read:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorTimedOut)];
                finishedFlag = YES;
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"on save (POST)", ^{
            [AGHTTPMockHelper mockResponse:nil
                                    status:200
                               requestTime:2]; // two secs delay

            Project *project = [[Project alloc] init];
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe save:project success:^(id responseObject) {
                // nope
                
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorTimedOut)];
                finishedFlag = YES;
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"on save (PUT)", ^{
            [AGHTTPMockHelper mockResponse:nil
                                    status:200
                               requestTime:2]; // two secs delay

            Project *project = [[Project alloc] init];
            project.recId = @1;
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe save:project success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorTimedOut)];
                finishedFlag = YES;
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });

        it(@"on remove (DELETE)", ^{
            [AGHTTPMockHelper mockResponse:nil
                                    status:200
                               requestTime:2]; // two secs delay

            Project *project = [[Project alloc] init];
            project.recId = @1;
            project.title = @"First Project";
            project.style = @"project-161-58-58";

            [restPipe remove:project success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorTimedOut)];
                finishedFlag = YES;
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
    });

    context(@"should handle multipart requests", ^{
        
        __block AGRESTPipe* restPipe = nil;
        
        beforeEach(^{
            AGPipeConfiguration* config = [[AGPipeConfiguration alloc] init];
            [config setBaseURL:[NSURL URLWithString:@"http://server.com"]];

            restPipe = [AGRESTPipe pipe:[Project class] config:config];
        });
        
        afterEach(^{
            // remove all handlers installed by test methods
            // to avoid any interference
            [AGHTTPMockHelper clearAllMockedRequests];
            
            finishedFlag = NO;
        });
        
        it(@"save with NSURL objects without ID should trigger a POST multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create a dummy file to send
            
            // access support directory
            NSURL *tmpFolder = [[NSFileManager defaultManager]
                                URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            
            // write a file
            NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
            [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            // construct the payload with the file added
            NSDictionary *dict = @{@"somekey": @"somevalue", @"file":file};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"POST"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];

                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];

            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            // remove dummy file
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        });
        
        it(@"save with NSURL objects and an ID should trigger a PUT multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create a dummy file to send
            
            // access support directory
            NSURL *tmpFolder = [[NSFileManager defaultManager]
                                URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            
            // write a file
            NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
            [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            // construct the payload with the file added
            NSDictionary *dict = @{@"id": @"1", @"somekey": @"somevalue", @"file":file};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"PUT"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];
                
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            // remove dummy file
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        });
        
        it(@"should throw an error when the NSURL is not a file url", ^{
            NSURL *invalidURL = [NSURL URLWithString:@"http://foo.com"];
            NSDictionary *dict = @{@"somekey": @"somevalue", @"file":invalidURL};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorBadURL)];
                finishedFlag = YES;
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"should throw an error when the NSURL points to an non reachable file", ^{
            NSURL *tmpFolder = [[NSFileManager defaultManager]
                                URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            
            // write a file
            NSURL *file = [tmpFolder URLByAppendingPathComponent:@"notexist.txt"];
            
            
            NSDictionary *dict = @{@"somekey": @"somevalue", @"file":file};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                // nope
            } failure:^(NSError *error) {
                [[theValue(error.code) should] equal:theValue(NSURLErrorBadURL)];
                finishedFlag = YES;
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"save with AGFilePart object without ID should trigger a POST multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create a dummy file to send
            
            // access support directory
            NSURL *tmpFolder = [[NSFileManager defaultManager]
                                URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            
            // write a file
            NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
            [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            AGFilePart *part = [[AGFilePart alloc] initWithFileURL:file name:@"file"];
            // construct the payload with the file added
            NSDictionary *dict = @{@"somekey": @"somevalue", @"file":part};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"POST"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];
                
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            // remove dummy file
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        });
        
        it(@"save with AGFilePart object and an ID should trigger a PUT multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create a dummy file to send
            
            // access support directory
            NSURL *tmpFolder = [[NSFileManager defaultManager]
                                URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:nil];
            
            // write a file
            NSURL *file = [tmpFolder URLByAppendingPathComponent:@"file.txt"];
            [@"Lorem ipsum dolor sit amet," writeToURL:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            AGFilePart *part = [[AGFilePart alloc] initWithFileURL:file name:@"file"];
            
            // construct the payload with the file added
            NSDictionary *dict = @{@"id": @"1", @"somekey": @"somevalue", @"file":part};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"PUT"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];
                
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
            // remove dummy file
            [[NSFileManager defaultManager] removeItemAtURL:file error:nil];
        });
        
        it(@"save with AGFileDataPart object without ID should trigger a POST multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create dummy NSData to send
            NSData *data = [@"Lorem ipsum dolor sit amet," dataUsingEncoding:NSUTF8StringEncoding];
            
            AGFileDataPart *part = [[AGFileDataPart alloc] initWithFileData:data name:@"file" fileName:@"file.txt" mimeType:@"text/plain"];
            
            // construct the payload with the file added
            NSDictionary *dict = @{@"somekey": @"somevalue", @"file":part};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"POST"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];
                
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"save with AGFileDataPart object and an ID should trigger a PUT multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create dummy NSData to send
            NSData *data = [@"Lorem ipsum dolor sit amet," dataUsingEncoding:NSUTF8StringEncoding];
            
            AGFileDataPart *part = [[AGFileDataPart alloc] initWithFileData:data name:@"file" fileName:@"file.txt" mimeType:@"text/plain"];
            
            // construct the payload with the file added
            NSDictionary *dict = @{@"id": @"1", @"somekey": @"somevalue", @"file":part};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"PUT"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];
                
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"save with AGStreamPart object without ID should trigger a POST multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create dummy NSData to send
            NSData *data = [@"Lorem ipsum dolor sit amet," dataUsingEncoding:NSUTF8StringEncoding];
            // construct stream from data
            NSInputStream *stream = [[NSInputStream alloc] initWithData:data];
            
            AGStreamPart *part = [[AGStreamPart alloc] initWithInputStream:stream name:@"file" fileName:@"file.txt" length:[data length] mimeType:@"text/plain"];
            
            // construct the payload with the file added
            NSDictionary *dict = @{@"somekey": @"somevalue", @"file":part};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"POST"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];
                
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
        
        it(@"save with AGStreamPart object and an ID should trigger a PUT multipart request", ^{
            [AGHTTPMockHelper mockResponseStatus:200];
            
            // create dummy NSData to send
            NSData *data = [@"Lorem ipsum dolor sit amet," dataUsingEncoding:NSUTF8StringEncoding];
            // construct stream from data
            NSInputStream *stream = [[NSInputStream alloc] initWithData:data];
            
            AGStreamPart *part = [[AGStreamPart alloc] initWithInputStream:stream name:@"file" fileName:@"file.txt" length:[data length] mimeType:@"text/plain"];
            
            // construct the payload with the file added
            NSDictionary *dict = @{@"id": @"1", @"somekey": @"somevalue", @"file":part};
            
            // upload
            [restPipe save:dict success:^(id responseObject) {
                [[[AGHTTPMockHelper lastHTTPMethodCalled] should] equal:@"PUT"];
                
                [[theValue([[AGHTTPMockHelper lastHTTPRequestHeaders][@"Content-Type"]
                            hasPrefix:@"multipart/form-data"]) should] equal:theValue(YES)];
                
                finishedFlag = YES;
            } failure:^(NSError *error) {
                // nope
            }];
            
            [[expectFutureValue(theValue(finishedFlag)) shouldEventuallyBeforeTimingOutAfter(5)] beYes];
        });
    });
});

SPEC_END