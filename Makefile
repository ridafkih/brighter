-include Local.mk
SIGN_IDENTITY ?= -

.PHONY: generate build test run install clean

generate:
	xcodegen generate --quiet

build: generate
	xcodebuild -project Brighter.xcodeproj -scheme Brighter -configuration Debug -derivedDataPath build -quiet build CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)"

test:
	swift test --package-path Packages/BrighterCore

run: build
	pkill -x Brighter || true
	open build/Build/Products/Debug/Brighter.app

install: generate
	xcodebuild -project Brighter.xcodeproj -scheme Brighter -configuration Release -derivedDataPath build -quiet build CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)"
	pkill -x Brighter || true
	rm -rf /Applications/Brighter.app
	cp -R build/Build/Products/Release/Brighter.app /Applications/
	open /Applications/Brighter.app

clean:
	rm -rf build Brighter.xcodeproj Packages/BrighterCore/.build
