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
 *  LKMessage executes LDAP requests and returns the results.
 *
 *  KVO-Compliant Properties
 *  ------------------------
 *
 *  The LKMessage class is key-value coding (KVC) and key-value observing (KVO)
 *  compliant for several of its properties in addition to the key-value coding
 *  (KVC) and key-value observing (KVO) compliant properties of the
 *  `NSOperation` class. As needed, you can observe these properties to control
 *  other parts of your application. The properties you can observe include the
 *  following:
 *
 *  * `entries` - read-only property
 *  * `referrals` - read-only property
 *  * `matchedDNs` - read-only property
 *
 *  Read the documentation for the `NSOperation` class for information on
 *  implementing observers in multi-threaded applications.
 */

#import <Foundation/Foundation.h>
#import <LdapKit/LKEnumerations.h>


#pragma mark LDAP message type
enum ldap_kit_ldap_message_type
{
   LKLdapMessageTypeBind              = 0x01,
   LKLdapMessageTypeUnbind            = 0x02,
   LKLdapMessageTypeSearch            = 0x03,
   LKLdapMessageTypeRebind            = 0x04,
   LKLdapMessageTypeDelete            = 0x05,
   LKLdapMessageTypeRename            = 0x06,
   LKLdapMessageTypeModify            = 0x07,
   LKLdapMessageTypeWhoAmI            = 0x08,
   LKLdapMessageTypeUnknown           = 0x00
};
typedef enum ldap_kit_ldap_message_type LKLdapMessageType;


@class LKLdap;


@interface LKMessage : NSOperation
{
   // state information
   LKLdap                 * session;
   LKLdapMessageType        messageType;

   // error information
   NSInteger                errorCode;
   NSString               * errorTitle;
   NSString               * errorMessage;
   NSString               * diagnosticMessage;

   // server information
   NSString               * ldapURI;
   LKLdapProtocolScheme     ldapProtocolScheme;
   LKLdapProtocolVersion    ldapProtocolVersion;

   // encryption information
   LKLdapEncryptionScheme   ldapEncryptionScheme;
   NSString               * ldapCACertificateFile;

   // timeout information
   NSInteger                ldapSearchSizeLimit;
   NSInteger                ldapSearchTimeLimit;
   NSInteger                ldapNetworkTimeout;

   // authentication information
   LKLdapBindMethod         ldapBindMethod;
   NSString               * ldapBindWho;
   NSData                 * ldapBindCredentials;
   NSString               * ldapBindSaslMechanism;
   NSString               * ldapBindSaslRealm;

   // search information
   NSArray                * searchDnList;
   NSString               * searchFilter;
   NSArray                * searchAttributes;
   BOOL                     searchAttributesOnly;
   LKLdapSearchScope        searchScope;

   // modify information
   NSString               * modifyDn;
   NSString               * modifyNewRdn;
   NSString               * modifyNewSuperior;
   NSInteger                modifyDeleteOldRdn;
   NSArray                * modifyList;

   // results
   NSMutableArray         * referrals;
   NSMutableArray         * entries;
   NSMutableArray         * matchedDNs;

   // client information
   NSInteger                tag;
   id <NSObject>            object;
}

#pragma mark - Message information
/// @name Message information

/// The type of request the message was initialized to process.
///
/// Valid values:
///
/// LKLdapMessageType         | Description
/// --------------------------|-------------------------
/// `LKLdapMessageTypeBind`   | LDAP bind request
/// `LKLdapMessageTypeDelete` | LDAP delete request
/// `LKLdapMessageTypeModify` | LDAP modify request
/// `LKLdapMessageTypeRename` | LDAP rename request
/// `LKLdapMessageTypeRebind` | LDAP unbind and bind request
/// `LKLdapMessageTypeSearch` | LDAP search request
/// `LKLdapMessageTypeUnbind` | LDAP unbind request
/// `LKLdapMessageTypeWhoAmI` | LDAP whoami request
@property (nonatomic, readonly) LKLdapMessageType messageType;


#pragma mark - Errors
/// @name Errors

/// The numeric value of the error.
///
/// See the man page for ldap_error(3) for descriptions of valid error
/// codes.
@property (atomic, readonly) NSInteger errorCode;

/// An optional title of the error for use when reporting error to users.
@property (nonatomic, readonly) NSString * errorTitle;

/// A human readable error message.
@property (nonatomic, readonly) NSString * errorMessage;

/// Additional diagnostic information if available.
@property (nonatomic, readonly) NSString * diagnosticMessage;

/// Determines if the error code indicates whether the task succeeded or failed.
@property (nonatomic, readonly) BOOL isSuccessful;


#pragma mark - Results
/// @name Results

/// An array of LKEntry objects returned by a search request.
@property (nonatomic, readonly) NSArray * entries;

/// An array of LDAP referrals returned by an LDAP request.
@property (nonatomic, readonly) NSArray * referrals;

@property (nonatomic, readonly) NSArray * matchedDNs;


#pragma mark - Identifying the LKMessage
/// @name Identifying the LKMessage

/// An integer that you can use to identify messages in your application.
@property (nonatomic, assign) NSInteger tag;

/// An object reference you can use to associate data with messages in your
/// application.
@property (nonatomic, retain) id <NSObject> object;

@end
