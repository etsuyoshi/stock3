#!/bin/sh
#how to execution : /bin/sh/ sendHeroku.sh
#実行方法
#/bin/sh ./sendHeroku.sh
git add -A
git commit -m "a"
git push heroku master
heroku open
