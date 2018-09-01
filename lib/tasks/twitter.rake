require 'twitter'
require 'open-uri'
require "date"

SLICE_SIZE = 100

#
# The Twitter gem won't take StringIO so don't allow downloaded files to be created as StringIO. Force a tempfile to be created.
OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
OpenURI::Buffer.const_set 'StringMax', 0


# いつ：①rake実行②view表示時③capistrano(定期実行)
# なにを：movie_thumnail_urlで問題なさそうな画像をシェア
# 誰に：all and ”相互”が含まれているツイートにのみ
# どうやって：画像＋文言（f好きのf好きな人のためのf好きによる動画
# どこで：twitter
# 何をするか：ひたすらtweet


#昨日の日経平均、ダウはいくら、売買総額、直近上昇率、下落確率はx％
namespace :twitter do
  desc "tweet hello"

  task tttest: :environment do
    get_today_nikkei_summary(Date.today)

  end

  #フォロワー数を取得する
  task :get_followers do
    client = get_twitter_client
    twitter_id = 'will14stone'
    #puts "tweet = " & client.user(twitter_id).tweets_count
    #puts "follower = " & client.user(twitter_id).followers_count
    # puts client.user(twitter_id).tweets_count
    # puts client.user(twitter_id).followers_count
    # puts client.user(twitter_id).name
    # puts client.user(twitter_id).screen_name.to_s

    # 以下を実行する場合はterminalでscript textfile_name[ENTER]を入力してからrake実行するとfile出力可能
    twitter_ids = ["will14stone","ZKzkshop","znamkaonline","MUUARATA","_KIKIAYA"]
    all_count = 0
    twitter_ids.each_slice(SLICE_SIZE).each do |user_ids|
      #client.users(user_ids).each do |user|
      user_ids.each do |user_id|

        begin
          user = client.user(user_id)
          #p all_count.to_s + " , " + user.screen_name.to_s + " , ", user_id + " , " + user.name.to_s + " , " + user.followers_count.to_s
          p all_count.to_s + " , " + user.screen_name.to_s + " , " +  user_id.to_s + " , " + user.name.to_s + " , " + user.followers_count.to_s
          all_count = all_count + 1
        rescue Twitter::Error::ClientError
          #アカウント停止(suspend)されてしまったユーザーに対してclient.user()を実行するとエラーとなるので除外する
          #continue
          p all_count.to_s + "," + user_id.to_s + "はアカウント停止済み"
        end
      end
    end




    puts "exit: all" + twitter_ids.count.to_s + " : get" + all_count.to_s
    # puts "exit: " + twitter_ids.count.to_s
  end
  task :tweetPromote => :environment do
    client = get_twitter_client
    tweet = "今日も株価を確認しましょう！  http://www.japanchart.com"
    puts tweet
    update(client, tweet)
  end

  #自動tweet&scheduler(heroku)
  #http://qiita.com/kyohei8/items/5a7d7db3838728a04140
  task :tweetHello => :environment do
    client = get_twitter_client
    # tweet = "今日も株価を確認して１日楽しいひと時を！  http://www.japanchart.com"
    # if HolidayJp.holiday?(Date.today)
    #   tweet = "今日は休日のため休場です！株価の振り返りをしましょう！  http://www.japanchart.com"
    # end
    tweet = getWeekDayComment(Date.today)
    # d = Time.now.in_time_zone('Tokyo')
    #str = d.strftime("%Y年%m月%d日 %H:%M")
    # str = d.strftime("%Y年%m月%d日")
    # tweet = str + tweet
    puts tweet
    update(client, tweet)
  end

  # 10時にtweetする内容
  task :tweetBranch => :environment do
    client = get_twitter_client
    tweet = get_kessan_summary(Date.today)
    puts tweet
    if !tweet.nil?
      update(client, tweet)
    end
  end

  task :tweetEvening => :environment do
    client = get_twitter_client
    tweet = get_today_nikkei_summary(Date.today)
    p tweet
    if tweet
      update(client, tweet)
    end
  end

  # 直近の予定やニュースについてtweet
  task :tweetFeed => :environment do
    client = get_twitter_client
    tweet = get_tweet_feed(Date.today)
    p tweet
    if tweet.nil?
      next
    end
    tweet = tweet.to_s + " #japanchart 他のスケジュールについてはこちら→ http://www.japanchart.com/"

    if tweet
      update(client, tweet)
    end
  end

  task :tweetEurope => :environment do
    client = get_twitter_client
    tweet = get_tweet_europe(Date.today)
    if tweet
      update(client, tweet)
    end
  end
  task :followTweeter => :environment do
    client = get_twitter_client
    arrKeywords = ["相互", "リフォロー", "フォロバ", "支援", "フォロー", "refollow","followme","相互"]
    prng = Random.new(seed = Random.new_seed)
    randToJudge = prng.rand(arrKeywords.count)
    keyword = arrKeywords[randToJudge]
    num_of_attempts = 0
    client.search(keyword).take(10).each do |tweet|
      begin
       num_of_attempts += 1
       client.follow(tweet.user.id)
       p "#{tweet.user.name}をフォローしました"
      rescue Twitter::Error::TooManyRequests => error
       if num_of_attempts % 3 == 0
        p "sleep..."
        sleep(15*60) # minutes * 60 seconds=>制限かかるのって15minだっけ？
        p "retry"
        retry
       else
        p "retry"
        retry
       end
      end
    end
  end
  task :removeUnfollowers => :environment do
    client = get_twitter_client
    #途中→localでやればいいんじゃね？
    #puts client.friendship?('cwkakunin2013','ichirilalala').to_s
    # 自分をフォローしてない人をあんフォローする
    arrFollowers = get_all_followers("ferajapcom1")
    #arrFollowers.each do |follower|
    #   p follower.id
    #end

    #フォローしている人
    arrFriends = get_all_friends("ferajapcom1")
    arrFriends.each do |friend|
        if arrFollowers.include?(friend) #idでやらないとだめ？
          p "friends = #{friend.name}"
        else
          p "not friend = #{friend.name}"
          #Twitter::Client::FriendsAndFollowers.unfollow(friend)
          #friend.unfollow()
          #client.friend(:remove, friend)# rescue nil
          #http://stackoverflow.com/questions/24543394/twitter-ruby-api-how-do-i-unfollow-a-person
          client.unfollow(friend)
          p "りむった"
      end
  end

