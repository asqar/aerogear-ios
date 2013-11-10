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

#import "AGPasswordKeyServices.h"

#import <AGRandomGenerator.h>
#import <AGCryptoBox.h>

@implementation AGPasswordKeyServices {
    NSString *_passKeyTag;
    NSString *_symmetricKeyTag;
}

- (id)initWithConfig:(AGKeyStoreCryptoConfig *)config {
    self = [super init];

    if (self) {
        // setup key tags used to access keychain
        _passKeyTag = [config.alias stringByAppendingString:@".password"];
        _symmetricKeyTag = [config.alias stringByAppendingString:@".symmetric"];

        NSMutableDictionary *query;
        CFTypeRef data;
        OSStatus status;
        NSData *key;
        
        // setup query for password
        query = [self keyChainDictionaryForPasswordClass];
        
        [query setObject:config.alias forKey:(__bridge id)kSecAttrService];
        [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        
        status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &data);
        
        if (status == errSecSuccess) { // password entry found
            // retrieve value
            NSData *password = [NSData dataWithData:(__bridge NSData *)data];
            if (data) CFRelease(data);
            
            // can't proceed if passwords don't match
            if (![password isEqualToData:[config.password dataUsingEncoding:NSUTF8StringEncoding]])
                return nil;
            
            // good to go, time to extract key..

            // setup query for key
            query = [self keyChainDictionaryForKeyClass];
            
            [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
            [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

            // Get the key bits.
          	status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&data);
            
            if (status == errSecSuccess) { // key found
                // extract it
                key = [NSData dataWithData:(__bridge NSData *)data];

                if (data) CFRelease(data);
            }
            
        } else if (status == errSecItemNotFound) {
            // step 1: add password to keychain
            query = [self keyChainDictionaryForPasswordClass];
            
            [query setObject:config.alias forKey:(__bridge id)kSecAttrService];

            NSData *data = [config.password dataUsingEncoding:NSUTF8StringEncoding];
            [query setObject:data forKey:(__bridge id)kSecValueData];
            
            // add it
            status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
            
            // step 2: generate and add symmetric key
            query = [self keyChainDictionaryForKeyClass];

            [query setObject:[NSNumber numberWithUnsignedInt:16]
                      forKey:(__bridge id)kSecAttrKeySizeInBits];
            [query setObject:[NSNumber numberWithUnsignedInt:16]
                      forKey:(__bridge id)kSecAttrEffectiveKeySize];
            [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanEncrypt];
            [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecAttrCanDecrypt];
            [query setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDerive];
            [query setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
            [query setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
            [query setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanWrap];
            [query setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanUnwrap];
            
            // generate key
            key = [AGRandomGenerator randomBytes:16];
            [query setObject:key forKey:(__bridge id)kSecValueData];
            
            // add it
            status = SecItemAdd((__bridge CFDictionaryRef) query, NULL);
        }
        
        // initialize cryptobox
        _cryptoBox = [[AGCryptoBox alloc] initWithKey:key];
    }
    
    return self;
}

-(void)resetKeychain {
    [self deleteAllKeysForSecClass:kSecClassGenericPassword];
    [self deleteAllKeysForSecClass:kSecClassKey];
}

#pragma mark - private helper methods

- (NSMutableDictionary *)keyChainDictionaryForPasswordClass {
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    
    [query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    [query setObject:[_passKeyTag dataUsingEncoding:NSUTF8StringEncoding]
              forKey:(__bridge id)kSecAttrGeneric];
    [query setObject:[_passKeyTag dataUsingEncoding:NSUTF8StringEncoding]
              forKey:(__bridge id)kSecAttrAccount];

    return query;
}

- (NSMutableDictionary *)keyChainDictionaryForKeyClass {
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    
    [query setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [query setObject:_symmetricKeyTag forKey:(__bridge id)kSecAttrApplicationTag];
    
    return query;
}

-(void)deleteAllKeysForSecClass:(CFTypeRef)secClass {
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:(__bridge id)secClass forKey:(__bridge id)kSecClass];
    OSStatus result = SecItemDelete((__bridge CFDictionaryRef) dict);
    NSAssert(result == noErr, @"Error deleting keychain data (%ld)", result);
}

@end
