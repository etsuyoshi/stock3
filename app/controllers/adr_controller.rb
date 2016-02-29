require 'yahoo-finance'

# nikkeiから値上がり率ランキング取得
require 'open-uri'# URLアクセス
require 'kconv'    # 文字コード変換
require 'nokogiri' # スクレイピング
require 'time'
require 'date'

class AdrController < ApplicationController
  def index

    # adr一覧の取得の銘柄コード、名称、ticker取得する
    arrADRs = get_code_array
    # 取得したadrデータを（まだ格納していなかったら）DBに保存する
    insert_adr(arrADRs)

    render :text => "Done!"
  end

  def insert_adr(arrADRs)
    p "DBに保存.."
    # p "all = #{arrADRs}"
    p "count = #{arrADRs.length}"
    arrADRs.each do |hashAdr|
      code = hashAdr['code']
      name = hashAdr['name']
      ticker = hashAdr['ticker']

      p code
      p name
      p ticker

      # すでにモデルに格納されていないものだけ保存する
      if !(Adr.find_by(ticker: ticker, tcode: code))

        # adr-DBに保存
        adrInfo = Adr.new(
          :tcode => code,
          :name => name,
          :ticker => ticker
        )

        p "insert->#{adrInfo}"
        adrInfo.save
      else
        p "すでにそのcode及びtickerは存在します"
      end
    end

  end

  def get_code_array
    p "adr一覧取得中..."
    # nokogiriでスクレイピング
    arrAdr = []

    url = "http://www.traders.co.jp/foreign_stocks/adr.asp"

    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end

    # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    # p "adr start"
    doc.xpath('//table[@bordercolor="#AAB5BB"]/tr').each do |content|

      code = content.xpath('td[1]/a').inner_text
      # p "code = #{code}"
      if !(code.nil? || code == "")

        # 特にnameは使わない？
        name = content.xpath('td[2]').inner_text
        hash = Hash.new
        hash['code'] = code.to_i
        hash['name'] = name.to_s.sub(/\s*/,"")#space除外
        hash['ticker'] = get_ticker(code.to_i)
        arrAdr.push(hash)



        # title
        # title = content.css('h3').css('a').inner_text
        # break
      else
        p "銘柄コードがありません（恐らくheader）"
      end

    end
    p "adr一覧#{arrAdr.length}個の取得完了(ticker以外)"

    return arrAdr

  end


  def get_ticker(code)
    ticker = nil

    # nikkei225.jpからtickerをスクレイピング
    # ex. http://adr-stock.com/japan/adr.php?a=7203
    url = "http://adr-stock.com/japan/adr.php?a=#{code}"
    # p "url = #{url}"
    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end

    # metaにあるtickerコード(toyota7203→TM)を取得する
    # print doc.xpath('/html/head/meta[@name="keywords"]/@content').to_s + "\t"



    # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')

    doc.xpath("//meta[@name='KEYWORDS']/@content").each do |attr|

      # puts attr.value
      arrKeywords = attr.value.split(',')
      # p arrKeywords
      # p arrKeywords[0]#name
      # p arrKeywords[1]#code
      # p arrKeywords[2]#ticker
      ticker = arrKeywords[2]

    end



    return ticker
  end
end
