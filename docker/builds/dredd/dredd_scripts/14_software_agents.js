var hooks = require('hooks');
var tools = require('./tools.js');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var SA_CREATE = "Software Agents > Software Agents collection > Create software agent";
var SA_LIST = "Software Agents > Software Agents collection > List software agents";
var SA_VIEW = "Software Agents > Software Agent instance > View software agent";
var SA_UPDATE = "Software Agents > Software Agent instance > Update software agent";
var SA_DELETE = "Software Agents > Software Agent instance > Delete software agent";
var SA_VIEW_APIKEY = "Software Agents > Software Agent Secret Key > View software agent API key";
var SA_REGENERATE = "Software Agents > Software Agent Secret Key > Re-generate software agent API key";
var SA_GET_TOKEN = "Software Agents > Software Agent Access Token > Get software agent access token";
var responseStash = {};
var g_sa_Id = null;
// get a sample chunk to upload
var chunk = tools.getSampleChunk(1);

hooks.before(SA_CREATE, function (transaction) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['name'] = 'dredd node agent';
  requestBody['description'] = 'Part of dredd testing from node';
  requestBody['repo_url'] = 'https://github.com/benneely/duke-data-service/tree/develop/docker/builds/';
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
});

hooks.after(SA_CREATE, function (transaction) {
  // saving HTTP response to the stash
  responseStash[SA_CREATE] = transaction.real.body;
});

hooks.before(SA_LIST, function (transaction) {
});

hooks.before(SA_VIEW, function (transaction) {
  // reusing data from previous response here
  var sa_Id = JSON.parse(responseStash[SA_CREATE])['id'];
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715', sa_Id);
  // set global id for downstream tests
  g_sa_Id = sa_Id;
});

hooks.before(SA_UPDATE, function (transaction) {
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715', g_sa_Id);
});

hooks.before(SA_DELETE, function (transaction,done) {
  //first we'll create a new software agent
  var payload = {
    "name": "Delete software agent for that endpoint",
  };
  var request = tools.createResource('POST', '/software_agents', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    delete_sa_id = data['id'];
    var url = transaction.fullPath;
    transaction.fullPath = url.replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715', delete_sa_id);
    done();
  });
});

hooks.before(SA_VIEW_APIKEY, function (transaction) {
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715', g_sa_Id);
});

hooks.before(SA_REGENERATE, function (transaction) {
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('9a4c28a2-ec18-40ed-b75c-3bf5b309715', g_sa_Id);
});

hooks.after(SA_REGENERATE, function (transaction) {
  // saving HTTP response to the stash
  responseStash[SA_REGENERATE] = transaction.real.body;
});

hooks.before(SA_GET_TOKEN, function (transaction,done) {
  //Current user - 02)current_user_hooks.js is called before this with global
  //I'm going to try that first - g_currentUserID before calling separately
  // reusing data from previous response here
  var sa_key = JSON.parse(responseStash[SA_REGENERATE])['key'];
  // replacing id in URL with stashed id from previous response
  //first we'll create a new software agent
  var payload = {
  };
  var request = tools.createResource('GET', '/current_user', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    current_user_id = data['id'];
    var requestBody = JSON.parse(transaction.request.body);
    // modify request body here
    requestBody['agent_key'] = sa_key;
    requestBody['user_key'] = current_user_id;
    // stringify the new body to request
    transaction.request.body = JSON.stringify(requestBody);
    done();
  });
});
