/*
 *  LDAP Kit
 *  Copyright (c) 2012, Bindle Binaries
 *
 *  @BINDLE_BINARIES_BSD_LICENSE_START@
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of Bindle Binaries nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 *  IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 *  THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BINDLE BINARIES BE LIABLE FOR
 *  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 *  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 *  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 *  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 *  LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 *  OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 *  SUCH DAMAGE.
 *
 *  @BINDLE_BINARIES_BSD_LICENSE_END@
 */
/**
 *  LKBerValue stores the inidividual attribute values returned as results from
 *  LDAP queries.  The information stored by an instance LKBerValue can be
 *  accessed as a string, an image, or binary data.
 */

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif
#import <Foundation/Foundation.h>
#import <ldap.h>

@interface LKBerValue : NSObject
{
   // BerValue data
   NSMutableData * berData;

   // derived data
   id <NSObject>   berImage;
   NSString      * berString;
   NSString      * berStringBase64;
   NSMutableData * berValue;

   // data attempts
   BOOL            attemptedValue;
   BOOL            attemptedImage;
   BOOL            attemptedString;
   BOOL            attemptedStringBase64;
}

/// @name BerValue data
@property (nonatomic, readonly) NSData     * berData;
@property (nonatomic, readonly) ber_len_t    bv_len;
@property (nonatomic, readonly) const char * bv_val;

/// @name derived data
#if TARGET_OS_IPHONE
@property (nonatomic, readonly) UIImage    * berImage;
#else
@property (nonatomic, readonly) NSImage    * berImage;
#endif
@property (nonatomic, readonly) NSString   * berString;
@property (nonatomic, readonly) NSString   * berStringBase64;
@property (nonatomic, readonly) BerValue   * berValue;

@end
