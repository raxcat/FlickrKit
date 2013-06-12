//
//  FKAPIBuilder.m
//  FlickrKit
//
//  Created by David Casserly on 10/06/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved.
//

#import "FKAPIBuilder.h"
#import "FlickrKit.h"

@interface FKAPIBuilder ()
@property (nonatomic, retain) NSString *factoryOutputPath;
@property (nonatomic, retain) NSString *outputPath;
@property (nonatomic, retain) NSArray *allMethods;
@end

@implementation FKAPIBuilder

+ (FKAPIBuilder *) sharedBuilder {
	static dispatch_once_t onceToken;
	static FKAPIBuilder *flickrKit = nil;
	
	dispatch_once(&onceToken, ^{
		flickrKit = [[self alloc] init];
	});
	
	return flickrKit;
}

- (id) init {
    self = [super init];
    if (self) {
        NSString *baseOutputPath = @"/Users/dave/Developer/GIT/FlickrKit/FlickrKit/Classes/Model/";
		
		//flickrKit.outputPath = @"/Users/Dave/Developer/GIT/bitbucket/FlickrKIT/FlickrKit/Classes/Model/Generated/";
		
		self.factoryOutputPath = baseOutputPath;
		self.outputPath = [NSString stringWithFormat:@"%@Generated/", baseOutputPath];
		
		BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:self.outputPath];
		NSAssert(exists, @"Ouput folder doesn't exist - you need to set this in the code");
		
		NSString *apiKey = nil;
		NSString *secret = nil;
		NSAssert(apiKey, @"You need to enter your own API key and secret");
		
		[[FlickrKit sharedFlickrKit] initializeWithAPIKey:apiKey sharedSecret:secret];
    }
    return self;
}

- (BOOL) buildAPI {
    [self findAllMethods];
    return YES;
}

- (void) findAllMethods {
    [[FlickrKit sharedFlickrKit] call:@"flickr.reflection.getMethods" args:nil completion:^(NSDictionary *response, NSError *error) {
        if (response) {
            self.allMethods = [response valueForKeyPath:@"methods.method._content"];
            NSLog(@"All methods %@", self.allMethods);
            [self createClassFiles];
        }
    }];
}

- (void) createClassFiles {
	
	NSMutableArray *enumNames = [NSMutableArray array];
	
	dispatch_group_t group = dispatch_group_create();
	
    __block int count = 1;
    for (NSString *method in self.allMethods) {
        
		dispatch_group_enter(group);
		
		NSMutableString *enumName = [[NSMutableString alloc] init];		
        NSMutableString *subCategory = [[NSMutableString alloc] init];
        
        NSMutableString *className = [[NSMutableString alloc] initWithString:@"FK"];
        NSArray *components = [method componentsSeparatedByString:@"."];
        int index = 1;
        for (NSString *comp in components) {
            NSString *camelCase = [NSString stringWithFormat:@"%@%@",[[comp substringToIndex:1] capitalizedString],[comp substringFromIndex:1]];
            [className appendString:camelCase];
            if (index != 1 && (index < components.count)) {
                [subCategory appendFormat:@"%@/", camelCase];
            }
			if (index != 1) {
                [enumName appendFormat:@"%@", camelCase];
            }
            index++;
        }
		
		// Add the enum name
		[enumNames addObject:enumName];
        
        // Create subCategory folder
        NSString *subPath = [NSString stringWithFormat:@"%@%@", self.outputPath, subCategory];
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:subPath];
        if (!exists) {
            [[NSFileManager defaultManager] createDirectoryAtPath:subPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        NSDictionary *args = @{@"method_name": method};
        [[FlickrKit sharedFlickrKit] call:@"flickr.reflection.getMethodInfo" args:args completion:^(NSDictionary *response, NSError *error) {                        
            [self writeHeaderForClass:className withData:response path:subPath];
            [self writeImplementationForClass:className withData:response path:subPath];
            NSLog(@"Written Class Files for %@. %i Remaining", method, self.allMethods.count - count);
            count++;
			dispatch_group_leave(group);
        }];
        
    }
	
	
	// Create the factory class
	NSMutableString *imports = [[NSMutableString alloc] init];
	for (NSString *e in enumNames) {
		[imports appendFormat:@"#import \"FKFlickr%@.h\"\n", e];
	}
	NSString *header = [self templateForFactoryHeader];
	header = [header stringByReplacingOccurrencesOfString:@"#IMPORTS#" withString:imports];
	NSString *outputPath = [NSString stringWithFormat:@"%@FKAPIMethods.h", self.factoryOutputPath];
	[self writeString:header toFileAtPath:outputPath];	
	
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	
	exit(0);	
}

- (NSDateFormatter *) dateFormatter {
    static NSDateFormatter *dateFormat = nil;
    if (!dateFormat) {
        dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"dd MMM, yyyy 'at' HH:mm"];
    }
    return dateFormat;
}

