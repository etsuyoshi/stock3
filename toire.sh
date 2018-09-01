/bin/sh ./gitpush.sh
heroku run rake db:delete_unused
heroku run rake db:getSchedules
heroku run rake db:getNews
heroku run rake db:updatePrice
