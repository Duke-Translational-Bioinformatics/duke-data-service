# advisable.js

__advisable.js__ is an implementation of functional mixins for synchronous and asynchronous before/after/around aspect-oriented advice. It is heavily inspired by a [talk on functional mixins](https://speakerdeck.com/u/anguscroll/p/how-we-learned-to-stop-worrying-and-love-javascript) by [Dan Webb](https://twitter.com/danwrong) and [Angus Croll](https://twitter.com/angustweets) at [FluentConf 2012](http://fluentconf.com/fluent2012).

This is certainly not the first JS implementation of advice, nor even the first implementation derived from patterns presented in the FluentConf talk. The goals and motivations behind reinventing this particular wheel are:

* Adherence to Node.js idioms (sync/async method separation, synchronous versions of methods appended with `Sync`, callbacks take errors as the first argument by convention).

* Clear, consistent calling semantics for declaring whether or not advice mutates arguments and return values.

* Thorough testing. This library injects intermediary methods into call chains and is intended to be used widely to modularize code in applications. As such, extensive testing of all expected use cases is a requirement.

## Supported Environments

__advisable.js__ is tested in a Node.js environment and supports CommonJS or AMD before falling back to adding an `advisable` property on the global object. The library should work in any browser environment with no dependencies provided that either a native or shimmed implementation of `Function.prototype.bind` is available. Browser support is caveated with *should* as tests are not currently run in browsers.

## Usage

The following usage examples are, quite obviously, contrived to show advice usage with simple arithmetic. In all examples, the object mixing in advisable methods is referred to as the target object, and the method receiving advice is the target method. All examples can be found and executed in [examples/advisable.js](https://github.com/repeatingbeats/advisable/blob/master/examples/advisable.js)

The `mutate` option allows advice callers to declare whether or not advice mutates arguments and return values. `mutate` defaults to false and the options object may be omitted entirely. Note that this option specifically refers to argument/return value mutation, as advice methods are invoked in the context of the target object, which is mutable within all advice methods. The `mutate` option can be used with all methods except `wrap` and `wrapSync`.

advisable's around advice is a syntactic shortcut for advising a target with both before and after advice in a single method call. This is unlike some other implementations, which pass the target function to a wrapper and expect the wrapper to invoke the target. `wrapSync` and `wrap` can be used for wrapping behavior.

First, we set up a very simple object with sync and async methods to advise:

    function Target(val) {
      this.val = val;
    }

    Target.prototype.syncFunc = function (a, b) {
      return a + b + this.val;
    };

    Target.prototype.asyncFunc = function (a, b, callback) {
      process.nextTick(function () {
        callback(null, a + b + this.val);
      }.bind(this));
    };

Advice methods are mixed in to a target object by invoking the functional mixin with the target object context.

    // Sync/async advice is mixed in separately
    advisable.sync.call(Target.prototype);
    advisable.async.call(Target.prototype);

### Synchronous Usage

First, without advice:

    target = new Target(1);

    // 10 + 100 + 1 => 111
    target.syncFunc(10, 100));

Before advice that changes target object state:

    target = new Target(1);
    target.beforeSync('syncFunc', function (a, b) {
      this.val++;
    });

    // 10 + 100 + 2 => 112
    target.syncFunc(10, 100);

Before advice that mutates arguments:

    target = new Target(1);
    target.beforeSync('syncFunc', function (a, b) {
      return [ a/10, b/10 ];
    }, { mutate: true });

    // 10/10 + 100/10 + 1 => 12
    target.syncFunc(10, 100);

After advice that changes target state but does not mutate return value:

    target = new Target(1);
    target.afterSync('syncFunc', function (a, b) {
      this.val--;
    });

    // 10 + 100 + 1 => 111 (original return value)
    target.syncFunc(10, 100));

    // But target.val is now 0 due to decrementing after advice

After advice that mutates a return value:

    target = new Target(1);
    target.afterSync('syncFunc', function (v) {
      return v * 2;
    }, { mutate: true });

    // (10/10 + 100/10 + 1) * 2 => 222
    target.syncFunc(10, 100);

