APP_SIGNING_ID ?= Developer ID Application: Donald McCaughey
INSTALLER_SIGNING_ID ?= Developer ID Installer: Donald McCaughey
NOTARIZATION_KEYCHAIN_PROFILE ?= Donald McCaughey
TMP ?= $(abspath tmp)

version := 1.3.4
libiconv_version := 1.17
revision := 1
archs := arm64 x86_64

rev := $(if $(patsubst 1,,$(revision)),-r$(revision),)
ver := $(version)$(rev)


.SECONDEXPANSION :


.PHONY : signed-package
signed-package : $(TMP)/flac-$(ver)-unnotarized.pkg


.PHONY : notarize
notarize : flac-$(ver).pkg


.PHONY : clean
clean :
	-rm -f flac-*.pkg
	-rm -rf $(TMP)


.PHONY : check
check :
	test "$(shell lipo -archs $(TMP)/libiconv/install/usr/local/lib/libiconv.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/flac/install/usr/local/bin/flac)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/flac/install/usr/local/bin/metaflac)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/flac/install/usr/local/lib/libFLAC.a)" = "x86_64 arm64"
	test "$(shell lipo -archs $(TMP)/flac/install/usr/local/lib/libFLAC++.a)" = "x86_64 arm64"
	test "$(shell ./tools/dylibs --no-sys-libs --count $(TMP)/flac/install/usr/local/bin/flac) dylibs" = "0 dylibs"
	test "$(shell ./tools/dylibs --no-sys-libs --count $(TMP)/flac/install/usr/local/bin/metaflac) dylibs" = "0 dylibs"
	codesign --verify --strict $(TMP)/flac/install/usr/local/bin/flac
	codesign --verify --strict $(TMP)/flac/install/usr/local/bin/metaflac
	codesign --verify --strict $(TMP)/flac/install/usr/local/lib/libFLAC.a
	codesign --verify --strict $(TMP)/flac/install/usr/local/lib/libFLAC++.a
	pkgutil --check-signature flac-$(ver).pkg
	spctl --assess --type install flac-$(ver).pkg
	xcrun stapler validate flac-$(ver).pkg


.PHONY : libiconv
libiconv : \
			$(TMP)/libiconv/install/usr/local/include/iconv.h \
			$(TMP)/libiconv/install/usr/local/lib/libiconv.a


.PHONY : flac
flac : $(TMP)/flac/install/usr/local/bin/flac


.PHONY : pkg
pkg : $(TMP)/flac.pkg


##### compilation flags ##########

arch_flags = $(patsubst %,-arch %,$(archs))

CFLAGS += $(arch_flags)
CXXFLAGS += $(arch_flags)


##### libiconv ##########

libiconv_config_options := \
			--disable-shared \
			CFLAGS='$(CFLAGS)'

libiconv_sources := $(shell find libiconv -type f \! -name .DS_Store)

$(TMP)/libiconv/install/usr/local/include/iconv.h \
$(TMP)/libiconv/install/usr/local/lib/libiconv.a : $(TMP)/libiconv/installed.stamp.txt
	@:

$(TMP)/libiconv/installed.stamp.txt : \
			$(TMP)/libiconv/build/include/iconv.h \
			$(TMP)/libiconv/build/lib/.libs/libiconv.a \
			| $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE) DESTDIR=$(TMP)/libiconv/install install
	date > $@

$(TMP)/libiconv/build/include/iconv.h \
$(TMP)/libiconv/build/lib/.libs/libiconv.a : $(TMP)/libiconv/built.stamp.txt | $$(dir $$@)
	@:

$(TMP)/libiconv/built.stamp.txt : $(TMP)/libiconv/configured.stamp.txt | $$(dir $$@)
	cd $(TMP)/libiconv/build && $(MAKE)
	date > $@

$(TMP)/libiconv/configured.stamp.txt : $(libiconv_sources) | $(TMP)/libiconv/build
	cd $(TMP)/libiconv/build \
			&& $(abspath libiconv/configure) $(libiconv_config_options)
	date > $@

$(TMP)/libiconv \
$(TMP)/libiconv/build \
$(TMP)/libiconv/install :
	mkdir -p $@


##### flac ##########

flac_config_options := \
				--disable-silent-rules \
				--enable-static \
				--disable-shared \
				--disable-xmms-plugin \
				--disable-ogg \
				--disable-examples \
				CFLAGS='$(CFLAGS) -I $(TMP)/libiconv/install/usr/local/include' \
				CXXFLAGS='$(CXXFLAGS) -I $(TMP)/libiconv/install/usr/local/include' \
				LDFLAGS='$(LDFLAGS) -L$(TMP)/libiconv/install/usr/local/lib'

flac_sources := $(shell find flac -type f \! -name .DS_Store)

$(TMP)/flac/install/usr/local/bin/flac : $(TMP)/flac/build/src/flac/flac | $(TMP)/flac/install
	cd $(TMP)/flac/build && $(MAKE) DESTDIR=$(TMP)/flac/install install
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$(TMP)/flac/install/usr/local/bin/flac
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$(TMP)/flac/install/usr/local/bin/metaflac
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$(TMP)/flac/install/usr/local/lib/libFLAC.a
	xcrun codesign \
		--sign "$(APP_SIGNING_ID)" \
		--options runtime \
		$(TMP)/flac/install/usr/local/lib/libFLAC++.a

$(TMP)/flac/build/src/flac/flac : $(TMP)/flac/build/config.status $(flac_sources)
	cd $(TMP)/flac/build && $(MAKE)

$(TMP)/flac/build/config.status : \
			flac/configure \
			$(TMP)/libiconv/install/usr/local/include/iconv.h \
			$(TMP)/libiconv/install/usr/local/lib/libiconv.a \
			| $$(dir $$@)
	cd $(TMP)/flac/build \
		&& sh $(abspath $<) $(flac_config_options)

