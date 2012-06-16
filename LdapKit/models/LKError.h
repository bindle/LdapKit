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
 *  LKError contains status information about LDAP operations and tasks.
 */

#import <Foundation/Foundation.h>
#import <LdapKit/LKEnumerations.h>


#pragma mark LDAP error type
enum ldap_kit_ldap_error_type
{
   LKLdapErrorTypeInternal           = 0x01,
   LKLdapErrorTypeLDAP               = 0x02
};
typedef enum ldap_kit_ldap_error_type LKLdapErrorType;

enum ldap_kit_ldap_error_code
{
   LKErrorCodeSuccess        =   0,   // operation was successful
   LKErrorCodeUnknown        =  -1,   // unknown error code
   LKErrorCodeCancelled      =  -2,   // operation was cancelled
   LKErrorCodeNotConnected   =  -3,   // not connected to server
   LKErrorCodeMemory         =  -4,   // out of memory
};
typedef enum ldap_kit_ldap_error_code LKErrorCode;


@interface LKError : NSObject
{
   // error information
   LKLdapErrorType    _errorType;
   NSInteger          _errorCode;
   NSString         * _errorTitle;
   NSString         * _errorMessage;
   NSString         * _diagnosticMessage;
};

/// @name error information
@property (atomic, readonly)    LKLdapErrorType    errorType;
@property (atomic, readonly)    NSInteger          errorCode;
@property (nonatomic, readonly) NSString         * errorTitle;
@property (nonatomic, readonly) NSString         * errorMessage;
@property (nonatomic, readonly) NSString         * diagnosticMessage;

/// @name derived results
@property (nonatomic, readonly) BOOL               isSuccessful;

/// @name Error strings
- (NSString *) messageForCode:(NSInteger)errorCode;
+ (NSString *) messageForCode:(NSInteger)errorCode;

@end
