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

#import "AGPageWebLinkingExtractor.h"

@implementation AGPageWebLinkingExtractor

- (NSDictionary*) parse:(id)response
                headers:(NSDictionary*)headers
                   next:(NSString*)nextIdentifier
                   prev:(NSString*)prevIdentifier {

    NSString* headerValue = [headers objectForKey:@"Link"];
    
    NSMutableDictionary *pagingLinks = [NSMutableDictionary dictionary];
    NSArray *links = [headerValue componentsSeparatedByString:@","];
    for (NSString *link in links) {
        NSArray *elementsPerLink = [link componentsSeparatedByString:@";"];
        
        NSDictionary *queryArguments;
        for (NSString *elem in elementsPerLink) {
            NSString *tmpElem = [elem stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if ([tmpElem hasPrefix:@"<"] && [tmpElem hasSuffix:@">"]) {
                NSURL *parsedURL = [NSURL URLWithString:[[tmpElem substringFromIndex:1] substringToIndex:tmpElem.length-2]]; //2 because, the first did already cut one char...
                queryArguments = [self transformQueryString:parsedURL.query];
            } else if ([tmpElem hasPrefix:@"rel="]) {
                // only those 'rel' links that we need (prev/next)
                NSString *rel = [[tmpElem substringFromIndex:5] substringToIndex:tmpElem.length-6]; // cutting 5 + the last....
                
                if ([nextIdentifier isEqualToString:rel]) {
                    [pagingLinks setValue:queryArguments forKey:@"AG-next-key"]; // internal key
                } else if ([prevIdentifier isEqualToString:rel]) {
                    [pagingLinks setValue:queryArguments forKey:@"AG-prev-key"]; // internal key
                }
            } else {
                // ignore title etc
            }
        }
    }
    
    return pagingLinks;
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
