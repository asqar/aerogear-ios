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

#import "AGEncryptionService.h"
#import "AGCryptoConfig.h"

/**
 AGKeyManager manages different AGEncryptionService implementations. It is basically a
 factory that hides the concrete instantiations of a specific AGEncryptionService implementation.
*/ 
@interface AGKeyManager : NSObject

/**
 * A factory method to instantiate the AGKeyManager object.
 *
 * @return the AGKeyManager object
 */
+ (id)manager;

/**
 * Return an implementation of an AGEncryptionService based on the AGCryptoConfig configuration object passed in. See AGPasswordKeyServices and AGPassPhraseKeyServices for the different encyption providers.
 *
 * @param config The CryptoConfig object. See AGKeyStoreCryptoConfig and AGPassPhraseCryptoConfig configuration objects.
 *
 * @return the newly created AGEncryptionService object.
 */
- (id<AGEncryptionService>)keyService:(id<AGCryptoConfig>)config;

@end
