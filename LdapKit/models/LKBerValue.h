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

@interface LKBerValue : NSObject <NSCopying>
{
   // BerValue data
   NSData        * berData;

   // Derived data
   id <NSObject>   berImage;
   NSString      * berString;
   NSString      * berStringBase64;

   // data attempts
   BOOL            attemptedImage;
   BOOL            attemptedString;
   BOOL            attemptedStringBase64;
}

#pragma mark - Object Management Methods
/// @name Object Management Methods

/// Initialize a new object with data from a BerValue struct.
/// @param value A BerValue referenced used to populate the object.
- (id) initWithBerValue:(BerValue *)value;

/// Initialize a new object with data from an NSData object.
/// @param value An NSData object used to populate the object.
- (id) initWithData:(NSData *)value;

/// Initialize a new object with data from an NSString object.
/// @param value An NSString object used to populate the object.
- (id) initWithString:(NSString *)value;

/// Allocate a new struct berval.
/// @return This method returns a pointer to a `struct berval`. The
/// `struct berval` must be freed using `ber_bvfree()`.
- (BerValue *) newBerValue;

/// Allocate a new struct berval from an NSData object
/// @param data The NSData object used to populate an allocated BerValue
/// @return This method returns a pointer to a `struct berval`. The
/// `struct berval` must be freed using `ber_bvfree()`.
+ (BerValue *) newBerValueWithData:(NSData *)data;

/// Creates a new object with data from a BerValue struct.
/// @param value A BerValue referenced used to populate the object.
+ (id) valueWithBerValue:(BerValue *)value;

/// Creates a new object with data from an NSData object.
/// @param value An NSData object used to populate the object.
+ (id) valueWithData:(NSData *)value;

/// Creates a new object with data from an NSString object.
/// @param value An NSString object used to populate the object.
+ (id) valueWithString:(NSString *)value;


#pragma mark - BerValue Data
/// @name BerValue Data

/// The NSData object which contains the object's value.
@property (nonatomic, readonly) NSData     * berData;

/// The number of bytes required to store the object's value.
@property (nonatomic, readonly) ber_len_t    bv_len;

@property (nonatomic, readonly) const char * bv_val;
/// Returns a pointer to the receiver’s contents.
///
/// If the length of the receiver is 0, this method returns `NULL`.
/// @return A read-only pointer to the receiver’s contents.


#pragma mark - Derived Data
/// @name Derived Data

/// Attempts to interpret the object's value as an image.
/// @return This property returns an UIImage on iOS and NSImage on OS X. If
/// the data is not a valid image, nil is returned.
#if TARGET_OS_IPHONE
@property (nonatomic, readonly) UIImage    * berImage;
#else
@property (nonatomic, readonly) NSImage    * berImage;
#endif

/// Attempts to interpret the object's value as an UTF8 string.
/// @return If the Ber value is a valid UTF8 string, this property returns
/// an NSString.  Otherwise nil is returned.
@property (nonatomic, readonly) NSString   * berString;

/// Returns the object's value as a base64 encoded string.
@property (nonatomic, readonly) NSString   * berStringBase64;


#pragma mark - Type of data
/// @name Type of data

/// Indicates the data is valid an NSData object.
/// @return This property always returns `YES`.
@property (nonatomic, readonly) BOOL         isBerData;

/// Indicates the data is a valid image.
@property (nonatomic, readonly) BOOL         isBerImage;

/// Indicates that the data is a valid string.
@property (nonatomic, readonly) BOOL         isBerString;

/// Indicates the data can be base64 encoded.
/// @return This property always returns `YES`.
@property (nonatomic, readonly) BOOL         isBerStringBase64;


@end
