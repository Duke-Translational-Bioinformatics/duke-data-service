#!/bin/bash

diff apib_names.txt <(dredd apiary.apib http://go.com --names)
