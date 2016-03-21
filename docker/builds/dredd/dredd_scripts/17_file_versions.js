var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var tools = require('./tools.js');
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');


var LIST_VERSION = "File Versions > File Versions collection > List file versions";
var VIEW_VERSION = "File Versions > File Version instance > View file version";
var UPDATE_VERSION = "File Versions > File Version instance > Update file version";
var DELETE_VERSION = "File Versions > File Version instance > Delete file version";
var VERSION_URL = "File Versions > File Version instance > Get file version download URL";


var responseStash = {};
var g_fileId = null;

hooks.before(LIST_VERSION, function (transaction) {
  transaction.skip = true;
});

hooks.before(VIEW_VERSION, function (transaction) {
  transaction.skip = true;
});

hooks.before(UPDATE_VERSION, function (transaction) {
  transaction.skip = true;
});

hooks.before(DELETE_VERSION, function (transaction) {
  transaction.skip = true;
});

hooks.before(VERSION_URL, function (transaction) {
  transaction.skip = true;
});
