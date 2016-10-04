[![Build Status](https://secure.travis-ci.org/apiaryio/pitboss.png)](http://travis-ci.org/apiaryio/pitboss)
[![Build Status](https://ci.appveyor.com/api/projects/status/nctklpxwtt14vv4r?svg=true)](https://ci.appveyor.com/project/Apiary/pitboss)

![Pitboss](http://s3.amazonaws.com/img.mdp.im/renobankclubinside4.jpg_%28705%C3%97453%29-20120923-100859.jpg)

# Pitboss-NG (next gen)

## A module for running untrusted code

```javascript
var Pitboss = require('pitboss-ng').Pitboss;

var untrustedCode = "var a = !true;\n a";

var sandbox = new Pitboss(untrustedCode, {
  memoryLimit: 32*1024, // 32 MB memory limit (default is 64 MB)
  timeout: 5*1000, // 5000 ms to perform tasks or die (default is 500 ms = 0.5 s)
  heartBeatTick: 100 // interval between memory-limit checks (default is 100 ms)
});

sandbox.run({
  context: {       // context is an object of variables/values accessible by the untrusted code
    'foo': 'bar',  // context must be JSON.stringify positive
    'key': 'value' //  = no RegExp, Date, circular references, Buffer or more crazy things
  },
  libraries: {
    myModule: path.join(__dirname, './my/own/module'),
    // will be available as global "myModule" variable for the untrusted code
    'crypto': 'crypto', // you can also require system/installed packages
    '_': 'underscore'   // require underscore the traditional way
  }
}, function callback (err, result) {
  // result is synchronous "return" of the last line in your untrusted code, here "a = !true", so false
  console.log('Result is:', result); // prints "Result is: false"
  sandbox.kill(); // don't forget to kill the sandbox, if you don't need it anymore
});

// OR other option: libraries can be an array of system modules
sandbox.run({
  context: {}, // no data-variables are passed to context
  libraries: ['console', 'lodash'] // we will be using global "lodash" & "console"
}, function callback (err, result) {
  // finished, kill the sandboxed process
  sandbox.kill();
});
```

### Runs JS code and returns the last eval'd statement

```javascript
var assert = require('chai').assert;
var Pitboss = require('pitboss-ng').Pitboss;

var code = "num = num % 5;\nnum;"

var sandbox = new Pitboss(code);

sandbox.run({context: {'num': 23}}, function (err, result) {
  assert.equal(3, result);
  sandbox.kill(); // sandbox is not needed anymore, so kill the sandboxed process
});
```

### Allows you to pass you own libraries into sandboxed content

```javascript
var assert = require('chai').assert;
var Pitboss = require('pitboss-ng').Pitboss;

var code = "num = num % 5;\n console.log('from sandbox: ' + num);\n num;"

var sandbox = new Pitboss(code);

sandbox.run({context: {'num': 23}, libraries: ['console']}, function (err, result) {
  // will print "from sandbox: 5"
  assert.equal(3, result);
  sandbox.kill(); // sandbox is not needed anymore, so end it
});
```

### Handles processes that take too damn long

```javascript
var assert = require('chai').assert;
var Pitboss = require('pitboss-ng').Pitboss;

var code = "while(true) { num % 3 };";

var sandbox = new Pitboss(code, {timeout: 2000});
sandbox.run({context: {'num': 23}}, function (err, result) {
  assert.equal("Timedout", err);
  sandbox.kill();
});
```

### Doesn't choke under pressure (or shitty code)

```javascript
var assert = require('chai').assert;
var Pitboss = require('pitboss-ng').Pitboss;

var code = "Not a JavaScript at all!";

var sandbox = new Pitboss(code, {timeout: 2000});

sandbox.run({context: {num: 23}}, function (err, result) {
  assert.include(err, "VM Syntax Error");
  assert.include(err, "Unexpected identifier");
  sandbox.kill();
});
```

### Doesn't handle this! But 'ulimit' or 'pidusage' does!

```javascript
var assert = require('chai').assert;
var Pitboss = require('pitboss-ng').Pitboss;

var code = "var str = ''; while (true) { str = str + 'Memory is a finite resource!'; }";

var sandbox = new Pitboss(code, {timeout: 10000});

sandbox.run({context: {num: 23}}, function (err, result) {
  assert.equal("Process failed", err);
  sandbox.kill();
});
```

And since Pitboss-NG forks each process, ulimit kills only the runner
