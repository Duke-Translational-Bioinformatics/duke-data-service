#!/usr/local/bin/node
process.stdin.resume();
process.stdin.setEncoding('utf8');

var htmlInput = "";

process.stdin.on('data', function(chunk) {
    htmlInput = htmlInput + chunk;
});

process.stdin.on('end', function() {
  var cheerio = require('cheerio'),
      $ = cheerio.load(htmlInput);
  console.log($.html('section.resource-group'));
});
