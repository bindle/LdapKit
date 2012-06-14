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
 *  LdapKit/LKLdap.m - manges a connection to a remote directory server
 */
#import "LKLdapCategory.h"


@interface LKLdap ()

/// @name Manages internal state
- (void) calculateLdapURL;

@end


@implementation LKLdap

// server state
@synthesize ld;
@synthesize isConnected;
@synthesize ldLock;
@synthesize queue;

// server information
@synthesize ldapProtocolVersion;

// encryption information
@synthesize ldapEncryptionScheme;

// timeout & limit information
@synthesize ldapSizeLimit;
@synthesize ldapSearchTimeout;
@synthesize ldapNetworkTimeout;

// authentication information
@synthesize ldapBindMethod;


#pragma mark - Object Management Methods

- (void) dealloc
{
   // unbind from LDAP server
   [ldLock lock];
   if ((ld))
      ldap_unbind_ext(ld, NULL, NULL);
   ld = NULL;
   [ldLock unlock];

   // server state
   [ldLock     release];
   [queue      release];

   // server information
   [ldapURI  release];
   [ldapHost release];

   // encryption information
   [ldapCACertificateFile release];

   // authentication information
   [ldapBindWho               release];
   [ldapBindCredentials       release];
   [ldapBindCredentialsString release];
   [ldapBindSaslMechanism     release];
   [ldapBindSaslRealm         release];

   [super dealloc];

   return;
}


- (id) init
{
   // initialize super
   if ((self = [super init]) == nil)
      return(self);

   // server state
   ldLock  = [[NSLock alloc] init];
   queue   = [[NSOperationQueue alloc] init];

   return(self);
}


- (id) initWithQueue:(NSOperationQueue *)newQueue
{
   if ((self = [self init]) == nil)
      return(self);

   // retains queue
   [queue release];
   queue = [newQueue retain];

   return(self);
}


#pragma mark - Getter/Setter methods

- (NSString *) ldapBindWho
{
   @synchronized(self)
   {
      return([[ldapBindWho retain] autorelease]);
   }
}
- (void) setLdapBindWho:(NSString *)aString
{
   @synchronized(self)
   {
      [ldapBindWho release];
      ldapBindWho = nil;
      if ((aString))
         ldapBindWho = [[NSString alloc] initWithString:aString];
   }
   return;
}


- (NSString *) ldapCACertificateFile
{
   @synchronized(self)
   {
      return([[ldapCACertificateFile retain] autorelease]);
   }
}
- (void) setLdapCACertificateFile:(NSString *)aString
{
   @synchronized(self)
   {
      [ldapCACertificateFile release];
      ldapCACertificateFile = nil;
      if ((aString))
         ldapCACertificateFile = [[NSString alloc] initWithString:aString];
   }
   return;
}


- (NSData *) ldapBindCredentials
{
   @synchronized(self)
   {
      return([[ldapBindCredentials retain] autorelease]);
   }
}
- (void) setLdapBindCredentials:(NSData *)data
{
   @synchronized(self)
   {
      [ldapBindCredentials       release];
      [ldapBindCredentialsString release];
      ldapBindCredentials       = nil;
      ldapBindCredentialsString = nil;
      if ((data))
         ldapBindCredentials = [[NSData alloc] initWithData:data];
   }
   return;
}


- (NSString *) ldapBindCredentialsString
{
   @synchronized(self)
   {
      return([[ldapBindWho retain] autorelease]);
   }
}
- (void) setLdapBindCredentialsString:(NSString *)aString
{
   NSAutoreleasePool * pool;

   pool = [[NSAutoreleasePool alloc] init];

   @synchronized(self)
   {
      [ldapBindCredentialsString release];
      [ldapBindCredentials       release];
      ldapBindCredentialsString = nil;
      ldapBindCredentials       = nil;
      if ((aString))
      {
         ldapBindCredentialsString = [[NSString alloc] initWithString:aString];
         ldapBindCredentials = [[aString dataUsingEncoding:NSUTF8StringEncoding] retain];
      };
   }

   [pool release];

   return;
}


