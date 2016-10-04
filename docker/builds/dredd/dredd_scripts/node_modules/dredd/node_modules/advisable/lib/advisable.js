(function (root, factory) {
  if (typeof exports === 'object') module.exports = factory();
  else if (typeof define === 'function' && define.amd) define(factory);
  else root.advisable = factory();
}(this, function () {

  // --- Synchronous advice methods

  /**
   * Adds synchronous before advice to a target method.
   *
   * @param {string} method       Target method name.
   * @param {Function} fn         Before advice function.
   * @param {Object} options
   *   @property {boolean} mutate If true, advice returns an array of
   *                              mutated arguments to pass to target
   *                              method. If false, target receives
   *                              target arguments and advice return value
   *                              is ignored.
   */

  function beforeSync(method, fn, options) {
    aroundSync.call(this, method, fn, null, options);
  }

  /**
   * Adds synchronous after advice to a target method.
   *
   * @param {string} method       Target method name.
   * @param {Function} fn         After advice function.
   * @param {Object} options
   *   @property {boolean} mutate If true, the return value of after advice
   *                              is returned to the caller of the advised
   *                              method. If false, the target return value
   *                              is returned to the advised method caller
   *                              and the advice return value is ignored.
   */

  function afterSync(method, fn, options) {
    aroundSync.call(this, method, null, fn, options);
  }

  /**
   * Adds synchronous around advice to a target method.
   *
   * @param {string} method       Target method name.
   * @param {Function} beforeFn   Before advice function.
   * @param {Function} afterFn    After advice function.
   * @param {Object} options
   *   @property {boolean} mutate If true, adheres to before/after advice
   *                              conventions for mutated arguments and
   *                              return values. If false, follows
   *                              non-mutated conventions.
   */

  function aroundSync(method, beforeFn, afterFn, options) {
    var target = this[method]
      , mutate = options && !!options.mutate;

    this[method] = function () {
      var rv
        , afterRv
        , afterArgs;

      beforeFn && (rv = beforeFn.apply(this, arguments));
      rv = target.apply(this, (rv && mutate ? rv : arguments));

      if (afterFn) {
        afterArgs = rv && mutate ? [ rv ] : arguments;
        afterRv = afterFn.apply(this, afterArgs);
      }

      return (mutate && afterRv) || rv;
    };
  }

  // --- Asynchronous advice methods

  /**
   * Adds asynchronous before advice to a target method.
   *
   * @param {string} method       Target method name.
   * @param {Function} fn         Before advice function.
   * @param {Object} options
   *   @property {boolean} mutate If true, advice calls back with arguments
   *                              to pass to target method. If false, target
   *                              receives target arguments and advice
   *                              callback arguments beyond initial error
   *                              argument are ignored.
   */

  function before(method, fn, options) {
    around.call(this, method, fn, null, options);
  }

  /**
   * Adds asynchronous after advice to a target method.
   *
   * @param {string} method       Target method name.
   * @param {Function} fn         After advice function.
   * @param {Object} options
   *   @property {boolean} mutate If true, advice is invoked with result
   *                              arguments passed to target method
   *                              callback, and advice callback arguments are
   *                              passed to the target caller's callback.
   *                              If false, advice is invoked with target
   *                              arguments, advice callback arguments are
   *                              ignored, and target callback arguments are
   *                              passed to target caller's callback.
   */

  function after(method, fn, options) {
    around.call(this, method, null, fn, options);
  }

  /**
   * Adds asynchronous around advice to a target method.
   *
   * @param {string} method       Target method name.
   * @param {Function} beforeFn   Before advice function.
   * @param {Function} afterFn    After advice function.
   * @param {Object} options
   *   @property {boolean} mutate If true, adheres to before/after async
   *                              advice conventions for mutated arguments
   *                              and return values. If false, follows
   *                              non-mutated conventions.
   */

  function around(method, beforeFn, afterFn, options) {
    var fns = []
      , mutate = options && !!options.mutate
      , first;

    beforeFn && fns.push(beforeFn);
    fns.push(this[method]);
    afterFn && fns.push(afterFn);

    this[method] = function () {
      var originalArgs = [].slice.call(arguments)
        , callback = originalArgs.pop()
        , fni = 0
        , chain;

      chain = function () {
        var args = [].slice.call(arguments)
          , err = args.shift()
          , nextArgs
          , next = fns[fni++]
          , last;

        if (err) return callback(err);

        !mutate && originalArgs.pop();
        nextArgs = mutate ? args : originalArgs;

        // When arg/result mutation is allowed, the final callback passes
        // the results of the last function in the chain. When mutation is
        // prohibited, the last callback needs to pass the results of the
        // target method. This is the last function when there is no after
        // function and the second to last function otherwise.
        last = (mutate || !afterFn) ? callback : function (err) {
          args.unshift(err);
          callback.apply(null, args);
        };
        nextArgs.push(fni === fns.length - 1 ? chain : last);

        next.apply(this, nextArgs);
      }.bind(this);

      originalArgs.push(chain);
      first = fns[fni++];
      first.apply(this, originalArgs);
    };
  }

  // --- Dual sync/async advice methods

  /**
   * Adds sync or async wrapper to a target method.
   *
   * Wrapper can add arbitrary code before and after target, and wrapper is
   * responsible for invocation of target, which is passed to the wrapper
   * as the first argument. Wrapper should either return or call back
   * depending on respective sync/async use.
   *
   * @param {string} method       Target method name.
   * @param {Function} fn         Wrapper function.
   */
  function wrap(method, fn) {
    var target = this[method];

    this[method] = function () {
      var args = [].slice.call(arguments);

      args.unshift(target.bind(this));

      return fn.apply(this, args);
    };
  }

  return {

    /**
     * sync advice interface
     */
    sync: function () {
      this.beforeSync = beforeSync;
      this.afterSync = afterSync;
      this.aroundSync = aroundSync;
      this.wrapSync = wrap;
    }

    /**
     * async advice interface
     */
  , async: function () {
      this.before = before;
      this.after = after;
      this.around = around;
      this.wrap = wrap;
    }

  };

}));
