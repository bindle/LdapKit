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
#import "LKMessage.h"

#import <signal.h>
#import <sasl/sasl.h>
#include <sys/socket.h>

#import "LKEntry.h"
#import "LKError.h"
#import "LKErrorCategory.h"
#import "LKLdap.h"


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

/// @name copies LDAP information
- (void) copySessionInformation;

/// @name LDAP tasks
- (BOOL) bind;
- (BOOL) search;
- (BOOL) testConnection;
- (BOOL) unbind;

/// @name LDAP subtasks
- (LDAP *) bindAuthenticate:(LDAP *)ld;
- (LDAP *) bindFinish:(LDAP *)ld;
- (LDAP *) bindInitialize;
- (LDAP *) bindStartTLS:(LDAP *)ld;
- (BOOL)   parseResult:(LDAPMessage *)res;
- (LDAPMessage *) resultWithMessageID:(int)msgid
                  resultEntries:(NSMutableArray *)resultEntries;
- (int)  searchBaseDN:(NSString *)dn scope:(LKLdapSearchScope)scope
         filter:(NSString *)filter attributes:(char **)attrs
         attributesOnly:(BOOL)attributesOnly;

/// @name memory methods
- (char **) createAttributeList:(NSArray *)attributes;
- (void) freeAttributeList:(char ***)attributesp;

/// @name C functions
int branches_sasl_interact(LDAP * ld, unsigned flags, void * defaults, void * sin);

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
   [session release];
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

   // search information
   [searchDnList     release];
   [searchFilter     release];
   [searchAttributes release];

   // results
   [referrals release];

   // client information
   [object release];

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


- (id) initBindWithSession:(LKLdap *)data
{
   // initialize super
   if ((self = [super init]) == nil)
      return(self);

   // state information
   session     = [data retain];
   error       = [[LKError alloc] init];
   messageType = LKLdapMessageTypeBind;

   // copies session data to local ivars
   [self copySessionInformation];

   return(self);
}


- (id) initSearchWithSession:(LKLdap *)data baseDN:(NSString *)dn
       scope:(LKLdapSearchScope)scope filter:(NSString *)filter
       attributes:(NSArray *)attributes attributesOnly:(BOOL)attributesOnly
{
   NSArray * dnList;
   dnList = [[NSArray alloc] initWithObjects:dn, nil];
   self = [self initSearchWithSession:data baseDnList:dnList scope:scope
      filter:filter attributes:attributes attributesOnly:attributesOnly];
   [dnList release];
   return(self);
}

- (id) initSearchWithSession:(LKLdap *)data baseDnList:(NSArray *)dnList
       scope:(LKLdapSearchScope)scope filter:(NSString *)filter
       attributes:(NSArray *)attributes attributesOnly:(BOOL)attributesOnly
{
   // initialize super
   if ((self = [super init]) == nil)
      return(self);

   // state information
   session     = [data retain];
   error       = [[LKError alloc] init];
   messageType = LKLdapMessageTypeSearch;

   // search information
   searchDnList         = [[NSArray alloc]  initWithArray:dnList copyItems:YES];
   searchFilter         = [[NSString alloc] initWithString:filter];
   searchAttributes     = [[NSArray alloc]  initWithArray:attributes copyItems:YES];
   searchAttributesOnly = attributesOnly;
   searchScope          = scope;

   return(self);
}


- (id) initUnbindWithSession:(LKLdap *)data
{
   // initialize super
   if ((self = [super init]) == nil)
      return(self);

   // state information
   session     = [data retain];
   error       = [[LKError alloc] init];
   messageType = LKLdapMessageTypeUnbind;

   return(self);
}


#pragma mark - Getter/Setter methods

- (NSArray *) entries
{
   @synchronized(self)
   {
      if (!(entries))
         return(nil);
      if (([self isFinished]))
         return([[entries retain] autorelease]);
      return([NSArray arrayWithArray:entries]);
   };
}


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