end
task :tweet => :environment do
 p "tweet task"
#task :tweetloop, [:arg1, :arg2] do |t, args|
#  puts "args were: #{args}"
#  next
  #timeloopモード
  #while true



  prng = Random.new(seed = Random.new_seed)
  randToJudge = prng.rand(2)
  p randToJudge
  #10分に一度実行されるrakeファイルなら
  #4回に１回すなわち40分に一度実行される確率
  if(false) then
   if !( randToJudge == 0) then
     puts 'next'
     next
   end
  end

  client = get_twitter_client
  tweet = "グッときたらRT❤️"

  #prng = Random.new(seed = Random.new_seed)
  array_tweets = ["#RTでリフォローします",
     "グッときたらRT❤️","RTでリフォロー❤️","リフォローするよー❤️",
     "nice body!!!❤️","エロいと思ったらRT❤️","かわいい！と思ったらRT❤️",
     "グッときたらRT❤️","\#refollow"]
  index_to_put_string = prng.rand(array_tweets.count)
  tweet = array_tweets[index_to_put_string]
  #d = Time.now #時間を入力する場合：ださいので挿入しないことにした
  #str = d.strftime("%Y年%m月%d日 %H:%M")
  #tweet = tweet + str
  puts "tweet = #{tweet}"

  # isTweetableフラグで判断する
  # idToTweet = 250 # prng.rand(Movie.count) ->loopで回して取得するまで脱出できないようにする
  # movieToTweet = Movie.first #find_by(movie_id: "442")

  arrMoviesTweetable = []
  Movie.all.each do |movie|
    if movie.is_tweetable
      p "tweetable id = #{movie.id}"
      arrMoviesTweetable.push(movie)
    end
  end
  # 一個も存在しない場合
  if arrMoviesTweetable.count == 0
    next
  end

  countMoviesTweetable = arrMoviesTweetable.count
  indexToPutMovie = prng.rand(countMoviesTweetable)
  movieToTweet = arrMoviesTweetable[indexToPutMovie]

  puts "movie = #{movieToTweet}"

  puts "movie_id = #{movieToTweet.movie_id}"
  puts "tweet id = #{movieToTweet.id}"

  media_url = movieToTweet.movie_thumnail_url;
  puts media_url
  # media_url = "http://newsdb.lolipop.jp/tmp/image/IMG_"#4416.JPG"
  # array_image = [3972,3973,3974,3975,3978,3982,3984,3985,4007,4016,4024,4035,4036,4041,4042,4047,4050,4051,4055,4076,4081,4086,4087,4090,4093,4094,4096,4098,4100,4101,4102,4104,4106,4107,4135,4141,4142,4143,4144,4145,4146,4221,4226,4227,4228,4229,4231,4232,4233,4247,4280,4282,4283,4284,4285,4286,4287,4288,4352,4372,4412,4413,4415,4416,4428,4433,4434,4435,4436,4437,4438,4439,4440,4441,4442,4443,4444,4445,4446,4447,4448,4449,4450,4451,4452,4453,4454,4455,4456,4457,4458,4459,4460,4461,4462,4463,4464,4465,4466,4467,4468,4469,4470,4471,4472,4473,4474,4475,4476,4477,4478,4479,4480,4481,4482,4483,4484,4485,4486,4487,4488,4489,4490,4491,4492,4493,4494,4495,4496,4497,4498,4499,4500,4501,4502,4503,4504,4505,4506,4507,4508,4509,4510,4518,4519,4520,4521,4522,4523,4524,4525,4526,9999,4528,4529,4552,4563,4564,4565,4566,4567,4568,4569,4570,4571,4572,4573,4574,4575,4576,4577,4578,4579]
  # num_of_array = array_image.count
  # puts "num of array  = " + num_of_array.to_s
  #random_image = prng.rand(num_of_array)
  #puts random_image
  #puts array_image[random_image]

  #puts array_image[index_to_put]

  # if prng.rand(2) == 0
   tweet = tweet + " www.ferajap.com/movies/#{movieToTweet.id}"
  # end
  # コメントに動画のタグを挿入したい！


  media = open(media_url)

  # 開いたファイルmediaが10kByte以下の場合、
  # mediaはtempfileではなくStringIOとなるため
  # tempfile形式に戻してやる必要がある。
  # http://easyramble.com/twiter-gem-update-with-media.html
  # if false
  #   if media.is_a?(StringIO)
  #     p "stringioなのでtempfileにする"
  #     ext = File.extname(media_url)
  #     name = File.basename(media_url, ext)
  #     tf = Tempfile.open([name, ext])
  #     tf.binmode
  #     tf.write(media.read)
  #     p "tf = #{tf}"
  #     client.update(tweet, tf)
  #   else
  #     p "stringio ではない"
  #     # 以下deprecated
  #     # client.update_with_media(tweet, media)
  #     client.update(tweet, media_url)
  #   end
  # end

#
  # media_ids = %w(/path/to/media1.png /path/to/media2.png).map do |filename|
  #  client.upload File.new filename
  # end
  # tweet = client.update "tweet text", {media_ids: media_ids.join(',')}


  # media_id = client.upload File.new media_url
  # tweet = client.update tweet, media_id
