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

#import "AGRESTPipe.h"
#import "AGHttpClient.h"

#import "AGPageHeaderExtractor.h"
#import "AGPageBodyExtractor.h"
#import "AGPageWebLinkingExtractor.h"
#import "AGRequestSerializer.h"
#import "AGModelResponseSerializer.h"
#import <Mantle/MTLJSONAdapter.h>

//category:
#import "AGNSMutableArray+Paging.h"

@implementation AGRESTPipe {

    NSString* _recordId;
    
    AGPageConfiguration* _pageConfig;
}

@synthesize type = _type;
@synthesize URL = _URL;

#pragma mark - 'factory' and 'init' section

+(instancetype) pipeWithConfig:(id<AGPipeConfig>) pipeConfig {
    return [[[self class] alloc] initWithConfig:pipeConfig];
}

-(instancetype) initWithConfig:(id<AGPipeConfig>) pipeConfig {
    self = [super init];
    if (self) {
        _type = @"REST";
        
        // set all the things:
        AGPipeConfiguration *_config = (AGPipeConfiguration*) pipeConfig;
        
        NSURL* baseURL = _config.baseURL;
        NSString* endpoint = _config.endpoint;
        // append the endpoint/name and use it as the final URL
        NSURL* finalURL = [self appendEndpoint:endpoint toURL:baseURL];
        
        _URL = finalURL;
        _recordId = _config.recordId;

        _restClient = [AGHttpClient clientFor:finalURL sessionConfiguration:_config.sessionConfiguration];

        // apply request serializer
        AGRequestSerializer *requestSerializer = [AGRequestSerializer serializer];
        // set the auth/authz modules
        requestSerializer.authModule = (id <AGAuthenticationModuleAdapter>)_config.authModule;
        requestSerializer.authzModule = (id <AGAuthzModuleAdapter>)_config.authzModule;
        // set the timeout interval
        requestSerializer.timeoutInterval = _config.timeout;
        // set Accept HTTP Header; see http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html#sec14.1
        [requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];

        _restClient.requestSerializer = requestSerializer;

        // apply response serializer
        AGModelResponseSerializer *responseSerializer = [AGModelResponseSerializer serializerForModelClass:_config.modelClass];
        _restClient.responseSerializer = responseSerializer;

        // if NSURLCredential object is set on the config
        if (_config.credential) {
            // apply it

            // capture the value to avoid strong reference cycle
            NSURLCredential *credential = _config.credential;
            // set it
            [_restClient setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession *session, NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, __autoreleasing NSURLCredential **cred) {
                if ([challenge previousFailureCount] == 0) {
                    *cred = credential;
                    return NSURLSessionAuthChallengeUseCredential;
                } else { // if there was a previous error, no need to continue
                    return NSURLSessionAuthChallengeCancelAuthenticationChallenge;
                }
            }];
        }

        // set up paging config from the user supplied block
        _pageConfig = [[AGPageConfiguration alloc] init];
        
        if (pipeConfig.pageConfig)
            pipeConfig.pageConfig(_pageConfig);
        
        if (!_pageConfig.pageExtractor) {
            if ([_pageConfig.metadataLocation isEqualToString:@"webLinking"]) {
                [_pageConfig setPageExtractor:[[AGPageWebLinkingExtractor alloc] init]];
            } else if ([_pageConfig.metadataLocation isEqualToString:@"header"]) {
                [_pageConfig setPageExtractor:[[AGPageHeaderExtractor alloc] init]];
            }else if ([_pageConfig.metadataLocation isEqualToString:@"body"]) {
                [_pageConfig setPageExtractor:[[AGPageBodyExtractor alloc] init]];
            }
        }
    }
    
    return self;
}

#pragma mark - public API (AGPipe)

