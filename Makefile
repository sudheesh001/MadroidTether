XCODEBUILD ?= /Applications/Xcode-4.6.3.app/Contents/Developer/usr/bin/xcodebuild

ifeq (,$(wildcard $(XCODEBUILD)))
	XCODEBUILD = xcodebuild
endif

ifeq (sudheesh,$(USER))
	CODESIGN_KEXT ?= "Developer ID Application: Sudheesh Singanamalla"
	CODESIGN_INST ?= "Developer ID Installer: Sudheesh Singanamalla"
endif

all: build/Release/Madroid.kext build/signed/Madroid.kext build/Madroid.pkg

build/Release/Madroid.kext: Madroid.cpp Madroid.h Madroid-Info.plist Madroid.xcodeproj Madroid.xcodeproj/project.pbxproj
	$(XCODEBUILD) -project Madroid.xcodeproj

build/root: build/Release/Madroid.kext build/signed/Madroid.kext
	rm -rf build/root
	mkdir -p build/root/System/Library/Extensions/
	cp -R build/Release/Madroid.kext build/root/System/Library/Extensions/
	mkdir -p build/root/Library/Extensions
	cp -R build/signed/Madroid.kext build/root/Library/Extensions/

build/Madroid-kext.pkg: build/root
	pkgbuild --identifier com.sudheeshsinganamalla.kexts.Madroid --root $< $@

build/Madroid.pkg: build/Madroid-kext.pkg package/Distribution.xml
	productbuild --distribution package/Distribution.xml --package-path build --resources package/resources $(if $(CODESIGN_INST),--sign $(CODESIGN_INST)) build/Madroid.pkg

ifeq (,$(CODESIGN_KEXT))

build/signed/%: build/Release/%
	@echo not building $@ because we have no key to sign with
	@echo ...but, you can still use $<, if you want
	@exit 1

else

build/signed/%: build/Release/%
	rm -rf $@
	mkdir -p build/signed
	cp -R $< $@
	codesign --force -s $(CODESIGN_KEXT) $@

endif