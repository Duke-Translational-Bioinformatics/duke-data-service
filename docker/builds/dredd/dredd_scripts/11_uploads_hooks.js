var hooks = require('hooks');
var tools = require('./tools.js');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');
var responseStash = {};

var INIT_CHUNKED_UPLOAD = "Uploads > Uploads collection > Initiate chunked upload";
var LIST_CHUNKED_UPLOADS = "Uploads > Uploads collection > List chunked uploads";
var VIEW_CHUNKED_UPLOAD = "Uploads > Upload instance > View chunked upload";
var GET_CHUNK_URL = "Uploads > Upload instance > Get pre-signed chunk URL";
var COMPLETE_CHUNKED_UPLOAD = "Uploads > Upload instance > Complete chunked file upload";
var responseStash = {};
var g_uploadId = null;
// get a sample chunk to upload
var chunk = getSampleChunk(1);

hooks.before(INIT_CHUNKED_UPLOAD, function (transaction) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['name'] = 'upload-sample'.concat('-').concat(shortid.generate()).concat('.txt');
  requestBody['content_type'] = chunk['content_type'];
  requestBody['size'] = chunk['size'];
  requestBody['hash']['value'] = chunk['hash']['value'];
  requestBody['hash']['algorithm'] = chunk['hash']['algorithm'];
  // stringify the new boy to request
  transaction.request.body = JSON.stringify(requestBody);
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23', g_projectId);
});

hooks.after(INIT_CHUNKED_UPLOAD, function (transaction) {
  // saving HTTP response to the stash
  responseStash[INIT_CHUNKED_UPLOAD] = transaction.real.body;
});

hooks.before(LIST_CHUNKED_UPLOADS, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23', g_projectId);
});

hooks.before(VIEW_CHUNKED_UPLOAD, function (transaction) {
  // reusing data from previous response here
  var uploadId = JSON.parse(responseStash[INIT_CHUNKED_UPLOAD])['id'];
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23', uploadId);
  // set global id for downstream tests
  g_uploadId = uploadId;
});

hooks.before(GET_CHUNK_URL, function (transaction) {
  // parse request body from blueprint
  var requestBody = JSON.parse(transaction.request.body);
  // modify request body here
  requestBody['number'] = chunk['number'];
  requestBody['size'] = chunk['size'];
  requestBody['hash']['value'] = chunk['hash']['value'];
  requestBody['hash']['algorithm'] = chunk['hash']['algorithm'];
  // stringify the new boy to request
  transaction.request.body = JSON.stringify(requestBody);
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23', g_uploadId);
});

hooks.after(GET_CHUNK_URL, function (transaction, done) {
  // saving HTTP response to the stash
  responseStash[GET_CHUNK_URL] = transaction.real.body;
  payload = JSON.parse(responseStash[GET_CHUNK_URL]);
  request = uploadSwiftChunk('PUT', payload['host'].concat(payload['url']), chunk['content']);
  request.then(function(data) {
    done();
  });
});

hooks.before(COMPLETE_CHUNKED_UPLOAD, function (transaction) {
  // replacing id in URL with stashed id from previous response
  var url = transaction.fullPath;
  transaction.fullPath = url.replace('666be35a-98e0-4c2e-9a17-7bc009f9bb23', g_uploadId);
});
