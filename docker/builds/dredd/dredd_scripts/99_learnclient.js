var tools = require('./tools.js');
var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var CREATE_FOLDER = "Folders > Folders collection > Create folder";
var DELETE_FOLDER = "Folders > Folder instance > Delete folder";
var g_folderId = null;
var responseStash = {};
//Let's play around with the users endpoint that needs the current user id
//First let's go out and get that current user id

hooks.after(CREATE_FOLDER, function (transaction) {
  // saving HTTP response to the stash
  responseStash[CREATE_FOLDER] = transaction.real.body;
});

hooks.before(DELETE_FOLDER, function (transaction,done) {
  var request = new Promise();
  var client = new Client();
  var request_payload = {
    "parent": { "kind": "dds-folder", "id": JSON.parse(responseStash[CREATE_FOLDER])['id'] },
    "name": "Delete folder for dredd - ".concat(shortid.generate())
  };
  var args = {
    "headers": { "Content-Type": "application/json", "Authorization": process.env.MY_GENERATED_JWT },
    "data": request_payload
  };
  var request_path = hooks.configuration.server.concat('/folders');
  client.registerMethod("apiMethod", request_path, 'POST');
  client.methods.apiMethod(args, function(data, response) {
	// parsed response body as js object
	console.log(data['id']);
  request.resolve(data);
  });
  request.then(function(data) {
    var url = transaction.fullPath;
    transaction.fullPath = url.replace('d5ae02a4-b9e6-473d-87c4-66f4c881ae7a', data['id']);
    done();
  });

});
