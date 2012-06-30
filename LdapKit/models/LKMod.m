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
 *  LdapKit/LKMod.m convenience class for BerValue.
 */
#import "LKMod.h"

#import "LKBerValue.h"


@implementation LKMod

// Modication data
@synthesize modOp = _modOp;


#pragma mark - Object Management Methods


- (id) copyWithZone:(NSZone *)zone
{
   return([[LKMod allocWithZone:zone] initWithOperation:_modOp type:_modType values:_modValues]);
}


- (void) dealloc
{
   // modification inforation
   [_modType   release];
   [_modValues release];

   [super dealloc];

   return;
}


- (id) initWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
{
   NSAssert(((modType)), @"modType must not be nil");
   NSAssert( ( (modOp == LKLdapModOperationAdd) ||
               (modOp == LKLdapModOperationDelete) ),
             @"modOp must be LKLdapModOperationAdd or LKLdapModOperationDelete.");
   return([self initWithOperation:modOp type:modType values:nil]);
}


- (id) initWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       value:(id <NSObject>)modValue
{
   NSArray * modValues;

   NSAssert(((modType)), @"modType must not be nil");
   NSAssert(((modValue)), @"modValue must not be nil");
   NSAssert( ( (modOp == LKLdapModOperationAdd) ||
               (modOp == LKLdapModOperationDelete) ||
               (modOp == LKLdapModOperationReplace) ),
             ( @"modOp must be LKLdapModOperationAdd, LKLdapModOperationDelete,"
               @" or LKLdapModOperationReplace" ) );
   NSAssert( ( (([modValue isKindOfClass:[LKBerValue class]])) ||
               (([modValue isKindOfClass:[NSString class]]))   ||
               (([modValue isKindOfClass:[NSData class]]))     ),
             @"modValues must only contain LKBerValue, NSData, and NSString objects.");

   modValues = [[NSArray alloc] initWithObjects:modValue, nil];
   self = [self initWithOperation:modOp type:modType values:modValues];
   [modValues release];

   return(self);
}


- (id) initWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       values:(NSArray *)modValues
{
   NSUInteger    pos;
   id <NSObject> object;

   NSAssert(((modType)), @"modType must not be nil");
   NSAssert( ( (modOp == LKLdapModOperationAdd) ||
               (modOp == LKLdapModOperationDelete) ||
               (modOp == LKLdapModOperationReplace) ),
             ( @"modOp must be LKLdapModOperationAdd, LKLdapModOperationDelete,"
               @" or LKLdapModOperationReplace" ) );
   if ((modOp == LKLdapModOperationAdd) || (modOp == LKLdapModOperationReplace))
      NSAssert(((modValues)), @"modValues must not be nil for LKLdapModOperationAdd or LKLdapModOperationReplace");
   if ((modValues))
      NSAssert((([modValues count])), @"modValues must contain at least one member");
   for(pos = 0; pos < [modValues count]; pos++)
   {
      object = [modValues objectAtIndex:pos];
      NSAssert( ( (([object isKindOfClass:[LKBerValue class]])) ||
                  (([object isKindOfClass:[NSString class]]))   ||
                  (([object isKindOfClass:[NSData class]]))     ),
         @"modValues must only contain LKBerValue, NSData, and NSString objects.");
   };

   if ((self = [super init]) == nil)
      return(self);

   // modification information
   _modOp     = modOp;
   _modType   = [[NSString allocWithZone:self.zone] initWithString:modType];
   _modValues = [[NSArray allocWithZone:self.zone] initWithArray:modValues copyItems:YES];

   return(self);
}


+ (id) modWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
{
   NSAssert(((modType)), @"modType must not be nil");
   NSAssert( ( (modOp == LKLdapModOperationAdd) ||
               (modOp == LKLdapModOperationDelete) ),
             @"modOp must be LKLdapModOperationAdd or LKLdapModOperationDelete.");
   return([[[LKMod alloc] initWithOperation:modOp type:modType] autorelease]);
}


+ (id) modWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       value:(id <NSObject>)modValue
{
   NSAssert(((modType)), @"modType must not be nil");
   NSAssert(((modValue)), @"modValue must not be nil");
   NSAssert( ( (modOp == LKLdapModOperationAdd) ||
               (modOp == LKLdapModOperationDelete) ||
               (modOp == LKLdapModOperationReplace) ),
             ( @"modOp must be LKLdapModOperationAdd, LKLdapModOperationDelete,"
               @" or LKLdapModOperationReplace" ) );
   NSAssert( ( (([modValue isKindOfClass:[LKBerValue class]])) ||
               (([modValue isKindOfClass:[NSString class]]))   ||
               (([modValue isKindOfClass:[NSData class]]))     ),
             @"modValues must only contain LKBerValue, NSData, and NSString objects.");
   return([[[LKMod alloc] initWithOperation:modOp type:modType value:modValue] autorelease]);
}


