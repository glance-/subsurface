NAME = subsurface
CAPITALIZED_NAME = Subsurface
TARGET = $(NAME)

VERSION=3.1.1

CC=gcc
CFLAGS=-Wall -Wno-pointer-sign -g $(CLCFLAGS) -DGSEAL_ENABLE
INSTALL=install
PKGCONFIG=pkg-config
XML2CONFIG=xml2-config
XSLCONFIG=xslt-config

# these locations seem to work for SuSE and Fedora
# prefix = $(HOME)
prefix = $(DESTDIR)/usr
BINDIR = $(prefix)/bin
DATADIR = $(prefix)/share
DESKTOPDIR = $(DATADIR)/applications
ICONPATH = $(DATADIR)/icons/hicolor
ICONDIR = $(ICONPATH)/scalable/apps
MANDIR = $(DATADIR)/man/man1
XSLTDIR = $(DATADIR)/$(NAME)/xslt
gtk_update_icon_cache = gtk-update-icon-cache -f -t $(ICONPATH)

ICONFILE = $(NAME)-icon.svg
DESKTOPFILE = $(NAME).desktop
MANFILES = $(NAME).1
XSLTFILES = xslt/*.xslt xslt/*.xsl

VERSION_FILE = version.h
# There's only one line in $(VERSION_FILE); use the shell builtin `read'
STORED_VERSION_STRING = \
	$(subst ",,$(shell [ ! -r $(VERSION_FILE) ] || \
			   read ignore ignore v <$(VERSION_FILE) && echo $$v))
#" workaround editor syntax highlighting quirk

UNAME := $(shell $(CC) -dumpmachine 2>&1 | grep -E -o "linux|darwin|win|gnu|kfreebsd")
GET_VERSION = ./scripts/get-version
VERSION_STRING := $(shell [ -d .git ] && $(GET_VERSION) linux || \
			echo "v$(VERSION)")
# Mac Info.plist style with three numbers 1.2.3
CFBUNDLEVERSION_STRING := $(shell [ -d .git ] && \
				$(GET_VERSION) darwin $(VERSION_STRING) || \
				echo "$(VERSION).0")
# Windows .nsi style with four numbers 1.2.3.4
PRODVERSION_STRING := $(shell [ -d .git ] && \
				$(GET_VERSION) win $(VERSION_STRING) || \
				echo "$(VERSION).0.0")

# 'pretty' output (easy to spot warnings) by default
# 'verbose' output (all the details) by calling with "make V=1"
ifeq ($(V),1)
	PRETTYECHO=true
	COMPILE_PREFIX=
else
	PRETTYECHO=echo
	COMPILE_PREFIX=@
endif

# find libdivecomputer
# First deal with the cross compile environment and with Mac.
# For the native case, Linus doesn't want to trust pkg-config given
# how young libdivecomputer still is - so we check the typical
# subdirectories of /usr/local and /usr and then we give up. You can
# override by simply setting it here
#
ifeq ($(CC), i686-w64-mingw32-gcc)
# ok, we are cross building for Windows
	LIBDIVECOMPUTERINCLUDES = $(shell $(PKGCONFIG) --cflags libdivecomputer)
	LIBDIVECOMPUTERARCHIVE = $(shell $(PKGCONFIG) --libs libdivecomputer)
	LIBGNUTLS = $(shell $(PKGCONFIG) --libs gnutls-extra) $(shell $(PKGCONFIG) --libs p11-kit-1)
	RESFILE = packaging/windows/$(NAME).res
	LDFLAGS += -Wl,-subsystem,windows
	LIBWINSOCK = -lwsock32
	TARGET = $(NAME).exe
else ifeq ($(UNAME), darwin)
	LIBDIVECOMPUTERINCLUDES = $(shell $(PKGCONFIG) --cflags libdivecomputer)
	LIBDIVECOMPUTERARCHIVE = $(shell $(PKGCONFIG) --libs libdivecomputer)
else ifeq ($(shell $(PKGCONFIG) --exists libdivecomputer; echo $$?),0)
	LIBDIVECOMPUTERINCLUDES = $(shell $(PKGCONFIG) --cflags libdivecomputer)
	LIBDIVECOMPUTERARCHIVE = $(shell $(PKGCONFIG) --libs libdivecomputer)
else
libdc-local := $(wildcard /usr/local/lib/libdivecomputer.a)
libdc-local64 := $(wildcard /usr/local/lib64/libdivecomputer.a)
libdc-usr := $(wildcard /usr/lib/libdivecomputer.a)
libdc-usr64 := $(wildcard /usr/lib64/libdivecomputer.a)

LIBDCDEVEL=1

ifneq ($(LIBDCDEVEL),)
	LIBDIVECOMPUTERDIR = ../libdivecomputer
	LIBDIVECOMPUTERINCLUDES = -I$(LIBDIVECOMPUTERDIR)/include
	LIBDIVECOMPUTERARCHIVE = $(LIBDIVECOMPUTERDIR)/src/.libs/libdivecomputer.a
else ifneq ($(strip $(libdc-local)),)
	LIBDIVECOMPUTERDIR = /usr/local
	LIBDIVECOMPUTERINCLUDES = -I$(LIBDIVECOMPUTERDIR)/include
	LIBDIVECOMPUTERARCHIVE = $(LIBDIVECOMPUTERDIR)/lib/libdivecomputer.a
else ifneq ($(strip $(libdc-local64)),)
	LIBDIVECOMPUTERDIR = /usr/local
	LIBDIVECOMPUTERINCLUDES = -I$(LIBDIVECOMPUTERDIR)/include
	LIBDIVECOMPUTERARCHIVE = $(LIBDIVECOMPUTERDIR)/lib64/libdivecomputer.a
else ifneq ($(strip $(libdc-usr)),)
	LIBDIVECOMPUTERDIR = /usr
	LIBDIVECOMPUTERINCLUDES = -I$(LIBDIVECOMPUTERDIR)/include
	LIBDIVECOMPUTERARCHIVE = $(LIBDIVECOMPUTERDIR)/lib/libdivecomputer.a
else ifneq ($(strip $(libdc-usr64)),)
	LIBDIVECOMPUTERDIR = /usr
	LIBDIVECOMPUTERINCLUDES = -I$(LIBDIVECOMPUTERDIR)/include
	LIBDIVECOMPUTERARCHIVE = $(LIBDIVECOMPUTERDIR)/lib64/libdivecomputer.a
else
$(error Cannot find libdivecomputer - please edit Makefile)
endif
endif

# Libusb-1.0 is only required if libdivecomputer was built with it.
# And libdivecomputer is only built with it if libusb-1.0 is
# installed. So get libusb if it exists, but don't complain
# about it if it doesn't.
LIBUSB = $(shell $(PKGCONFIG) --libs libusb-1.0 2> /dev/null)

LIBGTK = $(shell $(PKGCONFIG) --libs gtk+-3.0 glib-2.0)
LIBDIVECOMPUTERCFLAGS = $(LIBDIVECOMPUTERINCLUDES)
LIBDIVECOMPUTER = $(LIBDIVECOMPUTERARCHIVE) $(LIBUSB)

LIBXML2 = $(shell $(XML2CONFIG) --libs)
LIBXSLT = $(shell $(XSLCONFIG) --libs)
XML2CFLAGS = $(shell $(XML2CONFIG) --cflags)
GLIB2CFLAGS = $(shell $(PKGCONFIG) --cflags glib-2.0)
GTKCFLAGS = $(shell $(PKGCONFIG) --cflags gtk+-3.0)
CFLAGS += $(shell $(XSLCONFIG) --cflags)
OSMGPSMAPFLAGS += $(shell $(PKGCONFIG) --cflags osmgpsmap-1.0 2> /dev/null)
LIBOSMGPSMAP += $(shell $(PKGCONFIG) --libs osmgpsmap-1.0 2> /dev/null)
ifneq ($(strip $(LIBOSMGPSMAP)),)
	GPSOBJ = gps.o
	CFLAGS += -DHAVE_OSM_GPS_MAP
endif
LIBSOUPCFLAGS = $(shell $(PKGCONFIG) --cflags libsoup-2.4)
LIBSOUP = $(shell $(PKGCONFIG) --libs libsoup-2.4)

LIBZIP = $(shell $(PKGCONFIG) --libs libzip 2> /dev/null)
ifneq ($(strip $(LIBZIP)),)
	ZIP = -DLIBZIP $(shell $(PKGCONFIG) --cflags libzip)
endif

LIBSQLITE3 = $(shell $(PKGCONFIG) --libs sqlite3 2> /dev/null)
ifneq ($(strip $(LIBSQLITE3)),)
	SQLITE3 = -DSQLITE3 $(shell $(PKGCONFIG) --cflags sqlite3)
endif

ifneq (,$(filter $(UNAME),linux kfreebsd gnu))
	LIBGCONF2 = $(shell $(PKGCONFIG) --libs gconf-2.0)
	GCONF2CFLAGS =  $(shell $(PKGCONFIG) --cflags gconf-2.0)
	OSSUPPORT = linux
	OSSUPPORT_CFLAGS = $(GTKCFLAGS) $(GCONF2CFLAGS)
else ifeq ($(UNAME), darwin)
	OSSUPPORT = macos
	OSSUPPORT_CFLAGS = $(GTKCFLAGS)
	MACOSXINSTALL = /Applications/$(CAPITALIZED_NAME).app
	MACOSXFILES = packaging/macosx
	MACOSXSTAGING = $(MACOSXFILES)/$(CAPITALIZED_NAME).app
	INFOPLIST = $(MACOSXFILES)/Info.plist
	INFOPLISTINPUT = $(INFOPLIST).in
	EXTRALIBS = $(shell $(PKGCONFIG) --libs gtk-mac-integration) -framework CoreFoundation -framework CoreServices
	CFLAGS += $(shell $(PKGCONFIG) --cflags gtk-mac-integration)
	LDFLAGS += -headerpad_max_install_names -sectcreate __TEXT __info_plist $(INFOPLIST)
	GTK_MAC_BUNDLER = ~/.local/bin/gtk-mac-bundler
else
	OSSUPPORT = windows
	OSSUPPORT_CFLAGS = $(GTKCFLAGS)
	WINDOWSSTAGING = ./packaging/windows
	WINMSGDIRS=$(addprefix share/locale/,$(shell ls po/*.po | sed -e 's/po\/\(..\)_.*/\1\/LC_MESSAGES/'))
	NSIINPUTFILE = $(WINDOWSSTAGING)/$(NAME).nsi.in
	NSIFILE = $(WINDOWSSTAGING)/$(NAME).nsi
	MAKENSIS = makensis
	XSLTDIR = .\\xslt
