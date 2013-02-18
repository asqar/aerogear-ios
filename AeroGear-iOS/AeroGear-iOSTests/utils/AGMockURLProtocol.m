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

#import "AGMockURLProtocol.h"

@interface NSHTTPURLResponse(UndocumentedInitializer)
- (id)initWithURL:(NSURL*)URL statusCode:(NSInteger)statusCode headerFields:(NSDictionary*)headerFields requestTime:(double)requestTime;
@end

// AGMockURLProtocol instances are created by the runtime at the time
// and "static" was a way to set parameters on those instances.
// See NSURLProtocol documentation for more details.
static NSData* sResponseData = nil;
static NSMutableDictionary* sHeaders = nil;
static NSInteger sStatusCode = 200;
static NSError* sError = nil;
static NSString* sMethod = nil;
static NSTimeInterval sDelay = 0;

@implementation AGMockURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest*)request {
	return [[[request URL] scheme] isEqualToString:@"http"] ||
           [[[request URL] scheme] isEqualToString:@"https"] ;
}

+ (NSURLRequest*)canonicalRequestForRequest:(NSURLRequest*)request {
	return request;
}

+ (void)setResponseData:(NSData*)data {
    sResponseData = data;
}

+ (void)setHeaders:(NSDictionary*)headers {
    sHeaders = [NSMutableDictionary dictionaryWithDictionary:headers];
}

+ (void)addHeader:(NSString*)key value:(NSString*)value {
    if (sHeaders == nil)
        sHeaders = [[NSMutableDictionary alloc] init];
    
    [sHeaders setObject:value forKey:key];
}

+ (void)removeHeader:(NSString*)key {
    if (sHeaders == nil)
        return;
    
    [sHeaders removeObjectForKey:key];
}

+ (void)setStatusCode:(NSInteger)statusCode {
    sStatusCode = statusCode;
}

+ (void)setError:(NSError*)error {
    sError = error;
}

+ (void)setResponseDelay:(NSTimeInterval)seconds {
    sDelay = seconds;
}

- (NSCachedURLResponse*)cachedResponse {
	return nil;
}

+ (NSString*)methodCalled {
    return sMethod;
}

- (void)startLoading {
    NSURLRequest *request = [self request];
    
    sMethod = [request HTTPMethod];

	id<NSURLProtocolClient> client = [self client];
	
	if(sResponseData) {
		NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[request URL]
																  statusCode:sStatusCode
																headerFields:sHeaders
																 requestTime:0.0];
		
        // simulate delay in response (if set)
        [NSThread sleepForTimeInterval:sDelay];
        
		[client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
		[client URLProtocol:self didLoadData:sResponseData];
		[client URLProtocolDidFinishLoading:self];
	} else if(sError) {
		[client URLProtocol:self didFailWithError:sError];
	}
}

- (void)stopLoading {
}

@end
