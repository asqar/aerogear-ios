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

#import <Foundation/Foundation.h>
#import "AGPipe.h"
#import "AGAuthenticationModule.h"

/** `AGPipeline` represents a `collection` of server connections (`AGPipe` objects). The `AGPipeline` class offers some simple 'management' APIs to work with containing `AGPipe` objects, which itself represents a server connection. 

Create an empty `AGPipeline` object:

     // NSURL object:
    NSURL* serverURL = [NSURL URLWithString:@"http://todo-aerogear.rhcloud.com/todo-server/"];

    // create the 'todo' pipeline, which points to the baseURL of the REST application
    AGPipeline* todo = [AGPipeline pipeline:serverURL];
    
Simple create example....
 */
@interface AGPipeline : NSObject

/**
 * An initializer method to instantiate an empty AGPipeline.
 *
 * @param baseURL the URL of the server
 *
 * @return the AGPipeline object
 */
-(id) init:(NSURL*) baseURL;

/**
 * An initializer method to instantiate an empty AGPipeline.
 *
 * @return the AGPipeline object
 */
-(id) init;

/**
 * A factory method to instantiate an empty AGPipeline.
 *
 * @return the AGPipeline object
 */
+(id) pipeline;

/**
 * A factory method to instantiate an empty AGPipeline.
 *
 * @param baseURL the URL of the server
 *
 * @return the AGPipeline object
 */
+(id) pipeline:(NSURL*) baseURL;

// =====================================
// Adds that leverage the given base URL
// =====================================


/**
 * Adds a new RESTful pipe to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the endpoint name of the actual pipe
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name;

/**
 * Adds a new RESTful pipe to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the endpoint name of the actual pipe
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name authModule:(id<AGAuthenticationModule>) authModule;

/**
 * Adds a new RESTful pipe to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the name of the actual pipe
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name endpoint:(NSString*)endpoint;

/**
 * Adds a new RESTful pipe to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the name of the actual pipe
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name endpoint:(NSString*)endpoint authModule:(id<AGAuthenticationModule>) authModule;

/**
 * Adds a new pipe (server connection) to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the endpoint name of the actual pipe
 * @param type the type of the actual pipe/connection
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name type:(NSString*)type;

/**
 * Adds a new pipe (server connection) to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the endpoint name of the actual pipe
 * @param type the type of the actual pipe/connection
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name type:(NSString*)type authModule:(id<AGAuthenticationModule>) authModule;

/**
 * Adds a new pipe (server connection) to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the logical name of the actual pipe
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 * @param type the type of the actual pipe/connection
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name endpoint:(NSString*)endpoint type:(NSString*)type;

/**
 * Adds a new pipe (server connection) to the AGPipeline object,
 * leveraging the given baseURL argument.
 *
 * @param name the logical name of the actual pipe
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 * @param type the type of the actual pipe/connection
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name endpoint:(NSString*)endpoint type:(NSString*)type authModule:(id<AGAuthenticationModule>) authModule;


// =======================================
// Adds that specify a different base URL
// =======================================

/**
 * Adds a new RESTful pipe to the AGPipeline object
 *
 * @param name the endpoint name of the actual pipe
 * @param baseURL the URL of the server
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL;

/**
 * Adds a new RESTful pipe to the AGPipeline object
 *
 * @param name the endpoint name of the actual pipe
 * @param baseURL the URL of the server
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL authModule:(id<AGAuthenticationModule>) authModule;

/**
 * Adds a new RESTful pipe to the AGPipeline object
 *
 * @param name the name of the actual pipe
 * @param baseURL the URL of the server
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL endpoint:(NSString*)endpoint;

/**
 * Adds a new RESTful pipe to the AGPipeline object
 *
 * @param name the name of the actual pipe
 * @param baseURL the URL of the server
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL endpoint:(NSString*)endpoint authModule:(id<AGAuthenticationModule>) authModule;

/**
 * Adds a new pipe (server connection) to the AGPipeline object
 *
 * @param name the endpoint name of the actual pipe
 * @param baseURL the URL of the server
 * @param type the type of the actual pipe/connection
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL type:(NSString*)type;

/**
 * Adds a new pipe (server connection) to the AGPipeline object
 *
 * @param name the endpoint name of the actual pipe
 * @param baseURL the URL of the server
 * @param type the type of the actual pipe/connection
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL type:(NSString*)type authModule:(id<AGAuthenticationModule>) authModule;

/**
 * Adds a new pipe (server connection) to the AGPipeline object
 *
 * @param name the logical name of the actual pipe
 * @param baseURL the URL of the server
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 * @param type the type of the actual pipe/connection
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL endpoint:(NSString*)endpoint type:(NSString*)type;

/**
 * Adds a new pipe (server connection) to the AGPipeline object
 *
 * @param name the logical name of the actual pipe
 * @param baseURL the URL of the server
 * @param endpoint the serivce endpoint, if differs from the pipe name.
 * @param type the type of the actual pipe/connection
 * @param authModule the AGAuthenticationModule used to access protected resources
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) add:(NSString*) name baseURL:(NSURL*)baseURL endpoint:(NSString*)endpoint type:(NSString*)type authModule:(id<AGAuthenticationModule>) authModule;


// ============================
// remove and get functionality
// ============================

/**
 * Removes a pipe from the AGPipeline object
 *
 * @param name the name of the actual pipe
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) remove:(NSString*) name;

/**
 * Look up for a pipe object.
 *
 * @param name the name of the actual pipe
 *
 * @return the new created AGPipe object
 */
-(id<AGPipe>) get:(NSString*) name;

@end