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
 *  LDAPKit/LKEnumerations.h - defines public enumerations used by LDAP Kit.
 */
#ifndef _LDAPKIT_LDAPKIT_LKENUMERATIONS_H
#define _LDAPKIT_LDAPKIT_LKENUMERATIONS_H 1


#import <ldap.h>


#pragma mark LDAP bind method
enum ldap_kit_ldap_bind_method
{
   LKLdapBindMethodAnonymous = 0x01,
   LKLdapBindMethodSimple    = 0x02,
   LKLdapBindMethodSASL      = 0x04
};
typedef enum ldap_kit_ldap_bind_method LKLdapBindMethod;


#pragma mark LDAP encryption schemes
enum ldap_kit_ldap_encryption_scheme
{
   LKLdapEncryptionSchemeNone        = 0x01,
   LKLdapEncryptionSchemeAttemptTLS  = 0x02,
   LKLdapEncryptionSchemeTLS         = 0x04,
   LKLdapEncryptionSchemeSSL         = 0x08
};
typedef enum ldap_kit_ldap_encryption_scheme LKLdapEncryptionScheme;


#pragma mark LDAP error type
enum ldap_kit_ldap_error_type
{
   LKLdapErrorTypeInternal           = 0x01,
   LKLdapErrorTypeLDAP               = 0x01
};
typedef enum ldap_kit_ldap_error_type LKLdapErrorType;


#pragma mark LDAP protocol scheme
enum ldap_kit_ldap_protocol_scheme
{
   LKLdapProtocolSchemeLDAP     = 0x01,
   LKLdapProtocolSchemeLDAPS    = 0x02,
   LKLdapProtocolSchemeLDAPI    = 0x04
};
typedef enum ldap_kit_ldap_protocol_scheme LKLdapProtocolScheme;


#pragma mark LDAP protocol version
enum ldap_kit_ldap_protocol_version
{
   LKLdapProtocolVersion2    = LDAP_VERSION2,
   LKLdapProtocolVersion3    = LDAP_VERSION3
};
typedef enum ldap_kit_ldap_protocol_version LKLdapProtocolVersion;


#pragma mark LDAP search scopes
enum ldap_kit_ldap_search_scope
{
   LKLdapSearchScopeBase        = LDAP_SCOPE_BASE,
   LKLdapSearchScopeOneLevel    = LDAP_SCOPE_ONELEVEL,
   LKLdapSearchScopeSubTree     = LDAP_SCOPE_SUBTREE,
   LKLdapSearchScopeChildren    = LDAP_SCOPE_CHILDREN
};
typedef enum ldap_kit_ldap_search_scope LKLdapSearchScope;

#endif
