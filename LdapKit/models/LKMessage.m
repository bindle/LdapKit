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
 *  LdapKit/LKMessage.m returns results from LDAP operations.
 */
#import "LKMessageCategory.h"

#import <signal.h>
#import <sasl/sasl.h>
#include <sys/socket.h>

#import "LKError.h"
#import "LKLdapCategory.h"


#pragma mark - Data Types
struct ldap_kit_ldap_auth_data
{
   const char     * saslmech;  ///< SASL mechanism to use for authentication
   const char     * authuser;  ///< user to authenticate
   const char     * user;      ///< pre-authenticated user
   const char     * realm;     ///< SASL realm used for authentication
   BerValue         cred;      ///< the credentials of "user" (i.e. password)
};
typedef struct ldap_kit_ldap_auth_data LKLdapAuthData;


@interface LKMessage ()

// Getter/Setter methods
- (void) setError:(LKError *)anError;

/// @name LDAP tasks
- (BOOL) connect;
//- (BOOL) search;
- (BOOL) testConnection;
- (BOOL) unbind;

/// @name LDAP subtasks
- (LDAP *) connectBind:(LDAP *)ld;
- (LDAP *) connectFinish:(LDAP *)ld;
- (LDAP *) connectInitialize;
- (LDAP *) connectStartTLS:(LDAP *)ld;

@end


@implementation LKMessage

// state information
@synthesize error;
@synthesize messageType;

// client information
@synthesize tag;
@synthesize object;


#pragma mark - Object Management Methods

- (void) dealloc
{
   // server state
   [ldap    release];
   [error   release];

   // server information
   [ldapURI release];

   // encryption information
   [ldapCACertificateFile release];

   // authentication information
   [ldapBindWho               release];
   [ldapBindCredentials       release];
   [ldapBindSaslMechanism     release];
   [ldapBindSaslRealm         release];

   [super dealloc];

   return;
}


- (id) init
{
   NSAssert(FALSE, @"use initLdapWithSession:");
   return(nil);
   // initialize super
   if ((self = [super init]) == nil)
      return(self);
   return(self);
}


- (id) initLdapInitialzieWithSession:(LKLdap *)data
{
   NSAutoreleasePool * pool;

   // initialize super
   if ((self = [super init]) == nil)
      return(self);

   pool = [[NSAutoreleasePool alloc] init];

   // state information
   ldap        = [data retain];
   error       = [[LKError alloc] init];
   messageType = LKLdapMessageTypeConnect;

   // server information
   ldapURI             = [ldap.ldapURI retain];
   ldapScheme          = ldap.ldapScheme;
   ldapProtocolVersion = ldap.ldapProtocolVersion;

   // encryption information
   ldapEncryptionScheme  = ldap.ldapEncryptionScheme;
   ldapCACertificateFile = [ldap.ldapCACertificateFile retain];

   // timeout information
   ldapSizeLimit      = ldap.ldapSizeLimit;
   ldapSearchTimeout  = ldap.ldapSearchTimeout;
   ldapNetworkTimeout = ldap.ldapNetworkTimeout;

   // authentication information
   ldapBindMethod        = ldap.ldapBindMethod;
   ldapBindWho           = [ldap.ldapBindWho retain];
   ldapBindCredentials   = [ldap.ldapBindCredentials retain];
   ldapBindSaslMechanism = [ldap.ldapBindSaslMechanism retain];;
   ldapBindSaslRealm     = [ldap.ldapBindSaslRealm retain];

   [pool release];

   return(self);
}


#pragma mark - Getter/Setter methods

- (LKError *) error
{
   @synchronized(self)
   {
      return([[error retain] autorelease]);
   };
}


- (void) setError:(LKError *)anError
{
   @synchronized(self)
   {
      [error release];
      error = [anError retain];
   };
   return;
}


#pragma mark - non-concurrent tasks

