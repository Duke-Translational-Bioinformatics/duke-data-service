module.exports = function (grunt) {

  grunt.initConfig({
    lint: {
      all: [
        'grunt.js'
      , 'examples/**/*.js'
      , 'lib/**/*.js'
      , 'test/**/*.js'
      ]
    }
  , jshint: {
      options: {
        bitwise: true
      , curly: false
      , eqeqeq: true
      , forin: false
      , immed: true
      , latedef: true
      , newcap: true
      , noarg: true
      , noempty: true
      , nonew: true
      , plusplus: false
      , regexp: false
      , undef: false
      , strict: false
      , trailing: true
      , expr: true
      , laxcomma: true
      , es5: true
    }
  }
  , watch: {
      lint: {
        files: [ '<config:lint.all>' ]
      , tasks: 'lint'
      }
    }
  });

};
