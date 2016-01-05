var hooks = require('hooks');
var tools = require('./tools.js');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var responseStash = {};

//dependencies to get these endpoints working
var LIST_PROJECT_PERMISSIONS = "Project Permissions > Project Permissions collection > List project permissions";
var GRANT_PROJECT_PERMISSION = "Project Permissions > Project Permission instance > Grant project permission";
var VIEW_PROJECT_PERMISSION = "Project Permissions > Project Permission instance > View project permission";
var REVOKE_PROJECT_PERMISSION = "Project Permissions > Project Permission instance > Revoke project permission";

hooks.before(LIST_PROJECT_PERMISSIONS, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    url = url.substr(0, url.indexOf('?'));
  }
  transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
});

hooks.before(GRANT_PROJECT_PERMISSION, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', g_userId);
});

hooks.before(VIEW_PROJECT_PERMISSION, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', g_userId);
});

hooks.before(REVOKE_PROJECT_PERMISSION, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', g_userId);
});
