#!/usr/local/bin/node
var readline = require('readline');
var rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false
});

var htmlparser = require("htmlparser2");
var parser = new htmlparser.Parser({
    ontext: function(text){
      var vals = text.split(' ');
      console.log('<div id="'+vals[2]+'">'+'<%= ',vals[0],'"'+vals[1]+'"','%>'+'</div>');
    },
});

rl.on('line', function(line){

  if (line.indexOf('render') == -1) {
    console.log(line);
  } else {
    parser.write(line);
  }
})
