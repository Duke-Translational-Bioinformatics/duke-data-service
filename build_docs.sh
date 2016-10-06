#!/bin/bash

api-blueprint-validator apiary.apib
aglio -i apiary.apib -o app/views/apidocs/index.html 
