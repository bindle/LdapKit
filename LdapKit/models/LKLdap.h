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
 *  LKLdap manges connections to remote directory servers and initiates
 *  LDAP requests.
 */

#import <Foundation/Foundation.h>
#import <LdapKit/LKEnumerations.h>

@class LKMessage;

@interface LKLdap : NSObject
{
   // Server State
   LDAP                   * ld;
   NSOperationQueue       * queue;
   BOOL                     isConnected;

   // Server Information
   NSString               * ldapURI;
   LKLdapProtocolScheme     ldapProtocolScheme;
   NSString               * ldapHost;
   NSInteger                ldapPort;
   LKLdapProtocolVersion    ldapProtocolVersion;

   // Encryption Settings
   LKLdapEncryptionScheme   ldapEncryptionScheme;
   NSString               * ldapCACertificateFile;

   // Timeouts & Limits
   NSInteger                ldapSizeLimit;
   NSInteger                ldapSearchTimeout;
   NSInteger                ldapNetworkTimeout;

   // Authentication Credentials
   LKLdapBindMethod         ldapBindMethod;
   NSString               * ldapBindWho;
   NSData                 * ldapBindCredentials;
   NSString               * ldapBindCredentialsString;
   NSString               * ldapBindSaslMechanism;
   NSString               * ldapBindSaslRealm;
}


#pragma mark - Object management methods
/// @name Object Management Methods

/// Initialize a new object with default values and a private operation queue.
- (id) init;

/// Initialize a new object with default values and a shared operation queue.
/// @param queue  The queue to use when executing LDAP tasks.
- (id) initWithQueue:(NSOperationQueue *)queue;


#pragma mark - Server State
/// @name Server State

/// Returns the NSOperationQueue used to execute LDAP tasks.
@property (nonatomic, readonly) NSOperationQueue       * operationQueue;

/// Returns a Boolean value indicating whether the object is connected
/// to an LDAP server.
@property (nonatomic, readonly) BOOL                     isConnected;


#pragma mark - Server Information
/// @name Server Information

/// The URL string used to initialize an LDAP connection.
///
/// The default value is `@"ldap://localhost/"`.
///
/// @note Updating ldapURI will update the values of `ldapProtocolScheme`,
/// `ldapHost`, `ldapPort`, and `ldapEncryptionScheme`.
///
/// The following table shows the values which will be assigned to
/// `ldapProtocolScheme` and `ldapEncryptionScheme` for a given URI scheme.
///
/// URI Scheme | Protocol Scheme                                 | Encryption Scheme
/// -----------|-------------------------------------------------|---------------------------------------------------------
/// _ldap://_   | `[LKLdapProtocolSchemeLDAP](ldapProtocolScheme)`  | `[LKLdapEncryptionSchemeAttemptTLS](ldapEncryptionScheme)`
/// _ldaps://_  | `[LKLdapProtocolSchemeLDAPS](ldapProtocolScheme)` | `[LKLdapEncryptionSchemeSSL](ldapEncryptionScheme)`
/// _ldapi://_  | `[LKLdapProtocolSchemeLDAPI](ldapProtocolScheme)` | `[LKLdapEncryptionSchemeNone](ldapEncryptionScheme)`
///
/// @warning Changes to this property do not affect active LDAP connections. The
/// `-ldapRebind` method must be called before changes will take affect.
@property (nonatomic, copy)     NSString               * ldapURI;

/// The protocol scheme used to initialize an LDAP connection.
///
/// LKLdap can be used to initate connections using LDAP, LDAPS, and LDAPI. The
/// default value is `LKLdapProtocolSchemeLDAP`.
///
///
/// LKLdapProtocolScheme       | Description
/// ---------------------------|---------------------------------------
/// `LKLdapProtocolSchemeLDAP`   | Use either no validation or TLS when connecting to the directory server.
/// `LKLdapProtocolSchemeLDAPS`  | Use SSL when connecting to the directory server.
/// `LKLdapProtocolSchemeLDAPI`  | Use a UNIX domain socket when connecting to the directory server.
///
/// @warning Changes to this property do not affect active LDAP connections. The
/// `-rebind` method must be called before changes will take affect.
@property (nonatomic, assign)   LKLdapProtocolScheme     ldapProtocolScheme;

/// The host name used to initialize an LDAP connection.
///
/// The default value is `@"localhost"`.
///
/// @warning Changes to this property do not affect active LDAP connections. The
/// `-rebind` method must be called before changes will take affect.
@property (nonatomic, copy)     NSString               * ldapHost;

