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
 *  LdapKit/LKError.m manages error information.
 */
#import "LKError.h"
#import "LKErrorCategory.h"

@implementation LKError

#pragma mark - Object Management Methods

- (void) dealloc
{
   // error information
   [_errorTitle        release];
   [_errorMessage      release];
   [_diagnosticMessage release];

   [super dealloc];

   return;
}


- (id) initErrorWithTitle:(NSString *)errorTitle
{
   NSAutoreleasePool * pool;

   if ((self = [super init]) == nil)
      return(nil);

   pool = [[NSAutoreleasePool alloc] init];

   self.errorTitle        = errorTitle;
   self.errorCode         = LDAP_SUCCESS;
   self.errorMessage      = [LKError messageForCode:LDAP_SUCCESS];
   self.diagnosticMessage = nil;

   [pool release];

   return(self);
}


- (id) initErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
{
   NSAutoreleasePool * pool;

   if ((self = [super init]) == nil)
      return(nil);

   pool = [[NSAutoreleasePool alloc] init];

   self.errorTitle   = errorTitle;
   self.errorCode    = errorCode;
   self.errorMessage = [LKError messageForCode:errorCode];
   self.diagnosticMessage = nil;

   [pool release];

   return(self);
}


- (id) initErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       diagnostics:(NSString *)diagnosticMessage
{
   NSAutoreleasePool * pool;

   if ((self = [super init]) == nil)
      return(nil);

   pool = [[NSAutoreleasePool alloc] init];

   self.errorTitle        = errorTitle;
   self.errorCode         = errorCode;
   self.errorMessage      = [LKError messageForCode:errorCode];
   self.diagnosticMessage = diagnosticMessage;

   [pool release];

   return(self);
}



- (id) initErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       ldap:(LDAP *)ld
{
   NSAutoreleasePool * pool;
   int                 rc;
   char              * sval;

   NSAssert((ld != NULL), @"LDAP handle cannot be NULL");

   if ((self = [super init]) == nil)
      return(self);

   pool = [[NSAutoreleasePool alloc] init];

   self.errorTitle        = errorTitle;
   self.errorCode         = errorCode;
   self.errorMessage      = [LKError messageForCode:errorCode];

   // diagnostic message
   rc = ldap_get_option(ld, LDAP_OPT_DIAGNOSTIC_MESSAGE, &sval);
   if (rc == LDAP_OPT_SUCCESS)
   {
      self.diagnosticMessage = [NSString stringWithUTF8String:sval];
      ldap_memfree(sval);
   };

   [pool release];

   return(self);
}


- (id) initErrorWithTitle:(NSString *)errorTitle ldap:(LDAP *)ld
{
   NSAutoreleasePool * pool;
   int                 rc;
   int                 ival;
   char              * sval;

   NSAssert((ld != NULL), @"LDAP handle cannot be NULL");

   if ((self = [super init]) == nil)
      return(self);

   pool = [[NSAutoreleasePool alloc] init];

   // diagnostic message
   rc = ldap_get_option(ld, LDAP_OPT_DIAGNOSTIC_MESSAGE, &sval);
   if (rc == LDAP_OPT_SUCCESS)
   {
      self.diagnosticMessage = [NSString stringWithUTF8String:sval];
      ldap_memfree(sval);
   };
   ldap_get_option(ld, LDAP_OPT_RESULT_CODE, &ival);

   self.errorTitle        = errorTitle;
   self.errorCode         = ival;
   self.errorMessage      = [LKError messageForCode:ival];

   [pool release];

   return(self);
}


+ (id) errorWithTitle:(NSString *)errorTitle
{
   return([[[LKError alloc] initErrorWithTitle:errorTitle] autorelease]);
}


+ (id) errorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
{
   return([[[LKError alloc] initErrorWithTitle:errorTitle code:errorCode] autorelease]);
}


+ (id) errorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode diagnostics:(NSString *)diagnosticMessage
{
   return([[[LKError alloc] initErrorWithTitle:errorTitle code:errorCode diagnostics:diagnosticMessage] autorelease]);
}


+ (id) errorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode ldap:(LDAP *)ld
{
   return([[[LKError alloc] initErrorWithTitle:errorTitle code:errorCode ldap:ld] autorelease]);
}


+ (id) errorWithTitle:(NSString *)errorTitle ldap:(LDAP *)ld
{
   return([[[LKError alloc] initErrorWithTitle:errorTitle ldap:ld] autorelease]);
}


#pragma mark - Getter/Setter methods

- (NSString *) diagnosticMessage
{
   @synchronized(self)
   {
      return([[_diagnosticMessage retain] autorelease]);
   };
}
- (void) setDiagnosticMessage:(NSString *)diagnosticMessage
{
   @synchronized(self)
   {
      [_diagnosticMessage release];
      _diagnosticMessage = nil;
      if ((diagnosticMessage))
         _diagnosticMessage = [[NSString alloc] initWithString:diagnosticMessage];
   };
   return;
}


- (NSInteger) errorCode
{
   @synchronized(self)
   {
      return(_errorCode);
   };
}
- (void) setErrorCode:(NSInteger)errorCode
{
   NSAutoreleasePool * pool;
   pool = [[NSAutoreleasePool alloc] init];
   @synchronized(self)
   {
      _errorCode = errorCode;

      _errorType = LKLdapErrorTypeInternal;
      if (_errorCode > 0)
         _errorType = LKLdapErrorTypeLDAP;

      [_errorMessage release];
      _errorMessage = [[self messageForCode:errorCode] retain];
   };
   [pool release];
   return;
}


- (NSString *) errorMessage
{
   @synchronized(self)
   {
      return([[_errorMessage retain] autorelease]);
   };
}
- (void) setErrorMessage:(NSString *)errorMessage
{
   @synchronized(self)
   {
      [_errorMessage release];
      _errorMessage = nil;
      if ((errorMessage))
         _errorMessage = [[NSString alloc] initWithString:errorMessage];
   };
   return;
}


- (NSString *) errorTitle
{
   @synchronized(self)
   {
      return([[_errorTitle retain] autorelease]);
   };
}
- (void) setErrorTitle:(NSString *)errorTitle
{
   @synchronized(self)
   {
      [_errorTitle release];
      _errorTitle = nil;
      if ((errorTitle))
         _errorTitle = [[NSString alloc] initWithString:errorTitle];
   };
   return;
}


- (LKLdapErrorType) errorType
{
   @synchronized(self)
   {
      return(_errorType);
   };
}
- (void) setErrorType:(LKLdapErrorType)errorType
{
   @synchronized(self)
   {
      _errorType = errorType;
   };
   return;
}


- (BOOL) isSuccessful
{
   switch(_errorType)
   {
      case LKLdapErrorTypeInternal:
      return(_errorCode == LDAP_SUCCESS);

      case LKLdapErrorTypeLDAP:
      return(_errorCode == LDAP_SUCCESS);

      default:
      break;
   };
   return(NO);
}


#pragma mark - Error strings

- (NSString *) messageForCode:(NSInteger)errorCode
{
   return([LKError messageForCode:errorCode]);
}


+ (NSString *) messageForCode:(NSInteger)errorCode
{
   return([NSString stringWithUTF8String:ldap_err2string(errorCode)]);
}


#pragma mark - Error operations

- (void) resetError
{
   self.diagnosticMessage = nil;
   self.errorCode = 0;
   return;
}


- (void) resetErrorWithTitle:(NSString *)errorTitle
{
   [self resetError];
   self.errorTitle = errorTitle;
   return;
}


@end
