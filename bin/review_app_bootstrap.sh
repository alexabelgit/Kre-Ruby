#!/usr/bin/env bash

echo "Running db:migrate & db:seed"
DISABLE_DATABASE_ENVIRONMENT_CHECK=1 bundle exec rake db:migrate db:seed

bundle exec rake features:enable_default
