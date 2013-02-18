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

// this implementation was inspired by the blog post
// found here http://bit.ly/nhJx0A

#import <Foundation/Foundation.h>

@interface AGMockURLProtocol : NSURLProtocol

+ (void)setResponseData:(NSData*)data;
+ (void)setHeaders:(NSDictionary*)headers;
+ (void)addHeader:(NSString*)key value:(NSString*)value;
+ (void)removeHeader:(NSString*)key;
+ (void)setStatusCode:(NSInteger)statusCode;
+ (void)setError:(NSError*)error;
+ (void)setResponseDelay:(NSTimeInterval)seconds;

+ (NSString*)methodCalled;

@end
