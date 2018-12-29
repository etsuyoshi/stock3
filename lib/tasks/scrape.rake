require 'yahoo-finance'

require "csv"
#scrape255:
require 'nokogiri'
require 'open-uri'


namespace :db do
	desc "Fill database with sample data"
	#特定商品の画像を抽出する(aliexpress)
	task aliexpress: :environment do
		target_url = "https://ja.aliexpress.com/item/2018/32893580190.html?spm=a2g0s.8937460.0.0.3de02e0eUwnDLU"

		# <img alt="9047764137_2106944726" src="https://ae01.alicdn.com/kf/HTB1.s5FksIrBKNjSZK9q6ygoVXa4.jpg">
		html = ApplicationController.new.getDocFromHtmlWithJS(URI.encode(target_url))
		# p html

		# p style box-sizing

		#p html.css("img").first.attribute('src').value
#		p html.xpath('//div[@class="origin-part"]')
		p html.css("h1")
		#p html.css("p")
		#p html.xpath('//p[@style="box-sizing: content-box"]')
		p html.css('//img[@alt="HTB1dnqYXMKTBuNkSne1q6yJoXXaq"]')
		# <img alt="HTB1dnqYXMKTBuNkSne1q6yJoXXaq" height="420" src="https://ae01.alicdn.com/kf/HTB1dnqYXMKTBuNkSne1q6yJoXXaq.jpg" style="box-sizing: content-box;margin: 0.0px;padding: 0.0px;border: 0.0px;font-style: inherit;font-weight: inherit;font-size: 0.0px;line-height: inherit;vertical-align: middle;color: transparent;" width="655" data-spm-anchor-id="a2g11.10010108.1000023.i5.5d6b6a7cjEuEMR">

		html.xpath('//p[@style="box-sizing: content-box;"]').css("p").each do |ppp|
			ppp.css("img").each do |img|
				p img.attribute('src').value
			end
		end
	end
  # 特定の店舗の投稿頻度を算出する
	task insta: :environment do

		arrShops = getShopId(0)

		counter = 0
		output_filename = 'instafollower7.csv'

		continue_flag = FALSE

		# 初回実行時のみ列名入力(継続実行時には実施しない)
		if !continue_flag
			CSV.open(output_filename,'w') do |test|
				test << ["instagram_id", "max_posts", "follower", "numMonth", "numWeek","numMonthTag","numWeekTag", "recent_post_date"]
			end
		end

		#test
		getInsta("baseec")


		CSV.open(output_filename,'a') do |test|
			for shop_insta_id in arrShops

				if shop_insta_id.nil? || shop_insta_id == "" || shop_insta_id == "NA"
					next
				end

				# 途中からやる場合
				if continue_flag #
					if shop_insta_id == "honnoh_genta" #最初に実施する店舗ID
						continue_flag = FALSE
						next
					else
						next
					end
				end
				counter = counter  + 1
				if counter > 5000
					break
				end
				#insta_idからフォロワー数やポスト数など取得
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

	# 自己紹介文にリンクがあれば良い
	task insta_intro_link: :environment do
		p "insta intro"

		# file_link = "#{ENV['HOME']}/Documents/log-analyze/instagram_list.csv"
		file_link = "#{ENV['HOME']}/Documents/log-analyze/open_shops.csv"
		#csv_data = CSV.read("#{ENV['HOME']}/Documents/log-analyze/target_shops.csv", headers: true)
		insta_ids = CSV.read(file_link, headers: true)
		row = 1
		output_filename="insta_link2.csv"
		# target_id = "1988.design"#instagram_listで最初に読み込むinsta_id
		# is_target = FALSE
		is_target = TRUE
		CSV.open(output_filename,'a') do |test|
			for row_insta_id in insta_ids
				insta_id = row_insta_id.to_s.gsub(/\n/, "").to_s
				if insta_id == 'lily_accessory'#lily_accessory
					is_target = TRUE
				end
				if !is_target
					p "next : #{insta_id}"
					next
				end

				# insta_id = insta_ids[0].to_s.gsub(/\n/, "").to_s
				shop_url = "https://www.instagram.com/#{insta_id.to_s}/"
				doc = ApplicationController.new.getDocFromHtmlWithJS(URI.encode(shop_url))
				if !doc
					return nil
				end
				if doc.css('.yLUwa').first.nil?
					p "#{insta_id} is not exist"
					next;
				else
					# p doc.css('.yLUwa')
				end
				shop_link = doc.css('.yLUwa').first.text
				p "#{row}, insta_ids=#{insta_id}, link=#{shop_link}"

				test << [insta_id, shop_link]
				row = row + 1
			end
		end

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
		numMonthHashTag = 0
		numWeekHashTag = 0

		hash_tag = "#baseec"

		# 直近X件取得
		count = 0
		max_posts = posts.count
		most_recent_time = 0
		#p "#{insta_id}, 取得できた投稿数=#{max_posts}"
		posts[0..30].each do |post|
			count = count + 1
	 		shortcode = post['node']['shortcode']

			#test
			# if shortcode != 'BnVXKCNH96R'
			# 	next
			# end

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

			if JSON.parse(metaInfo)['entry_data']['PostPage'][0]["graphql"]["shortcode_media"]["edge_media_to_caption"]["edges"].count == 0
				p "#{insta_id} : edgesにデータが格納されていません"
				next
			elsif JSON.parse(metaInfo)['entry_data']['PostPage'][0]["graphql"]["shortcode_media"]["edge_media_to_caption"]["edges"][0]["node"]["text"].nil?
				p "#{insta_id} : 投稿データがありません"
				next
			end

			post_contents = JSON.parse(metaInfo)['entry_data']['PostPage'][0]["graphql"]["shortcode_media"]["edge_media_to_caption"]["edges"][0]["node"]["text"].to_s

			post_comment = ""
			if JSON.parse(metaInfo)['entry_data']['PostPage'][0]["graphql"]["shortcode_media"]["edge_media_to_comment"]["edges"].count > 0
				if !JSON.parse(metaInfo)['entry_data']['PostPage'][0]["graphql"]["shortcode_media"]["edge_media_to_comment"]["edges"][0]["node"]["text"].nil?
					post_comment = JSON.parse(metaInfo)['entry_data']['PostPage'][0]["graphql"]["shortcode_media"]["edge_media_to_comment"]["edges"][0]["node"]["text"]
					post_contents = post_contents.to_s + " " + post_comment.to_s
				end
			end
			# p "contents = #{post_contents}"



			if count == 1
				most_recent_time = post_time
			end

			#今週かどうか
			#if post_time > Time.current.in_time_zone('Tokyo').beginning_of_week.to_time.to_i
			#１週間以内かどうか
			if post_time >= Time.current.in_time_zone('Tokyo').to_time.to_i-7*24*3600
				# p "週内"
				numWeek = numWeek + 1

				# p "hashtag search"
				if post_contents.include?(hash_tag)
					numWeekHashTag = numWeekHashTag + 1
				end
			end

			#月内かどうか
			#if post_time > Time.current.in_time_zone('Tokyo').beginning_of_month.to_time.to_i
			if post_time >= Time.current.in_time_zone('Tokyo').to_time.to_i - 31 * 24 * 3600
				# p "月内"
				numMonth = numMonth + 1

				if post_contents.include?(hash_tag)
					numMonthHashTag = numMonthHashTag + 1
				end

			else
				# p "月内でないので終了"
				break
			end
		end
		p "insta_id=#{insta_id}, max_posts=#{max_posts}, follower=#{follower}, numMonth=#{numMonth}, numWeek=#{numWeek}, hashWeek=#{numWeekHashTag}, hashMonth=#{numMonthHashTag}, time = #{Time.at(most_recent_time).in_time_zone('Tokyo').strftime('%Y%m%d')}"

		#insta_id, 投稿数,...
		return [insta_id, max_posts, follower, numMonth, numWeek,numMonthHashTag,numWeekHashTag, Time.at(most_recent_time).in_time_zone('Tokyo').strftime('%Y%m%d')]

  end

	def getShopId(numToGet)
		puts "start...#{numToGet}"

		returnArray = []
		csv_data = CSV.read("#{ENV['HOME']}/Documents/log-analyze/target_shops.csv", headers: true)

		# shop_rfms = dbGetQuery(dbc, paste(
		#   "select user_id, lower(shop_id) shop_id, r_score, f_score, m_score, date_format(created, '%Y-%m-%d') dates from base_batch.shop_rfms ",
		#   "where date_format(created, '%Y%m%d') = '20180705' order by recency desc", sep=""))
		# # "where date_format(created, '%Y%m%d') = '20180601' order by recency desc", sep=""))
		# #"where date_format(created, '%Y%m%d') = '20180427' order by recency desc", sep=""))
		#
		# target_r = 3
		# target_f = 2
		# target_shops = shop_rfms[shop_rfms$r_score==target_r & shop_rfms$f_score==target_f,]
		# insta_ids = dbGetQuery(dbc, paste(
		#   "select lower(shop_id) shop_id, instagram_id from users where id in (",
		#   paste(target_shops$user_id, collapse=","), ")", sep=""))
		# head(insta_ids[insta_ids$instagram_id=="",])
		# head(insta_ids[is.na(insta_ids$instagram_id),])
		#
		# target_shops = merge(
		#   target_shops,
		#   insta_ids, by="shop_id", all.x=TRUE)
		# head(target_shops)
		#
		# write.csv(target_shops, "target_shops.csv")
		# read.csv("target_shops.csv")


		r = Random.new(Time.new.to_time.to_i)
		csv_data.each_with_index do |data, i|
			#numToGetになるまでreturnArrayにinstagram_idを追加する（numToGet=0の場合は全部追加する）
			if numToGet > 0 && returnArray.length < numToGet
				if r.rand(2) % 2 == 1
					next
				end
			elsif numToGet > 0 && returnArray.length >= numToGet
				p "#{numToGet}, #{returnArray.length}"
				break
			end
			if data["instagram_id"] && data["instagram_id"] != ""
				line_msg = "user_id:#{data["user_id"]}, shop_id:#{data["shop_id"]}, insta_id:#{data["instagram_id"]}\n"
				puts line_msg
				returnArray.push(data["instagram_id"])
			end
  	end


		puts "#{returnArray.count}complete! See intro.txt."
		return returnArray;

	end
end
