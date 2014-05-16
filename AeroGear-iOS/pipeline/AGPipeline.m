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

#import "AGPipeline.h"
#import "AGPipeConfiguration.h"
#import "AGRESTPipe.h"

// category
@interface AGPipeline ()
// concurrency...
@property (atomic, copy) NSMutableDictionary* pipes;
@end

@implementation AGPipeline {
    NSURL* _baseURL;
    NSURLSessionConfiguration *_sessionConfiguration;
}
@synthesize pipes = _pipes;

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
    return [self initWithBaseURL:baseURL sessionConfiguration:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL sessionConfiguration:(NSURLSessionConfiguration *)configuration {
    if (self = [super init]) {
        // to hold our Pipes
        _pipes = [NSMutableDictionary dictionary];
        // stash the baseURL, used for the 'add' functions that have no (base)URL argument
        _baseURL = baseURL;

        _sessionConfiguration = configuration;
        // if no session configuration is provided, create a default one
        if (!_sessionConfiguration) {
            _sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
    }
    return self;
}

+(instancetype)pipelineWithBaseURL:(NSURL*) baseURL; {
    return [[[self class] alloc] initWithBaseURL:baseURL];
}

+(instancetype)pipelineWithBaseURL:(NSURL*) baseURL sessionConfiguration:(NSURLSessionConfiguration *)configuration {
    return [[[self class] alloc] initWithBaseURL:baseURL sessionConfiguration:configuration];
}

-(id<AGPipe>) pipe:(Class)class {
    return [self pipe:class config:nil];
}

-(id<AGPipe>) pipe:(Class)class config:(void (^)(id<AGPipeConfig> config)) config {
    AGPipeConfiguration* pipeConfig = [[AGPipeConfiguration alloc] init];

    // applying the defaults:
    [pipeConfig setBaseURL:_baseURL];
    [pipeConfig setSessionConfiguration:_sessionConfiguration];

    // apply user defined settings
    if (config) {
        config(pipeConfig);
    }

    if (! [pipeConfig.type isEqualToString:@"REST"]) {
        return nil;
    }

    id<AGPipe> pipe = [AGRESTPipe pipe:class config:pipeConfig];
    [_pipes setValue:pipe forKey:[pipeConfig name]];
    
    return pipe;
}

-(id<AGPipe>) remove:(NSString*) name {
    id<AGPipe> pipe = [self pipeWithName:name];
    [_pipes removeObjectForKey:name];
    
    return pipe;
}

-(id<AGPipe>)pipeWithName:(NSString*) name {
    return [_pipes valueForKey:name];
}

-(NSString *) description {
    return [NSString stringWithFormat: @"%@ %@", self.class, _pipes];
}

@end
