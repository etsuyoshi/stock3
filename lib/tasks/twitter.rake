require 'twitter'
require 'open-uri'

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

namespace :twitter do
  desc "tweet hello"
  task :tweetNews => :environment do
    
  end
  task :tweetHello => :environment do

    client = get_twitter_client
    tweet = "今日も１日楽しいひと時を！"
    d = Time.now + 60 * 60 * 24 * 1
    #str = d.strftime("%Y年%m月%d日 %H:%M")
    str = d.strftime("%Y年%m月%d日%T")
    tweet = tweet + str
    puts tweet
    update(client, tweet)
  end


  task :tweetGoodMorning => :environment do
    client = get_twitter_client
    tweet = "今日も１日楽しいひと時を！"
    d = Time.now + 60 * 60 * 24 * 1
    #str = d.strftime("%Y年%m月%d日 %H:%M")
    str = d.strftime("%Y年%m月%d日")
    tweet = tweet + str
    puts tweet
    update(client, tweet)
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
    tweet = (tweet.length > 140) ? tweet[0..139].to_s : tweet
    client.update(tweet.chomp)
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
