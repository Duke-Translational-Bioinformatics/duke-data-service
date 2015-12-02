var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

// function to create resources on fly - returns promise
function createResource(request_method, request_path, request_payload) {
  var request = new Promise();
  var client = new Client();
  var args = {
    "headers": { "Content-Type": "application/json", "Authorization": process.env.MY_GENERATED_JWT },
    "data": request_payload
  };
  var request_path = hooks.configuration.server.concat(request_path);
  client.registerMethod("apiMethod", request_path, request_method);
  client.methods.apiMethod(args, function(data, response) {
    if (!(_.contains([200, 201], response.statusCode))) {
        console.log('The create resource request failed - '.concat(response.statusCode).concat(': '));
        console.log(request_path);
        console.log(JSON.stringify(data));
        // console.log(response);
    }
    request.resolve(data);
  });
  return request;
}

// function to generate sample chunk details - returns chunk object
function getSampleChunk(chunk_number) {
  var chunk = {};
  chunk['content'] = 'This is sample chunk content for chunk number: '.concat(chunk_number);
  // console.log('Sample chunk content to upload: '.concat(chunk['content']));
  chunk['content_type'] = 'text/plain';
  chunk['number'] = chunk_number;
  chunk['size'] = Buffer.byteLength(chunk['content']);
  chunk['hash'] = {};
  chunk['hash']['value'] = md5(chunk['content']);
  chunk['hash']['algorithm'] = 'md5';
  return chunk;
}

// function to upload Swift file chunk - returns promise
function uploadSwiftChunk(request_method, request_path, chunk_content) {
  var request = new Promise();
  var client = new Client();
  var args = {
    // "headers": { "Content-Type": "application/json", "Authorization": process.env.DUKEDS_API_KEY },
    "data": chunk_content
  };
  console.log('Upload Swift chunk request path: '.concat(request_path));
  client.registerMethod("apiMethod", request_path, request_method);
  client.methods.apiMethod(args, function(data, response) {
    console.log('Upload Swift chunk HTTP status code: '.concat(response.statusCode));
    if (!(_.contains([200, 201], response.statusCode))) {
        console.log('The Swift chunk upload failed - '.concat(response.statusCode).concat(': '));
        console.log(request_path);
        console.log(JSON.stringify(data));
        // console.log(response);
    }
    request.resolve(data);
  });
  return request;
}

function createUploadResource() {
  var upload = new Promise();
  var chunk = getSampleChunk(1);
  var uploadId = null;
  var init_chunked_upload = function() {
    var request = new Promise();
    var payload = {};
    payload['name'] = 'upload-sample'.concat('-').concat(shortid.generate()).concat('.txt');
    payload['content_type'] = chunk['content_type'];
    payload['size'] = chunk['size'];
    payload['hash'] = {};
    payload['hash']['value'] = chunk['hash']['value'];
    payload['hash']['algorithm'] = chunk['hash']['algorithm'];
    createResource('POST', '/projects/'.concat(g_projectId).concat('/uploads'), JSON.stringify(payload)).then(function(data) {
      uploadId = data['id'];
      request.resolve(data);
    });
    return request;
  }
  var upload_chunk = function(data) {
    var request = new Promise();
    var payload = {};
    payload['number'] = chunk['number'];
    payload['size'] = chunk['size'];
    payload['hash'] = {};
    payload['hash']['value'] = chunk['hash']['value'];
    payload['hash']['algorithm'] = chunk['hash']['algorithm'];
    createResource('PUT', '/uploads/'.concat(uploadId).concat('/chunks'), JSON.stringify(payload)).then(function(data) {
      uploadSwiftChunk('PUT', data['host'].concat(data['url']), chunk['content']).then(function(data) {
        request.resolve(data);
      });
    });
    return request;
  }
  var complete_upload = function(uploadId) {
    payload = '';
    return createResource('PUT', '/uploads/'.concat(uploadId).concat('/complete'), JSON.stringify(payload));
  }
  init_chunked_upload().then(upload_chunk).then(function(data) {
    complete_upload(uploadId).then(function(data) {
      upload.resolve(data);
    });
  });
  return upload;
}
