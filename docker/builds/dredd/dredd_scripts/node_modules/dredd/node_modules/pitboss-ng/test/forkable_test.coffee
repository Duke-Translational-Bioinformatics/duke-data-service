{assert} = require 'chai'
{fork} = require 'child_process'

describe "The forkable process", ->
  referenceErrorMsg = 'VM Runtime Error: ReferenceError:'
  syntaxErrorMsg = 'VM Syntax Error: SyntaxError:'
  typeErrorMsg = 'VM Runtime Error: TypeError:'

  beforeEach ->
    @runner = fork './lib/forkable.js'
    return

  afterEach ->
    @runner?.kill?()
    @runner = null
    return

  describe "basic operation", ->
    beforeEach ->
      @code = """
        // EchoTron: returns the 'data' variable in a VM
        if(typeof data == "undefined") {
          var data = null
        };
        data
      """

    it "run without errors", (done) ->
      @runner.on 'message', (msg) ->
        assert.equal(msg.id, "123")
        assert.equal(msg.result, null)
        done()
      @runner.send({code: @code}) # Setup
      @runner.send({id: "123", context:{}}) # Setup

  describe "running code that assumes priviledge", ->
    beforeEach ->
      @code = """
        require('http');
        123;
      """

    it "should fail on require", (done) ->
      @runner.on 'message', (msg) ->
        assert.equal(msg.id, "123")
        assert.equal(msg.result, null)
        assert.include msg.error, "require is not defined"
        assert.include msg.error, referenceErrorMsg
        done()
      @runner.send({code: @code}) # Setup
      @runner.send({id: "123", context:{}}) # Setup

  describe "Running code that uses JSON global", ->
    beforeEach ->
      @code = """
        JSON.stringify({});
      """

    it "should work as expected", (done) ->
      @runner.on 'message', (msg) ->
        assert.equal(msg.id, "123")
        assert.equal(msg.result, '{}')
        done()
      @runner.send({code: @code}) # Setup
      @runner.send({id: "123", context:{}}) # Setup

  describe "Running code that uses Buffer", ->
    beforeEach ->
      @code = """
        var buf = new Buffer();
        123;
      """

    it "should fail on require", (done) ->
      @runner.on 'message', (msg) ->
        assert.equal(msg.id, "123")
        assert.equal(msg.result, null)
        assert.include msg.error, 'Buffer is not defined'
        assert.include msg.error, referenceErrorMsg
        done()
      @runner.send({code: @code}) # Setup
      @runner.send({id: "123", context:{}}) # Setup

  describe "Running shitty code", ->
    beforeEach ->
      @code = """
        This isn't even Javascript!!!!
      """

    # We can't even run this code, so we return an error immediately on run
    it "should return errors on running of bad syntax code", (done) ->
      @runner.on 'message', (msg) ->
        assert.equal(msg.id, "123")
        assert.equal(msg.result, undefined)
        assert.include msg.error, syntaxErrorMsg
        assert.include msg.error, "Unexpected identifier"
        done()
      @runner.send({code: @code}) # Setup
      @runner.send({id: "123", context:{}}) # Setup

  describe "Running runtime error code", ->
    beforeEach ->
      @code = """
        var foo = [];
        foo[data][123];
      """

    it "should happily suck up and relay the errors", (done) ->
      @runner.on 'message', (msg) ->
        assert.equal(msg.id, "123")
        assert.equal(msg.result, undefined)
        assert.include msg.error, typeErrorMsg
        assert.include msg.error, "Cannot read property '123' of undefined"
        done()
      @runner.send({code: @code}) # Setup
      @runner.send({id: "123", context:{data:'foo'}}) # Setup

  describe "requiring libraries in context", () ->
    describe "from array", () ->
      beforeEach ->
        @code = """
          if(vm == undefined){
            throw('vm is undefined');
          }
          null
        """

      it "should require and pass library to the context under variriable with module name", (done) ->
        @runner.on 'message', (msg) ->
          assert.equal msg.id, "123"
          assert.equal msg.result, null
          assert.equal msg.error, null
          done()

        @runner.send({code: @code}) # Setup
        @runner.send({id: "123", context: {data:'foo'}, libraries: ['vm']}) # Setup

    describe "from object for specifiyng context variable name", () ->
      beforeEach ->
        @code = """
          if(vmFooBar == undefined){
            throw('vmFooBar is undefined');
          }
          null
        """

      it "should require and pass library to the context under variable with key name", (done) ->
        @runner.on 'message', (msg) ->
          assert.equal msg.id, "123"
          assert.equal msg.result, null
          assert.equal msg.error, null
          done()

        @runner.send({code: @code}) # Setup
        @runner.send({id: "123", context: {data:'foo'}, libraries: {'vmFooBar': 'vm'}}) # Setup

    describe "from unintentional other type", () ->
      beforeEach ->
        @code = """
        var a = 'result'
        a
        """

      it "should raise and exception telling that it expects array or obejct", (done) ->
        @runner.on 'message', (msg) ->
          assert.equal msg.id, "1234"
          assert.equal msg.result, undefined
          assert.equal msg.error, "Pitboss error: Libraries must be defined by an array or by an object."
          done()

        @runner.send({code: @code}) # Setup
        @runner.send({id: "1234", context: {data:'foo'}, libraries: "vm"}) # Setup

