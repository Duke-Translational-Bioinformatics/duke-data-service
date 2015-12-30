var hooks = require('hooks');
var shortid = require('shortid32');
var tools = require('./tools.js');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var CREATE_FOLDER = "Folders > Folders collection > Create folder";
var VIEW_FOLDER = "Folders > Folder instance > View folder";
var DELETE_FOLDER = "Folders > Folder instance > Delete folder";
var MOVE_FOLDER = "Folders > Folder instance > Move folder";
var RENAME_FOLDER = "Folders > Folder instance > Rename folder";
var responseStash = {};
var g_folderId = null;

hooks.before(CREATE_FOLDER, function (transaction,done) {
  //first we'll create a project
  var payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var payload_na = {};
  var request = tools.createResource('POST', '/projects', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    responseStash['createdProject'] = data['id'];
    // parse request body from blueprint
    var requestBody = JSON.parse(transaction.request.body);
    // modify request body here
    requestBody['parent']['kind'] = 'dds-project';
    requestBody['parent']['id'] = responseStash['createdProject'];
    requestBody['name'] = requestBody['name'].concat(' - ').concat(shortid.generate());
    // stringify the new body to request
    transaction.request.body = JSON.stringify(requestBody);
    done();
  });
});

hooks.after(CREATE_FOLDER, function (transaction) {
  // saving HTTP response to the stash
  responseStash[CREATE_FOLDER] = transaction.real.body;
});

hooks.before(VIEW_FOLDER, function (transaction) {
  // reusing data from previous response here
  var folderId = JSON.parse(responseStash[CREATE_FOLDER])['id'];
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a', folderId);
  // set global id for downstream tests
  g_folderId = folderId;
});

hooks.before(DELETE_FOLDER, function (transaction, done) {
  var payload = {
    "parent": { "kind": "dds-folder", "id": g_folderId },
    "name": "Delete folder for dredd - ".concat(shortid.generate())
  };
  var request = tools.createResource('POST', '/folders', JSON.stringify(payload),hooks.configuration.server);
  // delete sample folder resource we created
  request.then(function(data) {
    var url = transaction.fullPath;
    transaction.fullPath = url.replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a', data['id']);
    done();
  });
});

hooks.before(MOVE_FOLDER, function (transaction, done) {
  var payload = {
    "parent": { "kind": "dds-project", "id": responseStash['createdProject'] },
    "name": "Move folder for dredd - ".concat(shortid.generate())
  };
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['parent']['kind'] = 'dds-folder';
  requestBody['parent']['id'] = g_folderId;
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
  var request = tools.createResource('POST', '/folders', JSON.stringify(payload),hooks.configuration.server);
  // move sample folder resource we created
  request.then(function(data) {
    var url = transaction.fullPath;
    transaction.fullPath = url.replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a', data['id']);
    done();
  });
});

hooks.before(RENAME_FOLDER, function (transaction) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['name'] = requestBody['name'].concat(' - ').concat(shortid.generate()).concat(' - rename via dredd');
  // stringify the new body to request
  transaction.request.body = JSON.stringify(requestBody);
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a', g_folderId);
});