- (NSArray *) matchedDNs
{
   @synchronized(self)
   {
      if (!(matchedDNs))
         return(nil);
      if (([self isFinished]))
         return([[matchedDNs retain] autorelease]);
      return([NSArray arrayWithArray:matchedDNs]);
   };
}


- (NSArray *) referrals
{
   @synchronized(self)
   {
      if (!(referrals))
         return(nil);
      if (([self isFinished]))
         return([[referrals retain] autorelease]);
      return([NSArray arrayWithArray:referrals]);
   };
}


#pragma mark - copies LDAP information

- (void) copySessionInformation
{
   NSAutoreleasePool * pool;

   pool = [[NSAutoreleasePool alloc] init];

   // server information
   [ldapURI release];
   ldapURI             = [session.ldapURI retain];
   ldapScheme          = session.ldapScheme;
   ldapProtocolVersion = session.ldapProtocolVersion;

   // encryption information
   [ldapCACertificateFile release];
   ldapEncryptionScheme  = session.ldapEncryptionScheme;
   ldapCACertificateFile = [session.ldapCACertificateFile retain];

   // timeout information
   ldapSizeLimit      = session.ldapSizeLimit;
   ldapSearchTimeout  = session.ldapSearchTimeout;
   ldapNetworkTimeout = session.ldapNetworkTimeout;

   // authentication information
   [ldapBindWho           release];
   [ldapBindCredentials   release];
   [ldapBindSaslMechanism release];
   [ldapBindSaslRealm     release];
   ldapBindMethod        = session.ldapBindMethod;
   ldapBindWho           = [session.ldapBindWho           retain];
   ldapBindCredentials   = [session.ldapBindCredentials   retain];
   ldapBindSaslMechanism = [session.ldapBindSaslMechanism retain];;
   ldapBindSaslRealm     = [session.ldapBindSaslRealm     retain];

   [pool release];

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
      case LKLdapMessageTypeBind:
      [self bind];
      break;

      case LKLdapMessageTypeSearch:
      [self search];
      self.error.errorTitle = @"LDAP Search";
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

- (BOOL) bind
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

   // copies data required to BIND to LDAP
   [self copySessionInformation];

   // obtain the lock for LDAP handle
   @synchronized(session)
   {
      // initialize LDAP handle
      if ((ld = [self bindInitialize]) == NULL)
         return(error.isSuccessful);

      // starts TLS session
      if ((ld = [self bindStartTLS:ld]) == NULL)
         return(error.isSuccessful);

      // binds to LDAP
      if ((ld = [self bindAuthenticate:ld]) == NULL)
         return(error.isSuccessful);

      // finish configuring connection
      if ((ld = [self bindFinish:ld]) == NULL)
         return(error.isSuccessful);

      // saves LDAP handle
      session.ld          = ld;
      session.isConnected = YES;
   };

   return(error.isSuccessful);
}


