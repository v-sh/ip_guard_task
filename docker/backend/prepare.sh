#!/bin/bash

echo "= Preparing backend dev environment"
bundle check || bundle install -j4
echo "= Creating && migrating db"
bin/rails db:create db:migrate
