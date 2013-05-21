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

#import <Foundation/Foundation.h>
#import "AGPageConfig.h"
#import "AGAuthenticationModule.h"

/**
 * Represents the public API to configure AGPipe objects.
 */
@protocol AGPipeConfig <AGConfig>

/**
 * The baseURL to the configuration.
 */
@property (strong, nonatomic) NSURL* baseURL;

/**
 * The endpoint to the configuration.
 * If no endpoint is specified, the name will be used as its value.
 */
@property (copy, nonatomic) NSString* endpoint;

/**
 * The recordId to the configuration.
 */
@property (copy, nonatomic) NSString* recordId;

/**
 * The Authentication Module configured for this Pipe.
 */
@property (strong, nonatomic) id<AGAuthenticationModule> authModule;

/**
 * The timeout interval for a request to complete.
 */
@property (assign, nonatomic) NSTimeInterval timeout;

/**
 * The NSURLCredential to use if the request requires authentication
 */
@property (strong, nonatomic) NSURLCredential *credential;

/**
 * A block specifying paging configuration for this Pipe.
 * See AGPageConfig and for the available paging configuration parameters 
 * and category AGNSMutableArray(Paging) for example usage.
 */
@property (copy, nonatomic) void (^pageConfig)(id<AGPageConfig>);

@end
