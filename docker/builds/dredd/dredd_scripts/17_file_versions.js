var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var tools = require('./tools.js');
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');


var LIST_VERSION = "File Versions > File Versions collection > List file versions";
var VIEW_VERSION = "File Versions > File Version instance > View file version";
var UPDATE_VERSION = "File Versions > File Version instance > Update file version";
var DELETE_VERSION = "File Versions > File Version instance > Delete file version";
var VERSION_URL = "File Versions > File Version instance > Get file version download URL";

var responseStash = {};
var g_fileId = null;

hooks.before(LIST_VERSION, function (transaction,done) {
  //first create a project
  var payload = {
    "name": "List file versions project for dredd - ".concat(shortid.generate()),
    "description": "A project to create a file and play with versions"
  };
  var request = tools.createResource('POST', '/projects', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    //Once project created, stash the id
    responseStash['createdProject'] = data['id'];
    //create an upload resource
    var request2 = tools.createUploadResource(responseStash['createdProject'],hooks.configuration.server);
    request2.then(function(data2) {
      responseStash['uploadID'] = data2['id'];
      payload2 = {
        "parent": {
          "kind": 'dds-project',
          "id": responseStash['createdProject']
        },
        "upload": {
          "id": responseStash['uploadID']
        }
      }
      var request3 = tools.createResource('POST', '/files', JSON.stringify(payload2),hooks.configuration.server);
      request3.then(function(data3) {
        console.log(data3)
        g_fileId = data3['id'];
        var url = transaction.fullPath;
        transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', g_fileId);
        done();
      });
    });
  });
});

hooks.after(LIST_VERSION, function (transaction) {
  // saving HTTP response to the stash
  // responseStash[LIST_VERSION] = transaction.real.body;
  // console.log(responseStash[LIST_VERSION])
});

hooks.before(VIEW_VERSION, function (transaction) {
  // var fileVersionId = JSON.parse(responseStash[LIST_VERSION])['id'];
  // var url = transaction.fullPath;
  // transaction.fullPath = url.replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b', fileVersionId);
  transaction.skip = true;
});

hooks.after(VIEW_VERSION, function (transaction) {
  // saving HTTP response to the stash
  // responseStash[VIEW_VERSION] = transaction.real.body;
  // console.log(responseStash[VIEW_VERSION])
});

hooks.before(UPDATE_VERSION, function (transaction) {
  // var fileVersionId = JSON.parse(responseStash[LIST_VERSION])['id'];
  // var url = transaction.fullPath;
  // transaction.fullPath = url.replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b', fileVersionId);
  transaction.skip = true;
});

hooks.before(DELETE_VERSION, function (transaction) {
  transaction.skip = true;
});

hooks.before(VERSION_URL, function (transaction) {
  transaction.skip = true;
});
