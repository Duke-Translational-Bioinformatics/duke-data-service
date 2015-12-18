var tools = require('./tools.js');
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

function createUploadResource(g_projectId) {
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


var SEARCH_PROJECT_CHILDREN = "Search Project/Folder Children > Search Project Children > Search Project Children";
var SEARCH_FOLDER_CHILDREN = "Search Project/Folder Children > Search Folder Children > Search Folder Children";

hooks.before(SEARCH_PROJECT_CHILDREN, function (transaction, done) {
  //first create a project
  var payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var request = createResource('POST', '/projects', JSON.stringify(payload));
  request.then(function(data) {
    //Once project created, create folder
    var project_id = data['id'];
    var payload = {
      "parent": { "kind": "dds-project", "id": project_id },
      "name": "Delete folder for dredd - ".concat(shortid.generate())
    };
    var request2 = createResource('POST', '/folders', JSON.stringify(payload));
    request2.then(function(data) {
      var folder_id = data['id'];
      //Once folder created, upload file, post it to folder
      // upload a file
      var request3 = createUploadResource(project_id);
      request3.then(function(data3) {
        var upload_id = data3['id'];
        var payload = {
          "parent": { "kind": "dds-folder", "id": folder_id },
          "upload": { "id": upload_id }
        };
        //post that file to the new folder
        var request4 = createResource('POST', '/files', JSON.stringify(payload));
        request4.then(function(data4) {
          // once the file is posted to the folder, modify the hook's transaction.fullpath
          var file_id = data4['id'];
          var url = transaction.fullPath;
          //we don't want any parameters in our path, so we'll remove them
          if (url.indexOf('?') > -1) {
            url = url.substr(0, url.indexOf('?'));
          }
          transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', project_id);
          console.log("Project id: " + project_id);
          console.log("Folder id: " + folder_id);
          console.log("Upload id: " + upload_id);
          console.log("File id: " + file_id);
          console.log("Called Endpoint: " + transaction.fullPath);
          done();
        });
      });
    });
  });
});

// hooks.beforeValidation(SEARCH_PROJECT_CHILDREN, function (transaction) {
//   // get the real body content
//   var realBody = JSON.parse(transaction.real.body);
//   // place a folder and file on top of the array stack to aligh with apiary
//   var folder_idx = _.findIndex(realBody.results, { kind: 'dds-folder' });
//   realBody.results = _.move(realBody.results, folder_idx, 0);
//   var file_idx = _.findIndex(realBody.results, { kind: 'dds-file' });
//   realBody.results = _.move(realBody.results, file_idx, 1);
//   transaction.real.body = JSON.stringify(realBody);
// });

hooks.before(SEARCH_FOLDER_CHILDREN, function (transaction, done) {
  //first create a project
  var payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var request = createResource('POST', '/projects', JSON.stringify(payload));
  request.then(function(data) {
    //Once project created, create folder
    var project_id = data['id'];
    var payload = {
      "parent": { "kind": "dds-project", "id": project_id },
      "name": "Delete folder for dredd - ".concat(shortid.generate())
    };
    var request2 = createResource('POST', '/folders', JSON.stringify(payload));
    request2.then(function(data) {
      var folder_id = data['id'];
      //Once folder created, upload file, post it to folder
      // upload a file
      var request3 = createUploadResource(project_id);
      request3.then(function(data3) {
        var upload_id = data3['id'];
        var payload = {
          "parent": { "kind": "dds-folder", "id": folder_id },
          "upload": { "id": upload_id }
        };
        //post that file to the new folder
        var request4 = createResource('POST', '/files', JSON.stringify(payload));
        request4.then(function(data4) {
          // once the file is posted to the folder, modify the hook's transaction.fullpath
          var file_id = data4['id'];
          var url = transaction.fullPath;
          //we don't want any parameters in our path, so we'll remove them
          if (url.indexOf('?') > -1) {
            url = url.substr(0, url.indexOf('?'));
          }
          transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', folder_id);
          console.log("Project id: " + project_id);
          console.log("Folder id: " + folder_id);
          console.log("Upload id: " + upload_id);
          console.log("File id: " + file_id);
          console.log("Called Endpoint: " + transaction.fullPath);
          done();
        });
      });
    });
  });
});

// hooks.beforeValidation(SEARCH_FOLDER_CHILDREN, function (transaction) {
//   // get the real body content
//   var realBody = JSON.parse(transaction.real.body);
//   // place a folder and file on top of the array stack to aligh with apiary
//   var folder_idx = _.findIndex(realBody.results, { kind: 'dds-folder' });
//   realBody.results = _.move(realBody.results, folder_idx, 0);
//   var file_idx = _.findIndex(realBody.results, { kind: 'dds-file' });
//   realBody.results = _.move(realBody.results, file_idx, 1);
//   transaction.real.body = JSON.stringify(realBody);
// });
