var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var responseStash = {};

var LIST_STORAGE_PROVIDERS = "Storage Providers > Storage Providers collection > List storage providers";
var VIEW_STORAGE_PROVIDER = "Storage Providers > Storage Provider instance > View storage provider";
var responseStash = {};

hooks.before(LIST_STORAGE_PROVIDERS, function (transaction) {
  // remove the optional query params
  var url = transaction.fullPath;
  if (url.indexOf('?') > -1) {
    transaction.fullPath = url.substr(0, url.indexOf('?'));
  }
});

hooks.after(LIST_STORAGE_PROVIDERS, function (transaction) {
  // saving HTTP response to the stash
  responseStash[LIST_STORAGE_PROVIDERS] = transaction.real.body;
});

hooks.before(VIEW_STORAGE_PROVIDER, function (transaction) {
  // reusing data from previous response here
  var storageProviderId = _.sample(_.pluck(JSON.parse(responseStash[LIST_STORAGE_PROVIDERS])['results'], 'id'));
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('g5579f73-0558-4f96-afc7-9d251e65bv33', storageProviderId);
});