/// The port number used to initialize an LDAP connection.
///
/// The default value is 389.
///
/// @warning Changes to this property do not affect active LDAP connections. The
/// `-rebind` method must be called before changes will take affect.
@property (nonatomic, assign)   NSInteger                ldapPort;

/// The protocol version used to initiate an LDAP connection.
///
/// LKLdap supports LDAPv2 and LDAPv3. The default value is
/// `LKLdapProtocolVersion3`.
///
/// LKLdapProtocolVersion  | Description
/// -----------------------|---------------------------------------
/// LKLdapProtocolVersion2 | Use LDAPv2 (RFC 1777).
/// LKLdapProtocolVersion3 | Use LDAPv3 (RFC 4510).
///
/// @warning Changes to this property do not affect active LDAP connections. The
/// `-rebind` method must be called before changes will take affect.
@property (nonatomic, assign)   LKLdapProtocolVersion    ldapProtocolVersion;


#pragma mark - Encryption Settings
/// @name Encryption Settings

/// The encryption method used to communicate with the LDAP server.
///
/// LKLdap supports TLS and SSL connections. The default value is
/// `LKLdapEncryptionSchemeAttemptTLS`. The following table describes the
/// valid values for ldapEncryptionScheme:
///
/// LKLdapEncryptionScheme           | Description
/// ---------------------------------|---------------------------------------
/// LKLdapEncryptionSchemeNone       | Do not use encryption.
/// LKLdapEncryptionSchemeAttemptTLS | Attempt to use TLS, but allow unencrypted connections if TLS is unavailable.
/// LKLdapEncryptionSchemeTLS        | Require TLS when establishing a connection.
/// LKLdapEncryptionSchemeSSL        | Require SSL when establishing a connection.
///
/// @warning Changes to this property do not affect active LDAP connections. The
/// `-rebind` method must be called before changes will take affect.
@property (nonatomic, assign)   LKLdapEncryptionScheme   ldapEncryptionScheme;

/// The file name containing certificates of authorized certificate authorities.
///
/// The data contained within this file must be in PEM format. This value is only
/// used when establishing a new TLS or SSL connection. The default for Mac OS X
/// is to use the system's list of authorized certificate authorities.
/// @warning iOS does not have a default value for ldapCACertificateFile. In order
/// to use TLS or SSL on iOS, this property must be set to a file name which
/// contains valid certificates.
@property (nonatomic, copy)     NSString               * ldapCACertificateFile;

#pragma mark - Timeouts & Limits
/// @name Timeouts & Limits

/// The maximum number of entries to be returned by a search operation.
@property (nonatomic, assign)   NSInteger                ldapSearchSizeLimit;

/// The time limit (in seconds) after which a search operation should be
/// terminated by the server.
@property (nonatomic, assign)   NSInteger                ldapSearchTimeLimit;

/// The network timeout value after which a connection fails due to no activity.
///
/// Setting the value to -1 results in an infinite timeout, which is the default.
@property (nonatomic, assign)   NSInteger                ldapNetworkTimeout;


#pragma mark - Authentication Credentials
/// @name Authentication Credentials

/// The method used to bind to a directory server.
///
/// The default value is `LKLdapBindMethodAnonymous`. The following table
/// describes the valid values for ldapBindMethod:
///
/// LKLdapBindMethod            | Description
/// ----------------------------|----------------------------
/// `LKLdapBindMethodAnonymous` | Perform an anonymous bind.
/// `LKLdapBindMethodSimple`    | Perform a simple bind.
/// `LKLdapBindMethodSASL`      | Perform a SASL bind.
///
/// @note The value of ldapBindMethod is recalculated when the value of
/// `ldapBindWho`,  `ldapBindSaslMechanism`, or `ldapBindSaslRealm` is changed.
/// The following is the matrix used to determine the calculated value of
/// `ldapBindMethod` based upon the values of `ldapBindWho`,
/// `ldapBindSaslMechanism`, and `ldapBindSaslRealm`.
///
/// LKLdapBindMethod            | ldapBindWho    | ldapBindSaslMechanism | ldapBindSaslRealm
/// ----------------------------|----------------|-----------------------|---------------------------------------
/// `LKLdapBindMethodAnonymous` | `nil`          | `nil`              | `nil`
/// `LKLdapBindMethodSimple`    | not `nil`      | `nil`              | `nil`
/// `LKLdapBindMethodSASL`      | not `nil`      | not `nil`          | `nil` or not `nil`
/// `LKLdapBindMethodSASL`      | not `nil`      | `nil` or not `nil` | not `nil`
@property (nonatomic, assign)   LKLdapBindMethod         ldapBindMethod;

