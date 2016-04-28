var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var tools = require('./tools.js');
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');


var SEARCH_PROV = "Search Provenance > NOT_IMPLEMENTED Search Provenance > NOT_IMPLEMENTED Search Provenance";

var responseStash = {};

hooks.before(SEARCH_PROV, function (transaction) {
  transaction.skip = true;
});
