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

#import "AGKeyManager.h"

#import "AGPasswordKeyServices.h"
#import "AGPassPhraseKeyServices.h"

@implementation AGKeyManager

- (id)init {
    self = [super init];
    if (self) {
       
    }
    return self;
}

+ (id)manager {
    return [[self alloc] init];
}

- (id<AGEncryptionService>)keyService:(id<AGCryptoConfig>)config {
    
    id<AGEncryptionService> keyService;
    
    if ([config isKindOfClass:[AGKeyStoreCryptoConfig class]]) {
        keyService = [[AGPasswordKeyServices alloc] initWithConfig:config];
    } else if ([config isKindOfClass:[AGPassPhraseCryptoConfig class]]) {
        keyService = [[AGPassPhraseKeyServices alloc] initWithConfig:config];
    }
    
    return keyService;
}


@end
