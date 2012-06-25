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
 *  LdapKit/LKErrorCategory.h private/hidden interface for LKError
 */
#import "LKError.h"

@interface LKError()

/// @name Object Management Methods
- (id) initErrorWithTitle:(NSString *)errorTitle;
- (id) initErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode;
- (id) initErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode diagnostics:(NSString *)diagnosticMessage;
- (id) initErrorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode ldap:(LDAP *)ld;
- (id) initErrorWithTitle:(NSString *)errorTitle ldap:(LDAP *)ld;
+ (id) errorWithTitle:(NSString *)errorTitle;
+ (id) errorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode;
+ (id) errorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode diagnostics:(NSString *)diagnosticMessage;
+ (id) errorWithTitle:(NSString *)errorTitle code:(NSInteger)errorCode ldap:(LDAP *)ld;
+ (id) errorWithTitle:(NSString *)errorTitle ldap:(LDAP *)ld;

/// @name Error operations
- (void) resetError;
- (void) resetErrorWithTitle:(NSString *)errorTitle;

/// @name error information
- (void) setErrorCode:(NSInteger)code;
- (void) setErrorTitle:(NSString *)title;
- (void) setErrorMessage:(NSString *)message;
- (void) setDiagnosticMessage:(NSString *)message;

@end
