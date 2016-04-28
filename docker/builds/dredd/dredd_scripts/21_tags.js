var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var tools = require('./tools.js');
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');


var TAG_CREATE   = "Tags > Tags collection > NOT_IMPLEMENTED Create object tag"
var TAG_LIST_OBJ = "Tags > Tags collection > NOT_IMPLEMENTED List object tags"
var TAG_LIST_LAB = "Tags > Tags collection > NOT_IMPLEMENTED List tag labels"
var TAG_VIEW     = "Tags > Tag instance > NOT_IMPLEMENTED View tag"
var TAG_DELETE   = "Tags > Tag instance > NOT_IMPLEMENTED Delete tag"

var responseStash = {};

hooks.before(TAG_CREATE, function (transaction) {
  transaction.skip = true;
});

hooks.before(TAG_LIST_OBJ, function (transaction) {
  transaction.skip = true;
});

hooks.before(TAG_LIST_LAB, function (transaction) {
  transaction.skip = true;
});

hooks.before(TAG_VIEW, function (transaction) {
  transaction.skip = true;
});

hooks.before(TAG_DELETE, function (transaction) {
  transaction.skip = true;
});