- (void) main
{
   NSAutoreleasePool * pool;

   // add signal handlers
   signal(SIGPIPE, SIG_IGN);

   pool = [[NSAutoreleasePool alloc] init];

   switch(messageType)
   {
      case LKLdapMessageTypeConnect:
      [self connect];
      break;

      case LKLdapMessageTypeUnbind:
      [self unbind];
      self.error.errorTitle = @"LDAP unbind";
      break;

      default:
      break;
   };

   [pool release];

   return;
}


#pragma mark - LDAP tasks

- (BOOL) connect
{
   BOOL                isConnected;
   LDAP              * ld;

   // reset errors
   [error resetErrorWithTitle:@"LDAP initialize"];

   // checks for existing connection
   isConnected = [self testConnection];
   if ((isConnected))
      return(error.isSuccessful);
   if ((self.isCancelled))
   {
      self.error = [LKError errorWithTitle:@"LDAP Error" code:LKErrorCodeCancelled];
      return(error.isSuccessful);
   };

   // obtain the lock for LDAP handle
   [ldap.ldLock lock];

   // initialize LDAP handle
   if ((ld = [self connectInitialize]) == NULL)
   {
      [ldap.ldLock unlock];
      return(error.isSuccessful);
   };

   // starts TLS session
   if ((ld = [self connectStartTLS:ld]) == NULL)
   {
      [ldap.ldLock unlock];
      return(error.isSuccessful);
   };

   // binds to LDAP
   if ((ld = [self connectBind:ld]) == NULL)
   {
      [ldap.ldLock unlock];
      return(error.isSuccessful);
   };

   // finish configuring connection
   if ((ld = [self connectFinish:ld]) == NULL)
   {
      [ldap.ldLock unlock];
      return(error.isSuccessful);
   };

   // saves LDAP handle
   ldap.ld          = ld;
   ldap.isConnected = YES;

   // unlocks LDAP handle
   [ldap.ldLock unlock];

   return(error.isSuccessful);
}


- (BOOL) testConnection
{
   BOOL             isConnected;
   int              err;
   struct timeval   timeout;
   struct timeval * timeoutp;
   LDAPMessage    * res;

   char * attrs[] =
   {
      "objectClass",
      NULL
   };

   // reset errors
   [error resetErrorWithTitle:@"Test LDAP Connection"];

   // start off assuming session is connected
   isConnected = YES;

   // obtain the lock for LDAP handle
   [ldap.ldLock lock];

   // assume session is correct if reporting not connected
   if (!(ldap.isConnected))
   {
      isConnected = NO;
      if ((ldap.ld))
         ldap_unbind_ext_s(ldap.ld, NULL, NULL);
      ldap.ld  = NULL;
   }

   // verify LDAP handle exists
   else if (!(ldap.ld))
      isConnected = NO;

   // test connection with simple LDAP query
   else
   {
      // calculates search timeout
      memset(&timeout, 0, sizeof(struct timeval));
      timeout.tv_sec  = ldapSearchTimeout;
      timeoutp        = &timeout;
      if (!(timeout.tv_sec))
         timeoutp = NULL;

      // performs search against known entry
      err = ldap_search_ext_s(
         ldap.ld,                    // LDAP            * ld
         "",                         // char            * base
         LDAP_SCOPE_BASE,            // int               scope
         "(objectclass=*)",          // char            * filter
         attrs,                      // char            * attrs[]
         1,                          // int               attrsonly
         NULL,                       // LDAPControl    ** serverctrls
         NULL,                       // LDAPControl    ** clientctrls
         timeoutp,                   // struct timeval  * timeout
         2,                          // int               sizelimit
         &res                        // LDAPMessage    ** res
      );

      // frees result if one was returned (result is not needed)
      if (err == LDAP_SUCCESS)
         ldap_msgfree(res);

      // interpret error code
      switch(err)
      {
         case LDAP_SERVER_DOWN:
         case LDAP_TIMEOUT:
         case LDAP_CONNECT_ERROR:
         isConnected = NO;
         break;

         default:
         break;
      };
   };

   // release lock for LDAP handle
   [ldap.ldLock unlock];

   if (!(isConnected))
   {
      [self unbind];
      self.error = [LKError errorWithTitle: @"Test LDAP Connection" code:LKErrorCodeNotConnected];
      return(self.error.isSuccessful);
   };

   return(self.error.isSuccessful);
}


