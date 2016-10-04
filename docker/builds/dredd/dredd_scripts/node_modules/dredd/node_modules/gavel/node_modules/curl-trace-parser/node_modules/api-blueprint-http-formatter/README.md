# HTTP API Blueprint formater

[![Build Status](https://travis-ci.org/apiaryio/api-blueprint-http-formatter.png)](https://travis-ci.org/apiaryio/api-blueprint-http-formatter)
[![Dependency Status](https://david-dm.org/apiaryio/api-blueprint-http-formatter.png)](https://david-dm.org/apiaryio/api-blueprint-http-formatter)
[![devDependency Status](https://david-dm.org/apiaryio/api-blueprint-http-formatter/dev-status.png)](https://david-dm.org/apiaryio/api-blueprint-http-formatter#info=devDependencies)


## Usage

It accepts object with `request` and `response` keys in format used by [Gavel](https://github.com/apiaryio/gavel) and returns it back in [API Blueprint format](http://apiblueprint.org)

- [Request format](https://www.relishapp.com/apiary/gavel/v/1-0/docs/data-model#http-request)
- [Response format](https://www.relishapp.com/apiary/gavel/v/1-0/docs/data-model#http-response)


# Example usage

```javascript
var bf = require('./src/api-blueprint-http-formatter');
var post = {
  "request": {
    "method": "POST",
    "uri": "/shopping-cart",
    "headers": {
      "User-Agent": "curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8x zlib/1.2.5",
      "Host": "curltraceparser.apiary.io",
      "Accept": "*/*",
      "Content-Type": "application/json",
      "Content-Length": "39"
    },
    "body": "{ \"product\":\"1AB23ORM\", \"quantity\": 2 }"
  },
  "response": {
    "statusCode": "201",
    "statusMessage": "Created",
    "headers": {
      "Content-Type": "application/json",
      "Date": "Sun, 21 Jul 2009 14:51:09 GMT",
      "X-Apiary-Ratelimit-Limit": "120",
      "X-Apiary-Ratelimit-Remaining": "119",
      "Content-Length": "50",
      "Connection": "keep-alive"
    },
    "body": "{ \"status\": \"created\", \"url\": \"/shopping-cart/2\" }"
  }
};

blueprint = bf.format(post);
console.log(blueprint);
```

## Output is a API Blueprint

```
# POST /shopping-cart
+ Request
    + Headers

            User-Agent:curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8x zlib/1.2.5
            Host:curltraceparser.apiary.io
            Accept:*/*
            Content-Type:application/json
            Content-Length:39

    + Body

            { "product":"1AB23ORM", "quantity": 2 }

+ Response 201
    + Headers

            Content-Type:application/json
            Date:Sun, 21 Jul 2009 14:51:09 GMT
            X-Apiary-Ratelimit-Limit:120
            X-Apiary-Ratelimit-Remaining:119
            Content-Length:50
            Connection:keep-alive

    + Body

            { "status": "created", "url": "/shopping-cart/2" }

```

Use [Protagoinst](https://github.com/apiaryio/protagonist), Api Blueprint Node.js parser to parse or canonical [Snowcrash](https://github.com/apiaryio/snowcrash) parser to get Blueprint AST

## API Reference

`format(pair)` - returns string with message pair in API blueprint format