endif

ifneq ($(strip $(LIBXSLT)),)
	XSLT=-DXSLT='"$(XSLTDIR)"'
endif

LIBS = $(LIBXML2) $(LIBXSLT) $(LIBSQLITE3) $(LIBGTK) $(LIBGCONF2) $(LIBDIVECOMPUTER) $(EXTRALIBS) $(LIBZIP) -lpthread -lm $(LIBOSMGPSMAP) $(LIBSOUP) $(LIBWINSOCK) $(LIBGNUTLS)

MSGLANGS=$(notdir $(wildcard po/*.po))
MSGOBJS=$(addprefix share/locale/,$(MSGLANGS:.po=.UTF-8/LC_MESSAGES/$(NAME).mo))

GTKOBJS = info-gtk.o divelist-gtk.o planner-gtk.o statistics-gtk.o gtk-gui.o

OBJS =	main.o dive.o time.o profile.o info.o equipment.o divelist.o deco.o planner.o \
	parse-xml.o save-xml.o libdivecomputer.o print.o uemis.o uemis-downloader.o \
	statistics.o file.o device.o download-dialog.o prefs.o \
	webservice.o sha1.o $(GPSOBJ) $(OSSUPPORT).o $(RESFILE) $(GTKOBJS)

DEPS = $(wildcard .dep/*.dep)

all: $(TARGET)

$(TARGET): gen_version_file $(OBJS) $(MSGOBJS) $(INFOPLIST)
	@$(PRETTYECHO) '    LINK' $(TARGET)
	$(COMPILE_PREFIX)$(CC) $(LDFLAGS) -o $(TARGET) $(OBJS) $(LIBS)

gen_version_file:
ifneq ($(STORED_VERSION_STRING),$(VERSION_STRING))
	$(info updating $(VERSION_FILE) to $(VERSION_STRING))
	@echo \#define VERSION_STRING \"$(VERSION_STRING)\" >$(VERSION_FILE)
endif

install: all
	$(INSTALL) -d -m 755 $(BINDIR)
	$(INSTALL) $(NAME) $(BINDIR)
	$(INSTALL) -d -m 755 $(DESKTOPDIR)
	$(INSTALL) $(DESKTOPFILE) $(DESKTOPDIR)
	$(INSTALL) -d -m 755 $(ICONDIR)
	$(INSTALL) -m 644 $(ICONFILE) $(ICONDIR)
	@-if test -z "$(DESTDIR)"; then \
		$(gtk_update_icon_cache); \
	fi
	$(INSTALL) -d -m 755 $(MANDIR)
	$(INSTALL) -m 644 $(MANFILES) $(MANDIR)
	@-if test ! -z "$(XSLT)"; then \
		$(INSTALL) -d -m 755 $(DATADIR)/$(NAME); \
		$(INSTALL) -d -m 755 $(XSLTDIR); \
		$(INSTALL) -m 644 $(XSLTFILES) $(XSLTDIR); \
	fi
	for LOC in $(wildcard share/locale/*/LC_MESSAGES); do \
		$(INSTALL) -d $(prefix)/$$LOC; \
		$(INSTALL) -m 644 $$LOC/$(NAME).mo $(prefix)/$$LOC/$(NAME).mo; \
	done


install-macosx: all
	$(INSTALL) -d -m 755 $(MACOSXINSTALL)/Contents/Resources
	$(INSTALL) -d -m 755 $(MACOSXINSTALL)/Contents/MacOS
	$(INSTALL) $(NAME) $(MACOSXINSTALL)/Contents/MacOS/$(NAME)-bin
	$(INSTALL) $(MACOSXFILES)/$(NAME).sh $(MACOSXINSTALL)/Contents/MacOS/$(NAME)
	$(INSTALL) $(MACOSXFILES)/PkgInfo $(MACOSXINSTALL)/Contents/
	$(INSTALL) $(MACOSXFILES)/Info.plist $(MACOSXINSTALL)/Contents/
	$(INSTALL) $(ICONFILE) $(MACOSXINSTALL)/Contents/Resources/
	$(INSTALL) $(MACOSXFILES)/$(CAPITALIZED_NAME).icns $(MACOSXINSTALL)/Contents/Resources/
	for LOC in $(wildcard share/locale/*/LC_MESSAGES); do \
		$(INSTALL) -d -m 755 $(MACOSXINSTALL)/Contents/Resources/$$LOC; \
		$(INSTALL) $$LOC/$(NAME).mo $(MACOSXINSTALL)/Contents/Resources/$$LOC/$(NAME).mo; \
	done
	@-if test ! -z "$(XSLT)"; then \
		$(INSTALL) -d -m 755 $(MACOSXINSTALL)/Contents/Resources/xslt; \
		$(INSTALL) -m 644 $(XSLTFILES) $(MACOSXINSTALL)/Contents/Resources/xslt/; \
	fi


create-macosx-bundle: all
	$(INSTALL) -d -m 755 $(MACOSXSTAGING)/Contents/Resources
	$(INSTALL) -d -m 755 $(MACOSXSTAGING)/Contents/MacOS
	$(INSTALL) $(NAME) $(MACOSXSTAGING)/Contents/MacOS/
	$(INSTALL) $(MACOSXFILES)/PkgInfo $(MACOSXSTAGING)/Contents/
	$(INSTALL) $(MACOSXFILES)/Info.plist $(MACOSXSTAGING)/Contents/
	$(INSTALL) $(ICONFILE) $(MACOSXSTAGING)/Contents/Resources/
	$(INSTALL) $(MACOSXFILES)/$(CAPITALIZED_NAME).icns $(MACOSXSTAGING)/Contents/Resources/
	for LOC in $(wildcard share/locale/*/LC_MESSAGES); do \
		$(INSTALL) -d -m 755 $(MACOSXSTAGING)/Contents/Resources/$$LOC; \
		$(INSTALL) $$LOC/$(NAME).mo $(MACOSXSTAGING)/Contents/Resources/$$LOC/$(NAME).mo; \
	done
	@-if test ! -z "$(XSLT)"; then \
		$(INSTALL) -d -m 755 $(MACOSXSTAGING)/Contents/Resources/xslt; \
		$(INSTALL) -m 644 $(XSLTFILES) $(MACOSXSTAGING)/Contents/Resources/xslt/; \
	fi
	$(GTK_MAC_BUNDLER) packaging/macosx/$(NAME).bundle

sign-macosx-bundle: all
	codesign -s "3A8CE62A483083EDEA5581A61E770EC1FA8BECE8" /Applications/$(CAPITALIZED_NAME).app/Contents/MacOS/$(NAME)-bin

install-cross-windows: all
	$(INSTALL) -d -m 755 $(WINDOWSSTAGING)/share/locale
	for MSG in $(WINMSGDIRS); do\
		$(INSTALL) -d -m 755 $(WINDOWSSTAGING)/$$MSG;\
		$(INSTALL) $(CROSS_PATH)/$$MSG/* $(WINDOWSSTAGING)/$$MSG;\
	done
	for LOC in $(wildcard share/locale/*/LC_MESSAGES); do \
		$(INSTALL) -d -m 755 $(WINDOWSSTAGING)/$$LOC; \
		$(INSTALL) $$LOC/$(NAME).mo $(WINDOWSSTAGING)/$$LOC/$(NAME).mo; \
	done

