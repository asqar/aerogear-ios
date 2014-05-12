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

#import "AGRestAuthentication.h"
#import "AGAuthConfiguration.h"
#import <AFNetworking/AFHTTPSessionManager.h>


// TODO: Use #pragma marks to categorize methods and protocol implementations.

@implementation AGRestAuthentication {
    // ivars
    AFHTTPSessionManager *_restClient;
}

// =====================================================
// ======== public API (AGAuthenticationModule) ========
// =====================================================
@synthesize type = _type;
@synthesize baseURL = _baseURL;
@synthesize loginEndpoint = _loginEndpoint;
@synthesize logoutEndpoint = _logoutEndpoint;
@synthesize enrollEndpoint = _enrollEndpoint;

// custom getters for our properties (from AGAuthenticationModule)
-(NSString*) loginEndpoint {
    return [_baseURL stringByAppendingString:_loginEndpoint];
}

-(NSString*) logoutEndpoint {
    return [_baseURL stringByAppendingString:_logoutEndpoint];
}

-(NSString*) enrollEndpoint {
    return [_baseURL stringByAppendingString:_enrollEndpoint];
}

// ==============================================================
// ======== internal API (AGAuthenticationModuleAdapter) ========
// ==============================================================
@synthesize authTokens = _authTokens;



// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+(instancetype) moduleWithConfig:(id<AGAuthConfig>) authConfig {
    return [[[self class] alloc] initWithConfig:authConfig];
}

-(instancetype) initWithConfig:(id<AGAuthConfig>) authConfig {
    self = [super init];
    if (self) {
        // set all the things:
        AGAuthConfiguration* config = (AGAuthConfiguration*) authConfig;
        _type = config.type;
        _loginEndpoint = config.loginEndpoint;
        _logoutEndpoint = config.logoutEndpoint;
        _enrollEndpoint = config.enrollEndpoint;
        _baseURL = config.baseURL.absoluteString;

        // TODO timeout
        _restClient = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:_baseURL]];
        
    }

    return self;
}

-(void)dealloc {
    _restClient = nil;
}


// =====================================================
// ======== public API (AGAuthenticationModule) ========
// =====================================================
-(void) enroll:(NSDictionary*) userData
     success:(void (^)(id object))success
     failure:(void (^)(NSError *error))failure {

    [_restClient POST:_enrollEndpoint parameters:userData success:^(NSURLSessionDataTask *task, id responseObject) {
        // stash the auth token...:
        [self readAndStashToken:task response:responseObject];

        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

-(void) login:(NSString*) username
     password:(NSString*) password
      success:(void (^)(id object))success
      failure:(void (^)(NSError *error))failure {

    [self login:@{@"username": username, @"password": password} success:success failure:failure];
}

-(void) login:(NSDictionary*) loginData
    success:(void (^)(id object))success
    failure:(void (^)(NSError *error))failure {

    [_restClient POST:_loginEndpoint parameters:loginData success:^(NSURLSessionDataTask *task, id responseObject) {
        // stash the auth token...:
        [self readAndStashToken:task response:responseObject];

        if (success) {
            success(responseObject);
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

-(void) logout:(void (^)())success
     failure:(void (^)(NSError *error))failure {

    // stash the token to the header:
    [_authTokens enumerateKeysAndObjectsUsingBlock:^(id header, id value, BOOL *stop) {
        [_restClient.requestSerializer setValue:value forHTTPHeaderField:header];
    }];

    [_restClient POST:_logoutEndpoint parameters:nil success:^(NSURLSessionDataTask *task, id responseObject) {

        [self deauthorize];

        if (success) {
            success();
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

-(void) cancel {
    // cancel all running http operations
    [_restClient.operationQueue cancelAllOperations];
}

// private method
-(void) readAndStashToken:(NSURLSessionDataTask *)task response:(id) responseObject {
    _authTokens = [[NSMutableDictionary alloc] init];
}

// ==============================================================
// ======== internal API (AGAuthenticationModuleAdapter) ========
// ==============================================================
- (BOOL)isAuthenticated {
    //return !!_authToken;
    return (nil != _authTokens);
}

- (void)deauthorize {
    _authTokens = nil;
}

// general override...
-(NSString *) description {
    return [NSString stringWithFormat: @"%@ [type=%@, loginEndpoint=%@, logoutEndpoint=%@, enrollEndpoint=%@]", self.class, _type, _loginEndpoint, _logoutEndpoint, _enrollEndpoint];
}

@end
