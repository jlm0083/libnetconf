#
# Copyright (c) 2011 CESNET
#
# LICENSE TERMS
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
# 3. Neither the name of the Company nor the names of its contributors
#    may be used to endorse or promote products derived from this
#    software without specific prior written permission.
#
# ALTERNATIVELY, provided that this notice is retained in full, this
# product may be distributed under the terms of the GNU General Public
# License (GPL) version 2 or later, in which case the provisions
# of the GPL apply INSTEAD OF those given above.
#
# This software is provided ``as is'', and any express or implied
# warranties, including, but not limited to, the implied warranties of
# merchantability and fitness for a particular purpose are disclaimed.
# In no event shall the company or contributors be liable for any
# direct, indirect, incidental, special, exemplary, or consequential
# damages (including, but not limited to, procurement of substitute
# goods or services; loss of use, data, or profits; or business
# interruption) however caused and on any theory of liability, whether
# in contract, strict liability, or tort (including negligence or
# otherwise) arising in any way out of the use of this software, even
# if advised of the possibility of such damage.
#

NAME = libnetconf

# Various configurable paths (remember to edit Makefile.in, not Makefile)
srcdir = .
abs_srcdir = /home/vasko/Documents/libnetconf
prefix = /usr/local
exec_prefix = ${prefix}
datarootdir = ${prefix}/share
datadir = ${datarootdir}
bindir = ${exec_prefix}/bin
includedir = ${prefix}/include
libdir =  ${exec_prefix}/lib64
mandir = ${datarootdir}/man

VERSION = $(shell cut -f1 "$(srcdir)/VERSION" | tr -d '\n')
# version for soname:
ABICOMPAT_VER = $(shell echo $(VERSION) | cut -d. -f1,2)
RELEASE = 1

CC = gcc
LN_S = ln -s
DOXYGEN = doxygen
DOXYGEN_CONFIG = Doxyfile
DOXYGEN_DIR = $(shell cat $(DOXYGEN_CONFIG) | grep '^OUTPUT_DIRECTORY' | sed 's/.*=//')
RPMBUILD = rpmbuild
LDCONFIG = ldconfig
INSTALL = /usr/bin/install -c
INSTALL_PROGRAM = ${INSTALL}
INSTALL_DATA = ${INSTALL} -m 644
RPMDIR = RPMBUILD
NC_WORKINGDIR_PATH = $(DESTDIR)//var/lib/libnetconf/
SETBIT = 0
SETUSER = 
SETGROUP = 
IDGIT = "built from git $(shell git show --pretty=oneline | head -1 | cut -c -20)"
IDNOGIT = "released as version $(VERSION)"
LIBS = -lxml2 -lz -lm -ldl   -lssh2  -lrt -lutil -ldbus-1  
CFLAGS = -Wall -I/usr/include/libxml2  -g -DDEBUG -pthread -I/usr/include/dbus-1.0 -I/usr/lib64/dbus-1.0/include  
CPPFLAGS = -DNC_WORKINGDIR_PATH=\"$(NC_WORKINGDIR_PATH)\" -DSETBIT=$(SETBIT)  -DRCSID=\"$(IDGIT)\"

DBUS_CONFDIR = /etc/dbus-1/

SUBDIRS = 

INCLUDES= -I$(abs_srcdir)/src

ifeq "$(shell pwd)" "$(shell readlink -f $(srcdir))"
OBJDIR = .obj
else
OBJDIR = .

endif

SRCS =  src/callbacks.c \
	src/error.c \
	src/internal.c \
	src/compat.c \
	src/messages.c \
	src/session.c \
	src/ssh.c src/notifications.c \
	src/with_defaults.c \
	src/nacm.c \
	src/datastore.c \
	src/datastore/edit_config.c \
	src/datastore/empty/datastore_empty.c \
	src/datastore/file/datastore_file.c \
	src/transapi/transapi.c \
	src/transapi/yinparser.c \
	src/transapi/xmldiff.c

HDRS_PUBL_ROOT = headers/libnetconf.h \
		 headers/libnetconf_ssh.h \
		 headers/libnetconf_xml.h

