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
  // create sample affiliate resource in case none exist for listing
  var payload = {
    "project_role": { "id": "principal_investigator" }
  };
  var request = tools.createResource('PUT', '/projects/'.concat(g_projectId).concat('/affiliates/').concat(g_userId), JSON.stringify(payload));
  request.then(function(data) {
    var url = transaction.fullPath;
    if (url.indexOf('?') > -1) {
      url = url.substr(0, url.indexOf('?'));
    }
    transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
    done();
  });
});

hooks.before(ASSOCIATE_AFFILIATE, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', g_userId);
});

hooks.before(VIEW_AFFILIATE, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', g_userId);
});

hooks.before(DELETE_AFFILIATE, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  url = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
  transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', g_userId);
});
