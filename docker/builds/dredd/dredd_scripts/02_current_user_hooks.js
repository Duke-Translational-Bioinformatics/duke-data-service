var tools = require('./tools');
var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var VIEW_CURRENT_USER = "Current User > Current User instance > View current user";
var g_currentUserId = null;
var responseStash = {};

hooks.after(VIEW_CURRENT_USER, function (transaction) {
  // saving HTTP response to the stash
  responseStash[VIEW_CURRENT_USER] = transaction.real.body;
  // set global id for downstream tests
  g_currentUserId = JSON.parse(responseStash[VIEW_CURRENT_USER])['id'];
});