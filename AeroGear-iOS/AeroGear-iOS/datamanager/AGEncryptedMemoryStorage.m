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

#import "AGEncryptedMemoryStorage.h"
#import "AGEncryptionService.h"

NSString *const AGEncryptedMemoryStorageErrorDomain = @"AGEncryptedMemoryStorageErrorDomain";

@implementation AGEncryptedMemoryStorage {
    NSMutableDictionary *_data;
    NSString *_recordId;
    
    id<AGEncryptionService> _encryptionService;
}

@synthesize type = _type;

// ==============================================
// ======== 'factory' and 'init' section ========
// ==============================================

+ (id)storeWithConfig:(id<AGStoreConfig>) storeConfig {
    return [[self alloc] initWithConfig:storeConfig];
}

- (id)initWithConfig:(id<AGStoreConfig>) storeConfig {
    self = [super init];
    if (self) {
        // base inits:
        _type = @"ENCRYPTED_MEMORY";
        _data = [[NSMutableDictionary alloc] init];
      
        AGStoreConfiguration *config = (AGStoreConfiguration*) storeConfig;
        _recordId = config.recordId;
        _encryptionService = config.encryptionService;
    }
    
    return self;
}

- (NSArray *)readAll {
    NSMutableArray *list = [NSMutableArray arrayWithCapacity:[_data count]];
    
    for (NSData *encryptedData in [_data allValues]) {
        NSData *decryptedData = [_encryptionService decrypt:encryptedData];

        id object = [NSJSONSerialization JSONObjectWithData:decryptedData
                                                    options:NSJSONReadingMutableContainers error:nil];
        
        [list addObject:object];
    }
    
    return list;
}

- (id)read:(id)recordId {
    id retval;
    
    NSData *encryptedData = [_data objectForKey:recordId];
 
    if (encryptedData) {
        NSData *decryptedData = [_encryptionService decrypt:encryptedData];

        retval = [NSJSONSerialization JSONObjectWithData:decryptedData
                                                 options:NSJSONReadingMutableContainers error:nil];
    }
    
    return retval;
}

- (NSArray *)filter:(NSPredicate*)predicate {
    // TODO
    return nil;
}

- (BOOL)save:(id)data error:(NSError**)error {
    // fail fast if invalid data
    if (![NSJSONSerialization isValidJSONObject:data]) {
        if (error)
            *error = [NSError errorWithDomain:AGEncryptedMemoryStorageErrorDomain
                                        code:0
                                    userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"data can't be encoded to json!",
                      NSLocalizedDescriptionKey, nil]];


        // do nothing
        return NO;
    }

    // convinience to add objects inside an array
    if ([data isKindOfClass:[NSArray class]]) {
        for (id record in data)
            [self saveOne:record];

    } else {
        [self saveOne:data];
    }
    
    return YES;
}

- (BOOL)reset:(NSError**)error {
    [_data removeAllObjects];
    
    return YES;
}

- (BOOL)isEmpty {
    return [_data count] == 0;
    
}

- (BOOL)remove:(id)record error:(NSError**)error {
    if (record == nil || [record isKindOfClass:[NSNull class]])
        return NO;

    id key = [record objectForKey:_recordId];
    
    if (key && [_data objectForKey:key]) {
        [_data removeObjectForKey:key];

        return YES;
    }
    
    return NO;
}

// =====================================================
// =========== private utility methods  ================
// =====================================================

- (void)saveOne:(NSDictionary*)data {
    id recordId = [data objectForKey:_recordId];
    
    // if the object hasn't set a recordId property
    if (!recordId) {
        //generate a UIID to be used instead
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
        
        recordId = uuidStr;
        // set the generated ID for the newly object
        [data setValue:recordId forKey:_recordId];
    }

    // json encode it
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:nil];
    // encrypt it
    NSData *encryptedData = [_encryptionService encrypt:jsonData];
    // set it
    [_data setValue:encryptedData forKey:recordId];
}

@end
