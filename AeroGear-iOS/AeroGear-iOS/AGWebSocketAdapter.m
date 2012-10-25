/*
 * JBoss, Home of Professional Open Source
 * Copyright 2012, Red Hat, Inc., and individual contributors
 * by the @authors tag. See the copyright.txt in the distribution for a
 * full listing of individual contributors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "AGWebSocketAdapter.h"
#import "AGRestAuthentication.h"
#import "SRWebSocket.h"

#import "AFJSONUtilities.h"

@interface AGWebSocketAdapter() <SRWebSocketDelegate>

@end

// SRWebSocketDelegate
@implementation AGWebSocketAdapter{
    SRWebSocket* _webSocketClient;
    AGRestAuthentication* _authModule;
    BOOL _open;
}

@synthesize type = _type;
@synthesize url = _url;

- (id)init {
    self = [super init];
    if (self) {
        // base inits:
        _type = @"WEBSOCKET";
    }
    return self;
}

-(id) initForURL:(NSURL*) url authModule:(id<AGAuthenticationModule>) authModule{
    self = [self init];
    if (self) {
        _url = url.absoluteString;
        _webSocketClient = [[SRWebSocket alloc] initWithURL:url];
        _webSocketClient.delegate = self;
        [_webSocketClient open];
        _authModule = (AGRestAuthentication*) authModule;
    }
    
    //  establish the connection:
    // keep the run loop going
    while(!_open) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }

    
    return self;
}

+(id) pipeForURL:(NSURL*) url authModule:(id<AGAuthenticationModule>) authModule{
    return [[self alloc] initForURL:url authModule:authModule];
}


void (^_readSuccessBlock)(id responseObject);
void (^_readFailureBlock)(NSError *error);

// read all, via HTTP GET
-(void) read:(void (^)(id responseObject))success
failure:(void (^)(NSError *error))failure {
    
    // try to add auth.token:
    [self applyAuthToken];
    
    _readSuccessBlock = success;
    _readFailureBlock = failure;
    
    
//    // TODO: better Endpoints....
//    [_restClient getPath:@"" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        
//        if (success) {
//            //TODO: NSLog(@"Invoking successblock....");
//            success(responseObject);
//        }
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        
//        if (failure) {
//            //TODO: NSLog(@"Invoking failure block....");
//            failure(error);
//        }
//    } ];
}

-(void) readWithFilter:(id)filterObject
success:(void (^)(id responseObject))success
failure:(void (^)(NSError *error))failure {
    //    // try to add auth.token:
    //    [self applyAuthToken];
    // TODO...
}

-(void) save:(NSDictionary*) object
success:(void (^)(id responseObject))success
failure:(void (^)(NSError *error))failure {
    
    // try to add auth.token:
    [self applyAuthToken];
    
    
    
    NSData *JSONData = AFJSONEncode(object, nil);
    NSString* JSONpayload = [[NSString alloc] initWithData:JSONData encoding:NSUTF8StringEncoding];
    
    [_webSocketClient send:JSONpayload];
    
    // Does a PUT or POST based on the fact if the object
    // already exists (if there is an 'id').
    
    // the blocks are unique to PUT and POST, so let's define them up-front:
//    id successCallback = ^(AFHTTPRequestOperation *operation, id responseObject) {
//        if (success) {
//            //TODO: NSLog(@"Invoking successblock....");
//            success(responseObject);
//        }
//    };
//    
//    id failureCallback = ^(AFHTTPRequestOperation *operation, NSError *error) {
//        if (failure) {
//            //TODO: NSLog(@"Invoking failure block....");
//            failure(error);
//        }
//    };
//    
//    
//    if ([object objectForKey:@"id"]) {
//        //TODO: NSLog(@"HTTP PUT to update the given object");
//        NSString* updateIdPath = [object objectForKey:@"id"];
//        [_restClient putPath:updateIdPath parameters:object success:successCallback failure:failureCallback];
//        return;
//    }
//    else {
//        //TODO: NSLog(@"HTTP POST to create the given object");
//        [_restClient postPath:@"" parameters:object success:successCallback failure:failureCallback];
//        return;
//    }
}

-(void) remove:(id) key
success:(void (^)(id responseObject))success
failure:(void (^)(NSError *error))failure {
    
    // try to add auth.token:
    [self applyAuthToken];
    
    id deleteKey;
    if ([key isKindOfClass:[NSString class]]) {
        deleteKey = key;
    } else {
        deleteKey = [key stringValue];
    }
    
//    [_restClient deletePath:deleteKey parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        
//        if (success) {
//            //TODO: NSLog(@"Invoking successblock....");
//            success(responseObject);
//        }
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        
//        if (failure) {
//            //TODO: NSLog(@"Invoking failure block....");
//            failure(error);
//        }
//    } ];
//    
}

// helper method:
-(void) applyAuthToken {
//    if ([_authModule isAuthenticated]) {
//        [_restClient setDefaultHeader:@"Auth-Token" value:[_authModule authToken]];
//    }
}

-(NSString *) description {
    return [NSString stringWithFormat: @"%@ [type=%@, url=%@]", self.class, _type, _url];
}

+ (BOOL) accepts:(NSString *) type {
    return [type isEqualToString:@"WEBSOCKET"];
}

#pragma mark - SRWebSocketDelegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket;
{
    NSLog(@"Websocket Connected");
    _open = YES;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error;
{
    NSLog(@":( Websocket Failed With Error %@", error);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message;
{
    NSLog(@"Received \"%@\"", message);
    if (_readSuccessBlock) {
        // TODO: NSLog(@"Invoking successblock....");
        _readSuccessBlock(message);
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean;
{
    NSLog(@"WebSocket closed");
}



@end