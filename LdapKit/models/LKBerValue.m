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
/*
 *  LdapKit/LKBerValue.m convenience class for BerValue.
 */
#import "LKBerValue.h"
#import "LKBerValueCategory.h"


@interface LKBerValue ()

/// @name calculations
- (NSString *) convertToBase64:(NSData *)value;

@end


@implementation LKBerValue

#pragma mark - Object Management Methods

- (void) dealloc
{
   // BerVal data
   [berData release];

   // derived data
   [berImage        release];
   [berString       release];
   [berStringBase64 release];
   [berValue        release];

   [super dealloc];

   return;
}


- (id) initWithBerValue:(BerValue *)value
{
   NSAssert((value != NULL), @"BerValue must not be NULL");
   if ((self = [super init]) == nil)
      return(self);

   // BerVal data
   berData = [[NSMutableData alloc] initWithBytes:value->bv_val length:value->bv_len];

   return(self);
}


+ (id) valueWithBerValue:(BerValue *)value
{
   return([[[LKBerValue alloc] initWithBerValue:value] autorelease]);
}


#pragma mark - Getter/Setter methods

/// The number of bytes required to store the object's value.
- (ber_len_t) bv_len
{
   return(berData.length);
}


/// C pointer to the memory allocation of object's value.
- (const char *) bv_val
{
   [[berData retain] autorelease];
   return([berData bytes]);
}


/// The NSData object which contains the object's value.
- (NSData *) berData
{
   return([[berData retain] autorelease]);
}


/// Attempts to interpret the object's value as an image.
/// @return This property returns an UIImage on iOS and NSImage on OS X. If
/// the data is not a valid image, nil is returned.
- (id) berImage
{
   @synchronized(self)
   {
      if ((attemptedImage))
         return([[berImage retain] autorelease]);
      attemptedImage = YES;
#if TARGET_OS_IPHONE
      berImage = [[UIImage alloc] initWithData:berData];
#else
      berImage = [[NSData alloc] initWithData:berData];
#endif
   };
   return([[berImage retain] autorelease]);
}


/// Attempts to interpret the object's value as an UTF8 string.
/// @return If the Ber value is a valid UTF8 string, this property returns
/// an NSString.  Otherwise nil is returned.
- (NSString *) berString
{
   @synchronized(self)
   {
      if ((attemptedString))
         return([[berString retain] autorelease]);
      attemptedString = YES;
      berString = [[NSString alloc] initWithData:berData encoding:NSUTF8StringEncoding];
   };
   return([[berString retain] autorelease]);
}


/// Returns the object's value as a base64 encoded string.
- (NSString *) berStringBase64
{
   NSAutoreleasePool * pool;
   @synchronized(self)
   {
      if ((attemptedStringBase64))
         return([[berStringBase64 retain] autorelease]);
      pool = [[NSAutoreleasePool alloc] init];
      berStringBase64 = [[self convertToBase64:berData] retain];
      [pool release];
   };
   return([[berStringBase64 retain] autorelease]);
}


/// Returns a C pointer to a BerValue struct populated with the object's value.
- (BerValue *) berValue
{
   BerValue      * bv;
   @synchronized(self)
   {
      if (!(attemptedValue))
      {
         berValue       = [[NSMutableData alloc] initWithCapacity:sizeof(BerValue)];
         attemptedValue = YES;
      };
      bv             = [berValue mutableBytes];
      bv->bv_len     = [berData length];
      bv->bv_val     = [berData mutableBytes];
      [[berData  retain] autorelease];
      [[berValue retain] autorelease];
   };
   return([berValue mutableBytes]);
}


/// Indicates the data is valid an NSData object.
/// @return This property always returns `YES`.
- (BOOL) isBerData
{
   return(YES);
}


/// Indicates the data is a valid image.
- (BOOL) isBerImage
{
   NSAutoreleasePool * pool;
   @synchronized(self)
   {
      if ((attemptedImage))
         return(berImage != nil);
      pool = [[NSAutoreleasePool alloc] init];
      [self berImage];
      [pool release];
      return(berImage != nil);
   };
}


/// Indicates that the data is a valid string.
- (BOOL) isBerString
{
   NSAutoreleasePool * pool;
   @synchronized(self)
   {
      if ((attemptedString))
         return(berString != nil);
      pool = [[NSAutoreleasePool alloc] init];
      [self berString];
      [pool release];
      return(berString != nil);
   };
}


/// Indicates the data can be base64 encoded.
/// @return This property always returns `YES`.
- (BOOL) isBerStringBase64
{
   return(YES);
}


/// Indicates the data can be encoded as a BerValue data type.
/// @return This property always returns `YES`.
- (BOOL) isBerValue
{
   return(YES);
}


#pragma mark - calculations

- (NSString *) convertToBase64:(NSData *)value
{
   NSUInteger        encLen;
   NSUInteger        srcLen;
   NSUInteger        pos;
   const char      * src;
   char            * enc;
   char            * buff;
   char              pad[4];
   NSString        * base64Value;

   // base64 table
   static uint8_t    b64t[64] =
   {
      'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P',
      'Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f',
      'g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v',
      'w','x','y','z','0','1','2','3','4','5','6','7','8','9','+','/'
   };

   // retrieves input information
   src    = [value bytes];
   srcLen = [value length];

   // calculates output size
   encLen  = (srcLen * 4) / 3;  // size of raw b64 encoding w/padding
   encLen += 1;                 // padding for '\0'

   // allocates memory for buffer
   if (!(enc = calloc(encLen, 1)))
      return(nil);

   // encodes data 3 bytes at a time
   buff = enc;
   for(pos = 0; (pos +3) < srcLen; pos += 3)
   {
      buff[0]  = b64t[ (src[pos]   >> 2) & 0x3f];
      buff[1]  = b64t[((src[pos]   << 4) & 0x30) | ((src[pos+1] >> 4) & 0x0f)];
      buff[2]  = b64t[((src[pos+1] << 2) & 0x3c) | ((src[pos+2] >> 6) & 0x03)];
      buff[3]  = b64t[  src[pos+2]       & 0x3f];
      buff    += 4; // jumps to next 4 bytes of output buffer
   };

   // encodes padding
   if (pos < srcLen)
   {
      // copies last three bytes of input into tmp buffer with 0 padding
      pad[0] = src[pos];
      pad[1] = ((pos+1) < srcLen) ? src[pos+1] : 0;
      pad[2] = ((pos+2) < srcLen) ? src[pos+2] : 0;

      // encodes tmp buffer
      buff[0]  = b64t[ (pad[0] >> 2) & 0x3f];
      buff[1]  = b64t[((pad[0] << 4) & 0x30) | ((pad[1] >> 4) & 0x0f)];
      buff[2]  = b64t[((pad[1] << 2) & 0x3c) | ((pad[2] >> 6) & 0x03)];
      buff[3]  = b64t[  pad[2]       & 0x3f];

      // calculates base64 padding
      if (srcLen <= (pos+1))
         buff[2] = '=';
      if (srcLen <= (pos+2))
         buff[3] = '=';
   };

   // creates NSString of base64
   base64Value = [[NSString alloc] initWithUTF8String:enc];

   // frees resources
   free(enc);

   return([base64Value autorelease]);
}

@end