HDRS_PUBL_SUBDIR = src/netconf.h \
	src/callbacks.h \
	src/callbacks_ssh.h \
	src/error.h \
	src/session.h \
	src/messages.h \
	src/messages_xml.h \
	src/ssh.h src/notifications.h src/notifications_xml.h \
	src/with_defaults.h \
	src/datastore.h \
	src/transapi/transapi.h \
	src/transapi/transapi_xml.h 
		
HDRS_PUBL = $(HDRS_PUBL_ROOT) $(HDRS_PUBL_SUBDIR)
SUBHEADERS_DIR = libnetconf

HDRS_PRIV = src/config.h.in \
	src/libnetconf.h \
	src/libnetconf_xml.h \
	src/libnetconf_ssh.h \
	src/callbacks.h \
	src/callbacks_ssh.h \
	src/error.h \
	src/messages.h \
	src/messages_internal.h \
	src/messages_xml.h \
	src/netconf.h \
	src/netconf_internal.h \
	src/session.h \
	src/ssh.h src/notifications.h src/notifications_xml.h \
	src/with_defaults.h \
	src/nacm.h \
	src/datastore.h \
	src/datastore/datastore_internal.h \
	src/datastore/edit_config.h \
	src/datastore/empty/datastore_empty.h \
	src/datastore/file/datastore_file.h \
	src/transapi/transapi_internal.h \
	src/transapi/yinparser.h \
	src/transapi/xmldiff.h

GENERATOR = src/transapi/generator/generator.py \

GENERATOR_FILES = src/transapi/generator/Makefile.in \
	src/transapi/generator/configure.in \
	src/transapi/generator/specfile.spec.in \
	src/transapi/generator/install-sh \
	src/transapi/generator/README

OBJS = $(SRCS:%.c=$(OBJDIR)/%.o)

all: $(NAME).a $(NAME).so $(SUBDIRS)

.PHONY: $(SUBDIRS)

$(SUBDIRS): $(NAME).a $(NAME).so
	$(MAKE) -C $@

$(NAME).a: $(OBJS)
	@rm -f $@
	ar rcs $@ $(OBJS)

$(NAME).so: $(OBJS)
	@rm -f $@;
	$(CC) -shared $(OBJS) $(LIBS) -Wl,-soname -Wl,$@.$(ABICOMPAT_VER) -o $@.$(VERSION);
	@[ ! -L $@.$(ABICOMPAT_VER) ] || rm -rf $@.$(ABICOMPAT_VER);
	$(LN_S) $@.$(VERSION) $@.$(ABICOMPAT_VER);
	@[ ! -L $@ ] || rm -rf $@;
	$(LN_S) $@.$(VERSION) $@;

$(OBJDIR)/%.o: %.c
	@[ -d $$(dirname $@) ] || \
		(mkdir -p $$(dirname $@))
	$(CC) $(CFLAGS) $(CPPFLAGS) $(INCLUDES) $(DBG) -fPIC -c $< -o $@

.PHONY: doc
doc: $(DOXYGEN_CONFIG) $(HDRS_PRIV)
	@if [ "$(DOXYGEN)" != "no" ]; then \
		[ -d $(DOXYGEN_DIR) ] || mkdir -p $(DOXYGEN_DIR); \
		$(DOXYGEN); \
	else \
		echo "Missing doxygen!"; \
	fi;

.PHONY: dist
dist: $(NAME).spec tarball rpm

