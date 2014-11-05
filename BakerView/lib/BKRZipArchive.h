//
//  SSZipArchive.h
//  SSZipArchive
//
//  Created by Sam Soffes on 7/21/10.
//  Copyright (c) Sam Soffes 2010-2013. All rights reserved.
//

#ifndef _BKRZIPARCHIVE_H
#define _BKRZIPARCHIVE_H

#import <Foundation/Foundation.h>
#include "minizip/unzip.h"

@protocol BKRZipArchiveDelegate;

@interface BKRZipArchive : NSObject

// Unzip
+ (BOOL)unzipFileAtPath:(NSString*)path toDestination:(NSString*)destination;
+ (BOOL)unzipFileAtPath:(NSString*)path toDestination:(NSString*)destination overwrite:(BOOL)overwrite password:(NSString*)password error:(NSError **)error;

+ (BOOL)unzipFileAtPath:(NSString*)path toDestination:(NSString*)destination delegate:(id<BKRZipArchiveDelegate>)delegate;
+ (BOOL)unzipFileAtPath:(NSString*)path toDestination:(NSString*)destination overwrite:(BOOL)overwrite password:(NSString*)password error:(NSError **)error delegate:(id<BKRZipArchiveDelegate>)delegate;

// Zip
+ (BOOL)createZipFileAtPath:(NSString*)path withFilesAtPaths:(NSArray*)filenames;
+ (BOOL)createZipFileAtPath:(NSString*)path withContentsOfDirectory:(NSString*)directoryPath;

- (id)initWithPath:(NSString*)path;
- (BOOL)open;
- (BOOL)writeFile:(NSString*)path;
- (BOOL)writeData:(NSData*)data filename:(NSString*)filename;
- (BOOL)close;

@end


@protocol BKRZipArchiveDelegate <NSObject>

@optional

- (void)zipArchiveWillUnzipArchiveAtPath:(NSString*)path zipInfo:(unz_global_info)zipInfo;
- (void)zipArchiveDidUnzipArchiveAtPath:(NSString*)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString*)unzippedPath;

- (void)zipArchiveWillUnzipFileAtIndex:(NSInteger)fileIndex totalFiles:(NSInteger)totalFiles archivePath:(NSString*)archivePath fileInfo:(unz_file_info)fileInfo;
- (void)zipArchiveDidUnzipFileAtIndex:(NSInteger)fileIndex totalFiles:(NSInteger)totalFiles archivePath:(NSString*)archivePath fileInfo:(unz_file_info)fileInfo;

@end

#endif /* _BKRZIPARCHIVE_H */
