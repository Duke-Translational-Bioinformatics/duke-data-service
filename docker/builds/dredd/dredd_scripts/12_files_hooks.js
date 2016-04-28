var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var tools = require('./tools.js');
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var CREATE_FILE = "Files > Files collection > Create file";
var VIEW_FILE = "Files > File instance > View file";
var UPDATE_FILE = "Files > File instance > Update file";
var DELETE_FILE = "Files > File instance > Delete file";
var GET_FILE_URL = "Files > File instance > Get file download URL";
var MOVE_FILE = "Files > File instance > Move file";
var RENAME_FILE = "Files > File instance > Rename file";
var responseStash = {};
var g_fileId = null;

hooks.before(CREATE_FILE, function (transaction,done) {
  //first create a project
  var payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var request = tools.createResource('POST', '/projects', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    //Once project created, stash the id
    responseStash['createdProject'] = data['id'];
    //create an upload resource
    var request2 = tools.createUploadResource(responseStash['createdProject'],hooks.configuration.server);
    request2.then(function(data2) {
      responseStash['uploadID'] = data2['id'];
      // parse request body from blueprint
      var requestBody = JSON.parse(transaction.request.body);
      // modify request body here
      requestBody['parent']['kind'] = 'dds-project';
      requestBody['parent']['id'] = responseStash['createdProject'];
      requestBody['upload']['id'] = responseStash['uploadID'];
      // stringify the new body to request
      transaction.request.body = JSON.stringify(requestBody);
      done();
    });
  });
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

hooks.before(UPDATE_FILE, function (transaction,done) {
  var request = tools.createUploadResource(responseStash['createdProject'],hooks.configuration.server);
  request.then(function(data) {
    uploadId = data['id']
    var requestBody = JSON.parse(transaction.request.body);
    requestBody['upload']['id'] = uploadId;
    requestBody['label'] = "just a test";
    transaction.request.body = JSON.stringify(requestBody);
    var url = transaction.fullPath;
    transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', g_fileId);
    console.log(transaction);
    console.log(g_fileId);
    console.log(uploadId);
    done();
  });
});

hooks.before(DELETE_FILE, function (transaction, done) {
  var request = tools.createUploadResource(responseStash['createdProject'],hooks.configuration.server);
  request.then(function(data) {
    var payload = {
      "parent": { "kind": "dds-project", "id": responseStash['createdProject'] },
      "upload": { "id": data['id'] }
    };
    var request2 = tools.createResource('POST', '/files', JSON.stringify(payload),hooks.configuration.server);
    // delete sample file resource we created
    request2.then(function(data2) {
      var url = transaction.fullPath;
      transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', data2['id']);
      done();
    });
  });
});

hooks.before(GET_FILE_URL, function (transaction) {
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', g_fileId);
});

hooks.before(MOVE_FILE, function (transaction, done) {
  //first create a folder
  var payload = {
    "parent": { "kind": "dds-project", "id": responseStash['createdProject'] },
    "name": "Folder for dredd - ".concat(shortid.generate())
  };
  var request = tools.createResource('POST', '/folders', JSON.stringify(payload), hooks.configuration.server);
  request.then(function(data) {
    responseStash['folderId'] = data['id'];
  // parse request body from blueprint
    var requestBody = JSON.parse(transaction.request.body);
    // modify request body here
    requestBody['parent']['kind'] = 'dds-folder';
    requestBody['parent']['id'] = responseStash['folderId'];
    // stringify the new body to request
    transaction.request.body = JSON.stringify(requestBody);
    // move sample file resource we created
      var url = transaction.fullPath;
      transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', g_fileId);
    done();
    });
});

hooks.before(RENAME_FILE, function (transaction) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['name'] = 'dredd_rename'.concat('.').concat(shortid.generate()).concat('.').concat(requestBody['name']);
  // stringify the new body to request
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', g_fileId);
});
