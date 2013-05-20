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

#import "AGHttpBasicDigestAuthentication.h"
#import "AGAuthConfiguration.h"

@implementation AGHttpBasicDigestAuthentication {

    NSURLCredential *_credential;
    NSURLProtectionSpace *_protectionSpace;

    bool isAuthenticated;
}

// =====================================================
// ======== public API (AGAuthenticationModule) ========
// =====================================================
@synthesize type = _type;
@synthesize baseURL = _baseURL;
@synthesize loginEndpoint = _loginEndpoint;
@synthesize logoutEndpoint = _logoutEndpoint;
@synthesize enrollEndpoint = _enrollEndpoint;
@synthesize realm = _realm;

// custom getters for our properties (from AGAuthenticationModule)
- (NSString *)loginEndpoint {
    return [_baseURL stringByAppendingString:_loginEndpoint];
}

- (NSString *)logoutEndpoint {
    return [_baseURL stringByAppendingString:_logoutEndpoint];
}

- (NSString *)enrollEndpoint {
    return [_baseURL stringByAppendingString:_enrollEndpoint];
}

// ==============================================================
// ======== internal API (AGAuthenticationModuleAdapter) ========
// ==============================================================
@synthesize authTokens = _authTokens;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+ (id)moduleWithConfig:(id <AGAuthConfig>)authConfig {
    return [[self alloc] initWithConfig:authConfig];
}

- (id)initWithConfig:(id <AGAuthConfig>)authConfig {
    self = [super init];
    if (self) {
        // set all the things:
        AGAuthConfiguration *config = (AGAuthConfiguration *) authConfig;
        _type = authConfig.type; // either 'Basic' or 'Digest'

        // not applicable for this type of authentication
        // reset to empty values
        _loginEndpoint = @"";
        _logoutEndpoint = @"";
        _enrollEndpoint = @"";

        _realm = authConfig.realm;

        _baseURL = config.baseURL.absoluteString;
    }

    return self;
}

// =====================================================
// ======== public API (AGAuthenticationModule) ========
// =====================================================
- (void)enroll:(id)userData
       success:(void (^)(id object))success
       failure:(void (^)(NSError *error))failure {

    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Unsupported operation for this authentication type"
                                 userInfo:nil];
}

- (void)login:(NSString *)username
     password:(NSString *)password
      success:(void (^)(id object))success
      failure:(void (^)(NSError *error))failure {

    isAuthenticated = true;

    _credential = [NSURLCredential credentialWithUser:username
                                             password:password
                                          persistence:NSURLCredentialPersistenceForSession];

    // used to extract path components from 'NSURL' convenient methods
    NSURL *url = [NSURL URLWithString:_baseURL];

    _protectionSpace = [[NSURLProtectionSpace alloc]
            initWithHost:url.host
                    port:[url.port integerValue]
                protocol:[url scheme]
                   realm:_realm
    authenticationMethod:[_type isEqualToString:@"Basic"]?
            NSURLAuthenticationMethodHTTPBasic: NSURLAuthenticationMethodHTTPDigest];


    [[NSURLCredentialStorage sharedCredentialStorage]
            setCredential:_credential forProtectionSpace:_protectionSpace];

    if (success)
        success(nil);
}

- (void)logout:(void (^)())success
       failure:(void (^)(NSError *error))failure {

    isAuthenticated = false;

    if (_credential && _protectionSpace)
        [[NSURLCredentialStorage sharedCredentialStorage]
                removeCredential:_credential forProtectionSpace:_protectionSpace];

    if (success)
        success();
}

- (void)cancel {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Unsupported operation for this authentication type"
                                 userInfo:nil];
}

// ==============================================================
// ======== internal API (AGAuthenticationModuleAdapter) ========
// ==============================================================
- (BOOL)isAuthenticated {
    return isAuthenticated;
}

- (void)deauthorize {
    // not needed for this authentication
}

// general override...
- (NSString *)description {
    return [NSString stringWithFormat:@"%@ [type=%@, loginEndpoint=%@, logoutEndpoint=%@, enrollEndpoint=%@]", self.class, _type, _loginEndpoint, _logoutEndpoint, _enrollEndpoint];
}

@end
