GRUNT :=./node_modules/.bin/grunt
MOCHA :=./node_modules/.bin/mocha
TESTS := test/*.mocha.js

lint:
	$(GRUNT) lint

watch: 
	$(GRUNT) watch

test:
	NODE_ENV=test $(MOCHA) $(TESTS)

test-debug:
	NODE_ENV=test $(MOCHA) --debug-brk $(TESTS)

.PHONY: lint watch test test-debug
