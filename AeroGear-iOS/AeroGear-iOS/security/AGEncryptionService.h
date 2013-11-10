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

/**
  An AGEncryptionService represents an abstraction layer for a encryption provider.
 */
@protocol AGEncryptionService <NSObject>

/**
 * Encrypts the data object passed in.
 *
 * @param data The data object to encrypt.
 *
 * @return An NSData object that holds the encrypted(cipher) data.
 */
- (NSData *)encrypt:(NSData *)data;

/**
 * Encrypts the data object passed in.
 *
 * @param data The data object to encrypt.
 * @param IV   A randomly choosen value used as the initialization vector during encrypt.
 *
 * @return An NSData object that holds the encrypted(cipher) data.
 */
- (NSData *)encrypt:(NSData *)data IV:(NSData *)IV;

/**
 * Decrypts the data object(cipher) passed in.
 *
 * @param data The data object(cipher) to decrypt.
 *
 * @return An NSData object that holds the decrypted data.
 */
- (NSData *)decrypt:(NSData *)data;

/**
 * Decrypts the data object(cipher) passed in.
 *
 * @param data The data object(cipher) to decrypt.
 * @param IV   A randomly choosen value used as the initialization vector during decrypt.
 *
 * @return An NSData object that holds the decrypted data.
 */
- (NSData *)decrypt:(NSData *)data IV:(NSData *)IV;

@end
