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
 *  LKSession/LKSession.m - manges a connection to a remote directory server
 */
#import "LKSession.h"


@implementation LKSession

// server state
@synthesize isConnected;
@synthesize queue;
@synthesize configHash;

// server information
@synthesize ldapURI;
@synthesize ldapScheme;
@synthesize ldapHost;
@synthesize ldapPort;
@synthesize ldapProtocolVersion;

// encryption information
@synthesize ldapEncryptionScheme;
@synthesize ldapCACertificateFile;

// timeout information
@synthesize ldapSearchTimeout;
@synthesize ldapNetworkTimeout;

// authentication information
@synthesize ldapBindMethod;
@synthesize ldapBindWho;
@synthesize ldapBindCredentials;
@synthesize ldapBindCredentialsString;
@synthesize ldapBindSaslMechanism;
@synthesize ldapBindSaslRealm;


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
   [configHash release];

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

   return(self);
}


#pragma mark - Getter/Setter methods


#pragma mark - Manages internal state


@end
