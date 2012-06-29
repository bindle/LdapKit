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
 *  LKUrl is a convience class for parsing an LDAP URL into its componets.
 *
 *  LDAP URLs have the following format:
 *
 *  > `ldap://hostport/dn[?attrs[?scope[?filter[?exts]]]]`
 *
 *  Where:
 *
 *  * `hostport` is a host name with an optional ":portnumber".
 *  * `dn` is the search base DN.
 *  * `attrs` is a comma separated list of attributes to request.
 *  * `scope` is the scope of the request ("one", "sub", or "base").
 *  * `filter` is the search filter of the request.
 *  * `exts` is recognized set of LDAP and/or API extensions.
 *
 *  Example:
 *  > `ldap://ldap.example.net/dc=example,dc=net?cn,sn?sub?(cn=*)`
 *
 *  See [RFC 4516](http://tools.ietf.org/html/rfc4515) and the
 *  [ldap_url](http://www.openldap.org/software/man.cgi?query=ldap%5furl) man
 *  page for more information.
 */

#import <Foundation/Foundation.h>
#import <ldap.h>
#import <LdapKit/LKEnumerations.h>

@interface LKUrl : NSObject <NSCopying>
{
   // URL
   NSString             * ludUrl;
   NSString             * ludConnectionUrl;

   // URL componets
   LKLdapProtocolScheme   ludScheme;
   NSString             * ludHost;
   NSInteger              ludPort;
   NSString             * ludDn;
   NSArray              * ludAttrs;
   LKLdapSearchScope      ludScope;
   NSString             * ludFilter;
   NSArray              * ludExts;
   BOOL                   ludCritExts;
}

#pragma mark - Object management methods
/// @name Object Management Methods

/// Initialize a new object with default values.
- (id) init;

/// Initialize a new object with values from a URL.
/// @param uri  The URL used to populate internal values.
- (id) initWithURI:(NSString *)uri;

/// Creates a new object with values from a URL.
/// @param uri  The URL used to populate internal values.
+ (id) urlWithURI:(NSString *)uri;

/// Tests the syntax of the provided URL.
/// @param uri  The LDAP URL to test.
/// @return Returns `TRUE` if the URL is a valid LDAP URL or `FALSE` if the
/// URL is not a valid LDAP URL.
+ (BOOL) testLdapURI:(NSString *)uri;


#pragma mark - URL Componets
/// @name URL Componets

/// The LDAP URL that has been parsed into component pieces.
@property (nonatomic, copy)     NSString             * ldapUrl;
@property (nonatomic, readonly) NSString             * ldapConnectionUrl;


#pragma mark - URL Componets
/// @name URL Componets

/// The LDAP scheme used in the URL.
@property (nonatomic, assign)   LKLdapProtocolScheme   ldapScheme;

/// The hostname contained within the URL.
@property (nonatomic, copy)     NSString             * ldapHost;

/// The port number contained within the URL.
@property (nonatomic, assign)   NSInteger              ldapPort;

/// The search base DN.
@property (nonatomic, copy)     NSString             * ldapDn;

/// A list of attributes to request.
@property (nonatomic, copy)     NSArray              * ldapAttributes;

/// A scope of the search request.
@property (nonatomic, assign)   LKLdapSearchScope      ldapScope;

/// The LDAP filter.
@property (nonatomic, copy)     NSString             * ldapFilter;

/// Recognized set of LDAP and/or API extensions.
@property (nonatomic, copy)     NSArray              * ldapExtensions;

/// True if any extension is critical.
@property (nonatomic, assign)   BOOL                   ldapCriticalExtensions;

@end
