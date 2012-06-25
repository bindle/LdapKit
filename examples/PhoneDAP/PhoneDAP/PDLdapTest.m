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
 *  examples/PhoneDAP/PhoneDAP/PDLDapTest.h performs test with LDAP server
 */
#import "PDLdapTest.h"

@implementation PDLdapTest

#pragma mark - Object Management Methods

- (void) dealloc
{
   // state information
   [session          release];
   [currentOperation release];

   [super dealloc];

   return;
}


- (id) init
{
   NSAutoreleasePool * pool;

   if ((self = [super init]) == nil)
      return(self);

   pool = [[NSAutoreleasePool alloc] init];

   // session information
   session = [[LKLdap alloc] init];
   session.ldapURI              = @"ldap://ldaptest.bindlebinaries.com/";
   session.ldapBindMethod       = LKLdapBindMethodAnonymous;
   session.ldapEncryptionScheme = LKLdapEncryptionSchemeNone;

   // start search
   currentOperation = [[session searchBaseDN:@"o=test" scope:LKLdapSearchScopeSubTree
                      filter:@"(objectclass=*)" attributes:nil attributesOnly:0] retain];
   [currentOperation addObserver:self forKeyPath:@"isFinished"
      options:NSKeyValueObservingOptionNew context:nil];
   [currentOperation addObserver:self forKeyPath:@"entries"
      options:NSKeyValueObservingOptionNew context:nil];
   entriesPos = 0;

   [pool release];

   return(self);
}


- (void) processEntries:(LKMessage *)ldapOperation
{
   LKEntry           * entry;
   NSString          * attribute;
   LKBerValue        * berValue;
   NSAutoreleasePool * pool;
   NSArray           * entries;
   int                 pos;

   if (!([ldapOperation isKindOfClass:[LKMessage class]]))
      return;

   if (ldapOperation != currentOperation)
      return;

   pool = [[NSAutoreleasePool alloc] init];

   entries = ldapOperation.entries;
   for(pos = entriesPos; pos < [entries count]; pos++)
   {
      entry = [entries objectAtIndex:pos];
      NSLog(@"dn: %@", entry.dn);
      for(attribute in entry.attributes)
      {
         for(berValue in [entry valuesForAttribute:attribute])
         {
            NSLog(@"%@: %@", attribute, [berValue berString]);
         };
      };
      NSLog(@" ");
   };
   entriesPos = pos;

   [pool release];

   return;
}


- (void) processResult:(LKMessage *)ldapOperation
{
   NSAutoreleasePool * pool;
   NSArray           * entries;

   if (!([ldapOperation isKindOfClass:[LKMessage class]]))
      return;

   if (ldapOperation != currentOperation)
      return;
   if (!(currentOperation.isFinished))
      return;

   entries = currentOperation.entries;
   NSLog(@"%i entries found", [entries count]);

   if ((currentOperation.isCancelled))
   {
      NSLog(@"operation was canceled");
      return;
   };

   if (!(ldapOperation.isSuccessful))
   {
      pool = [[NSAutoreleasePool alloc] init];
      NSLog(@"%@ (%i): %@", ldapOperation.errorMessage, ldapOperation.errorCode, ldapOperation.errorMessage);
      [pool release];
      return;
   };

   return;
}


- (void) observeValueForKeyPath:(NSString *)keyPath
   ofObject:(id)object change:(NSDictionary *)change
   context:(void *)context
{
   if ([keyPath isEqualToString:@"entries"])
      [self performSelectorOnMainThread:@selector(processEntries:)
         withObject:object waitUntilDone:YES];
   else
      [self performSelectorOnMainThread:@selector(processResult:)
         withObject:object waitUntilDone:YES];
   return;
}

@end
