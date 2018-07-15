require 'yahoo-finance'

#scrape255:
require 'nokogiri'
require 'open-uri'


namespace :db do
	desc "Fill database with sample data"
  # 特定の店舗の投稿頻度を算出する
	task insta: :environment do
		getInsta()
	end

  # k-dbサービス終了に伴い、別の方法を検討
  # 日経銘柄：kabutan
  # dji : https://finance.yahoo.com/quote/%5EDJI/history?p=%5EDJI
  # sp5 : https://finance.yahoo.com/quote/%5EGSPC/history?p=%5EGSPC
  # gld : https://finance.yahoo.com/quote/GC=F?p=GC=F
  def getInsta()
    insta_id = "murababystore"
    shop_url = "https://www.instagram.com/#{insta_id.to_s}/"

  	url_encoded = URI.encode(shop_url)
  	charset = nil


  	# ひたすら業務フローマニュアルみたいな資料整理してくれるのはありがたいけど、マニュアル人間なのかなと思っ
  	html = open(url_encoded) do |f|
  		charset = f.charset # 文字種別を取得
  		f.read # htmlを読み込んで変数htmlに渡す
  	end
  	doc = Nokogiri::HTML.parse(html, nil, charset)

  	# p doc
    p doc.xpath('//div[@class="v9tJq"]')
    # xpath('//div[@class="thumb-block "]')


  end

end