#


  begin
    p "tweet = #{tweet}"
    p "media = #{media}"
    # client.update(tweet, media)
    client.update_with_media(tweet, media)
    # client.update(tweet, File.new(media_url))
    p "succeeded tweeting with image!!"
  rescue => e
    p "error : #{e.message}"
    Rails.logger.error "<<twitter.rake::tweet.update ERROR : #{e.message}>>"
  ensure
    media.close
  end


  if false
   prng1 = Random.new(seed = Random.new_seed)
   randToJudge1 = prng1.rand(1000)
   if randToJudge1 == 0
     Rake::Task["twitter:removeUnfollowers"].execute
   end
   if randToJudge1 % 2 == 0
     Rake::Task["twitter:followTweeter"].execute
   end
  end
end

#loop mode
task :timeloop => :environment do
  while true
   #Rake.application.invoke_task(":tweet")
   Rake::Task["twitter:tweet"].execute # invokeだと実行できない
   p "looping.."
   sleep 7
  end
end


end

def get_twitter_client
  # https://twitter.com/japanchart1
  client = Twitter::REST::Client.new do |config|
  # 旧アカウント:cwkakunin2013
  # config.consumer_key        = "OtyxWXFy1QvqokhL2sHVQtco7"
  # config.consumer_secret     = "19o71ULvwSnVqUw3uLOqM01ruTBBWLTFQdGgLcWBjyom7VXYdv"
  # config.access_token        = "3110882388-jhTmwHiO4E9M9ZadGfNuLxDoLDXPd09aeuo3BdY"
  # config.access_token_secret = "qaRXTAak8hIZIj5GmQZQKegIuYlMUY7BT2NZofhGnHhgM"

    config.consumer_key          = "ugVezI1XdYqPUhm3xP8y8XZNz"
    config.consumer_secret       = "1rnoHsm42mt6WgW8cFk29YD367sRdz6fgzxN5k9AcGUuSGa8Rm"
    config.access_token          = "726018073925283842-HhdJeIhJhEMebtCd84nNF0buqJbyDvJ"
    config.access_token_secret   = "IZBGHqcoirUC6METphql2l9W4AZiFxxGGRs4m5WRBoMa0"
  end
  client
end

def update(client, tweet)
  begin
    p "length = #{tweet.length}, twitter char.length=#{tweet.encode("EUC-JP").bytesize/2}"
    tweet_contents = (tweet.encode("EUC-JP").bytesize/2 > 140) ? tweet[0..139].to_s : tweet
    client.update(tweet_contents.chomp)



    if tweet.encode("EUC-JP").bytesize/2 > 140
      sleep(20)
      tweet_contents2 = "..(続き)" + tweet[140..[tweet.length-1,280].min].to_s + " 詳しくは↓↓ http://www.japanchart.com"
      client.update(tweet_contents2.chomp)
    end
  rescue => e
    Rails.logger.error "<<twitter.rake::tweet.update ERROR : #{e.message}>>"
  end
end
def get_all_friends(screen_name)
  client = get_twitter_client
  #API制限がかからないようにスライスする
  all_friends = []
  client.friend_ids(screen_name).each_slice(SLICE_SIZE).each do |slice|
    client.users(slice).each do |friend|
      all_friends << friend
    end
  end
  all_friends
end

def get_all_followers(screen_name)
  client = get_twitter_client
  all_followers = []
  client.follower_ids(screen_name).each_slice(SLICE_SIZE).each do |slice|
    client.users(slice).each do |follower|
      all_followers << follower
      end
  end

   all_followers
end

def getKessanComment()
  # 昨日の決算情報、今日の決算情報
  # 140文字以内になるなら全て出したいが、無理なら「a,b,cなど全10企業」と省略する
  kessan_todays = []
  kessan_yesterdays = []
  today_date = Time.now().in_time_zone('Tokyo').strftime('%Y%m%d')
  yesterday_date = Time.at(Time.now().in_time_zone('Tokyo').to_i-24*3600).strftime('%Y%m%d')
  today_date = '20180726'
  yesterday_date = '20180725'
  str_todays = ""
  str_yesterdays = ""
  Feed.tagged_with('kessan').where('title like ?', '%決算%').each do |kessan_feed|
    p kessan_feed.title + "@" + Time.at(kessan_feed.feed_id.to_i).strftime('%Y%m%d')
    if Time.at(kessan_feed.feed_id.to_i).strftime('%Y%m%d') == today_date
      kessan_todays.push(kessan_feed)
      if str_todays.encode('EUC-JP').bytesize < 50
        str_todays = str_todays + (str_todays=="" ? "" : ",") + kessan_feed.keyword
      end
    elsif Time.at(kessan_feed.feed_id.to_i).strftime('%Y%m%d') == yesterday_date
      kessan_yesterdays.push(kessan_feed)
      if str_yesterdays.encode('EUC-JP').bytesize < 50
        str_yesterdays = str_yesterdays + (str_yesterdays=="" ? "" : ",") + kessan_feed.keyword
      end
    end
  end
  p "本日決算を発表するのは#{str_todays}などの#{kessan_todays.length}企業です。"
  p "昨日決算を発表したのは#{str_todays}などの#{kessan_todays.length}企業です。"
end


