/*
 * JBoss, Home of Professional Open Source.
 * Copyright 2012 Red Hat, Inc., and individual contributors
 * as indicated by the @author tags.
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

/**
 * AGPipe represents a server connection. An object of this class is responsible to
 * communicate with the server and perfoms read/write operations.
 */
@protocol AGPipe <NSObject>

/**
 * Returns the type of the underlying 'pipe implementation'
 */
@property (nonatomic, readonly) NSString* type;

/**
 * Returns the url string of the underlying 'pipe implementation'
 */
@property (nonatomic, readonly) NSString* url;

/**
 * Reads all the data from the underlying server connection.
 *
 * @param success A block object to be executed when the request operation finishes successfully.
 * This block has no return value and takes one argument: The object created from the response
 * data of request.
 *
 * @param failure A block object to be executed when the request operation finishes unsuccessfully,
 * or that finishes successfully, but encountered an error while parsing the resonse data.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the network or parsing error that occurred.
 */
-(void) read:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure;


/**
 * Reads all the data that matches a given filter creteria from the underlying server connection.
 *
 * @param filterObject TODO some filter object..........
 *
 *
 * @param success A block object to be executed when the request operation finishes successfully.
 * This block has no return value and takes one argument: The object created from the response
 * data of request.
 *
 * @param failure A block object to be executed when the request operation finishes unsuccessfully,
 * or that finishes successfully, but encountered an error while parsing the resonse data.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the network or parsing error that occurred.
 */
-(void) readWithFilter:(id)filterObject
               success:(void (^)(id responseObject))success
               failure:(void (^)(NSError *error))failure;


/**
 * Saves (or updates) a give 'JSON' map on the server;
 *
 * @param object the data to save/update
 *
 * @param success A block object to be executed when the request operation finishes successfully.
 * This block has no return value and takes one argument: The object created from the response
 * data of request.
 *
 * @param failure A block object to be executed when the request operation finishes unsuccessfully,
 * or that finishes successfully, but encountered an error while parsing the resonse data.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the network or parsing error that occurred.
 */
-(void) save:(id) object
     success:(void (^)(id responseObject))success
     failure:(void (^)(NSError *error))failure;

/**
 * Removes an object from the underlying server connection. The
 * given key argument is used as the objects ID.
 *
 * @param key (string, integer,...) representing the 'id'
 *
 * @param success A block object to be executed when the request operation finishes successfully.
 * This block has no return value and takes one argument: The object created from the response
 * data of request.
 *
 * @param failure A block object to be executed when the request operation finishes unsuccessfully,
 * or that finishes successfully, but encountered an error while parsing the resonse data.
 * This block has no return value and takes one argument: The `NSError` object describing
 * the network or parsing error that occurred.
 */
-(void) remove:(id) key
       success:(void (^)(id responseObject))success
       failure:(void (^)(NSError *error))failure;

@end