+ (id) modWithOperation:(LKLdapModOperation)modOp type:(NSString *)modType
       values:(NSArray *)modValues
{
   NSUInteger    pos;
   id <NSObject> object;

   NSAssert(((modType)), @"modType must not be nil");
   NSAssert( ( (modOp == LKLdapModOperationAdd) ||
               (modOp == LKLdapModOperationDelete) ||
               (modOp == LKLdapModOperationReplace) ),
             ( @"modOp must be LKLdapModOperationAdd, LKLdapModOperationDelete,"
               @" or LKLdapModOperationReplace" ) );
   if ((modOp == LKLdapModOperationAdd) || (modOp == LKLdapModOperationReplace))
      NSAssert(((modValues)), @"modValues must not be nil for LKLdapModOperationAdd or LKLdapModOperationReplace");
   if ((modValues))
      NSAssert((([modValues count])), @"modValues must contain at least one member");
   for(pos = 0; pos < [modValues count]; pos++)
   {
      object = [modValues objectAtIndex:pos];
      NSAssert( ( (([object isKindOfClass:[LKBerValue class]])) ||
                  (([object isKindOfClass:[NSString class]]))   ||
                  (([object isKindOfClass:[NSData class]]))     ),
         @"modValues must only contain LKBerValue, NSData, and NSString objects.");
   };

   return([[[LKMod alloc] initWithOperation:modOp type:modType values:modValues] autorelease]);
}


#pragma mark - Getter/Setter methods

- (NSString *) modType
{
   @synchronized(self)
   {
      return([[_modType retain] autorelease]);
   };
}


- (NSArray *) modValues
{
   @synchronized(self)
   {
      return([[_modValues retain] autorelease]);
   };
}


#pragma mark - Modifications

- (void) addValue:(id <NSObject, NSCopying>)modValue
{
   NSMutableArray           * tmpArray;
   id <NSObject, NSCopying>   object;      
   NSAssert( ( (([modValue isKindOfClass:[LKBerValue class]])) ||
               (([modValue isKindOfClass:[NSString class]]))   ||
               (([modValue isKindOfClass:[NSData class]]))     ),
             @"modValues must only contain LKBerValue, NSData, and NSString objects.");
   @synchronized(self)
   {
      tmpArray = [[NSMutableArray alloc] initWithCapacity:([_modValues count]+1)];
      if ((_modValues))
         [tmpArray addObjectsFromArray:_modValues];
      object = [modValue copyWithZone:self.zone];
      [tmpArray addObject:object];
      [object release];
      [_modValues release];
      _modValues = [[NSArray alloc] initWithArray:tmpArray];
      [tmpArray release];
   };
   return;
}


#pragma mark - Manager LDAPMod References

- (LDAPMod *) newLDAPMod
{
   LDAPMod            * mod;
   size_t               len;
   size_t               pos;
   id                   value;
   BerValue           * bval;
   BerValue          ** bvals;
   NSAutoreleasePool  * pool;

   @synchronized(self)
   {
      // allocates memory for LDAPMod
      if ((mod = malloc(sizeof(LDAPMod))) == NULL)
         return(mod);

      pool = [[NSAutoreleasePool alloc] init];

      // generates list of mod values
      bvals = NULL;
      if ((_modValues))
      {
         len   = [_modValues count];

         if ((bvals = malloc(sizeof(BerValue *))) == NULL)
         {
            [LKMod freeLDAPMod:mod];
            [pool release];
            return(NULL);
         };
         bvals[0] = NULL;

         for(pos = 0; ((pos < len) && ((bvals))); pos++)
         {
            bval  = NULL;
            value = [_modValues objectAtIndex:pos];
            if (([value isKindOfClass:[LKBerValue class]]))
               bval = [(LKBerValue *)value newBerValue];
            else if (([value isKindOfClass:[NSData class]]))
               bval = [LKBerValue newBerValueWithData:value];
            else
               bval = ber_bvstrdup([(NSString *)value UTF8String]);
            if (!(bval))
            {
               [LKMod freeLDAPMod:mod];
               [pool release];
               return(NULL);
            };
            ber_bvecadd(&bvals, bval);
         };
      };

      mod->mod_op              = _modOp;
      mod->mod_type            = strdup([_modType UTF8String]);
      mod->mod_vals.modv_bvals = bvals;

      [pool release];
   };

   if (!(mod->mod_type))
   {
      [LKMod freeLDAPMod:mod];
      return(NULL);
   };

   return(mod);
}


+ (void) freeLDAPMod:(LDAPMod *)mod
{
   NSAssert((mod != NULL), @"mod must not be NULL");
   if ((mod->mod_type))
      free(mod->mod_type);
   if ((mod->mod_vals.modv_bvals))
      ber_bvecfree(mod->mod_vals.modv_bvals);
   free(mod);
   return;
}

@end
