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
 *  LdapKit/LKLdap.h - manges a connection to a remote directory server
 */

#import <Foundation/Foundation.h>
#import <LdapKit/LKEnumerations.h>

@class LKMessage;

@interface LKLdap : NSObject
{
   // server state
   LDAP                   * ld;
   NSLock                 * ldLock;
   NSOperationQueue       * queue;
   BOOL                     isConnected;

   // server information
   NSString               * ldapURI;
   LKLdapProtocolScheme     ldapScheme;
   NSString               * ldapHost;
   NSInteger                ldapPort;
   LKLdapProtocolVersion    ldapProtocolVersion;

   // encryption information
   LKLdapEncryptionScheme   ldapEncryptionScheme;
   NSString               * ldapCACertificateFile;

   // timeout & limit information
   NSInteger                ldapSizeLimit;
   NSInteger                ldapSearchTimeout;
   NSInteger                ldapNetworkTimeout;

   // authentication information
   LKLdapBindMethod         ldapBindMethod;
   NSString               * ldapBindWho;
   NSData                 * ldapBindCredentials;
   NSString               * ldapBindCredentialsString;
   NSString               * ldapBindSaslMechanism;
   NSString               * ldapBindSaslRealm;
}

/// @name server state
@property (nonatomic, readonly) NSOperationQueue       * queue;
@property (nonatomic, readonly) BOOL                     isConnected;

/// @name server information
@property (nonatomic, copy)     NSString               * ldapURI;
@property (nonatomic, assign)   LKLdapProtocolScheme     ldapScheme;
@property (nonatomic, copy)     NSString               * ldapHost;
@property (nonatomic, assign)   NSInteger                ldapPort;
@property (nonatomic, assign)   LKLdapProtocolVersion    ldapProtocolVersion;

/// @name encryption information
@property (nonatomic, assign)   LKLdapEncryptionScheme   ldapEncryptionScheme;
@property (nonatomic, copy)     NSString               * ldapCACertificateFile;

/// @name timeout & limit information
@property (nonatomic, assign)   NSInteger                ldapSizeLimit;
@property (nonatomic, assign)   NSInteger                ldapSearchTimeout;
@property (nonatomic, assign)   NSInteger                ldapNetworkTimeout;

/// @name authentication information
@property (nonatomic, assign)   LKLdapBindMethod         ldapBindMethod;
@property (nonatomic, copy)     NSString               * ldapBindWho;
@property (nonatomic, copy)     NSData                 * ldapBindCredentials;
@property (nonatomic, copy)     NSString               * ldapBindCredentialsString;
@property (nonatomic, copy)     NSString               * ldapBindSaslMechanism;
@property (nonatomic, copy)     NSString               * ldapBindSaslRealm;

/// @name Object Management Methods
- (id) initWithQueue:(NSOperationQueue *)queue;

/// @name LDAP operations
- (LKMessage *) bind;
- (LKMessage *) unbind;

@end
