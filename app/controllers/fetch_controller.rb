class FetchController < ApplicationController
  # http://kazsix.hatenablog.com/entry/2014/04/20/222749
  require 'open-uri'# URLアクセス
  require 'kconv'    # 文字コード変換
  require 'nokogiri' # スクレイピング

  def index

    # スクレイピング先のURL
    # url = 'http://example.com/news/index.html'
    url = 'http://jp.reuters.com/news/archive/topNews?view=page&page=1&pageSize=100'

    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end

    # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

    latest_id = get_latest_id()

    # 新着情報ごとにループ
    # doc.css('#contents a').each do |content|
    doc.css('.topStory2').each do |content|
      # <h3 class="topStory2"><a href="/article/imf-lagarde-idJPKCN0VK1PC"  >ＩＭＦ、次期専務理事に現職のラガルド氏指名</a></h3>
      # <p>［ワシントン　１１日　ロイター］ - 国際通貨基金（ＩＭＦ）は１１日、声明を発表し、次期専務理事に現職のラガルド氏が指名されたと明らかにした。</p>


      # <a name="news123"> の123の部分を取得
      feed_id          = content["name"].sub(/news/, "").to_i

      if latest_id < feed_id
        # DBに未登録の情報があったらDBに保存
        title            = content.css('h1').to_html
        description      = content.to_html
        link             = url + '#news' + feed_id.to_s
        insert_feed(feed_id, title, description, link)
      end
    end

    render :text => "Done!"
  end

  private
  # feedsテーブルに1件INSERT
  def insert_feed(feed_id, title, description, link)
    feed = Feed.new(
      :feed_id          => feed_id,
      :title            => title,
      :description      => description,
      :link             => link
    )
    feed.save
  end

  # DBに保存されている最新のfeed_idを取得
  def get_latest_id()
    row = Feed.order("feed_id desc").first
    if row.nil?
      return 0
    end
    latest_id = row["feed_id"].to_i
    return latest_id
  end
end
