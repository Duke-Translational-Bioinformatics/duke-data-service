#!/bin/bash
echo "apiToken="`heroku run rake api_test_user:create -a dukeds-dev | tail -1 | sed 's/\*\*.*\[NewRelic\].*//'` >> dredd.env
docker-compose -f docker-compose.dredd.yml run dredd
