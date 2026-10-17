-include Local.mk
SIGN_IDENTITY ?= -

.PHONY: generate build test run release-build install clean

generate:
	xcodegen generate --quiet

build: generate
	xcodebuild -project Brighter.xcodeproj -scheme Brighter -configuration Debug -derivedDataPath build -quiet build CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)"

test:
	swift test --package-path Packages/BrighterCore

run: build
	pkill -x Brighter; while pgrep -x Brighter >/dev/null; do sleep 0.1; done
	open build/Build/Products/Debug/Brighter.app

release-build: generate
	xcodebuild -project Brighter.xcodeproj -scheme Brighter -configuration Release -derivedDataPath build -quiet build CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)"

install: release-build
	pkill -x Brighter; while pgrep -x Brighter >/dev/null; do sleep 0.1; done
	rm -rf /Applications/Brighter.app
	cp -R build/Build/Products/Release/Brighter.app /Applications/
	open /Applications/Brighter.app

clean:
	rm -rf build Brighter.xcodeproj Packages/BrighterCore/.build