.PHONY: tarball
tarball: $(SRCS) $(HEADERS)
	@rm -rf $(NAME)-$(VERSION);
	@mkdir $(NAME)-$(VERSION);
	@for i in $(SUBDIRS) ; do $(MAKE) -C $$i tarball-prepare; done; \
	for i in $(SRCS) $(HDRS_PUBL) $(HDRS_PRIV) $(GENERATOR) $(GENERATOR_FILES) configure.in configure \
	    headers/libnetconf.h.in headers/libnetconf_xml.h.in \
	    Makefile.in VERSION $(NAME).spec.in $(NAME).pc.in \
	    install-sh config.sub config.guess Doxyfile.in doc/img/*.png models/*; do \
	    [ -d $(NAME)-$(VERSION)/$$(dirname $$i) ] || (mkdir -p $(NAME)-$(VERSION)/$$(dirname $$i)); \
		cp $$i $(NAME)-$(VERSION)/$$i; \
	done; \
	[ -z "src/notifications.c" ] || cp libnetconf.notifications.conf $(NAME)-$(VERSION)/ ;
	@rm -rf $(RPMDIR)/SOURCES/; \
	mkdir -p $(RPMDIR)/SOURCES/; \
	tar -c -z -f $(RPMDIR)/SOURCES/$(NAME)-$(VERSION)-$(RELEASE).tar.gz \
	    $(NAME)-$(VERSION); \
	rm -rf $(NAME)-$(VERSION);

.PHONY: rpm
rpm: tarball
	if [ "$(RPMBUILD)" != "no" ]; then \
		mkdir -p $(RPMDIR)/BUILD $(RPMDIR)/RPMS $(RPMDIR)/SRPMS; \
		$(RPMBUILD) -ba $(NAME).spec \
			--define "_topdir `pwd`/$(RPMDIR)"; \
	else \
		echo "Missing rpmbuild"; \
		exit 1; \
	fi

.PHONY: install
install: all install-devel install-doc install-generator
	[ -d $(DESTDIR)/$(libdir) ] || \
	    (mkdir -p $(DESTDIR)/$(libdir); chmod 755 $(DESTDIR)/$(libdir))
	$(INSTALL_PROGRAM) $(NAME).so.$(VERSION) $(DESTDIR)/$(libdir)/;
	@[ ! -L $(DESTDIR)/$(libdir)/$(NAME).so.$(ABICOMPAT_VER) ] || \
	    rm -rf $(DESTDIR)/$(libdir)/$(NAME).so.$(ABICOMPAT_VER);
	$(LN_S) $(NAME).so.$(VERSION) $(DESTDIR)/$(libdir)/$(NAME).so.$(ABICOMPAT_VER);
	[ -d "$(NC_WORKINGDIR_PATH)" ] || \
		mkdir -p $(NC_WORKINGDIR_PATH)
	chmod 700 $(NC_WORKINGDIR_PATH)
	if test "$$(($(SETBIT) & 1))" = "1"; then \
		if test -n "$(SETUSER)"; then \
			chown $(SETUSER) $(NC_WORKINGDIR_PATH) || \
				echo "WARNING: invalid group $(SETUSER)"; \
		fi; \
	fi; \
	if test "$$(($(SETBIT) & 2))" = "2"; then \
		chmod g+rwx $(NC_WORKINGDIR_PATH); \
		if test -n "$(SETGROUP)"; then \
			chown :$(SETGROUP) $(NC_WORKINGDIR_PATH) || \
				echo "WARNING: invalid group $(SETGROUP)"; \
		fi; \
	fi; \
	if test "$(SETBIT)" = "0"; then \
		chmod a+rwx $(NC_WORKINGDIR_PATH); \
	fi;
	for i in $(SUBDIRS) ; do \
		$(MAKE) DESTDIR=$(patsubst .%,$(abs_srcdir)/.%,$(DESTDIR)) -C $$i install \
		|| exit 1; \
	done;
	[ -d $(DESTDIR)/$(DBUS_CONFDIR)/system.d/ ] || (mkdir -p $(DESTDIR)/$(DBUS_CONFDIR)/system.d/);
	[ -z "src/notifications.c" ] || $(INSTALL_DATA) $(srcdir)/libnetconf.notifications.conf $(DESTDIR)/$(DBUS_CONFDIR)/system.d/

.PHONY: install-generator
install-generator:
	@[ -d $(DESTDIR)/$(bindir)/$(NAME) ] || \
		(mkdir -p $(DESTDIR)/$(bindir)/$(NAME); chmod 755 $(DESTDIR)/$(bindir)/$(NAME))
	$(INSTALL_PROGRAM) $(GENERATOR) $(DESTDIR)/$(bindir)/lnc-creator
	@[ -d $(DESTDIR)/$(datadir)/$(NAME)/templates ] || \
		(mkdir -p $(DESTDIR)/$(datadir)/$(NAME)/templates; chmod 755 $(DESTDIR)/$(datadir)/$(NAME)/templates)
	for i in $(GENERATOR_FILES); do \
		$(INSTALL_DATA) $$i $(DESTDIR)/$(datadir)/$(NAME)/templates/$$(basename $$i); \
	done

.PHONY: install-devel
install-devel:
	@[ -d $(DESTDIR)/$(libdir) ] || \
	    (mkdir -p $(DESTDIR)/$(libdir); chmod 755 $(DESTDIR)/$(libdir)); \
	[ -d $(DESTDIR)/$(libdir)/pkgconfig ] || \
	    (mkdir -p $(DESTDIR)/$(libdir)/pkgconfig; chmod 755 $(DESTDIR)/$(libdir)/pkgconfig); \
	[ -d $(DESTDIR)/$(includedir) ] || \
	    (mkdir -p $(DESTDIR)/$(includedir); chmod 755 $(DESTDIR)/$(includedir)); \
	[ -d $(DESTDIR)/$(includedir)/$(SUBHEADERS_DIR) ] || \
		(mkdir -p $(DESTDIR)/$(includedir)/$(SUBHEADERS_DIR));
	$(INSTALL_PROGRAM) $(NAME).a $(DESTDIR)/$(libdir)/;
	@[ ! -L $(DESTDIR)/$(libdir)/$(NAME).so ] || \
		rm -rf $(DESTDIR)/$(libdir)/$(NAME).so;	
	$(LN_S) $(NAME).so.$(VERSION) $(DESTDIR)/$(libdir)/$(NAME).so; \
	for i in $(HDRS_PUBL_ROOT); do \
		$(INSTALL_DATA) $(srcdir)/$$i $(DESTDIR)/$(includedir)/$$(basename $$i); \
	done; \
	for i in $(HDRS_PUBL_SUBDIR); do \
		$(INSTALL_DATA) $(srcdir)/$$i $(DESTDIR)/$(includedir)/$(SUBHEADERS_DIR)/$$(basename $$i); \
	done; \
	$(INSTALL_DATA) $(NAME).pc $(DESTDIR)/$(libdir)/pkgconfig/$(NAME).pc; \

.PHONY: install-doc
install-doc:
	[ -d $(DESTDIR)/$(datadir)/$(NAME)/doxygen ] || \
		(mkdir -p $(DESTDIR)/$(datadir)/$(NAME)/doxygen; \
		chmod -R 755 $(DESTDIR)/$(datadir)/$(NAME))
	cp -r $(DOXYGEN_DIR)/* $(DESTDIR)/$(datadir)/$(NAME)/doxygen/;

.PHONY: uninstall
uninstall: uninstall-devel uninstall-doc
	rm -f $(DESTDIR)/$(libdir)/$(NAME).so.$(VERSION)
	rm -f $(DESTDIR)/$(libdir)/$(NAME).so.$(ABICOMPAT_VER)
	for i in $(SUBDIRS) ; do \
		$(MAKE) DESTDIR=$(patsubst .%,$(abs_srcdir)/.%,$(DESTDIR)) -C $$i uninstall \
		|| exit 1; \
	done
	[ -z "src/notifications.c" ] || rm -f $(DESTDIR)/$(DBUS_CONFDIR)/system.d/libnetconf.notifications.conf

.PHONY: uninstall-devel
uninstall-devel:
	rm -f $(DESTDIR)/$(libdir)/$(NAME).a;
	@rm -f $(DESTDIR)/$(libdir)/$(NAME).so*; \
	for i in $(HDRS_PUBL_ROOT); do \
		rm -f $(DESTDIR)/$(includedir)/$$(basename $$i); \
	done; \
	for i in $(HDRS_PUBL_SUBDIR); do \
		rm -f $(DESTDIR)/$(includedir)/$(SUBHEADERS_DIR)/$$(basename $$i); \
	done; \
	rm $(DESTDIR)/$(libdir)/pkgconfig/$(NAME).pc; \

.PHONY: uninstall-doc
uninstall-doc:
	rm -rf $(DESTDIR)/$(datadir)/$(NAME)/doxygen;

.PHONY: clean clean-all clean-doc clean-rpm
clean:
	for i in $(SUBDIRS) ; do $(MAKE) -C $$i clean ; done
	rm -rf *.a *.so* .obj $(OBJS)

clean-all: clean clean-doc clean-rpm

clean-doc:
	rm -rf $(DOXYGEN_DIR);

clean-rpm:
	rm -rf $(RPMDIR)
