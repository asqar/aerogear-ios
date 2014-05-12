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

#import "AGModelResponseSerializer.h"
#import <Mantle/Mantle.h>

NSString * const AGModelResponseSerializerErrorDomain = @"AGModelResponseSerializerErrorDomain";
NSString * const AGModelResponseErrorKey = @"AGModelResponseErrorKey";

@interface  AGModelResponseSerializer()
    @property (readwrite, nonatomic, strong) Class modelClass;
@end

@implementation AGModelResponseSerializer

+ (instancetype)serializerForModelClass:(Class)modelClass {
    AGModelResponseSerializer *serializer = [self serializerWithReadingOptions:NSJSONReadingMutableContainers];
    serializer.modelClass = modelClass;

    return serializer;
}

# pragma mark - AFURLResponseSerialization protocol

- (id)responseObjectForResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error {
    id jsonObj = [super responseObjectForResponse:response data:data error:error];

    // no need to continue if error occurred
    if (error)
        return nil;

    // time to deserialize
    NSValueTransformer *transformer = nil;
    if ([jsonObj isKindOfClass:[NSDictionary class]]) {
        transformer = [NSValueTransformer mtl_JSONDictionaryTransformerWithModelClass:self.modelClass];
    } else if ([jsonObj isKindOfClass:[NSArray class]]) {
        transformer = [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:self.modelClass];
    } else { // unknown type
        if (error) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo setValue:@"unable to deserialize response received!" forKey:NSLocalizedDescriptionKey];
            [userInfo setValue:@"response neither a dictionary nor an array" forKey:NSLocalizedFailureReasonErrorKey];
            // attach the response to help debugging
            [userInfo setValue:response forKey:AGModelResponseErrorKey];

            *error = [[NSError alloc] initWithDomain:AGModelResponseSerializerErrorDomain code:NSURLErrorCannotDecodeContentData userInfo:userInfo];
        }

        return nil;
    }

    return [transformer transformedValue:jsonObj];
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.modelClass = NSClassFromString([aDecoder decodeObjectForKey:@"modelClass"]);
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:NSStringFromClass(self.modelClass) forKey:@"modelClass"];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    AGModelResponseSerializer *serializer = [super copyWithZone:zone];
    serializer.modelClass = self.modelClass;

    return serializer;
}

@end