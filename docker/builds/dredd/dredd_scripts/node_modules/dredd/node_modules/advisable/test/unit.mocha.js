/**
 * unit.mocha.js
 *
 * Unit tests with stubbing at every step in the call chain to assert
 * expectations on both function call arguments and return values.
 */

var path = require('path')
  , sinon = require('sinon')
  , advisable = require(path.resolve(__dirname, '..', 'lib', 'advisable'));

describe('advisable:unit', function () {

  beforeEach(function () {
    this.target = sinon.stub();
    this.obj = {
      target: this.target
    };
  });

  describe('sync', function () {

    beforeEach(function () {
      advisable.sync.call(this.obj);
    });

    describe('when advisable methods are mixed in but not used', function () {

      it('calls the target function with the passed arguments', function () {
        this.obj.target(1, 2, 3);

        this.target.should.have.been.calledWithExactly(1, 2, 3);
      });

      it('calls the target function with the correct context', function () {
        this.obj.target(1, 2, 3);

        this.target.lastCall.thisValue.should.equal(this.obj);
      });

      describe('when the target function throws', function () {

        beforeEach(function () {
          this.error = new Error('target-throws');
          this.target.throws(this.error);
        });

        it('throws the errors', function () {
          this.obj.target.should.throw(this.error);
        });

      });

      describe('when the target function returns', function () {

        beforeEach(function () {
          this.retval = 'target-return';
          this.target.returns(this.retval);
        });

        it('returns the target function return value', function () {
          this.obj.target(1, 2, 3).should.equal(this.retval);
        });

      });

    });

    describe('.beforeSync', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.obj.beforeSync('target', this.before, { mutate: true });
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3);

            this.before.should.have.been.calledWithExactly(1, 2, 3);
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3);

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice throws', function () {

            beforeEach(function () {
              this.error = 'beforeSync-mutate-before-throws';
              this.before.throws(this.error);
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

            it('does not call the target method', function () {
              try { this.obj.target(); } catch (e) {}

              this.target.should.not.have.been.called;
            });

          });

          describe('when the before advice returns', function () {

            beforeEach(function () {
              this.retval = [
                'beforeSync-mutate-before-return-one'
              , 'beforeSync-mutate-before-return-two'
              ];
              this.before.returns(this.retval);
            });

            it('invokes the target with the returned arguments', function () {
              this.obj.target(1, 2, 3);

              this.target.should.have.been.calledWithExactly(
                this.retval[0]
              , this.retval[1]
              );
            });

            it('invokes the target in the target object context', function () {
              this.obj.target(1, 2, 3);

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method throws', function () {

              beforeEach(function () {
                this.error = new Error('beforeSync-mutate-target-throws');
                this.target.throws(this.error);
              });

              it('throws the error', function () {
                this.obj.target.should.throw(this.error);
              });

            });

            describe('when the target method returns', function () {

              beforeEach(function () {
                this.retval = 'beforeSync-mutate-target-return';
                this.target.returns(this.retval);
              });

              it('returns the target method return value', function () {
                this.obj.target(1, 2, 3).should.equal(this.retval);
              });

            });

          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.obj.beforeSync('target', this.before);
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3);

            this.before.should.have.been.calledWithExactly(1, 2, 3);
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3);

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice throws', function () {

            beforeEach(function () {
              this.error = 'beforeSync-before-throws';
              this.before.throws(this.error);
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

            it('does not call the target method', function () {
              try { this.obj.target(); } catch (e) {}

              this.target.should.not.have.been.called;
            });

          });

          describe('when the before advice returns', function () {

            beforeEach(function () {
              this.retval = [
                'beforeSync-before-return-one'
              , 'beforeSync-before-return-two'
              ];
              this.before.returns(this.retval);
            });

            it('invokes the target with the original arguments', function () {
              this.obj.target(1, 2, 3);

              this.target.should.have.been.calledWithExactly(1, 2, 3);
            });

            it('invokes the target in the target object context', function () {
              this.obj.target(1, 2, 3);

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method throws', function () {

              beforeEach(function () {
                this.error = new Error('beforeSync-target-throws');
                this.target.throws(this.error);
              });

              it('throws the error', function () {
                this.obj.target.should.throw(this.error);
              });

            });

            describe('when the target method returns', function () {

              beforeEach(function () {
                this.retval = 'beforeSync-target-return';
                this.target.returns(this.retval);
              });

              it('returns the target method return value', function () {
                this.obj.target(1, 2, 3).should.equal(this.retval);
              });

            });

          });

        });

      });

    });

    describe('.afterSync', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.after = sinon.stub();
          this.obj.afterSync('target', this.after, { mutate: true });
        });

        describe('when the target method is invoked', function () {

          it('invokes the target with the passed arguments', function () {
            this.obj.target(1, 2, 3);

            this.target.should.have.been.calledWithExactly(1, 2, 3);
          });

          it('invokes the target in the target object context', function () {
            this.obj.target(1, 2, 3);

            this.target.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the target method throws', function () {

            beforeEach(function () {
              this.error = 'afterSync-mutate-target-throws';
              this.target.throws(this.error);
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

            it('does not call the after advice', function () {
              try { this.obj.target(); } catch (e) {}

              this.after.should.not.have.been.called;
            });

          });

          describe('when the target method returns', function () {

            beforeEach(function () {
              this.retval = 'afterSync-mutate-target-return';
              this.target.returns(this.retval);
            });

            it('invokes the after advice with the return value', function () {
              this.obj.target(1, 2, 3);

              this.after.should.have.been.calledWithExactly(this.retval);
            });

            it('invokes the advice in the target object context', function () {
              this.obj.target(1, 2, 3);

              this.after.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the advising method throws', function () {

              beforeEach(function () {
                this.error = new Error('afterSync-mutate-after-throws');
                this.after.throws(this.error);
              });

              it('throws the error', function () {
                this.obj.target.should.throw(this.error);
              });

            });

            describe('when the advising method returns', function () {

              beforeEach(function () {
                this.retval = 'afterSync-mutate-target-return';
                this.after.returns(this.retval);
              });

              it('returns the advising method return value', function () {
                this.obj.target(1, 2, 3).should.equal(this.retval);
              });

            });

          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.after = sinon.stub();
          this.obj.afterSync('target', this.after);
        });

        describe('when the target method is invoked', function () {

          it('invokes the target with the passed arguments', function () {
            this.obj.target(1, 2, 3);

            this.target.should.have.been.calledWithExactly(1, 2, 3);
          });

          it('invokes the target in the target object context', function () {
            this.obj.target(1, 2, 3);

            this.target.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the target method throws', function () {

            beforeEach(function () {
              this.error = 'afterSync-mutate-target-throws';
              this.target.throws(this.error);
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

            it('does not call the advising method', function () {
              try { this.obj.target(); } catch (e) {}

              this.after.should.not.have.been.called;
            });

          });

          describe('when the target method returns', function () {

            beforeEach(function () {
              this.retval = 'afterSync-target-return';
              this.target.returns(this.retval);
            });

            it('invokes the advice with the original arguments', function () {
              this.obj.target(1, 2, 3);

              this.after.should.have.been.calledWithExactly(1, 2, 3);
            });

            it('invokes the advice in the target object context', function () {
              this.obj.target(1, 2, 3);

              this.after.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the advising method throws', function () {

              beforeEach(function () {
                this.error = new Error('afterSync-after-throws');
                this.after.throws(this.error);
              });

              it('throws the error', function () {
                this.obj.target.should.throw(this.error);
              });

            });

            describe('when the advising method returns', function () {

              beforeEach(function () {
                this.afterRetval = 'afterSync-after-return';
                this.after.returns(this.afterRetval);
              });

              it('returns the advising method return value', function () {
                this.obj.target(1, 2, 3).should.equal(this.retval);
              });

            });

          });

        });

      });

    });

    describe('.aroundSync', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.after = sinon.stub();
          this.obj.aroundSync(
            'target'
          , this.before
          , this.after
          , { mutate: true });
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3);

            this.before.should.have.been.calledWithExactly(1, 2, 3);
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3);

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice throws', function () {

            beforeEach(function () {
              this.error = 'aroundSync-mutate-before-throws';
              this.before.throws(this.error);
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

            it('does not call the target method', function () {
              try { this.obj.target(); } catch (e) {}

              this.target.should.not.have.been.called;
            });

            it('does not call the after advice', function () {
              try { this.obj.target(); } catch (e) {}

              this.after.should.not.have.been.called;
            });

          });

          describe('when the before advice returns', function () {

            beforeEach(function () {
              this.retval = [
                'aroundSync-mutate-before-return-one'
              , 'aroundSync-mutate-before-return-two'
              ];
              this.before.returns(this.retval);
            });

            it('invokes the target with the returned arguments', function () {
              this.obj.target(1, 2, 3);

              this.target.should.have.been.calledWithExactly(
                this.retval[0]
              , this.retval[1]
              );
            });

            it('invokes the target in the target context', function () {
              this.obj.target(1, 2, 3);

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method throws', function () {

              beforeEach(function () {
                this.error = new Error('aroundSync-mutate-target-throws');
                this.target.throws(this.error);
              });

              it('throws the error', function () {
                this.obj.target.should.throw(this.error);
              });

              it('does not call the after advice', function () {
                try { this.obj.target(); } catch (e) {}

                this.after.should.not.have.been.called;
              });

            });

            describe('when the target method returns', function () {

              beforeEach(function () {
                this.retval = 'aroundSync-mutate-target-return';
                this.target.returns(this.retval);
              });

              it('invokes after advice with target return value', function () {
                this.obj.target(1, 2, 3);

                this.after.should.have.been.calledWithExactly(this.retval);
              });

              it('invokes the advice in the target context', function () {
                this.obj.target(1, 2, 3);

                this.after.lastCall.thisValue.should.equal(this.obj);
              });

              describe('when the after advice throws', function () {

                beforeEach(function () {
                  this.error = new Error('aroundSync-mutate-after-throws');
                  this.after.throws(this.error);
                });

                it('throws the error', function () {
                  this.obj.target.should.throw(this.error);
                });

              });

              describe('when the after advice returns', function () {

                beforeEach(function () {
                  this.retval = 'aroundSync-mutate-after-return';
                  this.after.returns(this.retval);
                });

                it('returns the after advice return value', function () {
                  this.obj.target(1, 2, 3).should.equal(this.retval);
                });

              });

            });

          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.after = sinon.stub();
          this.obj.aroundSync('target', this.before, this.after);
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3);

            this.before.should.have.been.calledWithExactly(1, 2, 3);
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3);

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice throws', function () {

            beforeEach(function () {
              this.error = 'aroundSync-before-throws';
              this.before.throws(this.error);
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

            it('does not call the target method', function () {
              try { this.obj.target(); } catch (e) {}

              this.target.should.not.have.been.called;
            });

            it('does not call the after advice', function () {
              try { this.obj.target(); } catch (e) {}

              this.after.should.not.have.been.called;
            });

          });

          describe('when the before advice returns', function () {

            beforeEach(function () {
              this.retval = [
                'aroundSync-before-return-one'
              , 'aroundSync-before-return-two'
              ];
              this.before.returns(this.retval);
            });

            it('invokes the target with the original arguments', function () {
              this.obj.target(1, 2, 3);

              this.target.should.have.been.calledWithExactly(1, 2, 3);
            });

            it('invokes the target in the target context', function () {
              this.obj.target(1, 2, 3);

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method throws', function () {

              beforeEach(function () {
                this.error = new Error('aroundSync-target-throws');
                this.target.throws(this.error);
              });

              it('throws the error', function () {
                this.obj.target.should.throw(this.error);
              });

              it('does not call the after advice', function () {
                try { this.obj.target(); } catch (e) {}

                this.after.should.not.have.been.called;
              });

            });

            describe('when the target method returns', function () {

              beforeEach(function () {
                this.retval = 'aroundSync-target-return';
                this.target.returns(this.retval);
              });

              it('invokes after advice with original arguments', function () {
                this.obj.target(1, 2, 3);

                this.after.should.have.been.calledWithExactly(1, 2, 3);
              });

              it('invokes after advice in the target context', function () {
                this.obj.target(1, 2, 3);

                this.after.lastCall.thisValue.should.equal(this.obj);
              });

              describe('when the after advice throws', function () {

                beforeEach(function () {
                  this.error = new Error('aroundSync-after-throws');
                  this.after.throws(this.error);
                });

                it('throws the error', function () {
                  this.obj.target.should.throw(this.error);
                });

              });

              describe('when the after advice returns', function () {

                beforeEach(function () {
                  this.afterRetval = 'aroundSync-after-return';
                  this.after.returns(this.retval);
                });

                it('returns the target method return value', function () {
                  this.obj.target(1, 2, 3).should.equal(this.retval);
                });

              });

            });

          });

        });

      });

    });

    describe('.wrapSync', function () {

      beforeEach(function () {
        var self = this;

        this.wa = 'wrapper-modified-arg-a';
        this.wb = 'wrapper-modified-arg-b';
        this.wc = 'wrapper-modified-arg-c';
        this.wrv = 'wrapper-modified-return-value';
        this.rv = null;

        this.wrapper = function (wrapped, a, b, c) {
          self.rv = wrapped(self.wa, self.wb, self.wc);

          return self.wrv;
        };
        sinon.spy(this, 'wrapper');

        this.obj.wrapSync('target', this.wrapper);
      });

      describe('when the target method is invoked', function () {

        it('invokes the wrapper with the target as first arg', function () {
          // Stub out auto-binding
          sinon.stub(this.target, 'bind').returns(this.target);
          this.obj.target(1, 2, 3);

          this.wrapper.should.have.been.calledWithExactly(
            this.target
           , 1
           , 2
           , 3
           );
        });

        it('invokes the wrapper in the target context', function () {
          this.obj.target(1, 2, 3);

          this.wrapper.lastCall.thisValue.should.equal(this.obj);
        });

        describe('when the wrapper invokes the target', function () {

          it('can modify the arguments', function () {
            this.obj.target(1, 2, 3);

            this.target.should.have.been.calledWithExactly(
              this.wa
            , this.wb
            , this.wc
            );
          });

          it('invokes in the target context', function () {
            this.obj.target(1, 2, 3);

            this.target.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the wrapped target returns', function () {

            beforeEach(function () {
              this.retval = 'wrapSync-target-return';
              this.target.returns(this.retval);
            });

            it('supplies a return value to the wrapper', function () {
              this.obj.target(1, 2, 3);

              this.rv.should.equal(this.retval);
            });

          });

          describe('when the wrapper returns', function () {

            it('supplies the wrapper return value', function () {
              this.obj.target(1, 2, 3).should.equal(this.wrv);
            });

          });

        });

        describe('when the wrapper throws', function () {

          beforeEach(function () {
            this.error = 'wrapSync-throws';
          });

          describe('before calling the target', function () {

            beforeEach(function () {
              var self = this;

              this.obj.wrapSync('target', function (wrapped, a, b, c) {
                sinon.stub().throws(self.error)();

                return wrapped(a, b, c);
              });
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

            it('does not call the target', function () {
              try { this.obj.target(); } catch (e) {}

              this.target.should.not.have.been.called;
            });

          });

          describe('after calling the target', function () {

            beforeEach(function () {
              var self = this;

              this.obj.wrapSync('target', function (wrapped, a, b, c) {
                var rv = wrapped(a, b, c);

                sinon.stub().throws(self.error)();

                return rv;
              });
            });

            it('calls the target', function () {
              try { this.obj.target(1, 2, 3); } catch (e) {}

              this.target.should.have.been.calledWithExactly(
                this.wa
              , this.wb
              , this.wc
              );
            });

            it('throws the error', function () {
              this.obj.target.should.throw(this.error);
            });

          });

        });

        describe('when the target throws', function () {

          beforeEach(function () {
            this.error = 'wrapSync-target-throws';
            this.target.throws(this.error);
          });

          it('throws the error', function () {
            this.obj.target.should.throw(this.error);
          });

        });

      });

    });

  });

  describe('async', function () {

    beforeEach(function () {
      advisable.async.call(this.obj);
    });

    describe('when advisable methods are mixed in but not used', function () {

      describe('when the target function is invoked', function () {

        it('calls the target function with the passed arguments', function () {
          var callback = function () {};

          this.obj.target(1, 2, 3, callback);

          this.target.should.have.been.calledWithExactly(1, 2, 3, callback);
        });

        it('calls the target function in the target context', function () {
          this.obj.target(1, 2, 3, function () {});

          this.target.lastCall.thisValue.should.equal(this.obj);
        });

        describe('when the target function errors', function () {

          beforeEach(function () {
            this.error = new Error('target-errors');
            this.target.yields(this.error);
          });

          it('calls back with the error', function (done) {
            this.obj.target(1, 2, 3, function (err, result) {
              err.should.equal(this.error);
              done();
            }.bind(this));
          });

        });

        describe('when the target function succeeds', function () {

          beforeEach(function () {
            this.retval = 'target-result';
            this.target.yields(null, this.retval);
          });

          it('calls back with the results', function (done) {
            this.obj.target(1, 2, 3, function (err, result) {
              result.should.equal(this.retval);
              done();
            }.bind(this));
          });

        });

      });

    });

    describe('.before', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.obj.before('target', this.before, { mutate: true });
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.should.have.been.calledWithExactly(
              1
            , 2
            , 3
            , sinon.match.func
            );
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice errors', function () {

            beforeEach(function () {
              this.error = new Error('before-mutate-before-errors');
              this.before.yields(this.error);
            });

            it('calls back with the error', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                err.should.equal(this.error);
                done();
              }.bind(this));
            });

            it('does not call the target method', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                this.target.should.not.have.been.called;
                done();
              }.bind(this));
            });

          });

          describe('when the before advice succeeds', function () {

            beforeEach(function () {
              this.resultOne = 'before-mutate-before-result-one';
              this.resultTwo = 'before-mutate-before-result-two';
              this.resultThree = 'before-mutate-before-result-three';
              this.before.yields(
                null
              , this.resultOne
              , this.resultTwo
              , this.resultThree
              );
            });

            it('invokes the target with the advice results', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.should.have.been.calledWithExactly(
                this.resultOne
              , this.resultTwo
              , this.resultThree
              , sinon.match.func
              );
            });

            it('invokes the target in the target context', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method errors', function () {

              beforeEach(function () {
                this.error = new Error('before-mutate-target-errors');
                this.target.yields(this.error);
              });

              it('calls back with the error', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  err.should.equal(this.error);
                  done();
                }.bind(this));
              });

            });

            describe('when the target method succeeds', function () {

              beforeEach(function () {
                this.result = 'before-mutate-target-result';
                this.target.yields(null, this.result);
              });

              it('calls back with the target method results', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  result.should.equal(this.result);
                  done();
                }.bind(this));
              });

            });

          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.obj.before('target', this.before);
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.should.have.been.calledWithExactly(
              1
            , 2
            , 3
            , sinon.match.func
            );
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice errors', function () {

            beforeEach(function () {
              this.error = 'before-before-errors';
              this.before.yields(this.error);
            });

            it('calls back with the error', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                err.should.equal(this.error);
                done();
              }.bind(this));
            });

          });

          describe('when the before advice succeeds', function () {

            beforeEach(function () {
              this.resultOne = 'before-before-result-one';
              this.resultTwo = 'before-before-result-two';
              this.resultThree = 'before-before-result-three';
              this.before.yields(
                null
              , this.resultOne
              , this.resultTwo
              , this.resultThree
              );
            });

            it('invokes the target with the original arguments', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.should.have.been.calledWithExactly(
                1
              , 2
              , 3
              , sinon.match.func
              );
            });

            it('invokes the target in the target context', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method errors', function () {

              beforeEach(function () {
                this.error = new Error('before-target-errors');
                this.target.yields(this.error);
              });

              it('calls back with the error', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  err.should.equal(this.error);
                  done();
                }.bind(this));
              });

            });

            describe('when the target method succeeds', function () {

              beforeEach(function () {
                this.result = 'before-target-result';
                this.target.yields(null, this.result);
              });

              it('calls back with the target method results', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  result.should.equal(this.result);
                  done();
                }.bind(this));
              });

            });

          });

        });

      });

    });

    describe('.after', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.after = sinon.stub();
          this.obj.after('target', this.after, { mutate: true });
        });

        describe('when the target method is invoked', function () {

          it('invokes the target with the passed arguments', function () {
            this.obj.target(1, 2, 3, function () {});

            this.target.should.have.been.calledWithExactly(
              1
            , 2
            , 3
            , sinon.match.func
            );
          });

          it('invokes the target method in the target context', function () {
            this.obj.target(1, 2, 3, function () {});

            this.target.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the target method errors', function () {

            beforeEach(function () {
              this.error = 'after-mutate-target-errors';
              this.target.yields(this.error);
            });

            it('calls back with the error', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                err.should.equal(this.error);
                done();
              }.bind(this));
            });

            it('does not call the after advice', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                this.after.should.not.have.been.called;
                done();
              }.bind(this));
            });

          });

          describe('when the target method succeeds', function () {

            beforeEach(function () {
              this.result = 'after-mutate-target-result';
              this.target.yields(null, this.result);
            });

            it('invokes after advice with the target results', function () {
              this.obj.target(1, 2, 3, function () {});

              this.after.should.have.been.calledWithExactly(
                this.result
              , sinon.match.func
              );
            });

            it('invokes after advice in the target context', function () {
              this.obj.target(1, 2, 3, function () {});

              this.after.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the advising method errors', function () {

              beforeEach(function () {
                this.error = new Error('after-mutate-after-errors');
                this.target.yields(this.error);
              });

              it('calls back with the error', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  err.should.equal(this.error);
                  done();
                }.bind(this));
              });

            });

            describe('when the advising method succeeds', function () {

              beforeEach(function () {
                this.afterResult = 'after-mutate-after-result';
                this.after.yields(null, this.afterResult);
              });

              it('calls back with the the advice results', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  result.should.equal(this.afterResult);
                  done();
                }.bind(this));
              });

            });

          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.after = sinon.stub();
          this.obj.after('target', this.after);
        });

        describe('when the target method is invoked', function () {

          it('invokes with the passed arguments', function () {
            this.obj.target(1, 2, 3, function () {});

            this.target.should.have.been.calledWithExactly(
              1
            , 2
            , 3
            , sinon.match.func
            );
          });

          it('invokes the target method in the target context', function () {
            this.obj.target(1, 2, 3, function () {});

            this.target.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the target method errors', function () {

            beforeEach(function () {
              this.error = 'after-target-errors';
              this.target.yields(this.error);
            });

            it('calls back with the error', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                err.should.equal(this.error);
                done();
              }.bind(this));
            });

            it('does not call the after advice', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                this.after.should.not.have.been.called;
                done();
              }.bind(this));
            });

          });

          describe('when the target method succeeds', function () {

            beforeEach(function () {
              this.result = 'after-target-result';
              this.target.yields(null, this.result);
            });

            it('invokes the advice with the original arguments', function () {
              this.obj.target(1, 2, 3, function () {});

              this.after.should.have.been.calledWithExactly(
                1
              , 2
              , 3
              , sinon.match.func
              );
            });

            it('invokes after advice in the target context', function () {
              this.obj.target(1, 2, 3, function () {});

              this.after.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the advising method errors', function () {

              beforeEach(function () {
                this.error = new Error('after-after-errors');
                this.target.yields(this.error);
              });

              it('calls back with the error', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  err.should.equal(this.error);
                  done();
                }.bind(this));
              });

            });

            describe('when the advising method succeeds', function () {

              beforeEach(function () {
                this.afterResult = 'after-after-result';
                this.after.yields(null, this.afterResult);
              });

              it('calls back with the target method results', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  result.should.equal(this.result);
                  done();
                }.bind(this));
              });

            });

          });

        });

      });

    });

    describe('.around', function () {

      describe('when the mutate option is true', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.after = sinon.stub();
          this.obj.around('target', this.before, this.after, { mutate: true });
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.should.have.been.calledWithExactly(
              1
            , 2
            , 3
            , sinon.match.func
            );
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice errors', function () {

            beforeEach(function () {
              this.error = new Error('around-mutate-before-errors');
              this.before.yields(this.error);
            });

            it('calls back with the error', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                err.should.equal(this.error);
                done();
              }.bind(this));
            });

            it('does not call the target method', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                this.target.should.not.have.been.called;
                done();
              }.bind(this));
            });

            it('does not call the after advice', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                this.after.should.not.have.been.called;
                done();
              }.bind(this));
            });

          });

          describe('when the before advice succeeds', function () {

            beforeEach(function () {
              this.resultOne = 'around-before-mutate-result-one';
              this.resultTwo = 'around-before-mutate-result-two';
              this.resultThree = 'around-before-mutate-result-three';
              this.before.yields(
                null
              , this.resultOne
              , this.resultTwo
              , this.resultThree
              );
            });

            it('invokes the target with the before results', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.should.have.been.calledWithExactly(
                this.resultOne
              , this.resultTwo
              , this.resultThree
              , sinon.match.func
              );
            });

            it('invokes the target in the target context', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method errors', function () {

              beforeEach(function () {
                this.error = new Error('around-mutate-target-errors');
                this.target.yields(this.error);
              });

              it('calls back with the error', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  err.should.equal(this.error);
                  done();
                }.bind(this));
              });

              it('does not call the after advice', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  this.after.should.not.have.been.called;
                  done();
                }.bind(this));
              });

            });

            describe('when the target method succeeds', function () {

              beforeEach(function () {
                this.result = 'around-mutate-target-result';
                this.target.yields(null, this.result);
              });

              it('invokes the after advice with target results', function () {
                this.obj.target(1, 2, 3, function () {});

                this.after.should.have.been.calledWithExactly(
                  this.result
                , sinon.match.func
                );
              });

              it('invokes after advice in the target context', function () {
                this.obj.target(1, 2, 3, function () {});

                this.after.lastCall.thisValue.should.equal(this.obj);
              });

              describe('when the after advice errors', function () {

                beforeEach(function () {
                  this.error = new Error('around-mutate-after-errors');
                  this.after.yields(this.error);
                });

                it('calls back with the error', function (done) {
                  this.obj.target(1, 2, 3, function (err, result) {
                    err.should.equal(this.error);
                    done();
                  }.bind(this));
                });

              });

              describe('when the after advice succeeds', function () {

                beforeEach(function () {
                  this.afterResults = [
                    'around-mutate-after-result-one'
                  , 'around-mutate-after-result-two'
                  ];
                  this.after.yields(
                    null
                  , this.afterResults[0]
                  , this.afterResults[1]
                  );
                });

                it('calls back with the after results', function (done) {
                  this.obj.target(1, 2, 3, function (err, r1, r2) {
                    [ r1, r2 ].should.deep.equal(this.afterResults);
                    done();
                  }.bind(this));
                });

              });

            });

          });

        });

      });

      describe('when the mutate option is not passed', function () {

        beforeEach(function () {
          this.before = sinon.stub();
          this.after = sinon.stub();
          this.obj.around('target', this.before, this.after);
        });

        describe('when the target method is invoked', function () {

          it('invokes before advice with the passed arguments', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.should.have.been.calledWithExactly(
              1
            , 2
            , 3
            , sinon.match.func
            );
          });

          it('invokes before advice in the target context', function () {
            this.obj.target(1, 2, 3, function () {});

            this.before.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the before advice errors', function () {

            beforeEach(function () {
              this.error = new Error('around-before-errors');
              this.before.yields(this.error);
            });

            it('calls back with the error', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                err.should.equal(this.error);
                done();
              }.bind(this));
            });

            it('does not call the target method', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                this.target.should.not.have.been.called;
                done();
              }.bind(this));
            });

            it('does not call the after advice', function (done) {
              this.obj.target(1, 2, 3, function (err, result) {
                this.after.should.not.have.been.called;
                done();
              }.bind(this));
            });

          });

          describe('when the before advice succeeds', function () {

            beforeEach(function () {
              this.resultOne = 'around-before-mutate-result-one';
              this.resultTwo = 'around-before-mutate-result-two';
              this.resultThree = 'around-before-mutate-result-three';
              this.before.yields(
                null
              , this.resultOne
              , this.resultTwo
              , this.resultThree
              );
            });

            it('invokes the target with the original arguments', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.should.have.been.calledWithExactly(
                1
              , 2
              , 3
              , sinon.match.func
              );
            });

            it('invokes the target in the target context', function () {
              this.obj.target(1, 2, 3, function () {});

              this.target.lastCall.thisValue.should.equal(this.obj);
            });

            describe('when the target method errors', function () {

              beforeEach(function () {
                this.error = new Error('around-target-errors');
                this.target.yields(this.error);
              });

              it('calls back with the error', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  err.should.equal(this.error);
                  done();
                }.bind(this));
              });

              it('does not call the after advice', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  this.after.should.not.have.been.called;
                  done();
                }.bind(this));
              });

            });

            describe('when the target method succeeds', function () {

              beforeEach(function () {
                this.result = 'around-target-result';
                this.target.yields(null, this.result);
              });

              it('invokes after advice with original arguments', function () {
                this.obj.target(1, 2, 3, function () {});

                this.after.should.have.been.calledWithExactly(
                  1
                , 2
                , 3
                , sinon.match.func
                );
              });

              it('invokes after advice in the target context', function () {
                this.obj.target(1, 2, 3, function () {});

                this.after.lastCall.thisValue.should.equal(this.obj);
              });

              describe('when the after advice errors', function () {

                beforeEach(function () {
                  this.error = new Error('around-after-errors');
                  this.after.yields(this.error);
                });

                it('calls back with the error', function (done) {
                  this.obj.target(1, 2, 3, function (err, result) {
                    err.should.equal(this.error);
                    done();
                  }.bind(this));
                });

              });

              describe('when the after advice succeeds', function () {

                beforeEach(function () {
                  this.afterResults = [
                    'around-after-result-one'
                  , 'around-after-result-two'
                  ];
                  this.after.yields(
                    null
                  , this.afterResults[0]
                  , this.afterResults[1]
                  );
                });

                it('calls back with the target results', function (done) {
                  this.obj.target(1, 2, 3, function (err, result) {
                    result.should.equal(this.result);
                    done();
                  }.bind(this));
                });

              });

            });

          });

        });

      });

    });

    describe('.wrap', function () {

      beforeEach(function () {
        var self = this;

        this.wa = 'wrapper-modified-arg-a';
        this.wb = 'wrapper-modified-arg-b';
        this.wc = 'wrapper-modified-arg-c';
        this.wrv = 'wrapper-modified-return-value';
        this.rv = null;

        this.wrapper = function (wrapped, a, b, c, callback) {
          wrapped(self.wa, self.wb, self.wc, function (err, result) {
            if (err) return callback(err);

            self.rv = result;
            process.nextTick(function () {
              callback(null, self.wrv);
            });
          });
        };
        sinon.spy(this, 'wrapper');
        this.callback = sinon.stub();

        this.obj.wrap('target', this.wrapper);
      });

      describe('when the target method is invoked', function () {

        it('invokes the wrapper with the target as first arg', function () {
          // Stub out auto-binding
          sinon.stub(this.target, 'bind').returns(this.target);
          this.obj.target(1, 2, 3, this.callback);

          this.wrapper.should.have.been.calledWithExactly(
            this.target
          , 1
          , 2
          , 3
          , this.callback
          );
        });

        it('invokes the wrapper in the target context', function () {
          this.obj.target(1, 2, 3, this.callback);

          this.wrapper.lastCall.thisValue.should.equal(this.obj);
        });

        describe('when the wrapper invokes the target', function () {

          it('can modify the arguments', function () {
            this.obj.target(1, 2, 3, this.callback);

            this.target.should.have.been.calledWithExactly(
              this.wa
            , this.wb
            , this.wc
            , sinon.match.func
            );
          });

          it('invokes in the target context', function () {
            this.obj.target(1, 2, 3, this.callback);

            this.target.lastCall.thisValue.should.equal(this.obj);
          });

          describe('when the wrapped target errors', function () {

            beforeEach(function () {
              this.error = new Error('wrap-target-error');
              this.target.yields(this.error);
            });

            it('calls back with the error', function () {
              this.obj.target(1, 2, 3, this.callback);

              this.callback.should.have.been.calledWithExactly(this.error);
            });

          });

          describe('when the wrapped target succeeds', function () {

            beforeEach(function () {
              this.result = new Error('wrap-target-result');
              this.target.yields(null, this.result);
            });

            it('passes the result to the wrapper', function () {
              this.obj.target(1, 2, 3, this.callback);

              this.rv.should.equal(this.result);
            });

            describe('when the wrapper calls back', function () {

              it('supplies a result to the wrapped caller', function (done) {
                this.obj.target(1, 2, 3, function (err, result) {
                  result.should.equal(this.wrv);
                  done();
                }.bind(this));
              });

            });

          });

        });

      });

    });

  });

});
