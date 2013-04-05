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

#import "AGPageBodyExtractor.h"

@implementation AGPageBodyExtractor

- (NSDictionary*) parse:(id)response
                headers:(NSDictionary*)headers
                   next:(NSString*)nextIdentifier
                   prev:(NSString*)prevIdentifier {

    // NSArray is ONLY being passed in, when the metadataLocation is "body"
    // AND it is actually NOT at the root level, like twitter does
    if (!response || ![response isKindOfClass:[NSDictionary class]]) {
        // for now... return NIL, since we do not support that...
        return nil;
    }

    NSDictionary* info = (NSDictionary*)response;

    // buld the MAP of links....:
    NSMutableDictionary *mapOfLink = [NSMutableDictionary dictionary];
    
    if ([info valueForKey:nextIdentifier] != nil)
        [mapOfLink setValue:[self transformQueryString:[info valueForKey:nextIdentifier]] forKey:@"AG-next-key"]; /// internal key...
    if ([info valueForKey:prevIdentifier] !=nil )
        [mapOfLink setValue:[self transformQueryString:[info valueForKey:prevIdentifier]] forKey:@"AG-prev-key"]; /// internal key...
    
    return mapOfLink;
}

-(NSDictionary *) transformQueryString:(NSString *) value {
    // we need to get rid of the '?' and everything before that
    // linke any URL info... (resource?params...)
    NSRange range = [value rangeOfString:@"?"];
    
    if (range.location != NSNotFound) {
        value = [value substringFromIndex:NSMaxRange(range)];
    }
    // chop the query string into a dictionary
    NSArray *components = [value componentsSeparatedByString:@"&"];
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    for (NSString *component in components) {
        [parameters setObject:[[component componentsSeparatedByString:@"="] objectAtIndex:1] forKey:[[component componentsSeparatedByString:@"="] objectAtIndex:0]];
    }
    return parameters;
}

@end