create-windows-installer: all $(NSIFILE) install-cross-windows
	$(MAKENSIS) $(NSIFILE)

$(NSIFILE): $(NSIINPUTFILE)
	$(shell cat $(NSIINPUTFILE) | sed -e 's/VERSIONTOKEN/$(VERSION_STRING)/;s/PRODVTOKEN/$(PRODVERSION_STRING)/' > $(NSIFILE))

$(INFOPLIST): $(INFOPLISTINPUT)
	$(shell cat $(INFOPLISTINPUT) | sed -e 's/CFBUNDLEVERSION_TOKEN/$(CFBUNDLEVERSION_STRING)/' > $(INFOPLIST))

# Transifex merge the translations
update-po-files:
	tx pull -af

push-pot:
	xgettext -o po/$(NAME)-new.pot -s -k_ -kN_ --keyword=C_:1c,2  --add-comments="++GETTEXT" *.c
	tx push -s

EXTRA_FLAGS =	$(GTKCFLAGS) $(GLIB2CFLAGS) $(XML2CFLAGS) \
		$(XSLT) $(ZIP) $(SQLITE3) $(LIBDIVECOMPUTERCFLAGS) \
		$(LIBSOUPCFLAGS) $(OSMGPSMAPFLAGS) $(GCONF2CFLAGS)