- (BOOL) search
{
   NSString        * baseDN;
   char           ** attrs;
   int               msgid;
   BOOL              isConnected;
   LDAPMessage     * res;

   // reset errors
   [error resetErrorWithTitle:@"LDAP Search"];

   // verifies session is connected to LDAP
   isConnected = [self bind];
   if (!(isConnected))
      return(error.isSuccessful);
   if ((self.isCancelled))
   {
      error.errorCode = LKErrorCodeCancelled;
      return(error.isSuccessful);
   };

   // allocates an array to copy UTF8 strings from searchAttributes
   attrs = [self createAttributeList:searchAttributes];

   // loops through DN list
   for(baseDN in searchDnList)
   {
      // initiates search
      msgid = [self searchBaseDN:baseDN scope:searchScope filter:searchFilter
                     attributes:attrs attributesOnly:searchAttributesOnly];
      if (!(error.isSuccessful))
      {
         [self freeAttributeList:(&attrs)];
         return(error.isSuccessful);
      };

      // verifies operation has not been cancelled
      if ((self.isCancelled))
      {
         @synchronized(session)
         {
            if ((session.ld))
               ldap_abandon_ext(session.ld, msgid, NULL, NULL);
         };
         error.errorCode = LKErrorCodeCancelled;
         [self freeAttributeList:(&attrs)];
         return(error.isSuccessful);
      };

      // waits for result
      if ((res = [self resultWithMessageID:msgid resultEntries:nil]) == NULL)
      {
         [self freeAttributeList:(&attrs)];
         return(error.isSuccessful);
      };

      // parses result
      if (!([self parseResult:res]))
      {
         [self freeAttributeList:(&attrs)];
         return(error.isSuccessful);
      };
   };

   // frees memory
   [self freeAttributeList:(&attrs)];

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
   @synchronized(session)
   {
      // assume session is correct if reporting not connected
      if (!(session.isConnected))
      {
      isConnected = NO;
         if ((session.ld))
            ldap_unbind_ext_s(session.ld, NULL, NULL);
         session.ld  = NULL;
      }

      // verify LDAP handle exists
      else if (!(session.ld))
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
            session.ld,                 // LDAP            * ld
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
   };

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

   // clears LDAP information
   @synchronized(session)
   {
      if ((session.ld))
         ldap_unbind_ext(session.ld, NULL, NULL);
      session.ld          = NULL;
      session.isConnected = NO;
   };

   return(self.error.isSuccessful);
}


#pragma mark - LDAP subtasks

- (LDAP *) bindAuthenticate:(LDAP *)ld
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


- (LDAP *) bindFinish:(LDAP *)ld
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


- (LDAP *) bindInitialize
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


- (LDAP *) bindStartTLS:(LDAP *)ld
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


- (BOOL) parseResult:(LDAPMessage *)res
{
   int    err;
   char            * dn;
   char            * errmsg;
   char           ** refs;
   size_t x;

   // checks for error
   @synchronized(session)
   {
      ldap_parse_result(session.ld, res, &err, &dn, &errmsg, &refs, NULL, 1);
   };

   // retrieves matched DN
   if ((dn))
   {
      @synchronized(self)
      {
         if (!(matchedDNs))
            matchedDNs = [[NSMutableArray alloc] initWithCapacity:1];
         [matchedDNs addObject:[NSString stringWithUTF8String:dn]];
      };
      ldap_memfree(dn);
   };

   // retrieves referrals
   if ((refs))
   {
      @synchronized(self)
      {
         if (!(referrals))
            referrals = [[NSMutableArray alloc] initWithCapacity:1];
         for(x = 0; refs[x]; x++)
            [referrals addObject:[NSString stringWithUTF8String:refs[x]]];
      };
      ldap_memvfree((void **)refs);
   };

   // processes error
   if (err != LDAP_SUCCESS)
   {
      error.errorTitle       = @"LDAP Result";
      error.errorCode        = err;
      if ((errmsg))
         error.errorMessage = [NSString stringWithUTF8String:errmsg];
   };
   ldap_memfree(errmsg);

   return(error.isSuccessful);
}


