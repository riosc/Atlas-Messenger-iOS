//
//  ATLMConfigurationSet.m
//  Atlas Messenger
//
//  Created by JP McGlone 01/04/2017
//  Copyright (c) 2014 Layer, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "ATLMConfiguration.h"
#import "ATLMConfigurationSet.h"

@implementation ATLMConfigurationSet

- (instancetype)initWithFileURL:(NSURL *)fileURL
{
    if (fileURL == nil) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because the `fileURL` argument was `nil`.", self.class] userInfo:nil];
    }
    
    self = [super init];
    if (self == nil) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@`.", self.class] userInfo:nil];
    }

    NSMutableSet<ATLMConfiguration *> *configurations = [NSMutableSet set];
    for (NSDictionary *dictionary in [self extractConfigurationsFromFileURL:fileURL]) {
        [configurations addObject:[[ATLMConfiguration alloc] initWithDictionary:dictionary]];
    }
    _configurations = configurations;
    
    return self;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"Failed to call designated initializer. Call the designated initializer '%@' on the `%@` instead.", NSStringFromSelector(@selector(initWithFileURL:)), self.class]
                                 userInfo:nil];
}

#pragma mark - Helpers

- (NSArray *)extractConfigurationsFromFileURL:(NSURL *)fileURL
{
    // Load the content of the file in memory.
    NSError *fileReadError;
    NSString *configurationsJSON = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&fileReadError];
    if (configurationsJSON == nil) {
        // File read failure.
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because the input file could not be read; error=%@", self.class, fileReadError] userInfo:nil];
    }

    // Deserialize the content of the input file.
    NSError *JSONDeserializationError;
    NSArray *configurations;
    configurations = [NSJSONSerialization JSONObjectWithData:[configurationsJSON dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&JSONDeserializationError];
    if (!configurations) {
        // Deserialization failure.
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because the input file could not be deserialized; error=%@", self.class, JSONDeserializationError] userInfo:nil];
    }

    if (![configurations isKindOfClass:[NSArray class]]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because the input file JSON root was not an array", self.class] userInfo:nil];
    }

    if (configurations.count == 0) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"Failed to initialize `%@` because the input file JSON root array was empty", self.class] userInfo:nil];
    }

    return configurations;
}

@end
