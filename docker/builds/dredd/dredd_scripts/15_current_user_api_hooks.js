var tools = require('./tools');
var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

var CU_VIEW = "Current User > Current User instance > View current user"
var CU_CUU = "Current User > Current User instance > Current user usage"
var GENERATE_CU_API = "Current User > Current User Secret Key > Generate current user API key";
var VIEW_CU_API = "Current User > Current User Secret Key > View current user API key";
var DEL_CU_API = "Current User > Current User Secret Key > Delete current user API key";
var g_currentUserId = null;
var responseStash = {};

hooks.before(CU_VIEW, function (transaction) {
  // saving HTTP response to the stash
  //responseStash[VIEW_CURRENT_USER] = transaction.real.body;
  // set global id for downstream tests
  //g_currentUserId = JSON.parse(responseStash[VIEW_CURRENT_USER])['id'];
});

hooks.before(CU_CUU, function (transaction) {
  // saving HTTP response to the stash
  //responseStash[VIEW_CURRENT_USER] = transaction.real.body;
  // set global id for downstream tests
  //g_currentUserId = JSON.parse(responseStash[VIEW_CURRENT_USER])['id'];
});

hooks.before(GENERATE_CU_API, function (transaction) {
  // saving HTTP response to the stash
  //responseStash[VIEW_CURRENT_USER] = transaction.real.body;
  // set global id for downstream tests
  //g_currentUserId = JSON.parse(responseStash[VIEW_CURRENT_USER])['id'];
});

hooks.before(VIEW_CU_API, function (transaction) {
  // saving HTTP response to the stash
  //responseStash[VIEW_CURRENT_USER] = transaction.real.body;
  // set global id for downstream tests
  //g_currentUserId = JSON.parse(responseStash[VIEW_CURRENT_USER])['id'];
});

hooks.before(DEL_CU_API, function (transaction) {
  // saving HTTP response to the stash
  //responseStash[VIEW_CURRENT_USER] = transaction.real.body;
  // set global id for downstream tests
  //g_currentUserId = JSON.parse(responseStash[VIEW_CURRENT_USER])['id'];
});
