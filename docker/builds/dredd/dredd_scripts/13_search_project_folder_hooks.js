var hooks = require('hooks');
var shortid = require('shortid32');
var _ = require('underscore');
var tools = require('./tools');

var SEARCH_PROJECT_CHILDREN = "Search Project/Folder Children > Search Project Children > Search Project Children";
var SEARCH_FOLDER_CHILDREN = "Search Project/Folder Children > Search Folder Children > Search Folder Children";

hooks.before(SEARCH_PROJECT_CHILDREN, function (transaction, done) {
  //first create a project
  var payload = {
    "name": "Delete project for dredd - ".concat(shortid.generate()),
    "description": "A project to delete for dredd"
  };
  var request = tools.createResource('POST', '/projects', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    //Once project created, create folder
    var project_id = data['id'];
    var payload = {
      "parent": { "kind": "dds-project", "id": project_id },
      "name": "Delete folder for dredd - ".concat(shortid.generate())
    };
    var request2 = tools.createResource('POST', '/folders', JSON.stringify(payload), hooks.configuration.server);
    request2.then(function(data) {
      var folder_id = data['id'];
      //Once folder created, upload file, post it to folder
      // upload a file
      var request3 = tools.createUploadResource(project_id,hooks.configuration.server);
      request3.then(function(data3) {
        var upload_id = data3['id'];
        var payload = {
          "parent": { "kind": "dds-folder", "id": folder_id },
          "upload": { "id": upload_id }
        };
        //post that file to the new folder
        var request4 = tools.createResource('POST', '/files', JSON.stringify(payload),hooks.configuration.server);
        request4.then(function(data4) {
          // once the file is posted to the folder, modify the hook's transaction.fullpath
          var file_id = data4['id'];
          var url = transaction.fullPath;
          //we don't want any parameters in our path, so we'll remove them
          if (url.indexOf('?') > -1) {
            url = url.substr(0, url.indexOf('?'));
          }
          transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', project_id);
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
  var request = tools.createResource('POST', '/projects', JSON.stringify(payload),hooks.configuration.server);
  request.then(function(data) {
    //Once project created, create folder
    var project_id = data['id'];
    var payload = {
      "parent": { "kind": "dds-project", "id": project_id },
      "name": "Delete folder for dredd - ".concat(shortid.generate())
    };
    var request2 = tools.createResource('POST', '/folders', JSON.stringify(payload),hooks.configuration.server);
    request2.then(function(data) {
      var folder_id = data['id'];
      //Once folder created, upload file, post it to folder
      // upload a filez
      var request3 = tools.createUploadResource(project_id,hooks.configuration.server);
      request3.then(function(data3) {
        var upload_id = data3['id'];
        var payload = {
          "parent": { "kind": "dds-folder", "id": folder_id },
          "upload": { "id": upload_id }
        };
        //post that file to the new folder
        var request4 = tools.createResource('POST', '/files', JSON.stringify(payload),hooks.configuration.server);
        request4.then(function(data4) {
          // once the file is posted to the folder, modify the hook's transaction.fullpath
          var file_id = data4['id'];
          var url = transaction.fullPath;
          //we don't want any parameters in our path, so we'll remove them
          if (url.indexOf('?') > -1) {
            url = url.substr(0, url.indexOf('?'));
          }
          transaction.fullPath = url.replace('ca29f7df-33ca-46dd-a015-92c46fdb6fd1', folder_id);
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