Around advice that simply observes:

    target = new Target(1);
    target.aroundSync(
      'syncFunc'
    , function (a, b) {
        console.log('around:before called with args: %d, %d', a, b);
      }
    , function (a, b) {
        console.log('around:after called with args: %d, %d', a, b);
      }
    );

    // 10 + 100 + 1 => 111
    target.syncFunc(10, 100);

Around advice that mutates arguments and return value:

    target = new Target(1);
    target.aroundSync(
      'syncFunc'
    , function (a, b) {
        return [ a * 3, b * 3 ];
      }
    , function (v) {
        return v + 123;
      }
    , { mutate: true }
    );

    // ((10*3) + (100*3) + 1) + 123 => 454
    target.syncFunc(10, 100);

Synchronous method wrapping:

    target = new Target(1);
    target.wrapSync('syncFunc', function (wrapped, a, b) {
      var targetRv;

      this.val++;

      // `wrapped` is the target method and will be invoked in the target
      // object context
      targetRv = wrapped(a * 3, b * 3);

      return targetRv + 123;
    });

    // ((10*3) + (100*3) + 1 + 1) + 123 => 455
    target.syncFunc(10, 100);

### Asynchronous Usage

First, without advice:

    target = new Target(1);

    target.asyncFunc(10, 100, function (err, result) {
      // result = 10 + 100 + 1 => 111
    });

Before advice that changes target object state:

    target = new Target(1);
    target.before('asyncFunc', function (a, b, callback) {
      this.val++;
      // Non-mutated async advice must call back, but the error (first) argument
      // is the only argument considered.
      callback();
    });

    target.asyncFunc(10, 100, function (err, result) {
      // result = 10 + 100 + 2 => 112
    });

Before advice that mutates arguments:

    target = new Target(1);
    target.before('asyncFunc', function (a, b, callback) {
      callback(null, a/10, b/10);
    }, { mutate: true });

    target.asyncFunc(10, 100, function (err, result) {
      // result = 10/10 + 100/10 + 1 => 12
    });

After advice that changes target object state:

    target = new Target(1);
    target.after('asyncFunc', function (a, b, callback) {
      this.val--;
      callback();
    });

    target.asyncFunc(10, 100, function (err, result) {
      // result = 10 + 100 + 1 => 111 (original return value)
      // target.val is now 0 (assuming, of course, that no one else changed it)
    });

After advice that mutates the return value:

    target = new Target(1);
    target.after('asyncFunc', function (v, callback) {
      callback(null, v * 2);
    }, { mutate: true });

    target.asyncFunc(10, 100, function (err, result) {
      // result = (10/10 + 100/10 + 1) * 2 => 222
    });

Around advice that simply observes:

    target = new Target(1);
    target.around(
      'asyncFunc'
    , function (a, b, callback) {
        console.log('around:before called with args: %d, %d', a, b);
        callback();
      }
    , function (a, b, callback) {
        console.log('around:after called with args: %d, %d', a, b);
        callback();
      }
    );

    target.asyncFunc(10, 100, function (err, result) {
      // result = 10 + 100 + 1 => 111
    });

Around advice that mutates arguments and return value:

    target = new Target(1);
    target.around(
      'asyncFunc'
    , function (a, b, callback) {
        callback(null, a * 3, b * 3);
      }
    , function (v, callback) {
        callback(null, v + 123);
      }
    , { mutate: true }
    );

    target.asyncFunc(10, 100, function (err, result) {
      // result = ((10*3) + (100*3) + 1) + 123 => 454
    });

Asynchronous method wrapping:

    target = new Target(1);
    target.wrap('asyncFunc', function (wrapped, a, b, callback) {
      this.val++;

      // `wrapped` is the target method and will be invoked in the target
      // object context
      wrapped(a * 3, b * 3, function (err, result) {
        if (err) return callback(err);

        process.nextTick(function () {
          callback(null, result + 123);
        });
      });
    });

    target.asyncFunc(10, 100, function (err, result) {
      // result = ((10*3) + (100*3) + 1 + 1) + 123 => 455
    });

## API

For now, see inline documentation in [advisable.js](https://github.com/repeatingbeats/advisable/blob/master/lib/advisable.js)

## Testing

    $ make test

## Linting

    $ make lint

## License

advisable.js is MIT licensed. See [LICENSE](https://github.com/repeatingbeats/advisable/blob/master/LICENSE).
