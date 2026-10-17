.PHONY: generate build test run clean

generate:
	xcodegen generate --quiet

build: generate
	xcodebuild -project Brighter.xcodeproj -scheme Brighter -configuration Debug -derivedDataPath build -quiet build

test:
	swift test --package-path Packages/BrighterCore

run: build
	pkill -x Brighter || true
	open build/Build/Products/Debug/Brighter.app

clean:
	rm -rf build Brighter.xcodeproj Packages/BrighterCore/.build
