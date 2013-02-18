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

#import "AGHttpClient.h"


@implementation AGHttpClient {
    // secs before a request timeouts (alternative name for primitive "double")
    NSTimeInterval _interval;
}

+ (AGHttpClient *)clientFor:(NSURL *)url {
    return [[self alloc] initWithBaseURL:url timeout:60];
}

+ (AGHttpClient *)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval {
    return [[self alloc] initWithBaseURL:url timeout:interval];
}

- (id)initWithBaseURL:(NSURL *)url timeout:(NSTimeInterval)interval {
	
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    
    // set the timeout interval for requests
    _interval = interval;
    
    [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
    
    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
	[self setDefaultHeader:@"Accept" value:@"application/json"];
    
    return self;
}

// override to not handle the cookies and to add a request timeout interval
- (NSMutableURLRequest *)requestWithMethod:(NSString *)method
                                      path:(NSString *)path
                                parameters:(NSDictionary *)parameters
{
    // invoke the 'requestWithMethod:path:parameters:' from AFNetworking:
    NSMutableURLRequest* req = [super requestWithMethod:method path:path parameters:parameters];
    
    // set the timeout interval
    [req setTimeoutInterval:_interval];
    
    // disable the default cookie handling in the override:
    [req setHTTPShouldHandleCookies:NO];

    return req;
}

@end
