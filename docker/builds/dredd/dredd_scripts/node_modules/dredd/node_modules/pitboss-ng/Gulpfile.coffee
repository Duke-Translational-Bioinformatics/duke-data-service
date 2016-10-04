gulp   = require 'gulp'
coffee = require 'gulp-coffee'
mocha  = require 'gulp-mocha'

gulp.task 'test', ['build'], ->
  gulp.src('test/*.coffee', read: false)
    .pipe mocha(timeout: 120000, reporter: 'spec')
    .once('end', ->
      process.exit()
    )

gulp.task 'build', ->
  gulp.src('src/*.coffee')
    .pipe coffee bare: true
    .pipe gulp.dest 'lib/'