- (NSString *) ldapBindSaslMechanism
{
   @synchronized(self)
   {
      return([[ldapBindSaslMechanism retain] autorelease]);
   }
}
- (void) setLdapBindSaslMechanism:(NSString *)aString
{
   @synchronized(self)
   {
      [ldapBindSaslMechanism release];
      ldapBindSaslMechanism = nil;
      if ((aString))
         ldapBindSaslMechanism= [[NSString alloc] initWithString:aString];
   }
   return;
}


- (NSString *) ldapBindSaslRealm
{
   @synchronized(self)
   {
      return([[ldapBindSaslRealm retain] autorelease]);
   }
}
- (void) setLdapBindSaslRealm:(NSString *)aString
{
   @synchronized(self)
   {
      [ldapBindSaslRealm release];
      ldapBindSaslRealm = nil;
      if ((aString))
         ldapBindSaslRealm = [[NSString alloc] initWithString:aString];
   }
   return;
}


- (NSString *) ldapHost
{
   @synchronized(self)
   {
      return([[ldapHost retain] autorelease]);
   }
}
- (void) setLdapHost:(NSString *)aString
{
   NSAssert((aString != nil), @"LDAP Host cannot be nil");
   @synchronized(self)
   {
      if ([aString localizedCaseInsensitiveCompare:ldapHost] == NSOrderedSame)
         return;
      [ldapHost release];
      ldapHost = [[NSString alloc] initWithString:aString];
      [self calculateLdapURL];
   }
   return;
}


- (NSInteger) ldapPort
{
   @synchronized(self)
   {
      return(ldapPort);
   }
}
- (void) setLdapPort:(NSInteger)port
{
   NSAssert((port > 0), @"LDAP Port must be greater than zero");
   @synchronized(self)
   {
      if (ldapPort == port)
         return;
      ldapPort = port;
      [self calculateLdapURL];
   }
   return;
}


- (LKLdapProtocolScheme) ldapScheme
{
   @synchronized(self)
   {
      return(ldapScheme);
   }
}
- (void) setLdapScheme:(LKLdapProtocolScheme)scheme
{
   @synchronized(self)
   {
      if (ldapScheme == scheme)
         return;
      ldapScheme = scheme;
      [self calculateLdapURL];
   }
   return;
}


- (NSString *) ldapURI
{
   @synchronized(self)
   {
      return([[ldapURI retain] autorelease]);
   }
}
- (void) setLdapURI:(NSString *)uri
{
   NSAutoreleasePool    * pool;
   LDAPURLDesc          * ludp;
   NSString             * newHost;
   LKLdapProtocolScheme   newScheme;

   pool = [[NSAutoreleasePool alloc] init];

   // applies default if URI is nil
   if (uri == nil)
      uri = @"ldap://localhost:389/";

   // determines if "uri" is a valid LDAP URL
   if ((ldap_url_parse([uri UTF8String], &ludp)))
   {
      NSLog(@"Invalid LDAP URL: %@", uri);
      [pool release];
      return;
   };

   // determines new scheme
   if (!(strcasecmp(ludp->lud_scheme, "ldapi")))
      newScheme = LKLdapProtocolSchemeLDAPI;
   else if (!(strcasecmp(ludp->lud_scheme, "ldaps")))
      newScheme = LKLdapProtocolSchemeLDAPS;
   else
      newScheme = LKLdapProtocolSchemeLDAP;

   // generates new host
   newHost = [NSString stringWithUTF8String:ludp->lud_host];

   @synchronized(self)
   {
      // sets LDAP scheme
      ldapScheme = newScheme;

      // sets LDAP hostname
      [ldapHost release];
      ldapHost = [newHost retain];

      // sets LDAP port number
      ldapPort = ludp->lud_port;

      // calculates LDAP URL from parts
      [self calculateLdapURL];
   }

   ldap_free_urldesc(ludp);

   [pool release];

   return;
}


#pragma mark - Manages internal state

- (void) calculateLdapURL
{
   NSString * scheme;

   // determines string representation of scheme
   switch(ldapScheme)
   {
      case LKLdapProtocolSchemeLDAPI:
      scheme = @"ldapi";
      break;

      case LKLdapProtocolSchemeLDAPS:
      scheme = @"ldaps";
      break;

      default:
      scheme = @"ldap";
      break;
   };

   [ldapURI release];
   ldapURI = [[NSString alloc] initWithFormat:@"%@://%@:%i", scheme, ldapHost, ldapPort];

   return;
}

@end
