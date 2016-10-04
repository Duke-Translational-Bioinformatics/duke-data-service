assert = require('chai').assert
bf = require '../../src/api-blueprint-http-formatter'
fs = require 'fs'
pairs = require '../fixtures/pairs'
protagonist = require 'protagonist'

pairs = pairs.post

describe.only 'HTTP Message Blueprint formatter module', () ->
  describe 'format(pairs)', () ->
    it 'is a function', () ->
      assert.isFunction bf.format
 
    describe ' its return', () ->
      output = ""
      before () ->
        output = bf.format pairs

      it 'is a String', () ->
        assert.isString bf.format pairs

      keywords = ['+ Request', '+ Headers', '+ Body', '+ Response']      
      keywords.forEach (keyword) ->
        it 'has API Blueprint keyword: ' + keyword, () ->
          assert.include  output, keyword

      describe 'Request data', () ->
        request = {}

        before () ->
          request = pairs['request']
          output = bf.format pairs
        
        it 'has URI', () ->
          assert.include output, request['uri']
        
        it 'has method', () ->
          assert.include output, request['method']
        
        it 'has all header keys', () ->
          Object.keys(request['headers']).forEach (key) ->
            assert.include output, key

        it 'has all header values', () -> 
          Object.keys(request['headers']).forEach (key) ->
              assert.include output, request['headers'][key]

        it 'has all body lines', () ->
          request['body'].split('\n').forEach (line) ->
            assert.include output, line

      describe 'Response data', () ->
        response = {}

        before () ->
          response = pairs['response']
          output = bf.format pairs

        it 'has status code', () ->
          assert.include output, response['statusCode']

        it 'has all header values', () -> 
          Object.keys(response['headers']).forEach (key) ->
              assert.include output, response['headers'][key]

        it 'has all body lines', () ->
          response['body'].split('\n').forEach (line) ->
            assert.include output, line

      it 'is a parseable API Blueprint', () ->
        protagonist.parse output, (error, result) ->
          assert.isNull error

      it 'should be parsed without any warnings', () ->
        protagonist.parse output, (error, result) ->
          assert.equal result.warnings.length, 0

      it 'sould and with LF', () ->
        chars = output.split('')
        console.error output
        assert.equal chars[chars.length - 1], "\n"




