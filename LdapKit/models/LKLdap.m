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
#import "LKLdap.h"
#import "LKLdapCategory.h"

#import "LKEntry.h"
#import "LKMessage.h"
#import "LKMessageCategory.h"
#import "LKMod.h"
#import "LKUrl.h"

@interface LKLdap ()

/// @name Manages internal state
- (void) calculateBindMethod;
- (void) calculateLdapURL;

@end


@implementation LKLdap

// server state
@synthesize ld;
@synthesize isConnected;
@synthesize operationQueue = queue;

// server information
@synthesize ldapProtocolVersion;

// encryption information
@synthesize ldapEncryptionScheme;

// timeout & limit information
@synthesize ldapSearchSizeLimit;
@synthesize ldapSearchTimeLimit;
@synthesize ldapNetworkTimeout;

// authentication information
@synthesize ldapBindMethod;


#pragma mark - Object Management Methods

- (void) dealloc
{
   // unbind from LDAP server
   if ((ld))
      ldap_unbind_ext(ld, NULL, NULL);
   ld = NULL;

   // server state
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
   queue   = [[NSOperationQueue alloc] init];
   queue.maxConcurrentOperationCount = 1;

   // server information
   self.ldapURI        = @"ldap://localhost/";
   ldapProtocolVersion = LKLdapProtocolVersion3;

   // encryption information
   ldapEncryptionScheme = LKLdapEncryptionSchemeAttemptTLS;

   // authentication information
   ldapBindMethod = LKLdapBindMethodAnonymous;

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


- (id) initWithQueue:(NSOperationQueue *)newQueue andURL:(LKUrl *)url
{
   NSAutoreleasePool * pool;

   if ((self = [self init]) == nil)
      return(self);

   pool = [[NSAutoreleasePool alloc] init];

   // retains queue
   [queue release];
   queue = [newQueue retain];

   // configures server information from LKUrl
   self.ldapURI = url.ldapConnectionUrl;

   [pool release];

   return(self);
}


- (id) initWithURL:(LKUrl *)url
{
   NSAutoreleasePool * pool;

   if ((self = [self init]) == nil)
      return(self);

   pool = [[NSAutoreleasePool alloc] init];

   // configures server information from LKUrl
   self.ldapURI = url.ldapConnectionUrl;

   [pool release];

   return(self);
}


#pragma mark - Getter/Setter methods

- (BOOL) isConnected
{
   @synchronized(self)
   {
      return(isConnected);
   }
}
- (void) setIsConnected:(BOOL)connected
{
   [self willChangeValueForKey:@"isConnected"];
   @synchronized(self)
   {
      isConnected = connected;
   }
   [self willChangeValueForKey:@"isConnected"];
   return;
}

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
      [self calculateBindMethod];
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
      [self calculateBindMethod];
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
      [self calculateBindMethod];
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


- (LKLdapProtocolScheme) ldapProtocolScheme
{
   @synchronized(self)
   {
      return(ldapProtocolScheme);
   }
}
- (void) setLdapProtocolScheme:(LKLdapProtocolScheme)scheme
{
   @synchronized(self)
   {
      if (ldapProtocolScheme == scheme)
         return;
      ldapProtocolScheme = scheme;
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
   NSAutoreleasePool      * pool;
   LDAPURLDesc            * ludp;
   NSString               * newHost;
   LKLdapProtocolScheme     newProtocol;
   LKLdapEncryptionScheme   newEncryption;

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
   {
      newProtocol   = LKLdapProtocolSchemeLDAPI;
      newEncryption = LKLdapEncryptionSchemeNone;
   }
   else if (!(strcasecmp(ludp->lud_scheme, "ldaps")))
   {
      newProtocol   = LKLdapProtocolSchemeLDAPS;
      newEncryption = LKLdapEncryptionSchemeSSL;
   }
   else
   {
      newProtocol   = LKLdapProtocolSchemeLDAP;
      newEncryption = LKLdapEncryptionSchemeAttemptTLS;
   };

   // generates new host
   newHost = [NSString stringWithUTF8String:ludp->lud_host];

   @synchronized(self)
   {
      // sets LDAP scheme
      ldapProtocolScheme   = newProtocol;
      ldapEncryptionScheme = newEncryption;

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

- (void) calculateBindMethod
{
   // verifies credentials are available
   if (!(ldapBindWho))
   {
      ldapBindMethod = LKLdapBindMethodAnonymous;
      return;
   };

   // verifies SASL information is available
   if ( ((ldapBindSaslMechanism)) || ((ldapBindSaslRealm)) )
   {
      ldapBindMethod = LKLdapBindMethodSASL;
      return;
   };

   // assume simple bind
   ldapBindMethod = LKLdapBindMethodSimple;

   return;
}


- (void) calculateLdapURL
{
   NSString * scheme;

   // determines string representation of scheme
   switch(ldapProtocolScheme)
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


#pragma mark - LDAP operations

- (LKMessage *) ldapBind
{
   LKMessage * message;
   @synchronized(self)
   {
      message = [[LKMessage alloc] initBindWithSession:self];
      message.queuePriority = NSOperationQueuePriorityHigh;
      [queue addOperation:message];
      return([message autorelease]);
   };
}


#warning "-ldapDeleteDN: has not been properly tested."
- (LKMessage *) ldapDeleteDN:(NSString *)dn
{
   LKMessage * message;
   NSAssert((dn != nil), @"dn must not be nil");
   @synchronized(self)
   {
      message = [[LKMessage alloc] initDeleteWithSession:self dn:dn];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


#warning "-ldapDeleteEntry: has not been properly tested."
- (LKMessage *) ldapDeleteEntry:(LKEntry *)entry
{
   LKMessage * message;
   NSAssert((entry != nil), @"entry must not be nil");
   @synchronized(self)
   {
      message = [[LKMessage alloc] initDeleteWithSession:self dn:entry.dn];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


#warning "-ldapModifyDN:modification: has not been properly tested."
- (LKMessage *) ldapModifyDN:(NSString *)dn modification:(LKMod *)mod
{
   LKMessage * message;
   NSArray   * mods;
   NSAssert((dn != nil), @"dn must not be nil");
   NSAssert((mod != nil), @"mod must not be nil");
   @synchronized(self)
   {
      mods = [[NSArray alloc] initWithObjects:mod, nil];
      message = [[LKMessage alloc] initModifyWithSession:self dn:dn mods:mods];
      [mods release];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


- (LKMessage *) ldapModifyDN:(NSString *)dn modifications:(NSArray *)mods
{
   LKMessage  * message;
   NSUInteger   pos;
   NSAssert((dn != nil), @"dn must not be nil");
   NSAssert((mods != nil), @"mods must not be nil");
   for(pos = 0; pos < [mods count]; pos++)
      NSAssert( ( (([[mods objectAtIndex:pos] isKindOfClass:[LKMod class]])) ||
                  (([[mods objectAtIndex:pos] isKindOfClass:[NSString class]])) ||
                  (([[mods objectAtIndex:pos] isKindOfClass:[NSData class]])) ),
         @"mods array must contain only NSData, NSString, or LKMod objects");
   @synchronized(self)
   {
      message = [[LKMessage alloc] initModifyWithSession:self dn:dn mods:mods];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


- (LKMessage *) ldapSearchBaseDN:(NSString *)dn scope:(LKLdapSearchScope)scope
                filter:(NSString *)filter attributes:(NSArray *)attributes
                attributesOnly:(BOOL)attributesOnly
{
   LKMessage  * message;
   NSUInteger   pos;
   NSAssert((dn != nil),         @"dn must not be nil");
   NSAssert((filter != nil),     @"filter must not be nil");
   if ((attributes))
   {
      for(pos = 0; pos < [attributes count]; pos++)
         NSAssert([[attributes objectAtIndex:pos] isKindOfClass:[NSString class]],
            @"attributes must only contain NSString objects");
   };
   @synchronized(self)
   {
      message = [[LKMessage alloc] initSearchWithSession:self baseDN:dn
                  scope:scope filter:filter attributes:attributes
                  attributesOnly:attributesOnly];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


- (LKMessage *) ldapSearchBaseDNList:(NSArray *)dnList
                scope:(LKLdapSearchScope)scope filter:(NSString *)filter
                attributes:(NSArray *)attributes
                attributesOnly:(BOOL)attributesOnly
{
   LKMessage  * message;
   NSUInteger   pos;
   NSAssert((dnList != nil), @"dnList must not be nil");
   NSAssert((filter != nil), @"filter must not be nil");
   for(pos = 0; pos < [dnList count]; pos++)
      NSAssert([[dnList objectAtIndex:pos] isKindOfClass:[NSString class]],
         @"attributes must only contain NSString objects");
   if ((attributes))
   {
      for(pos = 0; pos < [attributes count]; pos++)
         NSAssert([[attributes objectAtIndex:pos] isKindOfClass:[NSString class]],
            @"attributes must only contain NSString objects");
   };
   @synchronized(self)
   {
      message = [[LKMessage alloc] initSearchWithSession:self baseDnList:dnList
                  scope:scope filter:filter attributes:attributes
                  attributesOnly:attributesOnly];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


- (LKMessage *) ldapSearchUrl:(LKUrl *)url attributesOnly:(BOOL)attributesOnly
{
   LKMessage * message;
   NSAssert((url != nil), @"url must not be nil");
   @synchronized(self)
   {
      message = [[LKMessage alloc] initSearchWithSession:self baseDN:url.ldapDn
                  scope:url.ldapScope filter:url.ldapFilter attributes:url.ldapAttributes
                  attributesOnly:attributesOnly];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


#warning "-ldapRenameDN:newRDN:newSuperior:deleteOldRDN: has not been properly tested."
- (LKMessage *) ldapRenameDN:(NSString *)dn newRDN:(NSString *)newrdn
        newSuperior:(NSString *)newSuperior
        deleteOldRDN:(NSInteger)deleteOldRDN
{
   LKMessage * message;
   NSAssert((dn != nil), @"dn must not be nil");
   NSAssert((newrdn != nil), @"newrdn must not be nil");
   @synchronized(self)
   {
      message = [[LKMessage alloc] initRenameWithSession:self dn:dn
         newRDN:newrdn newSuperior:newSuperior deleteOldRDN:deleteOldRDN];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


- (LKMessage *) ldapRebind
{
   LKMessage * message;
   @synchronized(self)
   {
      message = [[LKMessage alloc] initRebindWithSession:self];
      [queue addOperation:message];
      return([message autorelease]);
   };
}


- (LKMessage *) ldapUnbind
{
   LKMessage * message;
   @synchronized(self)
   {
      message = [[LKMessage alloc] initUnbindWithSession:self];
      [queue addOperation:message];
      return([message autorelease]);
   };
}

@end