-(void) read:(id)recordId
     success:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {

    if (recordId == nil || [recordId isKindOfClass:[NSNull class]]) {
        [self raiseError:@"read" msg:@"read id value was nil" failure:failure];
        // do nothing
        return;
    }

    NSString* objectKey = [self getStringValue:recordId];
    [_restClient GET:[self appendObjectPath:objectKey] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

// read all, via HTTP GET
-(void) read:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {

    [self readWithParams:nil success:success failure:failure];
}

// read, with (filter/query) params. Used for paging, can be used
// to issue queries as well...
-(void) readWithParams:(NSDictionary*)parameterProvider
               success:(void (^)(id responseObject))success
               failure:(void (^)(NSError *error))failure {

    // if none has been passed, we use the "global" setting
    // which can be the default limit/offset OR what has
    // been configured on the PIPE level.....:
    if (!parameterProvider)
        parameterProvider = _pageConfig.parameterProvider;

    [_restClient GET:_URL.path parameters:parameterProvider success:^(NSURLSessionDataTask *task, id responseObject) {

        NSMutableArray* pagingObject;

        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            pagingObject = [NSMutableArray arrayWithObject:responseObject];
        } else {
            pagingObject = (NSMutableArray*) [responseObject mutableCopy];
        }

        // stash pipe reference:
        pagingObject.pipe = self;
        pagingObject.parameterProvider = [_pageConfig.pageExtractor parse:responseObject
                                                                  headers:[(NSHTTPURLResponse *) [task response] allHeaderFields]
                                                                     next:_pageConfig.nextIdentifier
                                                                     prev:_pageConfig.previousIdentifier];
        if (success) {
            success(pagingObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        if (failure) {
            failure(error);
        }
    } ];
}


-(void) save:(id) object
     success:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure {

    // when null is provided we try to invoke the failure block
    if (object == nil || [object isKindOfClass:[NSNull class]]) {
        [self raiseError:@"save" msg:@"object was nil" failure:failure];
        // do nothing
        return;
    }

    // the blocks are unique to PUT and POST, so let's define them up-front:
    id successCallback = ^(NSURLSessionDataTask *task, id responseObject) {
        if (success) {
            success(responseObject);
        }
    };

    id failureCallback = ^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    };

    id objectKey = [object valueForKey:_recordId];

    // we need to check if the map representation contains the "recordID" and its value is actually set,
    // to determine whether POST or PUT should be attempted
    if (objectKey == nil || [objectKey isKindOfClass:[NSNull class]]) {
        [_restClient POST:_URL.path parameters:[MTLJSONAdapter JSONDictionaryFromModel:object] success:successCallback failure:failureCallback];
    } else {

        // extract object's id
        NSString* updateId = [self getStringValue:objectKey];
       [_restClient PUT:[self appendObjectPath:updateId] parameters:[MTLJSONAdapter JSONDictionaryFromModel:object] success:successCallback failure:failureCallback];
    }
}

-(void) remove:(id) object
       success:(void (^)(id responseObject))success
       failure:(void (^)(NSError *error))failure {

    // when null is provided we try to invoke the failure block
    if (object == nil || [object isKindOfClass:[NSNull class]]) {
        [self raiseError:@"remove" msg:@"object was nil" failure:failure];
        // do nothing
        return;
    }

    id objectKey = [object valueForKey:_recordId];

    // we need to check if the map representation contains the "recordID" and its value is actually set:
    if (objectKey == nil || [objectKey isKindOfClass:[NSNull class]]) {
        [self raiseError:@"remove" msg:@"recordId not set" failure:failure];
        // do nothing
        return;
    }

    NSString* deleteKey = [self getStringValue:objectKey];

    [_restClient DELETE:[self appendObjectPath:deleteKey] parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {

        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {

        if (failure) {
            failure(error);
        }
    } ];
}

-(void) cancel {
    // enumerate all running tasks
    [_restClient.tasks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSURLSessionTask *task = obj;
        // cancel it
        [task cancel];
    }];
}

- (void)setUploadProgressBlock:(void (^)(NSURLSession *session, NSURLSessionTask *task, int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend))block {
    [_restClient setTaskDidSendBodyDataBlock:block];
}

#pragma mark - utility methods

// extract the sting value (e.g. for read:id, or remove:id)
-(NSString *) getStringValue:(id) value {
    NSString* objectKey;
    if ([value isKindOfClass:[NSString class]]) {
        objectKey = value;
    } else {
        objectKey = [value stringValue];
    }
    return objectKey;
}

// appends the path for delete/updates to the URL
-(NSString*) appendObjectPath:(NSString*)path {
    return [NSString stringWithFormat:@"%@/%@", _URL, path];
}

-(void) raiseError:(NSString*) domain
               msg:(NSString*) msg
           failure:(void (^)(NSError *error))failure {

    if (!failure)
        return;

    NSError* error = [NSError errorWithDomain:[NSString stringWithFormat:@"org.aerogear.pipes.%@", domain]
                                         code:0
                                     userInfo:@{NSLocalizedDescriptionKey: msg}];

    failure(error);
}

+ (BOOL) accepts:(NSString *) type {
    return [type isEqualToString:@"REST"];
}

// private helper to append the endpoint
-(NSURL*) appendEndpoint:(NSString*)endpoint toURL:(NSURL*)baseURL {
    if (endpoint == nil) {
        endpoint = @"";
    }

    // append the endpoint name and use it as the final URL
    return [baseURL URLByAppendingPathComponent:endpoint];
}

-(NSString *) description {
    return [NSString stringWithFormat: @"%@ [type=%@, url=%@]", self.class, _type, _URL];
}

@end