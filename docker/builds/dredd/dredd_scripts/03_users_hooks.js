var tools = require('./tools');
var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var LIST_USERS = "Users > Users collection > List users";
var VIEW_USER = "Users > User instance > View user";

hooks.before(LIST_USERS, function (transaction) {;
  // remove the optional query params
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    transaction.fullPath = url.substr(0, url.indexOf('?'));
  }
});

hooks.before(VIEW_USER, function (transaction,done) {
  var request = new Promise();
  var client = new Client();
  var request_payload = {};
  var args = {
    "headers": { "Content-Type": "application/json", "Authorization": process.env.MY_GENERATED_JWT },
    "data": request_payload
  };
  var request_path = hooks.configuration.server.concat('/current_user');
  client.registerMethod("apiMethod", request_path, 'GET');
  client.methods.apiMethod(args, function(data, response) {
	// parsed response body as js object
  request.resolve(data);
  });
  request.then(function(data) {
    var url = transaction.fullPath;
    transaction.fullPath = url.replace('c1179f73-0558-4f96-afc7-9d251e65b7bb', data['id']);
    done();
  });

});