#土曜日は前の月〜金曜日の振り返り
#日曜日は気になるニュースについて
#月曜日以外の平日は前日の振り返り
#月曜日は今週の予定（イベント：Feedなど）
def getWeekDayComment(d)
  # d = Date.today

  # 日経平均、ダウ、上海総合の当落
  nikkei_last2 = Priceseries.where(ticker: "0000").order(ymd: :desc).first(2)
  dow_last2 = Priceseries.where(ticker: "^DJI").order(ymd: :desc).first(2)
  shanghai_last2 = Priceseries.where(ticker: "0823").order(ymd: :desc).first(2)
  rtnNikkei_1 = (nikkei_last2.first.close / nikkei_last2.last.close - 1) * 100
  rtnDow_1 = (dow_last2.first.close / dow_last2.last.close - 1) * 100
  rtnShg_1 = (shanghai_last2.first.close / shanghai_last2.last.close - 1)*100

  # 厳密に7日前という風にすると存在しない場合があるので、x日前以前の最大の日付として取得する
  # Priceseries.arel_table[:ymd].lteq(nikkei_last2.first.ymd - 7*24*3600)
  # 前週比(last_week)
  nikkei_lw = Priceseries.where(ticker: "0000").where(Priceseries.arel_table[:ymd].lteq(nikkei_last2.first.ymd - 7*24*3600)).order(ymd: :desc).first.close
  dow_lw = Priceseries.where(ticker: "^DJI").where(Priceseries.arel_table[:ymd].lteq(dow_last2.first.ymd - 7*24*3600)).order(ymd: :desc).first.close
  shanghai_lw = Priceseries.where(ticker: "0823").where(Priceseries.arel_table[:ymd].lteq(shanghai_last2.first.ymd-7*24*3600)).order(ymd: :desc).first.close
  rtnNikkei_7 = (nikkei_last2.first.close / nikkei_lw - 1) * 100
  rtnDow_7 = (dow_last2.first.close / dow_lw - 1) * 100
  rtnShg_7 = (shanghai_last2.first.close / shanghai_lw - 1) * 100

  #前月比(last_month)
  nikkei_lm = Priceseries.where(ticker: "0000").where(Priceseries.arel_table[:ymd].lteq(nikkei_last2.first.ymd - 30*24*3600)).order(ymd: :desc).first.close
  dow_lm = Priceseries.where(ticker: "^DJI").where(Priceseries.arel_table[:ymd].lteq(dow_last2.first.ymd - 30*24*3600)).order(ymd: :desc).first.close
  shanghai_lm = Priceseries.where(ticker: "0823").where(Priceseries.arel_table[:ymd].lteq(shanghai_last2.first.ymd - 30*24*3600)).order(ymd: :desc).first.close
  rtnNikkei_30 = (nikkei_last2.first.close / nikkei_lm - 1) * 100
  rtnDow_30 = (dow_last2.first.close / dow_lm - 1) * 100
  rtnShg_30 = (shanghai_last2.first.close / shanghai_lm - 1) * 100


  daily_comment = "昨日の日経平均は#{nikkei_last2.first.close}円で前日比#{rtnNikkei_1.abs.round(2)}%の#{rtnNikkei_1>0 ? "上昇" : "下落"}、ダウは#{dow_last2.first.close}ドルで#{rtnDow_1.abs.round(2)}%#{rtnDow_1>0 ? "上昇" : "下落"}、上海総合は#{shanghai_last2.first.close}ptで#{rtnShg_1.abs.round(2)}%#{rtnShg_1>0 ? "上昇" : "下落"}でした。"
  #weekly_comment = "今週の日経平均は#{nikkei_last2.first.close}円で前週比#{rtnNikkei_7.abs.round(2)}%の#{rtnNikkei_7>0 ? "上昇" : "下落"}、ダウは#{dow_last2.first.close}ドルで#{rtnDow_7.abs.round(2)}%#{rtnDow_7>0 ? "上昇" : "下落"}、上海総合は#{shanghai_last2.first.close}ptで#{rtnShg_7.abs.round(2)}%#{rtnShg_7>0 ? "上昇" : "下落"}でした。"
  weekly_comment = "今週の日経平均は#{nikkei_last2.first.close}円で前週比#{rtnNikkei_7.abs.round(2)}%の#{rtnNikkei_7>0 ? "上昇" : "下落"}(前月比#{rtnNikkei_30.abs.round(2)}%#{rtnNikkei_30>0 ? "上昇" : "下落"})、" +
    "ダウは#{dow_last2.first.close}ドルで前週比#{rtnDow_7.abs.round(2)}%#{rtnDow_7>0 ? "上昇" : "下落"}(前月比#{rtnDow_30.abs.round(2)}%#{rtnDow_30>0 ? "上昇" : "下落"})、" +
    "上海総合は#{shanghai_last2.first.close}ptで前週比#{rtnShg_7.abs.round(2)}%#{rtnShg_7>0 ? "上昇" : "下落"}(前月比#{rtnShg_30.abs.round(2)}%#{rtnShg_30>0 ? "上昇" : "下落"})でした。"
  monthly_comment = "日経平均は1ヶ月で#{rtnNikkei_30.abs.round(2)}%の#{rtnNikkei_30>0 ? "上昇" : "下落"}、ダウは#{rtnDow_30.abs.round(2)}%#{rtnDow_7>0 ? "上昇" : "下落"}、上海総合は#{rtnShg_30.abs.round(2)}%#{rtnShg_30>0 ? "上昇" : "下落"}でした。"

  case d.wday
  when 0
    p "日曜日"

    # 先週の気になるニュース
    # 今週の予定
    comment = monthly_comment

    # 先週の決算があった銘柄の中で最も騰落率が大きかったのはxxxです。
    last_kessans = Feed.tagged_with('kessan').where('ticker is not null').where('title like ?', '%決算%').where(Feed.arel_table[:feed_id].lteq(Time.new.to_i)).order(feed_id: :desc)
    min_return = max_return = 0
    min_kessan = nil
    max_kessan = nil
    last_kessans.each do |kessan|
      # 決算企業の銘柄コードを取得して１週間騰落率を取得して、その中で最もabsが大きい銘柄を探す
      ticker = kessan.ticker
      #7日以上前で最近の値(=7日前の株価)
      before7 = Priceseries.where(ticker: ticker).where(Priceseries.arel_table[:ymd].lteq(Time.new.to_i-3600*24*7)).order(ymd: :desc).first
      todayPrice = Priceseries.where(ticker: ticker).order(ymd: :desc).first

      returnPrice = (todayPrice.close.to_f/before7.close.to_f-1 ) * 100
      if returnPrice > max_return
        max_return = returnPrice
        max_kessan = kessan
      end
      if returnPrice < min_return
        min_return = returnPrice
        min_kessan = kessan
      end
    end

    #日経平均は1ヶ月で1.67%の上昇、ダウは2.48%下落、上海総合は0.63%上昇でした。先週の決算で最も反応があった銘柄はＫＤＤＩ(9433:-0京王電鉄(9008:-0で

    # 先週の決算総括
    kessan_feature = nil;
    if !max_kessan.nil? || !min_kessan.nil?
      kessan_feature = "先週の決算で特に反応があった銘柄は";
      if !max_kessan.nil?
        p max_kessan
        kessan_feature = kessan_feature +
        "#{max_kessan.keyword}(#{max_kessan.ticker.nil? ? "" : (max_kessan.ticker + ":")}" +
        "前週比#{max_return>0 ? '+' : '-'}#{max_return.abs.round(1)}%)" + (min_kessan.nil? ? "" : "と")
      end
      if !min_kessan.nil?
        kessan_feature = kessan_feature +
        "#{min_kessan.keyword}(#{min_kessan.ticker.nil? ? "" : (min_kessan.ticker + ":")}" +
        "前週比#{min_return>0 ? '+' : '-'}#{min_return.abs.round(1)}%)"
      end
      kessan_feature = kessan_feature + "です。"
    end
    comment = comment + kessan_feature;
    # ↑まだ確認してない


  when 1
    # 今週の予定
    p "月曜日"
    min_feed_ir = Feed.tagged_with('kessan').where('title like ?', '%決算%').first
    feed_length = min_feed_ir.nil? ? 0 : min_feed_ir.title.encode('EUC-JP').bytesize
    Feed.tagged_with('kessan').where('title like ?', '%決算%').each do |feed_each|
      p feed_each.title + "(#{Time.at(feed_each.feed_id.to_i).in_time_zone('Tokyo')})"
      begin
        if feed_each.title.encode("EUC-JP").bytesize <= feed_length
          min_feed_ir = feed_each
          feed_length = feed_each.title.encode('EUC-JP').bytesize
        end
      rescue #エンコードや文字カウント絡みで何かしらのエラーが発生した時は無視して次を見る
        next
      end
    end
    min_feed_event = Feed.where(keyword: 'market_schedule').where(Priceseries.arel_table[:feed_id].gt(Time.now.to_i)).first
    feed_length = min_feed_event.nil? ? 0 : (min_feed_event.title.encode('EUC-JP').bytesize)
    Feed.where(keyword: 'market_schedule').each do |feed_each|
      p feed_each.title + "(#{Time.at(feed_each.feed_id.to_i).in_time_zone('Tokyo')})"
      begin
        if feed_each.title.encode("EUC-JP").bytesize <= feed_length ||
          feed_each.title.include?('日銀') || feed_each.title.include?('雇用統計')
          min_feed_event = feed_each
          feed_length = feed_each.title.encode('EUC-JP').bytesize
          if feed_each.title.include?('日銀') || feed_each.title.include?('雇用統計')
            # 日銀や雇用統計というキーワードがあれば優先する
            break
          end
        end
      rescue
        next
      end
    end

    # comment = "まず先週末のダウは#{dow_last2.first.close}ドルで引けました。これは前週比で#{rtnDow_7.round(2)}%です。今週は#{Time.at(min_feed_ir.feed_id.to_i).strftime('%-d')}日に#{min_feed_ir.keyword}による#{min_feed_ir.title}のIRがありました。"
    market_comment = "先週末の日経平均は#{nikkei_last2.first.close}円で引けた後、ダウは#{dow_last2.first.close}ドルに。日経平均は足元1週間で#{rtnNikkei_7.round(2)}％の#{rtnNikkei_7>0 ? "上昇" : "下落"} 、" +
              "ダウは#{rtnDow_7.round(2)}％の#{rtnDow_7>0 ? "上昇" : "下落"}、1ヶ月間ではそれぞれ#{rtnNikkei_30.round(2)}％の#{rtnNikkei_30>0? "上昇" : "下落"}、#{rtnDow_30.round(2)}％の#{rtnDow_30>0? "上昇" : "下落"}。"
    comment = market_comment
    if !min_feed_ir.nil?
      ir_comment = "先週は#{Time.at(min_feed_ir.feed_id.to_i).strftime('%-d')}日に#{min_feed_ir.keyword.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"")}から#{min_feed_ir.title}のIRがありました。"
      comment = comment + ir_comment
    end
    if !min_feed_event.nil?
      event_comment = "今週は#{Time.at(min_feed_event.feed_id.to_i).strftime('%-d')}日に#{min_feed_event.title}などの発表を控えている。"
      # ex. # 先週末の日経平均は22270.38円で引けた後、ダウは25669.32ドルに。日経平均は足元1週間で-0.12％の下落 、ダウは1.41％の上昇、1ヶ月間ではそれぞれ-2.3％の下落、1.87％の上昇。今週は17日に韓国・雇用統計などの発表を控えている。
      comment = comment + event_comment
    end
    # 文字サイズに応じて文章を変更する
    if comment.encode("EUC-JP").bytesize/2 > 140
      comment = market_comment + event_comment
    end
    if comment.encode("EUC-JP").bytesize/2 > 140
      comment = market_comment
    end
    p "comment = #{comment}"
    p "length = #{comment.length}, twitter char.length=#{comment.encode("EUC-JP").bytesize/2}"

  when 2,3,4,5
    p "月曜日以外の平日"
    # 前日の振り返り、前日の決算＆指標と当日の決算＆指標
    # 昨日の日経は円(+%)、ダウはドル(+%)でした。またAの決算とB指標などが発表されました。本日の決算はC決算とD指標が発表されます。
    today_date = Time.now().in_time_zone('Tokyo').strftime('%Y%m%d')
    yesterday_date = Time.at(Time.now().in_time_zone('Tokyo').to_i-24*3600).strftime('%Y%m%d')
    ir_todays = ApplicationController.new.getIrArrays(today_date)
    ir_yesterdays = ApplicationController.new.getIrArrays(yesterday_date)

    event_todays = ApplicationController.new.getMarketSchedules(today_date)
    event_yesterdays = ApplicationController.new.getMarketSchedules(yesterday_date)

    # comment = "まず先週末のダウは#{dow_last2.first.close}ドルで引けました。これは前週比で#{rtnDow_7.round(2)}%です。今週は#{Time.at(min_feed_ir.feed_id.to_i).strftime('%-d')}日に#{min_feed_ir.keyword}による#{min_feed_ir.title}のIRがありました。"
    market_comment = "昨日の日経平均は#{nikkei_last2.first.close}円(#{rtnNikkei_1>0 ? "+":"△"}#{rtnNikkei_1.abs.round(1)}%)、ダウは#{dow_last2.first.close}ドル(#{rtnDow_1>0 ? "+":"△"}#{rtnDow_1.abs.round(1)}%)。"
    comment = ""

    #決算情報
    kessan_comment = ""
    if ir_yesterdays.length > 0#昨日IR
      ir_yesterday_comment = "#{ir_yesterdays[0].keyword.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"")}"+
                             (ir_yesterdays.length>1 ? ",#{ir_yesterdays[1].keyword.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"")}" : "")+
                             (ir_yesterdays.length>2 ? ",#{ir_yesterdays[2].keyword.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"")}" : "")
      kessan_comment = kessan_comment + "昨日は" + ir_yesterday_comment
    end
    if ir_todays.length > 0#本日IR
      p "ir_todays.length = #{ir_todays.length}, ir_todays[1].keyword = #{ir_todays[1]}, #{ir_todays[1].keyword}"
      p "ir_todays.length = #{ir_todays.length}, ir_todays[1].keyword = #{ir_todays[2]}, #{ir_todays[2].keyword}"

      ir_today_comment = "#{ir_todays[0].keyword.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"")}"+
                         (ir_todays.length>1 ? ",#{ir_todays[1].keyword.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"")}" : "") +
                         (ir_todays.length>2 ? ",#{ir_todays[2].keyword.gsub(/ホールディングス/,"HD").gsub(/株式会社/,"")}など" : "")
      kessan_comment = kessan_comment + (ir_yesterdays.length>0 ? "," : "") + "本日は" + ir_today_comment
    end
    if ir_todays.length > 0 || ir_yesterdays.length > 0
      kessan_comment = kessan_comment + "の決算がありま#{ir_todays.length==0 && ir_yesterdays.length>0 ? "した" : "す"}."
    end

    #経済指標
    event_comment = ""
    if event_yesterdays.count > 0
      event_yesterday_comment =
        "#{event_yesterdays[0].title}"+
        (event_yesterdays.length>1 ? ",#{event_yesterdays[1].title}" : "") +
        (event_yesterdays.length>2 ? ",#{event_yesterdays[2].title}" : "" )
      event_comment = event_comment + "昨日は" + event_yesterday_comment
    end
    p "event_todays.count = #{event_todays.count}"
    if event_todays.count > 0
      event_today_comment =
        "#{event_todays[0].title}"+
        (event_todays.length>1 ? ",#{event_todays[1].title}" : "") +
        (event_todays.length>2 ? ",#{event_todays[2].title}" : "")
      event_comment = event_comment + (event_yesterdays.length>0 ? "の発表があり," : "") + "本日は" + event_today_comment
    end
    if event_todays.length > 0 || event_yesterdays.length > 0
      event_comment = event_comment + "の発表があります."
    end


    # 文章の結合
    # if event_comment.encode("EUC-JP").bytesize/2 < 140
      comment = event_comment
    # end
    # if (comment + kessan_comment).encode("EUC-JP").bytesize/2 < 140
      comment = comment + kessan_comment
    # end
    # if (comment + market_comment).encode("EUC-JP").bytesize/2 < 140
      # マーケット情報は先
      comment = market_comment + comment
    # end

    #その他の決算銘柄、マーケット情報はこちら
    other_words = "#{kessan_comment=='' ? '' : 'その他の'}決算銘柄、マーケット情報はこちら→ http://www.japanchart.com/"
    if (comment + other_words).encode("EUC-JP").bytesize/2 < 140
      comment = comment + other_words
    end

    # 今日の経済指標>今日の決算>>昨日の経済指標>昨日の決算
    p "comment = #{comment}"
    p "length = #{comment.length}, twitter char.length=#{comment.encode("EUC-JP").bytesize/2}"

    comment = comment.gsub(/アメリカ/,"米")


  when 6
    p "土曜日"

    # case Random.new.rand(5)
    # when 0
    #   before_comment = "待ちに待った週末。"
    # when 1
    #   before_comment = "今週もお疲れ様。"
    # when 2
    #   before_comment = "やっと土曜日ですね。"
    # when 3
    #   before_comment = "今週もお仕事ご苦労様。"
    # when 4
    #   before_comment = "いよいよ週末です。"
    # else
    #   before_comment = ""
    # end
    before_comment = ""
    #騰落率上位
    comment = before_comment + weekly_comment

    #騰落率ランキングトップ(where(rank: 1)としないでorderでやるのは１位がbitcoinや指数である可能性があるため)
    top_rank = Rank.where(market: "^N225-3days-return").where(sort: "up").where.not(name: "bitcoin").order(rank: :asc).first
    bottom_rank = Rank.where(market: "^N225-3days-return").where(sort: "down").where.not(name: "bitcoin").order(rank: :asc).first
    comment = comment + "日経での騰落率トップは#{top_rank.name.gsub(/ホールディングス/,"").gsub(/株式会社/,"")}(#{top_rank.return.to_f>0 ? "+" : "△"}#{top_rank.return.to_f.abs.round(2)}%)、" +
      "下落率トップは#{bottom_rank.name.gsub(/ホールディングス/,"").gsub(/株式会社/,"")}(#{bottom_rank.return.to_f>0 ? "+" : "△"}#{bottom_rank.return.to_f.abs.round(2)}%)でした。"

    # 今週の振り返り
    # ニュースも？
  else
    p "曜日取得エラー"
  end

  return comment
