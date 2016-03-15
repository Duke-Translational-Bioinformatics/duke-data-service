var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var tools = require('./tools.js');
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');


var PROV_CREATE_USED = "Provenance Relations > Relations collection > Create used relation";
var PROV_CREATE_GENERATED = "Provenance Relations > Relations collection > Create generated relation";
var PROV_REL_LIST = "Provenance Relations > Relations collection > List provenance relations";
var PROV_REL_VIEW = "Provenance Relations > Relation instance > View relation";
var PROV_REL_DELETE = "Provenance Relations > Relation instance > Delete relation";

var responseStash = {};

hooks.before(PROV_CREATE_USED, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_CREATE_GENERATED, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_REL_LIST, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_REL_VIEW, function (transaction) {
  transaction.skip = true;
});

hooks.before(PROV_REL_DELETE, function (transaction) {
  transaction.skip = true;
});
