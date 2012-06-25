#
#   LDAP Kit
#   Copyright (c) 2012, Bindle Binaries
#
#   @BINDLE_BINARIES_BSD_LICENSE_START@
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are
#   met:
# 
#      * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#      * Redistributions in binary form must reproduce the above copyright
#        notice, this list of conditions and the following disclaimer in the
#        documentation and/or other materials provided with the distribution.
#      * Neither the name of Bindle Binaries nor the
#        names of its contributors may be used to endorse or promote products
#        derived from this software without specific prior written permission.
# 
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
#   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
#   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL BINDLE BINARIES BE LIABLE FOR
#   ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
#   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#   OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
#   SUCH DAMAGE.
#
#   @BINDLE_BINARIES_BSD_LICENSE_END@
#
#   Makefile - Generates Xcode Documentation Sets from comments in source code
#

GITURL ?= syzdek@scm.office.bindlebinaries.com:/pub/scm/com.bindlebinaries/LdapKit.git

run_appledoc =	appledoc \
	--output docs/appledoc/ \
	--index-desc docs/appledoc.txt \
	--project-name "LDAP Kit" \
	--project-version "`git describe  --long --abbrev=7 |sed -e 's/v//g' -e 's/-/./g'`" \
	--project-company "Bindle Binaries" \
	--company-id com.bindlebinaries \
	--create-html \
	--verbose 2 \
	--keep-intermediate-files \
	--no-repeat-first-par \
	--docset-platform-family iphoneos \
	--include "./docs/appledoc/tmp/LDAP Kit License-template.txt" \
	--include "./docs/appledoc/tmp/LDAP Kit Project Information-template.txt" \
	--include "./docs/appledoc/tmp/LDAP Kit To Do List-template.txt" \
	LdapKit

all: docset

.PHONY: docset gh-pages

docset:
	@PATH=${PATH}:/usr/local/bin which appledoc > /dev/null 2>&1 || \
	{ \
	   MSG="Appledoc (https://github.com/tomaz/appledoc) must"; \
	   echo "$${MSG} be installed before the LdapKit docset can be built."; \
	   exit 1; \
	}
	@rm -Rf ./docs/appledoc/tmp/*
	@mkdir -p ./docs/appledoc/tmp/project/
	grep -v '@\([[:alnum:]]\{1,\}_[[:alnum:]]\{1,\}\)\{1,\}@' LICENSE \
	    > "./docs/appledoc/tmp/LDAP Kit License-template.txt"
	cp README \
	    "./docs/appledoc/tmp/LDAP Kit Project Information-template.txt"
	cp TODO \
	    "./docs/appledoc/tmp/LDAP Kit To Do List-template.txt"
	PATH=${PATH}:/usr/local/bin ${run_appledoc}

gh-pages: docset
	test -d ./docs/github/ || git clone -b gh-pages $(GITURL) ./docs/github
	cd ./docs/github && git fetch origin
	cd ./docs/github && git reset --hard origin/gh-pages
	rsync -rav --delete --exclude=.git/ ./docs/appledoc/html/ ./docs/github
	VER=`git describe --long --abbrev=7 |sed -e 's/-/./g'`; \
	   cd ./docs/github && git commit -m "Generating documentation from $$VER" .

clean:
	rm -Rf ./docs/appledoc/*

