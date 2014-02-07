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

#import "AGBaseEncryptionService.h"
#import <AGSecretBox.h>
#import <AGRandomGenerator.h>

static NSString *const kApplicationIV = @"applicationIV";

@implementation AGBaseEncryptionService

- (id)init {
    self = [super init];
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _applicationIV = [defaults dataForKey:kApplicationIV];
        
        if (!_applicationIV) {
            _applicationIV = [AGRandomGenerator randomBytes:16];
            
            [defaults setObject:_applicationIV forKey:kApplicationIV];
            [defaults synchronize];
        }
    }
    
    return self;
}

- (NSData *)encrypt:(NSData *)data {
    return [self encrypt:data IV:_applicationIV];
    
}

- (NSData *)encrypt:(NSData *)data IV:(NSData *)IV {
    return [_secretBox encrypt:data IV:IV];
    
}

- (NSData *)decrypt:(NSData *)data {
    return [self decrypt:data IV:_applicationIV];
    
}

- (NSData *)decrypt:(NSData *)data IV:(NSData *)IV {
    return [_secretBox decrypt:data IV:IV];
}

@end

