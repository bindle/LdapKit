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
 *  LdapKit/LKUrl.m convenience class for LDAP URLs.
 */
#import "LKUrl.h"

@implementation LKUrl

#pragma mark - Object Management Methods

- (id) copyWithZone:(NSZone *)zone
{
   return([[LKUrl allocWithZone:zone] initWithURI:ludUrl]);
}


- (void) dealloc
{
   // URL
   [ludUrl           release];
   [ludConnectionUrl release];

   // URL componets
   [ludHost    release];
   [ludDn      release];
   [ludAttrs   release];
   [ludFilter  release];
   [ludExts    release];

   [super dealloc];

   return;
}


- (id) init
{
   return([self initWithURI:@"ldap://localhost/"]);
}


- (id) initWithURI:(NSString *)uri
{
   NSAutoreleasePool * pool;

   if ((self = [super init]) == nil)
      return(self);

   pool = [[NSAutoreleasePool alloc] init];

   self.ldapUrl = uri;

   [pool release];

   return(self);
}


+ (id) urlWithURI:(NSString *)uri
{
   return([[[LKUrl alloc] initWithURI:uri] autorelease]);
}


+ (BOOL) testLdapURI:(NSString *)uri
{
   LDAPURLDesc       * lud;
   NSAutoreleasePool * pool;

   pool = [[NSAutoreleasePool alloc] init];

   if ((ldap_url_parse([uri UTF8String], &lud)))
   {
      [pool release];
      return(NO);
   };

   ldap_free_urldesc(lud);

   [pool release];

   return(YES);
}


#pragma mark - Getter/Setter methods

- (NSArray *) ldapAttributes
{
   @synchronized(self)
   {
      return([[ludAttrs retain] autorelease]);
   };
}
- (void) setLdapAttributes:(NSArray *)ldapAttributes
{
   NSUInteger pos;
   if ((ldapAttributes))
      for(pos = 0; pos < [ldapAttributes count]; pos++)
         NSAssert([[ldapAttributes objectAtIndex:pos] isKindOfClass:[NSString class]],
            @"ldapAttributes must only contain NSString objects.");
   @synchronized(self)
   {
      [ludUrl   release];
      [ludAttrs release];
      ludUrl   = nil;
      ludAttrs = nil;
      if ((ldapAttributes))
         ludAttrs = [[NSArray alloc] initWithArray:ldapAttributes copyItems:YES];
   };
   return;
}


- (NSString *) ldapConnectionUrl
{
   NSString * tmpScheme;
   @synchronized(self)
   {
      if ((ludConnectionUrl))
         return([[ludConnectionUrl retain] autorelease]);
      switch(ludScheme)
      {
         case LKLdapProtocolSchemeLDAPI:
         tmpScheme = @"ldapi";
         break;

         case LKLdapProtocolSchemeLDAPS:
         tmpScheme = @"ldaps";
         break;

         default:
         tmpScheme = @"ldap";
         break;
      };
      ludConnectionUrl = [[NSString alloc] initWithFormat:@"%@://%@:%i",
                           tmpScheme, ludHost, ludPort];
      return([[ludConnectionUrl retain] autorelease]);
   };
}


- (BOOL) ldapCriticalExtensions
{
   return(ludCritExts);
}
- (void) setLdapCriticalExtensions:(BOOL)ldapCriticalExtensions
{
   if (ldapCriticalExtensions == ludCritExts)
      return;

   @synchronized(self)
   {
      [ludUrl release];
      ludUrl      = nil;
      ludCritExts = ldapCriticalExtensions;
   };

   return;
}


- (NSString *) ldapDn
{
   @synchronized(self)
   {
      return([[ludDn retain] autorelease]);
   };
}
- (void) setLdapDn:(NSString *)ldapDn
{
   if (!(ldapDn))
      ldapDn = @"";
   if ( ((ldapDn)) && ((ludDn)) )
      if ([ldapDn localizedCaseInsensitiveCompare:ludDn] == NSOrderedSame)
         return;
   @synchronized(self)
   {
      [ludUrl release];
      [ludDn  release];
      ludUrl = nil;
      ludDn  = nil;
      if ((ldapDn))
         ludDn = [[NSString alloc] initWithString:ldapDn];
   };
   return;
}


