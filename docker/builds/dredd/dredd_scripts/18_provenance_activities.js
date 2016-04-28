var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var tools = require('./tools.js');
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');


var PROV_CREATE   = "Provenance Activities > Activities collection > NOT_IMPLEMENTED Create activity"
var PROV_LIST     = "Provenance Activities > Activities collection > NOT_IMPLEMENTED List activities";
var PROV_VIEW     = "Provenance Activities > Activities instance > NOT_IMPLEMENTED View activity";
var PROV_UPDATE   = "Provenance Activities > Activities instance > NOT_IMPLEMENTED Update activity";
var PROV_DELETE   = "Provenance Activities > Activities instance > NOT_IMPLEMENTED Delete activity";

var responseStash = {};

hooks.before(PROV_CREATE, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_LIST, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_VIEW, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_UPDATE, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_DELETE, function (transaction) {
  transaction.skip = true;
});
