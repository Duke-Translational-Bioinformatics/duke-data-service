var Client = require('node-rest-client').Client;
var Promise = require("node-promise").Promise;

createResource = function(request_method, request_path, request_payload, xserver) {
  var request = new Promise();
  var client = new Client();
  var args = {
    "headers": { "Content-Type": "application/json"},
    "data": request_payload
  };
  var request_path = xserver.concat(request_path);
  client.registerMethod("apiMethod", request_path, request_method);
  client.methods.apiMethod(args, function(data, response) {
    request.resolve(data);
  });
  return request;
}

module.exports.createResource = createResource;