%.o: %.c
	@$(PRETTYECHO) '    CC' $<
	@mkdir -p .dep
	$(COMPILE_PREFIX)$(CC) $(CFLAGS) $(EXTRA_FLAGS) -MD -MF .dep/$@.dep -c -o $@ $<

share/locale/%.UTF-8/LC_MESSAGES/$(NAME).mo: po/%.po po/%.aliases
	mkdir -p $(dir $@)
	msgfmt -c -o $@ po/$*.po
	@-if test -s po/$*.aliases; then \
		for ALIAS in `cat po/$*.aliases`; do \
			mkdir -p share/locale/$$ALIAS/LC_MESSAGES; \
			cp $@ share/locale/$$ALIAS/LC_MESSAGES; \
		done; \
	fi

satellite.png: satellite.svg
	convert -transparent white -resize 11x16 -depth 8 $< $@

# This should work, but it doesn't get the colors quite right - so I manually converted with Gimp
#	convert -colorspace RGB -transparent white -resize 256x256 $(NAME)-icon.svg $(NAME)-icon.png
#
# The following creates the pixbuf data in .h files with the basename followed by '_pixmap'
# as name of the data structure
%.h: %.png
	@$(PRETTYECHO) '    gdk-pixbuf-csource' $<
	$(COMPILE_PREFIX)gdk-pixbuf-csource --struct --name `echo $* | sed 's/-/_/g'`_pixbuf $< > $@

doc:
	$(MAKE) -C Documentation doc

clean:
	rm -f $(OBJS) *~ $(NAME) $(NAME).exe po/*~ po/$(NAME)-new.pot \
		$(VERSION_FILE)
	rm -rf share .dep

release:
	@scripts/check-version -cr $(VERSION_STRING)
	git archive --prefix $(CAPITALIZED_NAME)-$(VERSION_STRING)/ \
		    --output $(CAPITALIZED_NAME)-$(VERSION_STRING).tgz \
		    v$(VERSION_STRING)

-include $(DEPS)
