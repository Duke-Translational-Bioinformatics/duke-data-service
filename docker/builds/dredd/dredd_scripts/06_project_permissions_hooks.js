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

hooks.before(LIST_PROJECT_PERMISSIONS, function (transaction,done) {
  //first create a project
  var payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var request = tools.createResource('POST', '/projects', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    var url = transaction.fullPath;
    if (url.indexOf('?') > -1) {
      url = url.substr(0, url.indexOf('?'));
    }
    responseStash['createdProject'] = data['id'];
    transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
    done();
  });
  // replacing id in URL with stashed id from previous response
});

hooks.before(GRANT_PROJECT_PERMISSION, function (transaction,done) {
  //Now look into the system and get a user that is not ourself for testing
  payload={};
  var request = tools.createResource('GET', '/current_user', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    responseStash['my_user_id'] = data['id'];
    var request2 = tools.createResource('GET', '/users', JSON.stringify(payload),hooks.configuration.server);
    request2.then(function(data2) {
      // var responseStash['other_user_id'] = _.sample(_.without(_.pluck(JSON.parse(data)['results'], 'id'), responseStash['my_user_id']));
      responseStash['other_user_id'] = _.sample(_.without(_.pluck(data2['results'], 'id'), responseStash['my_user_id']));
      // replacing id in URL with stashed id from previous response
      var url = transaction.fullPath;
      url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
      transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', responseStash['other_user_id']);
      done();
    })
  });
});

hooks.before(VIEW_PROJECT_PERMISSION, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', responseStash['other_user_id']);
});

hooks.before(REVOKE_PROJECT_PERMISSION, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', responseStash['other_user_id']);
});