- (void) writeHeaderForClass:(NSString *)className withData:(NSDictionary *)data path:(NSString *)path {
    NSString *header = [self templateForHeader];
    if (header) {
        [header stringByReplacingOccurrencesOfString:@"FKFlickrMethodTemplate" withString:className];
        
        // Write the class name
        header = [header stringByReplacingOccurrencesOfString:@"#CLASS_NAME#" withString:className];
        
        // Write the header description
        NSString *description = [data valueForKeyPath:@"method.description._content"];
        NSString *explanationVal = [data valueForKeyPath:@"method.explanation._content"];
        NSString *explanation = nil;
        if (explanationVal) {
            explanation = [NSString stringWithFormat:@"%@\n", explanationVal];
        }
        NSString *responseEG = [data valueForKeyPath:@"method.response._content"];
        NSString *response = nil;
        if (responseEG) {
            response = [NSString stringWithFormat:@"Response:\n\n%@", responseEG];
        }
        NSString *headerComment = [NSString stringWithFormat:@"%@\n\n%@\n%@", description, explanation ? explanation : @"", response ? response : @""];
        header = [header stringByReplacingOccurrencesOfString:@"#HEADER_COMMENT#" withString:headerComment];
        
        // Write the args
        NSMutableString *argString = [[NSMutableString alloc] init];
        NSArray *args = [data valueForKeyPath:@"arguments.argument"];
        for (NSDictionary *arg in args) {
            NSString *argName = [arg valueForKey:@"name"];
            if ([argName isEqualToString:@"api_key"]) {
                continue;
            }
            [argString appendFormat:@"/* %@ */\n", [arg valueForKey:@"_content"]];
            [argString appendFormat:@"@property (nonatomic, strong) NSString *%@;", argName];
            BOOL optional = [[arg valueForKey:@"optional"] boolValue];
            if (!optional) {
                [argString appendString:@" /* (Required) */"];                
            }
            [argString appendString:@"\n\n"];
        }
        header = [header stringByReplacingOccurrencesOfString:@"#ARGS#" withString:argString];
        
        // Write the error codes
        NSMutableString *errorString = [[NSMutableString alloc] init];
        NSArray *errors = [data valueForKeyPath:@"errors.error"];
        for (NSDictionary *error in errors) {
            NSString *desc = [error valueForKey:@"_content"];
            NSString *message = [error valueForKey:@"message"];
			
			NSString *enumTitle = [self errorEnumTitleForError:message];			
			
            NSInteger code = [[error valueForKey:@"code"] integerValue];
            [errorString appendFormat:@"\t%@Error_%@ = %i,\t\t /* %@ */\n", className, enumTitle, code, desc];
        }
        header = [header stringByReplacingOccurrencesOfString:@"#ERROR_CODES#" withString:errorString];
        
                
        // Date Generated        
        NSString *generatedDate = [[self dateFormatter] stringFromDate:[NSDate date]];
        header = [header stringByReplacingOccurrencesOfString:@"#GENERATED_DATE#" withString:generatedDate];
        
        NSString *outputPath = [NSString stringWithFormat:@"%@%@.h", path, className];
        [self writeString:header toFileAtPath:outputPath];
    }
}


