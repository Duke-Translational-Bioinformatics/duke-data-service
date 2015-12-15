var tools = require('./tools');
var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var LIST_AUTH_ROLES = "Authorization Roles > Authorization Roles collection > List roles";
var VIEW_AUTH_ROLE = "Authorization Roles > Authorization Role instance > View role";
var responseStash = {};

hooks.before(LIST_AUTH_ROLES, function (transaction) {
  // remove the optional query params
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    transaction.fullPath = url.substr(0, url.indexOf('?'));
  } 
});

hooks.after(LIST_AUTH_ROLES, function (transaction) {
  // saving HTTP response to the stash
  responseStash[LIST_AUTH_ROLES] = transaction.real.body;
});

hooks.before(VIEW_AUTH_ROLE, function (transaction) {
  // reusing data from previous response here
  var authRoleId = _.sample(_.pluck(JSON.parse(responseStash[LIST_AUTH_ROLES])['results'], 'id'));
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('file_editor', authRoleId);
});
