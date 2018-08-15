require 'yahoo-finance'

require "csv"
#scrape255:
require 'nokogiri'
require 'open-uri'


namespace :db do
	desc "Fill database with sample data"
  # 特定の店舗の投稿頻度を算出する
	task insta: :environment do

		arrShops = getShopId(0)

		counter = 0
		# 初回実行時のみ列名入力
		# CSV.open('instafollower.csv','w') do |test|
		# 	test << ["insta_id", "max_posts", "follower", "numMonth", "numWeek", "recent_post_date"]
		# end
		CSV.open('instafollower2.csv','a') do |test|
			for shop_insta_id in arrShops
				counter = counter  + 1
				if counter > 5000
					break
				end
				outputInsta = getInsta(shop_insta_id)
				if !outputInsta
					# URLが存在しない、
					next
				else
					test << outputInsta
				end
			end
		end


	end


	def getInstaDoc(url)
		if !ApplicationController.new.isValidate(url)
			return nil
		end
		url_encoded = URI.encode(url)
  	charset = nil
  	html = open(url_encoded) do |f|
  		charset = f.charset # 文字種別を取得
  		f.read # htmlを読み込んで変数htmlに渡す
  	end

  	doc = Nokogiri::HTML.parse(html, nil, charset)
		html = nil
		return doc
	end

  # k-dbサービス終了に伴い、別の方法を検討
  # 日経銘柄：kabutan
  # dji : https://finance.yahoo.com/quote/%5EDJI/history?p=%5EDJI
  # sp5 : https://finance.yahoo.com/quote/%5EGSPC/history?p=%5EGSPC
  # gld : https://finance.yahoo.com/quote/GC=F?p=GC=F
  def getInsta(insta_id = "bull.tokyo")
	# def getInsta(insta_id = "lepshim-fashionstore-jp")
    # insta_id = "murababystore"
    shop_url = "https://www.instagram.com/#{insta_id.to_s}/"
		doc = getInstaDoc(shop_url)

		if !doc
			return nil
		end

		# p doc.css('body').css('span').css('section')
		metaInfo = doc.css('body script').first.text
		metaInfo.slice!(0, 21)
		metaInfo = metaInfo.chop
		posts = JSON.parse(metaInfo)['entry_data']['ProfilePage'][0]['graphql']['user']['edge_owner_to_timeline_media']['edges']

		follower = JSON.parse(metaInfo)['entry_data']['ProfilePage'][0]['graphql']['user']['edge_followed_by']['count']

		numMonth = 0
		numWeek = 0

		# 直近X件取得
		count = 0
		max_posts = posts.count
		most_recent_time = 0
		p "#{insta_id}, 取得できた投稿数=#{max_posts}"
		posts[0..30].each do |post|
			count = count + 1
	 		shortcode = post['node']['shortcode']

			post_link = "https://www.instagram.com/p/#{shortcode}"
			# post_link = "https://www.instagram.com/p/BlKNjYfgEVF/"
			# post_link = "https://www.instagram.com/p/BkkfzupH1Kb/"
			doc = getInstaDoc(post_link)
			metaInfo = doc.css('body script').first.text
			metaInfo.slice!(0, 21)
			metaInfo = metaInfo.chop
			# コメント投稿日時
			# time =  Time.at(JSON.parse(metaInfo)['entry_data']['PostPage'][0]['graphql']['shortcode_media']['edge_media_to_comment']['edges'][0]['node']['created_at']).in_time_zone('Tokyo')
			post_time =  Time.at(JSON.parse(metaInfo)['entry_data']['PostPage'][0]['graphql']['shortcode_media']['taken_at_timestamp']).in_time_zone('Tokyo').to_i

			if count == 1
				most_recent_time = post_time
			end

			#今週かどうか
			#if post_time > Time.current.in_time_zone('Tokyo').beginning_of_week.to_time.to_i
			#１週間以内かどうか
			if post_time >= Time.current.in_time_zone('Tokyo').to_time.to_i-7*24*3600
				# p "週内"
				numWeek = numWeek + 1
			end

			#月内かどうか
			#if post_time > Time.current.in_time_zone('Tokyo').beginning_of_month.to_time.to_i
			if post_time >= Time.current.in_time_zone('Tokyo').to_time.to_i - 31 * 24 * 3600
				# p "月内"
				numMonth = numMonth + 1
			else
				# p "月内でないので終了"
				break
			end

		end

		#insta_id, 投稿数,...
		return [insta_id, max_posts, follower, numMonth, numWeek, Time.at(most_recent_time).in_time_zone('Tokyo').strftime('%Y%m%d')]

  end

	def getShopId(numToGet)
		puts "start...#{numToGet}"

		returnArray = []
		csv_data = CSV.read("#{ENV['HOME']}/Documents/log-analyze/target_shops.csv", headers: true)
		r = Random.new(Time.new.to_time.to_i)
		csv_data.each_with_index do |data, i|
			if numToGet > 0 && returnArray.length < numToGet
				if r.rand(2) % 2 == 1
					next
				end
			elsif numToGet > 0 && returnArray.length >= numToGet
				p "#{numToGet}, #{returnArray.length}"
				break
			end
	    line_msg = "user_id:#{data["user_id"]}, shop_id:#{data["shop_id"]}\n"
	    puts line_msg
			returnArray.push(data["shop_id"])
  	end


		puts "complete! See intro.txt."
		return returnArray;

	end
end
