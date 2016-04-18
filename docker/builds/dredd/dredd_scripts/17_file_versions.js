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
var g_fileId1 = null;
var g_uploadId1 = null;
var g_versionId = null;

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
      g_uploadId1 = data2['id'];
      payload2 = {
        "parent": {
          "kind": 'dds-project',
          "id": responseStash['createdProject']
        },
        "upload": {
          "id": g_uploadId1
        }
      }
      var request3 = tools.createResource('POST', '/files', JSON.stringify(payload2),hooks.configuration.server);
      request3.then(function(data3) {
        //this is terrible, but i'm doing it
        g_fileId1 = data3['id'];
        //upload a new version
        var request4 = tools.createUploadResource(responseStash['createdProject'],hooks.configuration.server);
        request4.then(function(data4) {
          g_uploadId2 = data4['id'];
          //now update the file
          payload3 = {
            "upload": {
              "id": g_uploadId2
            },
            "label": "updating file versions endpoint"
          }
          var request5 = tools.createResource('PUT', '/files/'+g_fileId1, JSON.stringify(payload3),hooks.configuration.server);
          request5.then(function(data5) {
            var url = transaction.fullPath;
            transaction.fullPath = url.replace('777be35a-98e0-4c2e-9a17-7bc009f9b111', g_fileId1);
            console.log("upload id 1: " + g_uploadId1)
            console.log("file id 1: " + g_fileId1)
            console.log("upload id 2: " + g_uploadId2)
            done();
          });
        });
      });
    });
  });
});

hooks.after(LIST_VERSION, function (transaction) {
  // saving HTTP response to the stash
  // responseStash[LIST_VERSION] = transaction.real.body;
  // console.log(responseStash[LIST_VERSION])
  responseStash[LIST_VERSION] = transaction.real.body;
  g_versionId = JSON.parse(responseStash[LIST_VERSION])['results'][0]['id'];
});

hooks.before(VIEW_VERSION, function (transaction) {
   var url = transaction.fullPath;
   transaction.fullPath = url.replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b', g_versionId);
});

hooks.before(UPDATE_VERSION, function (transaction) {
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['label'] = 'new label';
  transaction.request.body = JSON.stringify(requestBody);
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b', g_versionId);
});

hooks.before(DELETE_VERSION, function (transaction,done) {
  //create an uploadId
  var request = tools.createUploadResource(responseStash['createdProject'],hooks.configuration.server);
  request.then(function(data) {
    uploadId = data['id']
    console.log("The newest upload id is:**************** " + uploadId)
    payload = {
      "upload": {
        "id": uploadId
      },
      "label": "version of deleting"
    }
    var request2 = tools.createResource('PUT', '/files/'+g_fileId1, JSON.stringify(payload),hooks.configuration.server);
    request2.then(function(data2) {
      var request3 = tools.createResource('GET', '/files/'+g_fileId1+'/versions', JSON.stringify(payload),hooks.configuration.server);
      request3.then(function(data3) {
        remove_version_id = data3['results'][1]['id'];
        var url = transaction.fullPath;
        transaction.fullPath = url.replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b', remove_version_id);
        done();
      });
    });
  });
});

hooks.before(VERSION_URL, function (transaction) {
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('89ef1e77-1a0b-40a8-aaca-260d13987f2b', g_versionId);
});
