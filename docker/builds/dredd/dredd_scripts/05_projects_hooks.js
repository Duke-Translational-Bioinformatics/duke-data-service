var tools = require('./tools.js');
var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var CREATE_PROJECT = "Projects > Projects collection > Create project";
var LIST_PROJECTS = "Projects > Projects collection > List projects";
var VIEW_PROJECT = "Projects > Project instance > View project";
var UPDATE_PROJECT = "Projects > Project instance > Update project";
var DELETE_PROJECT = "Projects > Project instance > Delete project";
var responseStash = {};
var g_projectId = null;

hooks.before(CREATE_PROJECT, function (transaction) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['name'] = requestBody['name'].concat(' - ').concat(shortid.generate());
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
});

hooks.after(CREATE_PROJECT, function (transaction) {
  // saving HTTP response to the stash
  responseStash[CREATE_PROJECT] = transaction.real.body;
});

hooks.before(LIST_PROJECTS, function (transaction) {
  // remove the optional query params
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    transaction.fullPath = url.substr(0, url.indexOf('?'));
  }
});

hooks.before(VIEW_PROJECT, function (transaction) {
  // reusing data from previous response here
  var projectId = JSON.parse(responseStash[CREATE_PROJECT])['id'];
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', projectId);
  // set global id for downstream tests
  g_projectId = projectId;
});

hooks.before(UPDATE_PROJECT, function (transaction) {
  // reusing data from previous response here
  var projectId = JSON.parse(responseStash[CREATE_PROJECT])['id'];
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['name'] = requestBody['name'].concat(' - ').concat(shortid.generate()).concat(' - update via dredd');
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', projectId);
});

hooks.before(DELETE_PROJECT, function (transaction,done) {
  var request = new Promise();
  var client = new Client();
  var request_payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var args = {
    "headers": { "Content-Type": "application/json", "Authorization": process.env.MY_GENERATED_JWT },
    "data": request_payload
  };
  var request_path = hooks.configuration.server.concat('/projects');
  client.registerMethod("apiMethod", request_path, 'POST');
  client.methods.apiMethod(args, function(data, response) {
	// parsed response body as js object
  request.resolve(data);
  });
  request.then(function(data) {
    var url = transaction.fullPath;
    transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', data['id']);
    done();
  });

});