- (BOOL) unbind
{
   // reset errors
   [error resetError];
   error.errorTitle = @"LDAP Unbind";

   // locks LDAP handle
   [ldap.ldLock lock];

   // clears LDAP information
   @synchronized(ldap)
   {
      if ((ldap.ld))
         ldap_unbind_ext(ldap.ld, NULL, NULL);
      ldap.ld          = NULL;
      ldap.isConnected = NO;
   };

   // unlocks LDAP handle
   [ldap.ldLock unlock];

   return(self.error.isSuccessful);
}


#pragma mark - LDAP subtasks

- (LDAP *) connectBind:(LDAP *)ld
{
   int                 err;
   LKLdapAuthData      auth;
   char              * buff;
   struct berval     * servercredp;

   // reset errors
   [error resetErrorWithTitle:@"LDAP Bind"];

   // prepares auth data
   memset(&auth, 0, sizeof(LKLdapAuthData));
   auth.authuser    = [ldapBindWho UTF8String];
   auth.realm       = [ldapBindSaslRealm UTF8String];
   auth.saslmech    = [ldapBindSaslMechanism UTF8String];
   auth.cred.bv_val = NULL;
   auth.cred.bv_len = ldapBindCredentials.length;

   // allocates memory for credentials
   buff = NULL;
   if (ldapBindCredentials.length > 0)
   {
      if ((buff = malloc(ldapBindCredentials.length+1)))
      {
         memcpy(buff, ldapBindCredentials.bytes, ldapBindCredentials.length);
         buff[ldapBindCredentials.length] = '\0';
         auth.cred.bv_val = buff;
      };
   };

   switch(ldapBindMethod)
   {
      case LKLdapBindMethodAnonymous:
      // authenticate to server with anonymous simple bind
      auth.authuser = NULL;
      auth.cred.bv_val = NULL;
      auth.cred.bv_len = 0;

      case LKLdapBindMethodSimple:
      // authenticate to server with simple bind
      err = ldap_sasl_bind_s
      (
         ld,                // LDAP           * ld
         auth.authuser,     // const char     * dn
         LDAP_SASL_SIMPLE,  // const char     * mechanism
         &auth.cred,        // struct berval  * cred
         NULL,              // LDAPControl    * sctrls[]
         NULL,              // LDAPControl    * cctrls[]
         &servercredp       // struct berval ** servercredp
      );
      break;

      case LKLdapBindMethodSASL:
      default:
      // authenticate to server with SASL bind
      err = ldap_sasl_interactive_bind_s
      (
         ld,                      // LDAP                    * ld
         NULL,                    // const char              * dn
         auth.saslmech,           // const char              * mechs
         NULL,                    // LDAPControl             * sctrls[]
         NULL,                    // LDAPControl             * cctrls[]
         LDAP_SASL_QUIET,         // unsigned                  flags
         branches_sasl_interact,  // LDAP_SASL_INTERACT_PROC * interact
         &auth                    // void                    * defaults
      );
      break;
   };

   // frees memory
   free(buff);

   // checks for error
   if (err != LDAP_SUCCESS)
   {
      self.error = [LKError errorWithTitle:@"Authentication Error" code:err];
      ldap_unbind_ext_s(ld, NULL, NULL);
      return(NULL);
   };

   // check for cancelled operation
   if ((self.isCancelled))
   {
      self.error = [LKError errorWithTitle:@"LDAP Error" code:LKErrorCodeCancelled];
      ldap_unbind_ext_s(ld, NULL, NULL);
      return(NULL);
   };

   return(ld);
}


