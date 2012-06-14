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
 *  LdapKit/LKEntry.m  contains LDAP entry information
 */
#import "LKEntry.h"

@implementation LKEntry

// entry information
@synthesize dn;


#pragma mark - Object Management Methods

- (void) dealloc
{
   // entry information
   [dn     release];
   [entry  release];

   // derived data
   [attributes release];

   [super dealloc];

   return;
}


- (id) initWithDn:(const char *)entryDN
{
   if ((self = [super init]) == nil)
      return(self);

   dn = [[NSString alloc] initWithUTF8String:entryDN];

   return(self);
}


#pragma mark - Getter/Setter methods

- (NSArray *) attributes
{
   @synchronized(self)
   {
      if (!(attributes))
         attributes = [entry allKeys];
      return([[attributes retain] autorelease]);
   };
};


#pragma mark - queries

- (NSArray *) valuesForAttribute:(NSString *)attribute
{
   @synchronized(self)
   {
      return([[[entry objectForKey:attribute] retain] autorelease]);
   };
}


- (void) setValues:(NSArray *)values forKey:(NSString *)attribute
{
   @synchronized(self)
   {
      [attributes release];
      attributes = nil;
      [entry setValue:[NSArray arrayWithArray:values] forKey:attribute];
   };
   return;
}



@end
