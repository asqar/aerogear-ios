#import "AGRequestSerializer.h"

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

#import "AGRequestSerializer.h"

@implementation AGRequestSerializer

+ (instancetype)serializer {
    AGRequestSerializer *serializer = [[self alloc] init];

    return serializer;
}

#pragma mark - AGRequestSerializer

- (NSURLRequest *)requestBySerializingRequest:(NSURLRequest *)request
                               withParameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error {

    // call base json serialization
    NSMutableURLRequest *mutableRequest = (NSMutableURLRequest *)[super requestBySerializingRequest:request
                                                                                     withParameters:parameters error:error];
    // finally apply auth/autz (if any) on request
    NSDictionary *headers;

    if (self.authModule && [self.authModule isAuthenticated]) {
        headers = [self.authModule authTokens];
    } else if (self.authzModule && [self.authzModule isAuthorized]) {
        headers = [self.authzModule accessTokens];
    }

    // apply them
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id name, id value, BOOL *stop) {
            [mutableRequest setValue:value forHTTPHeaderField:name];
        }];
    }

    return mutableRequest;
}

@end