- (LDAP *) connectFinish:(LDAP *)ld
{
   int err;
   int opt;
   int s;

   // reset errors
   [error resetErrorWithTitle:@"LDAP Connect"];

   // retrieves LDAP socket
   err = ldap_get_option(ld, LDAP_OPT_DESC, &s);
   if (err != LDAP_SUCCESS)
   {
      self.error = [LKError errorWithTitle:@"Internal LDAP Error" code:err];
      ldap_unbind_ext_s(ld, NULL, NULL);
      return(NULL);
   };

   // sets SO_NOSIGPIPE on socket
   opt = 1;
   err = setsockopt(s, SOL_SOCKET, SO_NOSIGPIPE, &opt, sizeof(opt));
   if (err == -1)
   {
      self.error = [LKError errorWithTitle:@"Internal LDAP Error" code:LKErrorCodeUnknown];
      error.errorMessage = [NSString stringWithUTF8String:strerror(errno)];
      ldap_unbind_ext_s(ld, NULL, NULL);
      return(NULL);
   };

   return(ld);
}


- (LDAP *) connectInitialize
{
   LDAP              * ld;
   int                 err;
   int                 opt;
   const char        * str;
   struct timeval      timeout;

   // reset errors
   [error resetErrorWithTitle:@"LDAP initialize"];

   // initialize LDAP handle
   err = ldap_initialize(&ld, [ldapURI UTF8String]);
   NSAssert((err == LDAP_SUCCESS), @"ldap_initialize(): %s", ldap_err2string(err));

   // set LDAP protocol version
   opt = ldapProtocolVersion;
   err = ldap_set_option(ld, LDAP_OPT_PROTOCOL_VERSION, &opt);
   if (err != LDAP_SUCCESS)
   {
      self.error = [LKError errorWithTitle:@"Internal LDAP Error" code:err];
      ldap_unbind_ext_s(ld, NULL, NULL);
      return(NULL);
   };

   // set network timout
   if ((ldapNetworkTimeout))
   {
      timeout.tv_usec = 0;
      timeout.tv_sec  = ldapNetworkTimeout;
      if (timeout.tv_sec < 1)
         timeout.tv_sec = -1;
      err = ldap_set_option(ld, LDAP_OPT_NETWORK_TIMEOUT, &timeout);
      if (err != LDAP_SUCCESS)
      {
         self.error = [LKError errorWithTitle:@"Internal LDAP Error" code:err];
         ldap_unbind_ext_s(ld, NULL, NULL);
         return(NULL);
      };
   };

   // set LDAP search timout
   if ((ldapSearchTimeout))
   {
      opt = ldapSearchTimeout;
      err = ldap_set_option(ld, LDAP_OPT_TIMELIMIT, &opt);
      if (err != LDAP_SUCCESS)
      {
         self.error = [LKError errorWithTitle:@"Internal LDAP Error" code:err];
         ldap_unbind_ext_s(ld, NULL, NULL);
         return(NULL);
      };
   };

   // set LDAP search size limit
   if ((ldapSizeLimit))
   {
      opt = ldapSizeLimit;
      err = ldap_set_option(ld, LDAP_OPT_SIZELIMIT, &opt);
      if (err != LDAP_SUCCESS)
      {
         self.error = [LKError errorWithTitle:@"Internal LDAP Error" code:err];
         ldap_unbind_ext_s(ld, NULL, NULL);
         return(NULL);
      };
   };

   // set SSL/TLS CA cert file
   if ((ldapCACertificateFile))
   {
      str = [ldapCACertificateFile UTF8String];
      err = ldap_set_option(NULL, LDAP_OPT_X_TLS_CACERTFILE, (void *)str);
      if (err != LDAP_SUCCESS)
      {
         self.error = [LKError errorWithTitle:@"Internal LDAP Error" code:err];
         ldap_unbind_ext_s(ld, NULL, NULL);
         return(NULL);
      };
   };

   // check for cancelled operation
   if ((self.isCancelled))
   {
      self.error = [LKError errorWithTitle:@"LDAP Error" code:LKErrorCodeCancelled];
      ldap_unbind_ext_s(ld, NULL, NULL);
      return(NULL);
   };

   return(ld);
}


