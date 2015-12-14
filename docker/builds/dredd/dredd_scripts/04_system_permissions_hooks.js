var tools = require('./tools');
var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var LIST_SYSTEM_PERMISSIONS = "System Permissions > System Permissions collection > List system permissions";
var GRANT_SYSTEM_PERMISSION = "System Permissions > System Permission instance > Grant system permission";
var VIEW_SYSTEM_PERMISSION = "System Permissions > System Permission instance > View system permission";
var REVOKE_SYSTEM_PERMISSION = "System Permissions > System Permission instance > Revoke system permission";

hooks.before(LIST_SYSTEM_PERMISSIONS, function (transaction) {
  transaction.skip = true;
});

hooks.before(GRANT_SYSTEM_PERMISSION, function (transaction) {
  transaction.skip = true;
});

hooks.before(VIEW_SYSTEM_PERMISSION, function (transaction) {
  transaction.skip = true;
});

hooks.before(REVOKE_SYSTEM_PERMISSION, function (transaction) {
  transaction.skip = true;
});