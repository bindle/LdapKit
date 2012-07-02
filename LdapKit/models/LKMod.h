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
 *  LKMod is used to specify the modifications to be made to an LDAP entry.
 */

#import <Foundation/Foundation.h>
#import <LdapKit/LKEnumerations.h>


#pragma mark LDAP mod operation
enum ldap_kit_ldap_mod_operation
{
   LKLdapModOperationAdd       = LDAP_MOD_ADD,
   LKLdapModOperationDelete    = LDAP_MOD_DELETE,
   LKLdapModOperationReplace   = LDAP_MOD_REPLACE
};
typedef enum ldap_kit_ldap_mod_operation LKLdapModOperation;


@interface LKMod : NSObject <NSCopying>
{
   // modification information
   LKLdapModOperation   _modOp;
   NSString           * _modType;
   NSArray            * _modValues;
}

#pragma mark - Object Management Methods
/// @name Object Management Methods

/// Initialize a new object
/// @param modOp     The type of operation to perform on the attribute. See
/// modOp for valid values.
/// @param modType   The attribute to modify.
- (id) initWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType;

/// Initialize a new object
/// @param modOp     The type of operation to perform on the attribute. See
/// modOp for valid values.
/// @param modType   The attribute to modify.
/// @param modValue  The value to delete, add, or replace.
- (id) initWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       value:(id <NSObject>)modValue;

/// Initialize a new object
/// @param modOp     The type of operation to perform on the attribute. See
/// modOp for valid values.
/// @param modType   The attribute to modify.
/// @param modValues The optional values to delete, add, or replace.
- (id) initWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       values:(NSArray *)modValues;

/// Creates a new object
/// @param modOp     The type of operation to perform on the attribute. See
/// modOp for valid values.
/// @param modType   The attribute to modify.
+ (id) modWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType;

/// Initialize a new object
/// @param modOp     The type of operation to perform on the attribute. See
/// modOp for valid values.
/// @param modType   The attribute to modify.
/// @param modValue  The value to delete, add, or replace.
+ (id) modWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       value:(id <NSObject>)modValue;

/// Creates a new object
/// @param modOp     The type of operation to perform on the attribute. See
/// modOp for valid values.
/// @param modType   The attribute to modify.
/// @param modValues The optional values to delete, add, or replace.
+ (id) modWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       values:(NSArray *)modValues;


#pragma mark - Modifications
/// @name Modifications

/// The type of modification to perform.
///
/// LKLdapModOperation        | Description
/// --------------------------|------------
/// LKLdapModOperationAdd     | Add attribute values.
/// LKLdapModOperationDelete  | Delete attribute values.
/// LKLdapModOperationReplace | Replace attribute values.
@property (atomic, readonly) LKLdapModOperation modOp;

/// The attribute to be modified.
@property (atomic, copy, readonly) NSString * modType;

/// The values to add, replace, or delete from an attribute.
@property (atomic, copy, readonly) NSArray * modValues;

/// Add value to list of modifications.
/// @param modValue Value to append to modification values.
- (void) addValue:(id <NSObject, NSCopying>)modValue;


#pragma mark - Manager LDAPMod References
/// @name Manager LDAPMod References

/// Allocate a new LDAPMod reference.
/// @return This method returns a pointer to a `LDAPMod` reference. The
/// `LDAPMod` reference must be freed using `+freeLDAPMod:`.
- (LDAPMod *) newLDAPMod;

/// Frees a LDAPMod reference.
/// @param mod The LDAPMod reference to be freed.
+ (void) freeLDAPMod:(LDAPMod *)mod;

@end