/// The SASL user or distinguished name used when performing an authenticated bind.
/// @note Changing the value of ldapBindWho will cause the value of
/// `ldapBindMethod` to be updated. The logic used to calculate the new value is
/// documented with `ldapBindMethod`.
@property (nonatomic, copy)     NSString               * ldapBindWho;

/// The binary credentials used when performing an authenticated bind.
@property (nonatomic, copy)     NSData                 * ldapBindCredentials;

/// The credentials used when performing an authenticated bind.
@property (nonatomic, copy)     NSString               * ldapBindCredentialsString;

/// The SASL mechanism used when performing a SASL bind.
/// @note Changing the value of ldapBindWho will cause the value of
/// `ldapBindMethod` to be updated. The logic used to calculate the new value is
/// documented with `ldapBindMethod`.
/// @warning Currently only `DIGEST-MD5` and `CRAM-MD5` are supported on iOS.
@property (nonatomic, copy)     NSString               * ldapBindSaslMechanism;

/// The SASL realm used when performing a SASL bind.
/// @note Changing the value of ldapBindWho will cause the value of
/// `ldapBindMethod` to be updated. The logic used to calculate the new value is
/// documented with `ldapBindMethod`.
@property (nonatomic, copy)     NSString               * ldapBindSaslRealm;


#pragma mark - LDAP Tasks
/// @name LDAP Tasks

/// Initiates a bind request to the remote server.
///
/// If not already connected to the remote server, this will cause a connection
/// to be established prior to submitting the bind request.
/// @return Returns the LKMessage object executing the bind request.
- (LKMessage *) ldapBind;

/// Performs an LDAP search operation on a single base DN.
/// @param base The DN of the entry at which to start the search.
/// @param scope The scope of the search and should be one of
/// `LKLdapSearchScopeBase`, `LKLdapSearchScopeOneLevel`,
/// `LKLdapSearchScopeSubTree`, or `LKLdapSearchScopeChildren`.
/// @param filter The string representation of the filter to apply in the search.
/// @param attributes An array of attribute descriptions to return from matching
/// entries.  The default is to return all attribute descriptions.
/// @param attributesOnly  The attrsonly parameter should be set to `YES` value
/// if  only  attribute  descriptions  are  wanted. It should be set to `NO`
/// if both attributes descriptions and attribute values are wanted.
/// @return Returns the LKMessage object executing the search request.
- (LKMessage *) ldapSearchBaseDN:(NSString *)base scope:(LKLdapSearchScope)scope
                filter:(NSString *)filter attributes:(NSArray *)attributes
                attributesOnly:(BOOL)attributesOnly;

/// Performs LDAP search operations on multiple base DNs.
/// @param bases An array of DNs of the entries at which to start the search.
/// @param scope The scope of the search and should be one of
/// `LKLdapSearchScopeBase`, `LKLdapSearchScopeOneLevel`,
/// `LKLdapSearchScopeSubTree`, or `LKLdapSearchScopeChildren`.
/// @param filter The string representation of the filter to apply in the search.
/// @param attributes An array of attribute descriptions to return from matching
/// entries.  The default is to return all attribute descriptions.
/// @param attributesOnly  The attrsonly parameter should be set to `YES` value
/// if  only  attribute  descriptions  are  wanted. It should be set to `NO`
/// if both attributes descriptions and attribute values are wanted.
///
/// If any one of the search operations generates an error, an error is reported
/// for the entire request.
/// @return Returns the LKMessage object executing the search request.
- (LKMessage *) ldapSearchBaseDNList:(NSArray *)bases
                scope:(LKLdapSearchScope)scope filter:(NSString *)filter
                attributes:(NSArray *)attributes
                attributesOnly:(BOOL)attributesOnly;

/// Initiates a rebind request to the remote server.
///
/// This will cause the current connection (if one exists) to be terminated
/// and a new connection to be established.
/// @return Returns the LKMessage object executing the rebind request.
- (LKMessage *) ldapRebind;

/// Initiates an unbind request to the remote server.
///
/// This will terminate the current connection (if one exists).
/// @return Returns the LKMessage object executing the unbind request.
- (LKMessage *) ldapUnbind;

@end
