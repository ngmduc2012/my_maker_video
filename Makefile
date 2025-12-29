.PHONY: init test test-root test-example push

FLUTTER ?= flutter

init:
	$(FLUTTER) pub get
	cd example && $(FLUTTER) pub get

test: test-root test-example
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html

test-root:
	$(FLUTTER) test --coverage

test-example:
	cd example && $(FLUTTER) test

push: test
	git add .
	git commit -m "$(shell date '+%Y-%m-%d %H:%M')" || true
	git push
