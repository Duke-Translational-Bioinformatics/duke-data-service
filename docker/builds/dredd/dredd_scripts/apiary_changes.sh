#!/bin/bash

diff <(dredd apiary_old.apib http://go.com --names) <(dredd apiary.apib http://go.com --names)
