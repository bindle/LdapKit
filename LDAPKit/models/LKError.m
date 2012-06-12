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
 *  LDAPKit/LKError.m manages error information.
 */
#import "LKError.h"

@implementation LKError

// error information
@synthesize errorType;


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


/// Creates and returns an LKError object initialized with the values of the
/// current error and assigns the title as the error's title.
/// @param  errorTitle   the title of the created error
- (id) errorWithTitle:(NSString *)errorTitle
{
   return([[[LKError alloc] initWithError:self andTitle:errorTitle] autorelease]);
}


- (id) initInternalErrorWithTitle:(NSString *)errorTitle code:(LKErrorCode)errorCode
{
   NSString * errorMessage = [LKError internalErrorMessageForCode:errorCode];
   self = [self initInternalErrorWithTitle:errorTitle code:errorCode
      message:errorMessage diagnostics:nil];
   return(self);
}


- (id) initInternalErrorWithTitle:(NSString *)errorTitle code:(LKErrorCode)errorCode
       message:(NSString *)errorMessage
{
   self = [self initInternalErrorWithTitle:errorTitle code:errorCode
                message:errorMessage diagnostics:nil];
   return(self);
}


- (id) initInternalErrorWithTitle:(NSString *)errorTitle code:(LKErrorCode)errorCode
       message:(NSString *)errorMessage diagnostics:(NSString *)diagnosticMessage
{
   if ((self = [super init]) == nil)
      return(self);

   _errorType  = LKLdapErrorTypeInternal;
   _errorCode  = errorCode;
   if ((errorTitle))
      _errorTitle = [[NSString alloc] initWithString:errorTitle];
   if ((errorMessage))
      _errorMessage = [[NSString alloc] initWithString:errorMessage];
   if ((diagnosticMessage))
      _diagnosticMessage = [[NSString alloc] initWithString:diagnosticMessage];

   return(self);
}


- (id) initLdapErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       message:(NSString *)errorMessage
{
   self = [self initLdapErrorWithTitle:errorTitle code:errorCode
                message:errorMessage diagnostics:nil];
   return(self);
}


- (id) initLdapErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       ldap:(LDAP *)ld
{
   int    rc;
   char * sval;

   NSAssert((ld != NULL), @"LDAP handle cannot be NULL");

   if ((self = [super init]) == nil)
      return(self);

   // error type
   _errorType  = LKLdapErrorTypeLDAP;

   // error code
   _errorCode  = errorCode;

   // error title
   if ((errorTitle))
      _errorTitle = [[NSString alloc] initWithString:errorTitle];

   // error message
   sval = ldap_err2string(_errorCode);
   if ((sval))
      _errorMessage = [[NSString alloc] initWithUTF8String:sval];

   // diagnostic message
   rc = ldap_get_option(ld, LDAP_OPT_DIAGNOSTIC_MESSAGE, &sval);
   if (rc == LDAP_OPT_SUCCESS)
   {
      _diagnosticMessage = [[NSString alloc] initWithUTF8String:sval];
      ldap_memfree(sval);
   };

   return(self);
}


- (id) initLdapErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       message:(NSString *)errorMessage diagnostics:(NSString *)diagnosticMessage
{
   if ((self = [super init]) == nil)
      return(self);

   _errorType  = LKLdapErrorTypeLDAP;
   _errorCode  = errorCode;
   if ((errorTitle))
      _errorTitle = [[NSString alloc] initWithString:errorTitle];
   if ((errorMessage))
      _errorMessage = [[NSString alloc] initWithString:errorMessage];
   if ((diagnosticMessage))
      _diagnosticMessage = [[NSString alloc] initWithString:diagnosticMessage];

   return(self);
}


- (id) initLdapErrorWithTitle:(NSString *)errorTitle ldap:(LDAP *)ld
{
   int ival;
   NSAssert((ld != NULL), @"LDAP handle cannot be NULL");
   ldap_get_option(ld, LDAP_OPT_RESULT_CODE, &ival);
   return([self initLdapErrorWithTitle:errorTitle code:ival ldap:ld]);
}