- (void) writeImplementationForClass:(NSString *)className withData:(NSDictionary *)data path:(NSString *)path {
    NSString *implementation = [self templateForImplementation];
    if (implementation) {
        [implementation stringByReplacingOccurrencesOfString:@"FKFlickrMethodTemplate" withString:className];
        
        // Write the class name
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#CLASS_NAME#" withString:className];
        
        // Write the arg builder
        NSMutableString *argString = [[NSMutableString alloc] init];
        NSMutableString *validationString = [[NSMutableString alloc] init];
        
        NSArray *args = [data valueForKeyPath:@"arguments.argument"];
        
        for (NSDictionary *arg in args) {
            NSString *argName = [arg valueForKey:@"name"];
            if ([argName isEqualToString:@"api_key"]) {
                continue;
            }
            BOOL optional = [[arg valueForKey:@"optional"] boolValue];
            [argString appendFormat:@"\tif(self.%@) {\n\t\t[args setValue:self.%@ forKey:@\"%@\"];\n\t}", argName, argName, argName];
            [argString appendString:@"\n"];
            
            if (!optional) {
				[validationString appendFormat:@"\tif(!self.%@) {\n", argName];
                [validationString appendString:@"\t\tvalid = NO;\n"];
				[validationString appendFormat:@"\t\t[errorDescription appendString:@\"'%@', \"];\n", argName];
				[validationString appendString:@"\t}\n"];
            }
        }
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#ARG_BUILDER#" withString:argString];
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#VALIDATION_BUILDER#" withString:validationString];
                
        // Write the error cases
        NSMutableString *errorString = [[NSMutableString alloc] init];
        NSArray *errors = [data valueForKeyPath:@"errors.error"];
        for (NSDictionary *error in errors) {
            NSString *message = [error valueForKey:@"message"];
			NSString *enumTitle = [self errorEnumTitleForError:message];
            message = [message stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];			
            [errorString appendFormat:@"\t\tcase %@Error_%@:\n", className, enumTitle];
            [errorString appendFormat:@"\t\t\treturn @\"%@\";\n", message];
        }
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#ERROR_CASES#" withString:errorString];
     
        // Write the method name
        NSString *methodName = [data valueForKeyPath:@"method.name"];
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#METHOD_NAME#" withString:methodName];
        
        
        // Date Generated
        NSString *generatedDate = [[self dateFormatter] stringFromDate:[NSDate date]];
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#GENERATED_DATE#" withString:generatedDate];
        
        
        // Other bool values
        NSString *needsLogin = [[data valueForKeyPath:@"method.needslogin"] integerValue] ? @"YES" : @"NO";
        NSString *needsSigning = [[data valueForKeyPath:@"method.needslogin"] integerValue] ? @"YES" : @"NO";
        NSString *requiredPerms = [NSString stringWithFormat:@"%i", [[data valueForKeyPath:@"method.requiredperms"] integerValue] - 1];
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#NEEDS_LOGIN#" withString:needsLogin];
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#NEEDS_SIGNING#" withString:needsSigning];
        implementation = [implementation stringByReplacingOccurrencesOfString:@"#REQUIRED_PERMS#" withString:requiredPerms];
        
        
        NSString *outputPath = [NSString stringWithFormat:@"%@%@.m", path, className];
        [self writeString:implementation toFileAtPath:outputPath];
    }
}

#pragma mark - Error Builders

- (NSString *) errorEnumTitleForError:(NSString *)message {
	NSMutableString *enumTitle = [[NSMutableString alloc] init];
	NSArray *comps = [message componentsSeparatedByString:@" "];
	for (NSString *comp in comps) {
		NSString *camelCase = [NSString stringWithFormat:@"%@%@",[[comp substringToIndex:1] capitalizedString],[comp substringFromIndex:1]];
		camelCase = [camelCase stringByReplacingOccurrencesOfString:@"\"xxx\"" withString:@"XXX"];
		camelCase = [camelCase stringByReplacingOccurrencesOfString:@"/" withString:@"Or"];
		camelCase = [camelCase stringByReplacingOccurrencesOfString:@"-" withString:@""];
		camelCase = [camelCase stringByReplacingOccurrencesOfString:@"." withString:@""];
		camelCase = [camelCase stringByReplacingOccurrencesOfString:@"," withString:@""];
		camelCase = [camelCase stringByReplacingOccurrencesOfString:@"'" withString:@""];
		camelCase = [camelCase stringByReplacingOccurrencesOfString:@"`" withString:@""];
		[enumTitle appendString:camelCase];
	}
	return enumTitle;
}

#pragma mark - File Util

- (NSString *) templateForFactoryHeader {
    NSString *headerPath = [[NSBundle mainBundle] pathForResource:@"FKAPIMethods" ofType:@"header"];
    NSError *error = nil;
    NSString *header = [[NSString alloc] initWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:&error];
    return header;
}

- (NSString *) templateForHeader {
    NSString *headerPath = [[NSBundle mainBundle] pathForResource:@"FKFlickrMethodTemplate" ofType:@"header"];
    NSError *error = nil;
    NSString *header = [[NSString alloc] initWithContentsOfFile:headerPath encoding:NSUTF8StringEncoding error:&error];
    return header;
}

- (NSString *) templateForImplementation {
    NSString *implPath = [[NSBundle mainBundle] pathForResource:@"FKFlickrMethodTemplate" ofType:@"implementation"];
    NSError *error = nil;
    NSString *implementation = [[NSString alloc] initWithContentsOfFile:implPath encoding:NSUTF8StringEncoding error:&error];
    return implementation;
}

- (void) writeString:(NSString *)string toFileAtPath:(NSString *)outputPath {
    [[NSFileManager defaultManager] createFileAtPath:outputPath contents:[string dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:outputPath]) {
        NSLog(@"Could not write file at path %@", outputPath);
    }
}

@end
