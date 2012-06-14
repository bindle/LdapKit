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
 *  LdapKit/LKMessage.h returns results from LDAP operations.
 */

#import <Foundation/Foundation.h>
#import <LdapKit/LKEnumerations.h>


#pragma mark LDAP message type
enum ldap_kit_ldap_message_type
{
   LKLdapMessageTypeConnect           = 0x01,
   LKLdapMessageTypeUnbind            = 0x02,
   LKLdapMessageTypeSearch            = 0x03,
   LKLdapMessageTypeUnknown           = 0x00
};
typedef enum ldap_kit_ldap_message_type LKLdapMessageType;


@class LKError;
@class LKLdap;


@interface LKMessage : NSOperation
{
   // state information
   LKLdap                 * ldap;
   LKError                * error;
   LKLdapMessageType        messageType;

   // server information
   NSString               * ldapURI;
   LKLdapProtocolScheme     ldapScheme;
   LKLdapProtocolVersion    ldapProtocolVersion;

   // encryption information
   LKLdapEncryptionScheme   ldapEncryptionScheme;
   NSString               * ldapCACertificateFile;

   // timeout information
   NSInteger                ldapSizeLimit;
   NSInteger                ldapSearchTimeout;
   NSInteger                ldapNetworkTimeout;

   // authentication information
   LKLdapBindMethod         ldapBindMethod;
   NSString               * ldapBindWho;
   NSData                 * ldapBindCredentials;
   NSString               * ldapBindSaslMechanism;
   NSString               * ldapBindSaslRealm;

   // client information
   NSInteger                tag;
   id                       object;
}

/// @name state information
@property (nonatomic, readonly) LKError                * error;
@property (nonatomic, readonly) LKLdapMessageType        messageType;

/// @name client information
@property (nonatomic, assign)   NSInteger                tag;
@property (nonatomic, retain)   id                       object;

/// @name Object Management Methods
- (id) initLdapInitialzieWithSession:(LKLdap *)session;

@end