/// Returns an error initialized with the values of error and assigns title as
/// the initialized error's title.
/// @param error        an error
/// @param errorTitle   the title of the initialized error
- (id) initWithError:(LKError *)error andTitle:(NSString *)errorTitle
{
   NSAssert((errorTitle != nil), @"new title cannot be nil");

   if ((self = [super init]) == nil)
      return(self);

   _errorType         = error.errorType;
   _errorCode         = error.errorCode;
   _errorTitle        = [[NSString alloc] initWithString:errorTitle];
   _errorMessage      = error.errorMessage;
   _diagnosticMessage = error.diagnosticMessage;

   return(self);
}


+ (id) internalErrorWithTitle:(NSString *)errorTitle code:(LKErrorCode)errorCode
{
   LKError * error;
   error = [[LKError alloc] initInternalErrorWithTitle:errorTitle code:errorCode];
   return([error autorelease]);
}


+ (id) internalErrorWithTitle:(NSString *)errorTitle code:(LKErrorCode)errorCode
       message:(NSString *)errorMessage
{
   LKError * error;
   error = [LKError internalErrorWithTitle:errorTitle code:errorCode
                message:errorMessage diagnostics:nil];
   return(error);
}


+ (id) internalErrorWithTitle:(NSString *)errorTitle code:(LKErrorCode)errorCode
       message:(NSString *)errorMessage diagnostics:(NSString *)diagnosticMessage
{
   LKError * error;
   error = [[LKError alloc] initInternalErrorWithTitle:errorTitle
               code:errorCode
               message:errorMessage
               diagnostics:diagnosticMessage];
   return([error autorelease]);
}


+ (id) ldapErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
{
   LKError * error;
   error = [LKError ldapErrorWithTitle:errorTitle code:errorCode
                message:[LKError errorMessageForCode:errorCode] diagnostics:nil];
   return(error);
}


+ (id) ldapErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       message:(NSString *)errorMessage
{
   LKError * error;
   error = [LKError ldapErrorWithTitle:errorTitle code:errorCode
                message:errorMessage diagnostics:nil];
   return(error);
}


+ (id) ldapErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       ldap:(LDAP *)ld
{
   return([[[LKError alloc] initLdapErrorWithTitle:errorTitle code:errorCode ldap:ld] autorelease]);
}


+ (id) ldapErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode
       message:(NSString *)errorMessage diagnostics:(NSString *)diagnosticMessage
{
   LKError * error;
   error = [[LKError alloc] initLdapErrorWithTitle:errorTitle
               code:errorCode
               message:errorMessage
               diagnostics:diagnosticMessage];
   return([error autorelease]);
}


+ (id) ldapErrorWithTitle:(NSString *)errorTitle ldap:(LDAP *)ld
{
   return([[[LKError alloc] initLdapErrorWithTitle:errorTitle ldap:ld] autorelease]);
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
      _errorMessage = [[self errorMessageForCode:errorCode] retain];
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


- (BOOL) isSuccessful
{
   switch(_errorType)
   {
      case LKLdapErrorTypeInternal:
      return(_errorCode == LKErrorCodeSuccess);

      case LKLdapErrorTypeLDAP:
      return(_errorCode == LDAP_SUCCESS);

      default:
      break;
   };
   return(NO);
}


#pragma mark - Error strings

- (NSString *) errorMessageForCode:(NSInteger)errorCode
{
   if (errorCode < 0)
      return([self internalErrorMessageForCode:errorCode]);
   return([NSString stringWithUTF8String:ldap_err2string(errorCode)]);
}


+ (NSString *) errorMessageForCode:(NSInteger)errorCode
{
   if (errorCode < 0)
      return([LKError internalErrorMessageForCode:errorCode]);
   return([NSString stringWithUTF8String:ldap_err2string(errorCode)]);
}


- (NSString *) internalErrorMessageForCode:(LKErrorCode)errorCode
{
   return([LKError internalErrorMessageForCode:errorCode]);
}


+ (NSString *) internalErrorMessageForCode:(LKErrorCode)errorCode
{
   switch (errorCode)
   {
      case LKErrorCodeSuccess:
      return(@"success");

      case LKErrorCodeCancelled:
      return(@"operation was canceled");

      case LKErrorCodeNotConnected:
      return(@"not connected to server");

      case LKErrorCodeMemory:
      return(@"out of virtual memory");

      case LKErrorCodeUnknown:
      default:
      break;
   };
   return(@"unknown internal error");
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
