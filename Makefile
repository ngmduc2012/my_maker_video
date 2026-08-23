.PHONY: init format-check analyze test test-root test-example android-check android-build ios-build verify publish-dry-run

FLUTTER ?= flutter
DART ?= dart

init:
	$(FLUTTER) pub get
	cd example && $(FLUTTER) pub get

format-check:
	$(DART) format --output=none --set-exit-if-changed lib test example/lib example/test example/integration_test

analyze:
	$(FLUTTER) analyze
	cd example && $(FLUTTER) analyze

test: test-root test-example

test-root:
	$(FLUTTER) test

test-example:
	cd example && $(FLUTTER) test

android-check:
	cd example/android && ./gradlew :my_maker_video:testDebugUnitTest :my_maker_video:lintDebug

android-build:
	cd example && $(FLUTTER) build apk --debug

ios-build:
	cd example && $(FLUTTER) build ios --simulator --no-codesign

verify: format-check analyze test android-check android-build ios-build

publish-dry-run:
	$(DART) pub publish --dry-run
