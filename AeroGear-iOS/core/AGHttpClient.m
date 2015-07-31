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
#import "AGMultipart.h"

@interface AGRequestSerializer : CSAFJSONRequestSerializer

    // auth/autz configuration
    @property (nonatomic, strong) id<AGAuthenticationModuleAdapter> authModule;
    @property (nonatomic, strong) id<AGAuthzModuleAdapter> authzModule;

@end

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


@implementation AGHttpClient

+ (instancetype)clientFor:(NSURL *)url {
    return [[[self class] alloc] initWithBaseURL:url timeout:60 sessionConfiguration:nil authModule:nil authzModule:nil];
}

+ (instancetype)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval {
    return [[[self class] alloc] initWithBaseURL:url timeout:interval sessionConfiguration:nil authModule:nil authzModule:nil];
}

+ (instancetype)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval sessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [[[self class] alloc] initWithBaseURL:url timeout:interval sessionConfiguration:configuration authModule:nil authzModule:nil];
}

+ (instancetype)clientFor:(NSURL *)url timeout:(NSTimeInterval)interval sessionConfiguration:(NSURLSessionConfiguration *)configuration
               authModule:(id<AGAuthenticationModuleAdapter>) authModule
              authzModule:(id<AGAuthzModuleAdapter>)authzModule {
    return [[[self class] alloc] initWithBaseURL:url timeout:interval sessionConfiguration:configuration authModule:authModule authzModule:authzModule];
}

- (instancetype)initWithBaseURL:(NSURL *)url timeout:(NSTimeInterval)interval sessionConfiguration:(NSURLSessionConfiguration *)configuration
                     authModule:(id<AGAuthenticationModuleAdapter>) authModule
                    authzModule:(id<AGAuthzModuleAdapter>)authzModule {

    self = [super initWithBaseURL:url sessionConfiguration:configuration];

    if (!self) {
        return nil;
    }

    // apply AG request serializer
    AGRequestSerializer *serializer = [AGRequestSerializer serializer];
    serializer.authModule = authModule;
    serializer.authzModule = authzModule;

    self.requestSerializer = serializer;
    // apply json response serializer
    self.responseSerializer = [CSAFJSONResponseSerializer serializer];

    // set the timeout interval
    self.requestSerializer.timeoutInterval = interval;

    // Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

    return (self);
}

#pragma mark - CSAFHTTPSessionManager override

// override to construct a multipart request if required by the params passed in
- (NSURLSessionDataTask *)POST:(NSString *)URLString
                    parameters:(NSDictionary *)parameters
                       success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                       failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {

    return [self processRequestWithMethod:@"POST" URLString:URLString parameters:parameters success:success failure:failure];

}

// override to construct a multipart request if required by the params passed in
- (NSURLSessionDataTask *)PUT:(NSString *)URLString
                   parameters:(NSDictionary *)parameters
                      success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                      failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {

    return [self processRequestWithMethod:@"PUT" URLString:URLString parameters:parameters success:success failure:failure];
}

#pragma mark - utility methods

- (NSURLSessionDataTask *)processRequestWithMethod:(NSString *)method
                                         URLString:(NSString *)URLString
                                        parameters:(NSDictionary *)parameters
                                           success:(void (^)(NSURLSessionDataTask *task, id responseObject))success
                                           failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure {
    __block NSURLSessionDataTask *task;

    // let's define up-front the completion callback since it's common
    id completionCallback = ^(NSURLResponse * __unused response, id responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(task, error);
            }
        } else {
            if (success) {
                success(task, responseObject);
            }
        }
    };

    if ([self hasMultipartData:parameters]) {
        NSError *error = nil;

        NSMutableURLRequest *request = [self multipartFormRequestWithMethod:method
                                                                       path:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString]
                                                                 parameters:parameters error:&error];

        // if there was an error during multipart processing
        // or in the construction of request
        if (error) {
            failure(nil, error);
            return nil;
        }

        task = [self uploadTaskWithStreamedRequest:request progress:nil completionHandler:completionCallback];

    } else {

        NSMutableURLRequest *request = [self.requestSerializer requestWithMethod:method
                                                                       URLString:[[NSURL URLWithString:URLString relativeToURL:self.baseURL] absoluteString]
                                                                      parameters:parameters error:nil];

        task = [self dataTaskWithRequest:request completionHandler:completionCallback];
    }

    [task resume];

    return task;
}

// construct a multi-part request
- (NSMutableURLRequest *)multipartFormRequestWithMethod:(NSString *)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                                                  error:(NSError **) error {

    NSMutableURLRequest *req;

    // extract multipart data;
    NSMutableDictionary *parts = [[NSMutableDictionary alloc] init];

    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(AGMultipart)]) {
            // add it
            parts[key] = obj;
        }  else if ([obj isKindOfClass:[NSURL class]]) { // TODO: deprecated
            obj = [[AGFilePart alloc] initWithFileURL:obj name:key];
            parts[key] = obj;
        }
    }];

    // cater for CSAFNetworking default behaviour to call [object description]
    // for parameters other than NSData and NSNull. We need to filter
    // AGMultipart objects from the request and apply them in the block later on
    NSMutableDictionary *filteredParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    [filteredParameters removeObjectsForKeys:[parts allKeys]];
    
    // will hold any error that occurs during multipart add
    __block NSError *err;

    req = [self.requestSerializer multipartFormRequestWithMethod:method URLString:path parameters:filteredParameters constructingBodyWithBlock:^(id <CSAFMultipartFormData> formData) {

        [parts enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            if ([obj isKindOfClass:[AGFilePart class]]) {
                AGFilePart *part = (AGFilePart *) obj;
                [formData appendPartWithFileURL:part.fileURL
                                           name:part.name
                                          error:&err];

                // if there was any error adding the
                // file stop immediately
                if (err)
                    *stop = YES;

            } else if ([obj isKindOfClass:[AGFileDataPart class]]) {
                AGFileDataPart *part = (AGFileDataPart *) obj;

                [formData appendPartWithFileData:part.data
                                            name:part.name
                                        fileName:part.fileName
                                        mimeType:part.mimeType];

            } else if ([obj isKindOfClass:[AGStreamPart class]]) {
                AGStreamPart *part = (AGStreamPart *) obj;

                [formData appendPartWithInputStream:part.inputStream
                                               name:part.name
                                           fileName:part.fileName
                                             length:part.length
                                           mimeType:part.mimeType];
            }
        }];
    } error:error];

    if (err) { // if there was error adding multipart
        *error = err;
        return nil;
    }

    return req;
}

// check if any file objects(if any) are embedded in the params
- (BOOL)hasMultipartData:(NSDictionary *)parameters {
    __block BOOL hasMultipart = NO;

    [[parameters allValues] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(AGMultipart)] ||
                [obj isKindOfClass:[NSURL class]]) { // TODO: deprecated
            hasMultipart = YES;
            *stop = YES; // no need to continue further
        }
    }];

    return hasMultipart;
}

@end