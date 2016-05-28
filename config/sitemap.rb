# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://www.japanchart.com"
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/' # 保存先（この場合 /public/sitemaps/以下になる）


# http://shirusu-ni-tarazu.hatenablog.jp/entry/2012/10/09/013117
SitemapGenerator::Sitemap.create do
  current_time = Time.now

  # トップ画面
  add root_path, lastmod: current_time, changefreq: 'daily', priority: 1.0

  # 静的ページ
  static_page_options = { lastmod: current_time, changefreq: 'monthly', priority: 0.5 }
  # 動的ページ
  dynamic_page_options = { changefreq: 'weekly', priority: 0.75 }

  # add(sign_in_path, static_page_options)
  # add(sign_up_path, static_page_options)
  # add(policy_path, static_page_options)
  # add(guide_path, static_page_options)
  # add(faq_path, static_page_options)
  add('/study_pages/elementary/why_you_invest', dynamic_page_options)
  add('/study_pages/elementary/aboutStock', dynamic_page_options)
  add('/study_pages/elementary/stockMechanism', dynamic_page_options)
  add('/study_pages/elementary/tradeMechanism', dynamic_page_options)
  add('/study_pages/elementary/marketDetail', dynamic_page_options)
  add('/study_pages/elementary/ipo', dynamic_page_options)
  add('/study_pages/elementary/otherManagement', dynamic_page_options)
  add('/study_pages/elementary/merit', dynamic_page_options)
  add('/study_pages/elementary/demerit', dynamic_page_options)


  # # Hogeモデル詳細画面
  # Hoge.only_opened.find_each do | hoge |
  #   add(hoge_path(hoge.id), dynamic_page_options.merge(lastmod: hoge.updated_at))
  # end
  #
  # # Fuga詳細画面
  # Fuga.find_each do | fuga |
  #   add(fuga_path(hall.id), dynamic_page_options.merge(lastmod: hall.updated_at))
  # end





  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end
end
