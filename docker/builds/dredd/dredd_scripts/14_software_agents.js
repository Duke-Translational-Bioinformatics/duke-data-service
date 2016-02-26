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
var g_uploadId = null;
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

hooks.before(SA_LIST, function (transaction) {
});

hooks.before(SA_VIEW, function (transaction) {
});

hooks.before(SA_UPDATE, function (transaction) {
});

hooks.before(SA_DELETE, function (transaction) {
});

hooks.before(SA_VIEW_APIKEY, function (transaction) {
});

hooks.before(SA_REGENERATE, function (transaction) {
});

hooks.before(SA_GET_TOKEN, function (transaction) {
});