end

#今週の決算データの総括(10時時点なので)
def get_kessan_summary(today)
  comment = nil;
  case today.wday
  when 0#日曜日
    p "日曜日"
    return nil;
  when 1,2,3,4,5 #平日
    p "平日"
    #今日の決算データの総括
    # from_unixtime = Time.at((Time.new.strftime('%Y-%m-%d') + " 00:00:00").to_time).to_i
    # to_unixtime = Time.at((Time.new.strftime('%Y-%m-%d') + " 23:59:59").to_time).to_i
    from_unixtime = Time.at((today.strftime('%Y-%m-%d') + " 00:00:00").to_time).to_i
    to_unixtime = Time.at((today.strftime('%Y-%m-%d') + " 23:59:59").to_time).to_i

    #localでは使えるが、herokuでは使えない
    kessans = Feed.where(Feed.arel_table[:feed_id].gteq(from_unixtime)).where(Feed.arel_table[:feed_id].lteq(to_unixtime)).tagged_with('kessan')
    p "決算情報がありません"
    if kessans.count == 0

      return nil
    end
    kessan_names = ""
    kessans.last(10).each_with_index do |kessan, i|
      kessan_names = kessan_names + (i==0 ? "" : ",") + kessan.keyword
    end
    comment = "本日は" + kessan_names + "など" + (kessans.count == 1 ? "" : "日経平均採用#{kessans.count}銘柄") + "の決算発表があります。"
    return comment
  when 6 #土曜日
    p "土曜日"
    #today_unixtime = Time.new.to_time.to_i
    today_unixtime = today.to_time.to_i
    # get feed for 7days ago
    #kessans = Feed.where("feed_id >= ?", today_unixtime - 7 * 24 * 3600).tagged_with('kessan').order(feed_id: :asc)
    kessans = Feed.where(Feed.arel_table[:feed_id].gteq(today_unixtime - 7 * 24 * 3600)).tagged_with('kessan').order(feed_id: :asc)
    if kessans.count == 0
      return nil
    end

    kessan_names = ""
    kessan_date = ""
    before_date = ""
    if kessans.count >= 10
      kessans.first(5).each_with_index do |kessan, i|
        # p kessan.title + ":" + kessan.description + ":" + kessan.tag_list.to_s
        if before_date != Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
          kessan_date = Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
          before_date = Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
        else
          kessan_date = "同日"
        end
        kessan_names = kessan_names + (i==0 ? "" : ",") + kessan.keyword + "(#{kessan_date})"
      end
      if kessan_names != ""
        kessan_names = kessan_names + "から"
      end
      kessans.last(5).each_with_index do |kessan, i|
        if before_date != Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
          kessan_date = Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
          before_date = Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
        else
          kessan_date = "同日"
        end
        kessan_names = kessan_names + (i==0 ? "" : ",") + kessan.keyword + "(#{kessan_date})"
      end
    else
      kessans.each_with_index do |kessan, i|
        if before_date != Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
          kessan_date = Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
          before_date = Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')
        else
          kessan_date = "同日"
        end
        kessan_names = kessan_names + (i==0 ? "" : ",") + kessan.keyword + "(#{Time.at(kessan.feed_id.to_i).strftime('%-m/%-d')})"
      end
    end
    if kessans.count > 1
      comment = kessan_names + "など日経225採用銘柄では#{kessans.count}銘柄の決算発表があった。"
    else
      comment = kessan_names + "の決算発表もあった。"
    end
    comment = "今週は" + comment
  else
    return nil
  end
  p comment.length
  return comment
