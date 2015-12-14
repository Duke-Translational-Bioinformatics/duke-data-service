var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var responseStash = {};

var LIST_PROJECT_ROLES = "Project Roles > Project Roles collection > List project roles";
var VIEW_PROJECT_ROLE = "Project Roles > Project Role instance > View project role";
var responseStash = {};

hooks.before(LIST_PROJECT_ROLES, function (transaction) {
  // remove the optional query params
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    transaction.fullPath = url.substr(0, url.indexOf('?'));
  }
});

hooks.after(LIST_PROJECT_ROLES, function (transaction) {
  // saving HTTP response to the stash
  responseStash[LIST_PROJECT_ROLES] = transaction.real.body;
});

hooks.before(VIEW_PROJECT_ROLE, function (transaction) {
  // reusing data from previous response here
  var projectRoleId = _.sample(_.pluck(JSON.parse(responseStash[LIST_PROJECT_ROLES])['results'], 'id'));
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('principal_investigator', projectRoleId);
});