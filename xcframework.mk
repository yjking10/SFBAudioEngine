##
## Copyright © 2021-2024 Stephen F. Booth <stephen@sbooth.name>
## MIT license
##

## Generate an iOS XCFramework from an Xcode project file using xcodebuild.
##
## This is a portion of a Makefile. To use it, include it in
## your own Makefile and set the following variables:
##
##   FRAMEWORK_NAME    The base name of the XCFramework to build.
##   XCODEPROJ         The path to the Xcode project file.
##
## The following targets are provided:
##
##   xcframework       Builds the XCFramework.
##   clean             Deletes the XCFramework and build products.
##   xz                Builds the XCFramework and compresses it to
##                     an XZ archive using `tar`.
##   zip               Builds the XCFramework and compresses it to
##                     a PKZip archive using `ditto`.
##                     This is similar to Finder's "Compress" functionality.
##
## The following variables are optional:
##
##   SCHEME            The scheme building the framework target.
##                     If not set the default is "Framework".
##   IOS_SCHEME        The scheme building the iOS framework target.
##                     If not set the default is `$(SCHEME)`.
##   BUILD_DIR         The directory where the build products should
##                     be written. If not set the default is "build".
##
## The following targets are provided when MAKELEVEL is not 0:
##
##   install           Copies the XCFramework to PREFIX.
##   uninstall         Deletes the XCFramework from PREFIX.
##
## The following variable should be set:
##
##   PREFIX            The path of the desired installation prefix.
##                     There is no default value.
##
## An example Makefile could look like:
##
##   FRAMEWORK_NAME := SFBAudioUtilities
##   XCODEPROJ := SFBAudioUtilities.xcodeproj
##
##   SCHEME := SFBAudioUtilities
##
##   include ./xcframework.mk
##
## Running 'make' will create './SFBAudioUtilities.xcframework'.

# The default name of the scheme that builds the framework
SCHEME ?= Framework
# The default name of the scheme that builds the framework for iOS
IOS_SCHEME ?= $(SCHEME)

# Build products directory
BUILD_DIR ?= build

# The directory for intermediate .xcarchives
XCARCHIVE_DIR := $(BUILD_DIR)

# The name of the output XCFramework
XCFRAMEWORK := $(BUILD_DIR)/$(FRAMEWORK_NAME).xcframework

XZ_FILE := $(XCFRAMEWORK).tar.xz
ZIP_FILE := $(XCFRAMEWORK).zip

IOS_XCARCHIVE := $(XCARCHIVE_DIR)/iOS.xcarchive
IOS_SIMULATOR_XCARCHIVE := $(XCARCHIVE_DIR)/iOS-Simulator.xcarchive

XCARCHIVES := $(IOS_XCARCHIVE) $(IOS_SIMULATOR_XCARCHIVE)

xcframework: $(XCFRAMEWORK)
.PHONY: xcframework

clean:
	rm -Rf $(foreach xcarchive,$(XCARCHIVES),"$(xcarchive)") "$(XCFRAMEWORK)" "$(XZ_FILE)" "$(ZIP_FILE)"
.PHONY: clean

xz: $(XZ_FILE)
.PHONY: xz

zip: $(ZIP_FILE)
.PHONY: zip

ifneq (0,$(MAKELEVEL))
install: xcframework uninstall
	cp -R "$(XCFRAMEWORK)" "$(PREFIX)"
.PHONY: install

uninstall:
	rm -Rf "$(PREFIX)/$(XCFRAMEWORK)"
.PHONY: uninstall
endif

$(IOS_XCARCHIVE): $(XCODEPROJ)
	xcodebuild archive -project "$(XCODEPROJ)" -scheme "$(IOS_SCHEME)" -destination "generic/platform=iOS" -archivePath "$(basename $@)"

$(IOS_SIMULATOR_XCARCHIVE): $(XCODEPROJ)
	xcodebuild archive -project "$(XCODEPROJ)" -scheme "$(IOS_SCHEME)" -destination "generic/platform=iOS Simulator" -archivePath "$(basename $@)"

$(XCFRAMEWORK): $(XCARCHIVES)
	rm -Rf "$@"
	xcodebuild -create-xcframework $(foreach xcarchive,$^,-framework "$(xcarchive)/Products/Library/Frameworks/$(FRAMEWORK_NAME).framework" -debug-symbols "$(realpath $(xcarchive)/dSYMs/$(FRAMEWORK_NAME).framework.dSYM)" ) -output "$@"

$(XZ_FILE): $(XCFRAMEWORK)
	cd $(BUILD_DIR) && tar --create --xz --file "$(notdir $@)" "$(notdir $<)"

$(ZIP_FILE): $(XCFRAMEWORK)
	cd $(BUILD_DIR) && ditto -c -k --sequesterRsrc --keepParent "$(notdir $<)" "$(notdir $@)"
