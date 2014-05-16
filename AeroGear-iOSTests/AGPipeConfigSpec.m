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

#import <Kiwi/Kiwi.h>
#import "AGPipeConfig.h"
#import "AGPipeConfiguration.h"

SPEC_BEGIN(AGPipeConfigSpec)

describe(@"AGPipeConfig.h", ^{
    context(@"when newly created", ^{
        
        //A pipe config object:
        __block AGPipeConfiguration *config = nil;
        
        beforeEach(^{
            
            // empty object, with defaults:
            config = [[AGPipeConfiguration alloc] init];
        });
        
        it(@"should not be nil", ^{
            [config shouldNotBeNil];
        });
        
        it(@"should have defaults", ^{
            [[config.type should] equal:@"REST"];
            [[config.recordId should] equal:@"recId"];
            [[theValue(config.timeout) should] equal:theValue(60)];
        });

        it(@"should allow overriding defaults", ^{
            
            // set up:
            config.recordId = @"recordId";
            config.timeout = 20;
            
            [[config.recordId should] equal:@"recordId"];
            [[theValue(config.timeout) should] equal:theValue(20)];
            
        });
    });
});

SPEC_END