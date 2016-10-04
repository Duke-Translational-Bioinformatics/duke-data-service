/**
 * repeated.mocha.js
 *
 * Test cases where advised methods are invoked multiple times to ensure
 * advice implementation does not have state-changing affects across
 * multiple invocations.
 */

var path = require('path')
  , advisable = require(path.resolve(__dirname, '..', 'lib', 'advisable'))
  , Target;

Target = function (v) {
  this.v = v;
};

// asyncFunc adds the passed argument to the stored value
Target.prototype.asyncFunc = function (a, callback) {
  process.nextTick(function () {
    callback(null, a + this.v);
  }.bind(this));
};

describe('advisable:repeated', function () {

  describe('async', function () {

    // Returns a callback that takes two arguments (err, result), checks
    // for error, and asserts against the expected result
    function checkResult(expected, done) {
      return function (err, result) {
        if (err) return done(err);

        result.should.equal(expected);
        done();
      };
    }

    // Returns a callback that takes one argument (err), checks for error,
    // and asserts the targets stored value against the expected result.
    // checkVal should be invoked in the test suite's context>
    function checkVal(expected, done) {
      return function (err) {
        if (err) return done(err);

        this.target.v.should.equal(expected);
        done();
      }.bind(this);
    }

    // Repeats this.target.asyncFunc n times with a passed value of zero
    function repeat(n, callback) {
      var chain;

      chain = function (err, result) {
        if (--n === 0) {
          callback(err, result);
        }
        else {
          this.target.asyncFunc(0, chain);
        }
      }.bind(this);

      this.target.asyncFunc(0, chain);
    }

    beforeEach(function () {
      this.target = new Target(0);
      advisable.async.call(this.target);
    });

    describe('.before', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.target.before('asyncFunc', function (a, callback) {
            this.v++;
            callback(null, a + this.v);
          }, { mutate: true });
        });

        [ 1, 2, 3, 4, 5 ].forEach(function (n) {

          // before: inc to n
          // target: call back with n + n = n * 2

          it('passes results for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkResult(n * 2, done));
          });

          it('maintains state for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkVal.bind(this)(n, done));
          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.target.before('asyncFunc', function (a, callback) {
            this.v++;
            callback();
          });
        });

        [ 1, 2, 3, 4, 5 ].forEach(function (n) {

          // before: inc to n
          // target: call back with 0 + n

          it('passes results for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkResult(n, done));
          });

          it('maintains state for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkVal.bind(this)(n, done));
          });

        });

      });

    });

    describe('.after', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.target.after('asyncFunc', function (result, callback) {
            this.v++;
            callback(null, result + this.v);
          }, { mutate: true });
        });

        [ 1, 2, 3, 4, 5 ].forEach(function (n) {

          // target: call back with (n - 1)
          // after:  inc to n, call back with (n + n - 1) = (n * 2 - 1)

          it('passes results for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkResult(n * 2 - 1, done));
          });

          it('maintains state for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkVal.bind(this)(n, done));
          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.target.after('asyncFunc', function (result, callback) {
            this.v++;
            callback();
          });
        });

        [ 1, 2, 3, 4, 5 ].forEach(function (n) {

          // target: call back with (n - 1)
          // after:  inc to n

          it('passes results for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkResult(n - 1, done));
          });

          it('maintains state for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkVal.bind(this)(n, done));
          });

        });

      });

    });

    describe('.around', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.target.around(
            'asyncFunc'
          , function (a, callback) {
              this.v++;
              callback(null, a + this.v);
            }
          , function (result, callback) {
              this.v++;
              callback(null, result + this.v);
            }
          , { mutate: true }
          );
        });

        [ 1, 2, 3, 4, 5 ].forEach(function (n) {

          // before: inc to (2 * n - 1), call back with 0 + (2 * n - 1)
          // target: call back with 2 * (2 * n - 1)
          // after:  inc to (2 * n), call back with (2 * n) + (2 * (2 * n - 1))

          it('passes results for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkResult(6 * n - 2, done));
          });

          it('maintains state for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkVal.bind(this)(2 * n, done));
          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.target.around(
            'asyncFunc'
          , function (a, callback) {
              this.v++;
              callback();
            }
          , function (a, callback) {
              this.v++;
              callback();
            }
          );
        });

        [ 1, 2, 3, 4, 5 ].forEach(function (n) {

          // before: inc to (2 * n - 1)
          // target: call back with (0 + (2 * n - 1))
          // after:  inc to (2 * n)

          it('passes results for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkResult(2 * n - 1, done));
          });

          it('maintains state for ' + n + ' invocations', function (done) {
            repeat.bind(this)(n, checkVal.bind(this)(2 * n, done));
          });

        });

      });

    });

    describe('.wrap', function () {

      beforeEach(function () {
        this.target.wrap('asyncFunc', function (wrapped, a, callback) {
          this.v++;
          wrapped(a + this.v, function (err, result) {
            if (err) return callback(err);

            this.v++;
            callback(null, result + this.v);
          }.bind(this));
        });
      });

      [ 1, 2, 3, 4, 5 ].forEach(function (n) {

        // before: inc to (2 * n - 1), call back with 0 + (2 * n - 1)
        // target: call back with 2 * (2 * n - 1)
        // after:  inc to (2 * n), call back with (2 * n) + (2 * (2 * n - 1))

        it('passes results for ' + n + ' invocations', function (done) {
          repeat.bind(this)(n, checkResult(6 * n - 2, done));
        });

        it('maintains state for ' + n + ' invocations', function (done) {
          repeat.bind(this)(n, checkVal.bind(this)(2 * n, done));
        });

      });

    });

  });

});