- (LDAPMessage *) resultWithMessageID:(int)msgid
                  resultEntries:(NSMutableArray *)results
{
   int               msgtype;
   struct timeval    timeout;
   LDAPMessage     * res;
   int               err;
   char            * dn;
   char            * attribute;
   BerElement      * ber;
   BerValue       ** vals;
   LKEntry         * entry;

   // initializes ivars
   res = NULL;
   if ((results))
      [results removeAllObjects];

   // sets limits
   timeout.tv_sec    = 0;
   timeout.tv_usec   = 250000; // 0.25 seconds

   // loops through results
   msgtype = LDAP_RES_SEARCH_ENTRY;
   while(msgtype == LDAP_RES_SEARCH_ENTRY)
   {
      // slight pause to prevent race condition
      usleep(250000);

      // verifies operation has not been cancelled
      if ((self.isCancelled))
      {
         @synchronized(session)
         {
            if ((session.ld))
               ldap_abandon_ext(session.ld, msgid, NULL, NULL);
         };
         error.errorCode = LKErrorCodeCancelled;
         return(NULL);
      };

      // retrieves result
      @synchronized(session)
      {
         msgtype = ldap_result(session.ld, msgid, 0, &timeout, &res);
         switch(msgtype)
         {
            // encountered an error
            case -1:
            ldap_get_option(session.ld, LDAP_OPT_RESULT_CODE, &err);
            error.errorTitle = @"LDAP Result";
            error.errorCode  = err;
            return(NULL);

            // timeout was exceeded
            case 0:
            break;

            // result was returned
            default:
            break;
         };
      };

      // determines result type
      msgtype = ldap_msgtype(res);
      if (msgtype != LDAP_RES_SEARCH_ENTRY)
         continue;

      // processes entry
      @synchronized(session)
      {
         // creates entry with DN
         dn = ldap_get_dn(session.ld, res);
         entry = [[[LKEntry alloc] initWithDn:dn] autorelease];
         ldap_memfree(dn);

         attribute = ldap_first_attribute(session.ld, res, &ber);
         while((attribute))
         {
            vals = ldap_get_values_len(session.ld, res, attribute);
            [entry setBerValues:vals forAttribute:attribute];
            ldap_value_free_len(vals);
            attribute = ldap_next_attribute(session.ld, res, ber);
         };
         ber_free(ber, 0);

         // stores entry for later use
         if ((results))
            [results addObject:entry];
         @synchronized(self)
         {
            if (!(entries))
               entries = [[NSMutableArray alloc] initWithCapacity:1];
            [entries addObject:entry];
         };
      };

      // frees result
      ldap_memfree(res);
   };

   return(res);
}


- (int)  searchBaseDN:(NSString *)dn scope:(LKLdapSearchScope)scope
         filter:(NSString *)filter attributes:(char **)attrs
         attributesOnly:(BOOL)attributesOnly
{
   struct timeval       timeout;
   struct timeval     * timeoutp;
   int                  msgid;

   // sets limits
   ldapSizeLimit   = session.ldapSizeLimit;
   timeout.tv_sec  = session.ldapSearchTimeout;
   timeout.tv_usec = 0;
   timeoutp        = &timeout;
   if (!(timeout.tv_sec))
      timeoutp = NULL;

   @synchronized(session)
   {
      // checks session
      if (!(session.ld))
      {
         error.errorCode = LKErrorCodeNotConnected;
         return(-1);
      };

      // initiates search
      error.errorCode = ldap_search_ext(
         session.ld,                      // LDAP            * ld
         [dn UTF8String],                 // char            * base
         scope,                           // int               scope
         [filter UTF8String],             // char            * filter
         attrs,                           // char            * attrs[]
         (int)attributesOnly,             // int               attrsonly
         NULL,                            // LDAPControl    ** serverctrls
         NULL,                            // LDAPControl    ** clientctrls
         timeoutp,                        // struct timeval  * timeout
         ldapSizeLimit,                   // int               sizelimit
         &msgid                           // int             * msgidp
      );
   };

   return(msgid);
}


#pragma mark - memory methods

- (char **) createAttributeList:(NSArray *)attributes
{
   NSString           * attribute;
   size_t               len;
   size_t               x;
   size_t               y;
   char              ** attrs;

   // allocates an array to copy UTF8 strings from searchAttributes
   attrs = NULL;
   if (([attributes count]))
   {
      len = [attributes count];
      if (!(attrs = malloc(sizeof(char *)*(len+1))))
         return(NULL);
      y = 0;
      for(x = 0; x < len; x++)
      {
         attribute = [attributes objectAtIndex:x];
         if (([attribute isKindOfClass:[NSString class]]))
         {
            attrs[y] = strdup([attribute UTF8String]);
            y++;
         };
      };
      attrs[y] = NULL;
   };

   return(attrs);
}


- (void) freeAttributeList:(char ***)attributesp
{
   size_t x;
   if (!(*attributesp))
      return;
   for(x = 0; (*attributesp)[x]; x++)
      free((*attributesp)[x]);
   free(*attributesp);
   *attributesp = NULL;
   return;
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
































