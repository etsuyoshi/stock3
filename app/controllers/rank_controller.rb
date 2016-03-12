require 'kconv'
class RankController < ApplicationController
  def index


    Rank.destroy_all
    scrape_rank_hash('priceup')
    scrape_rank_hash('pricedown')
  end

  def scrape_rank_hash(priceUpOrDown)
    # 値上がり率ランキング
    # url = "http://www.nikkei.com/markets/ranking/stock/priceup.aspx"
    p "scrape rank hash"
    if priceUpOrDown == 'priceup'
      p "値上がり上位"
    elsif priceUpOrDown == 'pricedown'
        p "値下がり上位"
    else
      return nil;
    end
    url = "http://www.nikkei.com/markets/ranking/stock/" + priceUpOrDown.to_s + ".aspx"
    html = open(url) do |f|
      f.read # htmlを読み込んで変数htmlに渡す
    end

    # htmlをパース(解析)してオブジェクトを生成(utf-8に変換）
    doc = Nokogiri::HTML.parse(html.toutf8, nil, 'utf-8')
    rank_all = Hash.new
    doc.xpath('//table[@class="tblModel-1"]').xpath('tr').each do |content|
      # p content
      # if content.xpath('tr').xpath('td').inner_text.to_i == 1
      #   p content.xpath('tr').xpath('td').xpath('a').inner_text
      # else
      #   p content.xpath('tr').xpath('td').xpath('a').inner_text
      # end

      rank_info = Hash.new
      rank = content.xpath('td[1]').inner_text.to_i


      if rank.kind_of?(Integer)
        rank2 = content.xpath('td[2]/a').inner_text #<- \r\tなどが含まれているので排除@rank_name
        stock_code = rank2[rank2.length-4,4]

        if stock_code
          rank_info["rank"] = rank
          rank_info["stock_code"] = stock_code
          rank_info["name"] = content.xpath('td[3]/a').attribute("title").value
          rank_info["return"] = content.xpath('td[5]').inner_text
          rank_info["price"] = content.xpath('td[6]').inner_text
          vsYesterday = content.xpath('td[7]').inner_text
          rank_info["vsYesterday"] = vsYesterday.match(/.*\r/)[0].sub(/\r/,"")
          # p rank_info

          rank_all[rank] = rank_info
        end

      end
    end

    if priceUpOrDown.downcase == 'priceup'
      p "upppppppppppppppppp"
      preserve_rank_array(rank_all, "up")
    elsif priceUpOrDown.downcase == 'pricedown'
      p "downnnnnnnnnnnnn"
      preserve_rank_array(rank_all, "down")
    else
      p "指定エラー"
    end

    # return rank_all
  end

  def preserve_rank_array(rank_array, upOrDown)
    p "preserve_rank_array : #{rank_array},,,,#{upOrDown}"


    rank_array.each do |rank_item|
      rank = rank_item[1]["rank"]
      stock_code = rank_item[1]["stock_code"]
      name = rank_item[1]["name"]
      ret =  rank_item[1]["return"]
      diff = rank_item[1]["vsYesterday"]
      price = rank_item[1]["price"]

      # market:string
      # rank:integer
      # name:string
      # sort:string
      # changerate:float
      # changeprice:integer
      # nowprice:float
      p "rank = #{rank}"
      p "name = #{name}"
      p "sort = #{upOrDown}"
      p "changerate = #{ret}"
      p "changeprice = #{diff}"
      p "nowprice = #{price}"

      rankModel = Rank.new(
        :market          => "^N225",
        :stock_code      => stock_code,
        :rank            => rank,
        :name            => name,
        :sort            => upOrDown,
        :vsYesterday     => diff,
        :return          => ret,
        # :changerate      => ret,
        # :changeprice     => diff,

        :nowprice        => price
      )
      rankModel.save
    end
  end
end
