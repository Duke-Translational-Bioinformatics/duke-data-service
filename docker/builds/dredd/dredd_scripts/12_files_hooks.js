var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var CREATE_FILE = "Files > Files collection > Create file";
var VIEW_FILE = "Files > File instance > View file";
var DELETE_FILE = "Files > File instance > Delete file";
var GET_FILE_URL = "Files > File instance > Get pre-signed download URL";
var MOVE_FILE = "Files > File instance > Move file";
var RENAME_FILE = "Files > File instance > Rename file";
var responseStash = {};
var g_fileId = null;

hooks.before(CREATE_FILE, function (transaction) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['parent']['kind'] = 'dds-project';
  requestBody['parent']['id'] = g_projectId;
  requestBody['upload']['id'] = g_uploadId;
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
});

hooks.after(CREATE_FILE, function (transaction) {
  // saving HTTP response to the stash
  responseStash[CREATE_FILE] = transaction.real.body;
});

hooks.before(VIEW_FILE, function (transaction) {
  // reusing data from previous response here
  var fileId = JSON.parse(responseStash[CREATE_FILE])['id'];
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', fileId);
  // set global id for downstream tests
  g_fileId = fileId;
});

hooks.before(DELETE_FILE, function (transaction, done) {
  var request = createUploadResource();
  request.then(function(data) {
    var payload = {
      "parent": { "kind": "dds-project", "id": g_projectId },
      "upload": { "id": data['id'] }
    };
    var request = tools.createResource('POST', '/files', JSON.stringify(payload));
    // delete sample file resource we created
    request.then(function(data) {
      var url = transaction.fullPath;
      transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', data['id']);
      done();
    });
  });
});

hooks.before(GET_FILE_URL, function (transaction) {
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', g_fileId);
});

hooks.before(MOVE_FILE, function (transaction, done) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['parent']['kind'] = 'dds-folder';
  requestBody['parent']['id'] = g_folderId;
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
  var request = createUploadResource();
  request.then(function(data) {
    var payload = {
      "parent": { "kind": "dds-project", "id": g_projectId },
      "upload": { "id": data['id'] }
    };
    var request = tools.createResource('POST', '/files', JSON.stringify(payload));
    // move sample file resource we created
    request.then(function(data) {
      var url = transaction.fullPath;
      transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', data['id']);
      done();
    });
  });
});

hooks.before(RENAME_FILE, function (transaction, done) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['name'] = 'dredd_rename'.concat('.').concat(shortid.generate()).concat('.').concat(requestBody['name']);
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
  var request = createUploadResource();
  request.then(function(data) {
    var payload = {
      "parent": { "kind": "dds-project", "id": g_projectId },
      "upload": { "id": data['id'] }
    };
    var request = tools.createResource('POST', '/files', JSON.stringify(payload));
    // rename sample file resource we created
    request.then(function(data) {
      var url = transaction.fullPath;
      transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', data['id']);
      done();
    });
  });
});
