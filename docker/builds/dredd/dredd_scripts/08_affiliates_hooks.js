var hooks = require('hooks');
var tools = require('./tools.js');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var responseStash = {};

var LIST_AFFILIATES = "Affiliates > Affiliates collection > List affiliates";
var ASSOCIATE_AFFILIATE = "Affiliates > Affiliate instance > Associate affiliate";
var VIEW_AFFILIATE = "Affiliates > Affiliate instance > View affiliate";
var DELETE_AFFILIATE = "Affiliates > Affiliate instance > Delete affiliate";

hooks.before(LIST_AFFILIATES, function (transaction, done) {
  //first we'll create a project
  var payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var payload_na = {};
  var request = tools.createResource('POST', '/projects', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    responseStash['createdProject'] = data['id'];
    //next let's identify our user id so that we can exclude it from the list of potentienal users
    var request2 = tools.createResource('GET', '/current_user', JSON.stringify(payload_na),hooks.configuration.server);
    request2.then(function(data2) {
      responseStash['my_user_id'] = data2['id'];
      //get the complete list of users
      var request3 = tools.createResource('GET', '/users', JSON.stringify(payload_na),hooks.configuration.server);
      request3.then(function(data3) {
        // grab somebody else's user id
        responseStash['other_user_id'] = _.sample(_.without(_.pluck(data3['results'], 'id'), responseStash['my_user_id']));
        // create sample affiliate resource in case none exist for listing
        var payload = {
          "project_role": { "id": "principal_investigator" }
        };
        var request4 = tools.createResource('PUT', '/projects/'.concat(responseStash['createdProject']).concat('/affiliates/').concat(responseStash['other_user_id']), JSON.stringify(payload),hooks.configuration.server);
        request4.then(function(data4) {
          var url = transaction.fullPath;
          url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
          transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', responseStash['other_user_id']);
          done();
        });
      });
    });
  });
});

hooks.before(ASSOCIATE_AFFILIATE, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', responseStash['other_user_id']);
});

hooks.before(VIEW_AFFILIATE, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', responseStash['other_user_id']);
});

hooks.before(DELETE_AFFILIATE, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', responseStash['createdProject']);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', responseStash['other_user_id']);
});
