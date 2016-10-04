#!/usr/bin/env node

var path = require('path')
  , advisable = require(path.resolve(__dirname, '..', 'lib', 'advisable'))
  , target;

function Target(val) {
  this.val = val;
}

Target.prototype.syncFunc = function (a, b) {
  console.log(
    'Target.prototype.syncFunc, a = %d, b = %d, this.val = %d'
  , a
  , b
  , this.val
  );

  return a + b + this.val;
};

Target.prototype.asyncFunc = function (a, b, callback) {
  console.log(
    'Target.prototype.asyncFunc, a = %d, b = %d, this.val = %d'
  , a
  , b
  , this.val
  );

  process.nextTick(function () {
    callback(null, a + b + this.val);
  }.bind(this));
};

// Mixin sync advice
advisable.sync.call(Target.prototype);

// Mixin async advice
advisable.async.call(Target.prototype);

// All examples create a new Target instance and invoke advice methods on the
// instance so that examples don't interfere with each other. Often, real
// world usage will involve advising the prototype, not an individual instance,
// so that all instances receive advice. That being said, advice can be mixed
// into to _any_ JS object and applied to any function on the given object.

// -----------------------------------------------------------------------------
//
// Synchronous Advice Examples
//
// -----------------------------------------------------------------------------

// No advice
target = new Target(1);

// 10 + 100 + 1 => 111
console.log('syncFunc, no advice: %d', target.syncFunc(10, 100));

// -----------------------------------------------------------------------------

// Before advice that increments target.val
target = new Target(1);
target.beforeSync('syncFunc', function (a, b) {
  this.val++;
});

// 10 + 100 + 2 => 112
console.log('syncFunc, increment before: %d', target.syncFunc(10, 100));

// -----------------------------------------------------------------------------

// Before advice that modifies arguments
target = new Target(1);
target.beforeSync('syncFunc', function (a, b) {
  return [ a/10, b/10 ];
}, { mutate: true });

// 10/10 + 100/10 + 1 => 12
console.log('syncFunc, divide args before: %d', target.syncFunc(10, 100));

// -----------------------------------------------------------------------------

// After advice that decrements target.val
target = new Target(1);
target.afterSync('syncFunc', function (a, b) {
  this.val--;
});

// 10 + 100 + 1 => 111 (original return value)
console.log('syncFunc, decrement after: %d', target.syncFunc(10, 100));

// this.val is now 0
console.log('syncFunc, decremented: %d', target.val);

// -----------------------------------------------------------------------------

// After advice that modifies the return value
target = new Target(1);
target.afterSync('syncFunc', function (v) {
  return v * 2;
}, { mutate: true });

// (10/10 + 100/10 + 1) * 2 => 222
console.log('syncFunc, double after: %d', target.syncFunc(10, 100));

// -----------------------------------------------------------------------------

// Around advice that simply observes
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
console.log('syncFunc, around advice: %d', target.syncFunc(10, 100));

// -----------------------------------------------------------------------------

// Mutated around advice
target = new Target(1);
target.aroundSync(
  'syncFunc'
, function (a, b) {
    console.log('around:before called with args: %d, %d', a, b);
    return [ a * 3, b * 3 ];
  }
, function (v) {
    console.log('around:after called with arg: %d', v);
    return v + 123;
  }
, { mutate: true }
);

// ((10*3) + (100*3) + 1) + 123 => 454
console.log('syncFunc, mutated around advice: %d', target.syncFunc(10, 100));

// -----------------------------------------------------------------------------

// Synchronous wrap
target = new Target(1);
target.wrapSync('syncFunc', function (wrapped, a, b) {
  var targetRv;

  this.val++;
  targetRv = wrapped(a * 3, b * 3);

  return targetRv + 123;
});

// ((10*3) + (100*3) + 1 + 1) + 123 => 455
console.log('syncFunc, wrapped: %d', target.syncFunc(10, 100));

// -----------------------------------------------------------------------------
//
// Asynchronous Advice Examples
//
// -----------------------------------------------------------------------------

// No advice
target = new Target(1);

// 10 + 100 + 1 => 111
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, no advice: %d', result);
});

// -----------------------------------------------------------------------------

// Before advice that increments target.val
target = new Target(1);
target.before('asyncFunc', function (a, b, callback) {
  this.val++;
  // Non-mutated async advice must call back, but the error (first) argument
  // is the only argument considered.
  callback();
});

// 10 + 100 + 2 => 112
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, increment before: %d', result);
});

// -----------------------------------------------------------------------------

// Before advice that modifies arguments
target = new Target(1);
target.before('asyncFunc', function (a, b, callback) {
  callback(null, a/10, b/10);
}, { mutate: true });

// 10/10 + 100/10 + 1 => 12
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, divide args before: %d', result);
});

// -----------------------------------------------------------------------------

// After advice that decrements target.val
target = new Target(1);
target.after('asyncFunc', function (a, b, callback) {
  this.val--;
  callback();
});

// 10 + 100 + 1 => 111 (original return value)
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, decrement after: %d', result);
  // target.val is now 0
  console.log('asyncFunc, decremented: %d', this.val);
}.bind(target));

// -----------------------------------------------------------------------------

// After advice that modifies the return value
target = new Target(1);
target.after('asyncFunc', function (v, callback) {
  callback(null, v * 2);
}, { mutate: true });

// (10/10 + 100/10 + 1) * 2 => 222
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, double after: %d', result);
});

// -----------------------------------------------------------------------------

// Around advice that simply observes
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

// 10 + 100 + 1 => 111
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, around advice: %d', result);
});

// -----------------------------------------------------------------------------

// Mutated around advice
target = new Target(1);
target.around(
  'asyncFunc'
, function (a, b, callback) {
    console.log('around:before called with args: %d, %d', a, b);
    callback(null, a * 3, b * 3);
  }
, function (v, callback) {
    console.log('around:after called with arg: %d', v);
    callback(null, v + 123);
  }
, { mutate: true }
);

// ((10*3) + (100*3) + 1) + 123 => 454
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, mutated around advice: %d', result);
});

// -----------------------------------------------------------------------------

// Asynchronous wrap
target = new Target(1);
target.wrap('asyncFunc', function (wrapped, a, b, callback) {
  this.val++;
  wrapped(a * 3, b * 3, function (err, result) {
    if (err) return callback(err);

    process.nextTick(function () {
      callback(null, result + 123);
    });
  });
});

// ((10*3) + (100*3) + 1 + 1) + 123 => 455
target.asyncFunc(10, 100, function (err, result) {
  console.log('asyncFunc, wrapped: %d', result);
});