- (NSArray *) ldapExtensions
{
   @synchronized(self)
   {
      return([[ludExts retain] autorelease]);
   };
}
- (void) setLdapExtensions:(NSArray *)ldapExtensions
{
   NSUInteger pos;
   if ((ldapExtensions))
      for(pos = 0; pos < [ldapExtensions count]; pos++)
         NSAssert([[ldapExtensions objectAtIndex:pos] isKindOfClass:[NSString class]],
            @"ldapExtensions must only contain NSString objects.");
   @synchronized(self)
   {
      [ludUrl  release];
      [ludExts release];
      ludUrl  = nil;
      ludExts = nil;
      if ((ldapExtensions))
         ludExts = [[NSArray alloc] initWithArray:ldapExtensions copyItems:YES];
   };
   return;
}


- (NSString *) ldapFilter
{
   @synchronized(self)
   {
      return([[ludFilter retain] autorelease]);
   };
}
- (void) setLdapFilter:(NSString *)ldapFilter
{
   if (!(ldapFilter))
      ldapFilter = @"(objectclass=*)";
   if ( ((ldapFilter)) && ((ludFilter)) )
      if ([ldapFilter localizedCaseInsensitiveCompare:ludFilter] == NSOrderedSame)
         return;
   @synchronized(self)
   {
      [ludUrl    release];
      [ludFilter release];
      ludUrl    = nil;
      ludFilter = nil;
      if ((ldapFilter))
         ludFilter = [[NSString alloc] initWithString:ldapFilter];
   };
   return;
}


- (NSString *) ldapHost
{
   @synchronized(self)
   {
      return([[ludHost retain] autorelease]);
   };
}
- (void) setLdapHost:(NSString *)ldapHost
{
   if (!(ldapHost))
      ldapHost = @"localhost";
   if ( ((ldapHost)) && ((ludHost)) )
      if ([ldapHost localizedCaseInsensitiveCompare:ludHost] == NSOrderedSame)
         return;
   @synchronized(self)
   {
      [ludUrl  release];
      [ludHost release];
      ludUrl  = nil;
      ludHost = nil;
      if ((ldapHost))
         ludHost = [[NSString alloc] initWithString:ldapHost];
   };
   return;
}


- (NSInteger) ldapPort
{
   return(ludPort);
}
- (void) setLdapPort:(NSInteger)ldapPort
{
   if ((!(ldapPort)) && (ludScheme == LKLdapProtocolSchemeLDAPS))
      ldapPort = 636;
   else if (!(ldapPort))
      ldapPort = 389;

   if (ldapPort == ludPort)
      return;

   @synchronized(self)
   {
      [ludUrl           release];
      [ludConnectionUrl release];
      ludUrl           = nil;
      ludConnectionUrl = nil;
      ludPort          = ldapPort;
   };

   return;
}


- (LKLdapProtocolScheme) ldapScheme
{
   return(ludScheme);
}
- (void) setLdapScheme:(LKLdapProtocolScheme)ldapScheme
{
   if (ldapScheme == ludScheme)
      return;

   @synchronized(self)
   {
      [ludUrl release];
      ludUrl   = nil;
      ludScheme = ldapScheme;
   };

   return;
}


- (LKLdapSearchScope) ldapScope
{
   return(ludScope);
}
- (void) setLdapScope:(LKLdapSearchScope)ldapScope
{
   if (ldapScope == ludScope)
      return;

   @synchronized(self)
   {
      [ludUrl release];
      ludUrl   = nil;
      ludScope = ldapScope;
   };

   return;
}