end

# 本日の日経上位と下位銘柄@夕方19時
def get_today_nikkei_summary(today)
  comment = nil;
  start_unixtime = 0
  target_unixtime = Priceseries.where(ticker: "8306").order(ymd: :desc).first.ymd.to_i
  term_word = ""

  case today.wday
  when 0#日曜日
    p "日曜日"
    #1ヶ月分の騰落率を取得したい
    start_unixtime = target_unixtime - 30 * 24 * 3600
    term_word = "この1ヶ月間"
  when 1,2,3,4,5 #平日
    p "平日"
    #前日からの騰落率を取得したい
    start_unixtime = target_unixtime - 1 * 24 * 3600
    term_word = "本日"
  when 6 #土曜日
    p "土曜日"
    # １週間分の騰落率を取得したい
    start_unixtime = target_unixtime - 7 * 24 * 3600
    term_word = "この１週間"
  end
  max_return = 0;
  min_return = 0;

  p "target_unixtime = #{target_unixtime}"
  # ticker_returns = Hash.new
  # Priceseries.where(ymd: target_unixtime).each do |price_unit|
  #   # ４桁の数字かどうか
  #   ticker=price_unit.ticker
  #   if ticker.scan(/\D/).empty?
  #     if ticker.to_i > 999
  #       # 直近分
  #       # price = Priceseries.where(ticker: ticker).order(ymd: :desc).first(2)
  #
  #       # 曜日によって異なるリターンの組み合わせ
  #       # 土曜日→[最新の株価]vs[7日（以前で最大の日における）株価]のリターン
  #       price = Priceseries.where(ticker: ticker).order(ymd: :desc).first(1) +
  #               Priceseries.where(ticker: ticker).where(Priceseries.arel_table[:ymd].lteq(start_unixtime)).order(ymd: :desc).first(1)
  #               #Priceseries.where(ticker: ticker).where(ymd: start_unixtime).order(ymd: :desc).first(1)
  #       return_price = price.first.close.to_f / price.last.close.to_f - 1
  #       ticker_returns[ticker] = return_price
  #     end
  #   end
  # end
  #
  # # 並び替え（降順）→ハッシュから配列に変化
  # ticker_returns = ticker_returns.sort {|(k1, v1), (k2, v2)| v2 <=> v1 }
  ticker_returns = ApplicationController.new.getReturnRanks(start_unixtime, target_unixtime)

  threashold = 0.03
  # 上昇銘柄と下落銘柄を最大５銘柄格納する
  arr_ups = []
  ticker_returns.first(5).each do |ticker_return|
    if ticker_return[1].to_f > threashold
      p "#{ticker_return[0]} : #{ticker_return[1]}"
      arr_ups.push(ticker_return)
    end
  end
  arr_downs = []
  ticker_returns.last(5).reverse.each do |ticker_return|
    if ticker_return[1].to_f < -1 * threashold
      p "#{ticker_return[0]} : #{ticker_return[1]}"
      arr_downs.push(ticker_return)
    end
  end

  up_contents = ""
  up_contents2 = ""
  up_num = 0
  arr_ups.each_with_index do |up,i|
    up_info = Priceseries.where(ticker: up[0]).order(ymd: :desc).first
    if up_info.close.to_f > 1000
      if i > 0
        up_contents = up_contents + ","
        up_contents2 = up_contents2 + ","
      end
      up_contents = up_contents + "#{up_info.name}(#{up_info.ticker})の#{up[1].to_f>0 ? '+' : '△'}#{((up[1].to_f)*100).abs.round(2)}%"
      up_contents2 = up_contents2 + "#{up_info.name}(#{up_info.ticker})が#{up[1].to_f>0 ? '+' : '△'}#{((up[1].to_f)*100).abs.round(2)}%"
      up_num = up_num + 1
    end
  end

  down_contents = ""
  down_contents2 = ""
  down_num = 0
  arr_downs.each_with_index do |down,i|
    down_info = Priceseries.where(ticker: down[0]).order(ymd: :desc).first
    if down_info.close.to_f > 1000
      if i > 0
        down_contents = down_contents + ","
        down_contents2 = down_contents2 + ","
      end
      down_contents = down_contents + "#{down_info.name}(#{down_info.ticker})の#{down[1].to_f>0 ? '+' : '△'}#{((down[1].to_f)*100).abs.round(2)}%"
      down_contents2 = down_contents2 + "#{down_info.name}(#{down_info.ticker})が#{down[1].to_f>0 ? '+' : '△'}#{((down[1].to_f)*100).abs.round(2)}%"
      down_num = down_num + 1
    end
  end

  #上昇銘柄数
  all_up_num = 0
  all_down_num = 0
  ticker_returns.each do |ticker_return|
    if ticker_return[1].to_f > 0
      all_up_num = all_up_num + 1
    elsif ticker_return[1].to_f < 0
      all_down_num = all_down_num + 1
    end
  end


  p up_contents
  p down_contents
  p up_num
  p down_num
  contents =
  "#{term_word}の上昇銘柄は#{up_num == 0 ? '' : (up_contents + 'など')}#{all_up_num}銘柄で"+
  "下落銘柄は#{down_num == 0 ? '' : (down_contents + 'など')}#{all_down_num}銘柄です。"


  contents2_1 =
  "日経225採用銘柄のうち、#{term_word}#{(today.wday%6 == 0) ? "で" : ""}上昇したのは#{all_up_num}銘柄,下落は#{all_down_num}銘柄です。"
  contents2_2 = ""
  # contents2_2 =
  # ((up_num==0) && (down_num==0)) ? '' :
  # ("主に#{up_contents2 == '' ? '' : (up_contents2 + 'の上昇、')}" +
  # "下落銘柄では#{down_contents2 == '' ? '' : (down_contents2 + '')}と大きく動いています。")
  p "up_num = #{up_num}, down_num = #{down_num}"
  if (up_num==0) || (down_num==0)
    if up_num > 0
      "pattern 1"
      contents2_2 = "特に大きく動いたのは#{up_contents}の上昇です。"
    elsif down_num > 0
      "pattern 2"
      contents2_2 = "特に大きく動いたのは#{up_contents}の下落です。"
    else
      "pattern 3"
      contents2_2 = "#{(threashold*100).to_i}%以上動いた銘柄はありませんでした。"
    end
  else
    "pattern 4"
    contents2_2 =
    "主に#{up_contents2 == '' ? '' : (up_contents2 + 'の上昇、')}" +
    "下落銘柄では#{down_contents2 == '' ? '' : (down_contents2 + '')}と大きく動いています。"
  end
  contents2 = contents2_1 + contents2_2


  # if ((up_num>0) || (down_num>0))
    contents = contents2
  # end
  return contents


  if Random.new(Time.now.to_i).rand(2) % 2 == 0
    return contents2
  else
    return contents
  end
end

def get_tweet_feed(today)
  feed_now_on = Feed.where(keyword: "market_schedule").where(Feed.arel_table[:feed_id].gt(Time.now.to_time.to_i)).where(is_tweeted: 0)
  if feed_now_on.count == 0
    return nil
  end
  tweet_feed = feed_now_on.order(feed_id: :desc).last(Random.new(Time.now.to_time.to_i).rand(feed_now_on.count)).last

  tweet = tweet_feed.description

  tweet_feed.is_tweeted = 1#tweet済みとする
  tweet_feed.save

  return tweet
end

def get_tweet_europe(today)
  comment = ""
  case today.wday
  when 0,6 #sunday
    p "ヨーロッパはこの１週間でxxxx%、この1ヶ月でxxxx%下落しました。先月比では主にイギリスがxx％と大きく動いています。"
  when 1,2,3,4,5 #mon,tue,wed,thu,fri
    p "昨日の欧州株式市場はイギリスが、フランスが、イタリアが、ドイツがxxx%の上昇となっています。この１週間ではイギリスがxxxの上昇と最も動いています。"

  else

  end



end