- (LDAP *) connectStartTLS:(LDAP *)ld
{
   int    err;
   int    opt;
   char * errmsg;

   // reset errors
   [error resetErrorWithTitle:@"LDAP Start TLS"];

   // checks scheme
   if (ldapScheme == LKLdapProtocolSchemeLDAPS)
      return(ld);

   if ( (ldapEncryptionScheme != LKLdapEncryptionSchemeAttemptTLS ) &&
        (ldapEncryptionScheme != LKLdapEncryptionSchemeTLS) )
      return(ld);

   switch(ldapEncryptionScheme)
   {
      case LKLdapEncryptionSchemeSSL:
         opt = LDAP_OPT_X_TLS_HARD;
         err = ldap_set_option(ld, LDAP_OPT_X_TLS, &opt);
         if (err != LDAP_SUCCESS)
         {
            self.error = [LKError errorWithTitle:@"LDAP SSL" code:err];
            ldap_unbind_ext_s(ld, NULL, NULL);
            return(NULL);
         };
         break;

      case LKLdapEncryptionSchemeAttemptTLS:
      case LKLdapEncryptionSchemeTLS:
         err = ldap_start_tls_s(ld, NULL, NULL);
         if ((err != LDAP_SUCCESS) && (ldapEncryptionScheme != LKLdapEncryptionSchemeAttemptTLS))
         {
            ldap_get_option(ld, LDAP_OPT_DIAGNOSTIC_MESSAGE, (void*)&errmsg);
            self.error = [LKError errorWithTitle:@"LDAP TLS" code:err diagnostics:[NSString stringWithUTF8String:errmsg]];
            ldap_unbind_ext_s(ld, NULL, NULL);
            return(NULL);
         };

      default:
         break;
   };

   // check for cancelled operation
   if ((self.isCancelled))
   {
      self.error = [LKError errorWithTitle:@"LDAP Error" code:LKErrorCodeCancelled];
      ldap_unbind_ext_s(ld, NULL, NULL);
      return(NULL);
   };

   return(ld);
}


#pragma mark - C functions

int branches_sasl_interact(LDAP * ld, unsigned flags, void * defaults, void * sin)
{
   LKLdapAuthData  * ldap_inst;
   sasl_interact_t * interact;

   if (!(ld))
      return(LDAP_PARAM_ERROR);

   if (!(defaults))
      return(LDAP_PARAM_ERROR);

   if (!(sin))
      return(LDAP_PARAM_ERROR);

   switch(flags)
   {
      case LDAP_SASL_AUTOMATIC:
      case LDAP_SASL_INTERACTIVE:
      case LDAP_SASL_QUIET:
      default:
      break;
   };

   ldap_inst = defaults;

   for(interact = sin; (interact->id != SASL_CB_LIST_END); interact++)
   {
      interact->result = NULL;
      interact->len    = 0;
      switch(interact->id)
      {
         case SASL_CB_GETREALM:
            interact->result = ldap_inst->realm ? ldap_inst->realm : "";
            interact->len    = (unsigned)strlen( interact->result );
            break;
         case SASL_CB_AUTHNAME:
            interact->result = ldap_inst->authuser ? ldap_inst->authuser : "";
            interact->len    = (unsigned)strlen( interact->result );
            break;
         case SASL_CB_PASS:
            interact->result = ldap_inst->cred.bv_val ? ldap_inst->cred.bv_val : "";
            interact->len    = (unsigned)ldap_inst->cred.bv_len;
            break;
         case SASL_CB_USER:
            interact->result = ldap_inst->user ? ldap_inst->user : "";
            interact->len    = (unsigned)strlen( interact->result );
            break;
         case SASL_CB_NOECHOPROMPT:
            break;
         case SASL_CB_ECHOPROMPT:
            break;
         default:
            // I don't know how to process this.
            break;
      };
   };

   return(LDAP_SUCCESS);
}

@end
