- (NSString *) ldapUrl
{
   NSUInteger          pos;
   NSString          * tmpScheme;
   NSString          * tmpDn;
   NSString          * tmpAttrs;
   NSString          * tmpScope;
   NSString          * tmpFilter;
   NSString          * tmpExts;
   NSAutoreleasePool * pool;

   @synchronized(self)
   {
      if ((ludUrl))
         return([[ludUrl retain] autorelease]);

      pool = [[NSAutoreleasePool alloc] init];

      switch(ludScheme)
      {
         case LKLdapProtocolSchemeLDAPI:
         tmpScheme = @"ldapi";
         break;

         case LKLdapProtocolSchemeLDAPS:
         tmpScheme = @"ldaps";
         break;

         default:
         tmpScheme = @"ldap";
         break;
      };
      tmpDn = ((ludDn)) ? ludDn : @"";
      tmpAttrs = ([ludAttrs count] > 0) ? [ludAttrs objectAtIndex:0] : @"";
      for(pos = 0; pos < [ludAttrs count]; pos++)
         tmpAttrs = [NSString stringWithFormat:@"%@,%@", tmpAttrs, [ludAttrs objectAtIndex:pos]];
      switch(ludScope)
      {
         case LKLdapSearchScopeOneLevel:
         tmpScope = @"one";
         break;

         case LKLdapSearchScopeChildren:
         tmpScope = @"children";
         break;

         case LKLdapSearchScopeSubTree:
         tmpScope = @"sub";
         break;

         default:
         tmpScope = @"base";
         break;
      };
      tmpFilter = ((ludFilter)) ? ludFilter : @"";
      tmpExts = ([ludExts count] > 0) ? [ludExts objectAtIndex:0] : @"";
      for(pos = 0; pos < [ludExts count]; pos++)
         tmpExts = [NSString stringWithFormat:@"%@,%@", tmpExts, [ludExts objectAtIndex:pos]];

      ludUrl = [[NSString alloc] initWithFormat:@"%@://%@:%i/%@?%@?%@?%@?%@",
         tmpScheme,
         ludHost,
         ludPort,
         tmpDn,
         tmpAttrs,
         tmpScope,
         tmpFilter,
         tmpExts];

      [pool release];

      return([[ludUrl retain] autorelease]);
   };
}
- (void) setLdapUrl:(NSString *)ldapUrl
{
   NSUInteger          count;
   NSUInteger          pos;
   NSMutableArray    * list;
   LDAPURLDesc       * lud;
   NSAutoreleasePool * pool;

   [ludUrl           release];
   [ludConnectionUrl release];
   ludUrl           = nil;
   ludConnectionUrl = nil;

   pool = [[NSAutoreleasePool alloc] init];

   if ((ldap_url_parse([ldapUrl UTF8String], &lud)))
   {
      [pool release];
      return;
   };

   @synchronized(self)
   {
      // URL componets
      self.ldapScheme = LKLdapProtocolSchemeLDAP;
      if ((lud->lud_scheme))
      {
         if (!(strcasecmp(lud->lud_scheme, "ldapi")))
            self.ldapScheme = LKLdapProtocolSchemeLDAPI;
         else if (!(strcasecmp(lud->lud_scheme, "ldaps")))
            self.ldapScheme = LKLdapProtocolSchemeLDAPS;
      };
      if ((lud->lud_host))
         self.ldapHost   = [NSString stringWithUTF8String:lud->lud_host];
      self.ldapPort      = lud->lud_port;
      if ((lud->lud_dn))
         self.ldapDn     = [NSString stringWithUTF8String:lud->lud_dn];
      if ((lud->lud_attrs))
      {
         for(count = 0; lud->lud_attrs[count]; count++);
         list = [NSMutableArray arrayWithCapacity:count];
         for(pos = 0; pos < count; pos++)
            [list addObject:[NSString stringWithUTF8String:lud->lud_attrs[pos]]];
         self.ldapAttributes = list;
      };
      self.ldapScope     = lud->lud_scope;
      if ((lud->lud_filter))
         self.ldapFilter = [NSString stringWithUTF8String:lud->lud_filter];;
      if ((lud->lud_exts))
      {
         for(count = 0; lud->lud_exts[count]; count++);
         list = [NSMutableArray arrayWithCapacity:count];
         for(pos = 0; pos < count; pos++)
            [list addObject:[NSString stringWithUTF8String:lud->lud_exts[pos]]];
         self.ldapExtensions = list;
      };
      self.ldapCriticalExtensions  = (lud->lud_crit_exts != 0);

      // URL
      ludUrl           = [[NSString alloc] initWithString:ldapUrl];
      ludConnectionUrl = [[NSString alloc] initWithFormat:@"%s://%s:%i/",
                         lud->lud_scheme, lud->lud_host, lud->lud_port];
   };

   ldap_free_urldesc(lud);

   [pool release];

   return;
}

@end