$(TMP)/flac/build \
$(TMP)/flac/install :
	mkdir -p $@


##### pkg ##########

$(TMP)/flac.pkg : \
		$(TMP)/flac/install/usr/local/bin/uninstall-flac
	pkgbuild \
		--root $(TMP)/flac/install \
		--identifier cc.donm.pkg.flac \
		--ownership recommended \
		--version $(version) \
		$@

$(TMP)/flac/install/etc/paths.d/flac.path : flac.path | $$(dir $$@)
	cp $< $@

$(TMP)/flac/install/usr/local/bin/uninstall-flac : \
		uninstall-flac \
		$(TMP)/flac/install/etc/paths.d/flac.path \
		$(TMP)/flac/install/usr/local/bin/flac \
		| $$(dir $$@)
	cp $< $@
	cd $(TMP)/flac/install && find . -type f \! -name .DS_Store | sort >> $@
	sed -e 's/^\./rm -f /g' -i '' $@
	chmod a+x $@

$(TMP)/flac/install/etc/paths.d \
$(TMP)/flac/install/usr/local/bin :
	mkdir -p $@


##### product ##########

arch_list := $(shell printf '%s' "$(archs)" | sed "s/ / and /g")
date := $(shell date '+%Y-%m-%d')
macos:=$(shell \
	system_profiler -detailLevel mini SPSoftwareDataType \
	| grep 'System Version:' \
	| awk -F ' ' '{print $$4}' \
	)
xcode:=$(shell \
	system_profiler -detailLevel mini SPDeveloperToolsDataType \
	| grep 'Version:' \
	| awk -F ' ' '{print $$2}' \
	)

$(TMP)/flac-$(ver)-unnotarized.pkg : \
		$(TMP)/flac.pkg \
		$(TMP)/build-report.txt \
		$(TMP)/distribution.xml \
		$(TMP)/resources/background.png \
		$(TMP)/resources/background-darkAqua.png \
		$(TMP)/resources/license.html \
		$(TMP)/resources/welcome.html
	productbuild \
		--distribution $(TMP)/distribution.xml \
		--resources $(TMP)/resources \
		--package-path $(TMP) \
		--version v$(version)-r$(revision) \
		--sign '$(INSTALLER_SIGNING_ID)' \
		$@

$(TMP)/build-report.txt : | $$(dir $$@)
	printf 'Build Date: %s\n' "$(date)" > $@
	printf 'Software Version: %s\n' "$(version)" >> $@
	printf 'libiconv Version: %s\n' "$(libiconv_version)" >> $@
	printf 'Installer Revision: %s\n' "$(revision)" >> $@
	printf 'Architectures: %s\n' "$(arch_list)" >> $@
	printf 'macOS Version: %s\n' "$(macos)" >> $@
	printf 'Xcode Version: %s\n' "$(xcode)" >> $@
	printf 'APP_SIGNING_ID: %s\n' "$(APP_SIGNING_ID)" >> $@
	printf 'INSTALLER_SIGNING_ID: %s\n' "$(INSTALLER_SIGNING_ID)" >> $@
	printf 'NOTARIZATION_KEYCHAIN_PROFILE: %s\n' "$(NOTARIZATION_KEYCHAIN_PROFILE)" >> $@
	printf 'TMP directory: %s\n' "$(TMP)" >> $@
	printf 'CFLAGS: %s\n' "$(CFLAGS)" >> $@
	printf 'Tag: v%s-r%s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Title: flac %s for macOS rev %s\n' "$(version)" "$(revision)" >> $@
	printf 'Tag Message: A signed and notarized universal installer package for `flac` %s, built with libiconv %s.\n' \
		"$(version)" "$(libiconv_version)" >> $@

$(TMP)/distribution.xml \
$(TMP)/resources/welcome.html : $(TMP)/% : % | $$(dir $$@)
	sed \
		-e 's/{{arch_list}}/$(arch_list)/g' \
		-e 's/{{date}}/$(date)/g' \
		-e 's/{{macos}}/$(macos)/g' \
		-e 's/{{libiconv_version}}/$(libiconv_version)/g' \
		-e 's/{{revision}}/$(revision)/g' \
		-e 's/{{version}}/$(version)/g' \
		-e 's/{{xcode}}/$(xcode)/g' \
		$< > $@

$(TMP)/resources/background.png \
$(TMP)/resources/background-darkAqua.png \
$(TMP)/resources/license.html : $(TMP)/% : % | $$(dir $$@)
	cp $< $@

$(TMP) \
$(TMP)/resources :
	mkdir -p $@


##### notarization ##########

$(TMP)/submit-log.json : $(TMP)/flac-$(ver)-unnotarized.pkg | $$(dir $$@)
	xcrun notarytool submit $< \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		--output-format json \
		--wait \
		> $@

$(TMP)/submission-id.txt : $(TMP)/submit-log.json | $$(dir $$@)
	jq --raw-output '.id' < $< > $@

$(TMP)/notarization-log.json : $(TMP)/submission-id.txt | $$(dir $$@)
	xcrun notarytool log "$$(<$<)" \
		--keychain-profile "$(NOTARIZATION_KEYCHAIN_PROFILE)" \
		$@

$(TMP)/notarized.stamp.txt : $(TMP)/notarization-log.json | $$(dir $$@)
	test "$$(jq --raw-output '.status' < $<)" = "Accepted"
	date > $@

flac-$(ver).pkg : $(TMP)/flac-$(ver)-unnotarized.pkg $(TMP)/notarized.stamp.txt
	cp $< $@
	xcrun stapler staple $@

