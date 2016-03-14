var hooks = require('hooks');
var tools = require('./tools.js');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var responseStash = {};

var SEARCH_UPLOADS = "Search Uploads > Search uploads > Search uploads";
var responseStash = {};
var g_uploadId = null;

hooks.before(SEARCH_UPLOADS, function (transaction) {
  transaction.skip = true;
});
