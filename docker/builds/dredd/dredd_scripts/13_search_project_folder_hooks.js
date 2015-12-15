var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var responseStash = {};

var SEARCH_PROJECT_CHILDREN = "Search Project/Folder Children > Search Project Children > Search Project Children";
var SEARCH_FOLDER_CHILDREN = "Search Project/Folder Children > Search Folder Children > Search Folder Children";

hooks.before(SEARCH_PROJECT_CHILDREN, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    url = url.substr(0, url.indexOf('?'));
  }
  transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_projectId);
});

hooks.before(SEARCH_FOLDER_CHILDREN, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    url = url.substr(0, url.indexOf('?'));
  }
  transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', g_folderId);
});
