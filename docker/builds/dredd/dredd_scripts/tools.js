var shortid = require('shortid32');
var _ = require('underscore');
var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;
var fs = require("fs");
var md5 = require('md5');

// function to generate sample chunk details - returns chunk object
getSampleChunk = function(chunk_number) {
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
uploadSwiftChunk = function(request_method, request_path, chunk_content) {
  var request = new Promise();
  var client = new Client();
  var args = {
    // "headers": { "Content-Type": "application/json", "Authorization": process.env. },
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

createResource = function(request_method, request_path, request_payload, xserver) {
  var request = new Promise();
  var client = new Client();
  var args = {
    "headers": { "Content-Type": "application/json", "Authorization": process.env.MY_GENERATED_JWT },
    "data": request_payload
  };
  var request_path = xserver.concat(request_path);
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

exports.createUploadResource = function(g_projectId,xserver) {
  var upload = new Promise();
  // console.log('project id is: ' + g_projectId);
  // console.log('xserver id is: ' + xserver);
  var chunk = getSampleChunk(1);
  var payload = {};
  payload['name'] = 'upload-sample'.concat('-').concat(shortid.generate()).concat('.txt');
  payload['content_type'] = chunk['content_type'];
  payload['size'] = chunk['size'];
  payload['hash'] = {};
  payload['hash']['value'] = chunk['hash']['value'];
  payload['hash']['algorithm'] = chunk['hash']['algorithm'];
  //first step in uploading is to create an upload object and composite status object through this endpoint
  var request = createResource('POST', '/projects/'.concat(g_projectId).concat('/uploads'), JSON.stringify(payload),xserver);
  request.then(function(data) {
    // console.log('upload id: ' + data['id']);
    uploadId = data['id'];
    //next step is to generate and obtain a pre-signed URL that can be used by the client
    var payload = {};
    payload['number'] = chunk['number'];
    payload['size'] = chunk['size'];
    payload['hash'] = {};
    payload['hash']['value'] = chunk['hash']['value'];
    payload['hash']['algorithm'] = chunk['hash']['algorithm'];
    request2 = createResource('PUT', '/uploads/'.concat(uploadId).concat('/chunks'), JSON.stringify(payload),xserver)
    request2.then(function(data2) {
      //Now we (client) needs to actually upload the data to swift:
      request3 = uploadSwiftChunk('PUT', data2['host'].concat(data2['url']), chunk['content'])
      request3.then(function(data3) {
        //Once the upload is complete, we (client) needs to tell DDS the file is now uploaded in swift
        request4 = createResource('PUT', '/uploads/'.concat(uploadId).concat('/complete'), JSON.stringify(payload),xserver)
        request4.then(function(data4) {
          //once dds is aware that the file is uploaded, we can resolve the data and return the promise
          upload.resolve(data4);
        });
      });
    });
  });
  return upload;
}

// function to create resources on fly - returns promise
exports.createResource = createResource;
exports.getSampleChunk = getSampleChunk;
exports.uploadSwiftChunk = uploadSwiftChunk;
