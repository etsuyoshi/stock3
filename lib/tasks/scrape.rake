require 'yahoo-finance'

require "csv"
#scrape255:
require 'nokogiri'
require 'open-uri'


namespace :db do
	desc "Fill database with sample data"
  # 特定の店舗の投稿頻度を算出する
	task insta: :environment do

		arrShops = getShopId()

		counter = 0
		# 初回実行時のみ列名入力
		# CSV.open('instafollower.csv','w') do |test|
		# 	test << ["insta_id", "max_posts", "follower", "numMonth", "numWeek", "recent_post_date"]
		# end
		CSV.open('instafollower.csv','a') do |test|
			for shop_insta_id in arrShops
				counter = counter  + 1
				if counter > 1000
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
		if !isValidate(url)
			return nil
		end
		url_encoded = URI.encode(url)
  	charset = nil
  	html = open(url_encoded) do |f|
  		charset = f.charset # 文字種別を取得
  		f.read # htmlを読み込んで変数htmlに渡す
  	end
  	doc = Nokogiri::HTML.parse(html, nil, charset)
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
			if post_time > Time.current.in_time_zone('Tokyo').beginning_of_week.to_time.to_i
				# p "週内"
				numWeek = numWeek + 1
			end

			#月内かどうか
			#if post_time > Date.new(2018, 7, 1).in_time_zone('Tokyo').to_time.to_i
			if post_time > Time.current.in_time_zone('Tokyo').beginning_of_month.to_time.to_i
				# p "月内"
				numMonth = numMonth + 1
			else
				# p "月内でないので終了"
				break
			end

		end

		return [insta_id, max_posts, follower, numMonth, numWeek, Time.at(most_recent_time).in_time_zone('Tokyo').strftime('%Y%m%d')]





		# 1週間の投稿回数と今月の投稿回数


		# p JSON.parse(metaInfo)['entry_data']['ProfilePage'][0]['graphql']['user']['edge_owner_to_timeline_media']['edges']

		# post_link = "https://www.instagram.com/p/#{shortcode}"
		# doc = getInstaDoc(post_link)
		# metaInfo = doc.css('body script').first.text
		# metaInfo.slice!(0, 21)
		# metaInfo = metaInfo.chop
		# time =  Time.at(JSON.parse(metaInfo)['entry_data']['PostPage'][0]['graphql']['shortcode_media']['edge_media_to_comment']['edges'][0]['node']['created_at']).in_time_zone('Tokyo')


		# {"PostPage"=>[
		# 	{"graphql"=>{
		# 		"shortcode_media"=>{
		# 			"__typename"=>"GraphImage",
		# 			"id"=>"1825795371421152809",
		# 			"shortcode"=>"BlWhzeCHDYp",
		# 			"dimensions"=>{
		# 				"height"=>1080,
		# 				"width"=>1080},
		# 			"gating_info"=>nil,
		# 			"media_preview"=>"ACoq3BMi4QcDtjoPbjYANjg54GM/WoaUHByOKok20yQMenWn7B71Ch+QH2p1SI//Z",
		# 			"display_url"=>"https://scont86405888_n.jpg",
		# 			"config_width"=>640,
		# 			"config_height"=>640},
		# 		{
		# 			"src"=>"https://sconten83786405888_n.jpg",
		# 			"config_width"=>750, "config_height"=>750},
		# 		{
		# 			"src"=>"https://scontent-nr405888_n.jpg",
		# 			"config_width"=>1080, "config_height"=>1080
		# 		}],
		# "is_video"=>false,
		# "should_log_client_event"=>false,
		# "tracking_token"=>"eyJ2ZXJzaW9uIjNDIxMTUyODA5ZSI6IiJ9",
		# "edge_media_to_tagged_user"=>{"edges"=>[]},
		# "edge_media_to_caption"=>{
		# 	"edges"=>[{"node"=>{"text"=>"大変お待たせいたしました。ピザTシャツ完成🍕初めてのプリンフza"}}]
		# },
		# "caption_is_edited"=>true,
		# "edge_media_to_comment"=>{
		# 	"count"=>2,
		# 	"page_info"=>{
		# 		"has_next_page"=>false,
		# 		"end_cursor"=>nil},
		# 	"edges"=>[{
		# 		"node"=>{
		# 			"id"=>"17955967810069561",
		# 			"text"=>"楽しみに待\u{1F923}",
		# 			"created_at"=>1531873080,




		# {
		# 	"logging_page_id"=>"profilePage_5760079548",
		# 	"show_suggested_profiles"=>false,
		# 	"graphql"=>{
		# 		"user"=>{
		# 			 "biography"=>"フレンチブルドッグのウエア・レザーアイテムの店「Bull.」We are open ! \nOur product are made in 🇯🇵TOKYO .\n⬇︎Bull. Online shop⬇︎",
		# 			 "blocked_by_viewer"=>false,
		# 			 "country_block"=>false,
		# 			 "external_url"=>"https://www.bull.tokyo/",
		# 			 "external_url_linkshimmed"=>"https://l.instagram.com/?u=https%3A%2F%2Fwww.bull.tokyo%2F&e=ATMItv4fhSvY3vSdvnyrwYIs21l3lI5qyCrZ9uMStGsU_UX1m87oYDGSCqL9gNLmzzCx5Uvx",
		# 			 "edge_followed_by"=>{"count"=>1058},
		# 			 "followed_by_viewer"=>false,
		# 			 "edge_follow"=>{"count"=>0},
		# 			 "follows_viewer"=>false,
		# 			 "full_name"=>"bull.tokyo",
		# 			 "has_channel"=>false,
		# 			 "has_blocked_viewer"=>false,
		# 			 "highlight_reel_count"=>0,
		# 			 "has_requested_viewer"=>false,
		# 			 "id"=>"5760079548",
		# 			 "is_private"=>false,
		# 			 "is_verified"=>false,
		# 			 "mutual_followers"=>nil,
		# 			 "profile_pic_url"=>"https://scontent-nrt1-1.cdninstagram.com/vp/ca65b7e2992f3242f32cca47ef0fe012/5BCFED30/t51.2885-19/s150x150/19228778_451290341902814_3929338826035560448_a.jpg", "profile_pic_url_hd"=>"https://scontent-nrt1-1.cdninstagram.com/vp/ca65b7e2992f3242f32cca47ef0fe012/5BCFED30/t51.2885-19/s150x150/19228778_451290341902814_3929338826035560448_a.jpg",
		# 			 "requested_by_viewer"=>false,
		# 			 "username"=>"bull.tokyo",
		# 			 "connected_fb_page"=>nil,
		# 			 "edge_felix_combined_post_uploads"=>{
		# 				 "count"=>0,
		# 				 "page_info"=>{
		# 					 "has_next_page"=>false,
		# 					 "end_cursor"=>nil},
		# 				 "edges"=>[]},
		# 			 "edge_felix_combined_draft_uploads"=>{
		# 				 "count"=>0,
		# 				 "page_info"=>{
		# 					 "has_next_page"=>false,
		# 					 "end_cursor"=>nil},
		# 				 "edges"=>[]},
		# 			 "edge_felix_video_timeline"=>{
		# 				 "count"=>0,
		# 				 "page_info"=>{
		# 					 "has_next_page"=>false,
		# 					 "end_cursor"=>nil},
		# 				 "edges"=>[]},
		# 			 "edge_felix_drafts"=>{
		# 				 "count"=>0,
		# 				 "page_info"=>{
		# 					 "has_next_page"=>false,
		# 					 "end_cursor"=>nil},
		# 				 "edges"=>[]},
		# 			 "edge_felix_pending_post_uploads"=>{
		# 				 "count"=>0,
		# 				 "page_info"=>{"has_next_page"=>false, "end_cursor"=>nil},
		# 				 "edges"=>[]},
		# 			 "edge_felix_pending_draft_uploads"=>{
		# 				 "count"=>0,
		# 				 "page_info"=>{"has_next_page"=>false, "end_cursor"=>nil},
		# 				 "edges"=>[]},
		# 			 "edge_owner_to_timeline_media"=>{
		# 				 "count"=>59,
		# 				 "page_info"=>{
		# 					 "has_next_page"=>true,
		# 					 "end_cursor"=>"AQDfrmqpi1vIWelfTls6y4oSszbnWwxJNj4szjM8tXXSLWBWoZM1JlmdMFDiYjmVKMNb1ix9mxGqxIP19k2GHrJ8DWEz7cmr1jWfiiGkyn7Dcg"},
		# 				 "edges"=>[{
		# 					 "node"=>{
		# 						 "__typename"=>"GraphImage",
		# 						 "id"=>"1825795371421152809",
		# 						 "edge_media_to_caption"=>{
		# 							 "edges"=>[
		# 								 {"node"=>{"text"=>"大変お待たせいたしました。ピザTシャツ完成ウ #プリントtシャツ #ピザ #pizza"}}]
		# 						 },
		# 						 "shortcode"=>"BlWhzeCHDYp",





  	# p doc
    # p doc.xpath('//body[@class]')
		# p doc.css('body').css('span').css('section')
		# p doc.css('#react-root > section > main > div > div._2z6nI')
		# p doc.css('#react-root').css('section')

		# p doc.xpath('//body[@class]').count
		# p doc.xpath('//*[@class="v9tJq"]')
    # xpath('//div[@class="thumb-block "]')
		# //*[@id="react-root"]/section/main/div


  end

	def getShopId()
		# shop_rfms = dbGetQuery(dbc, paste(
		#   "select user_id, lower(shop_id) shop_id, r_score, f_score, m_score, date_format(created, '%Y-%m-%d') dates from base_batch.shop_rfms ",
		#   "where date_format(created, '%Y%m%d') = CURDATE()-7 order by recency desc", sep=""))
		# target_r = 3
		# target_f = 2
		# target_shops = shop_rfms[shop_rfms$r_score==target_r & shop_rfms$f_score==target_f,]
		#
		# #insta_id
		# a = dbGetQuery(dbc, paste("select instagram_id from base.users where id in (", paste(target_shops$user_id, collapse=","), ") and instagram_id is not null and instagram_id != ''", sep=""))
		# paste("'", paste(a$instagram_id, collapse="','"), "'", sep="")

		arrShops = [
			# 'atelier_kaname','miyukyy','nufic_designwork','kirisaki29','noirfr','46n_yoron','gallery_fuuro','rena_japan_made_shop',
			# 'ANAM_Leather','_lalaclover_','hirocore.d','ohanabatake66','hejsanbutiken','yokoichi777','brblss','brokecitygold',
			# 'haliaalohailio','copporate_shop','jackey_joe','sunkingleather','ika_ashi_ballet','PEACEFULSMILEKOBE','Farmhousecafe',
			# 'knekm','teruko_notebooks','grove5777','atoron_art','TOKYOWOODPICK','fuyunokoooo','kojimano_','floraflora13',
			# 'yanomekouziya','cygnetchr','mid_jum','aloalo_hat','beauty_merrows','junya1129','byplayer','qestwear','gabrielatierra',
			# 'kaori.lecorail','coookacoooka','shinobu.hashimoto','atlaspedal','Aumbak','gnkosaiband',
			# 'NERD_SKATES','u_uecology','tomokix115','hydrangeamacrophyll','gespa.interior','8yo','madein2f',
			# 'puzzle.jwl','___mizueyone','plomme_888','nakochi_iya','miraqnews','sugarco.ltd','warunekokun','tao_no_ie26','inoe_craft','printiloyuka','garyu.bz',
			# 'saoriifujii_fem','ava_jp','emera','yumimpo','aki_phraula','industrialsuite','LamilyBridal','no_4321',
			# 'fullswing_furniture','aki_rose0921','yumyumyumin','RIYUNNU','mihr.a','kumaya1997','brahmaworks.hac',
			# 'hidekofukushima','medaiya','printersflowers','ishiikan','citycitycitycity','anandamidelaboratorium',
			# 'cachette_jewelry','kyaraaisan','luceaki','cosecose','toystar2016','10rc0','abemamoru_shoten','sumomo_koubou',
			# 'AISUWEDDING','twice_pea.717','spiceofgreen','mielcandle','mUIkxmIKu','roumanya','hakuba_renka','maho.ms',
			# 'nodabuichi7000','mikimikimikky1016','kuruemh','rs_nature','thecoffeetimewest','himi5','thedollsjapan','namacolove',
			# 'mniftokyo','choniichonii','solanita2014','s_o_s_tokyo','PENSEE1207','spicaspoon','ACOT_CAKE','kitchenmarch',
			# 'nibi_craft','k_kokochi','nail_cure','chihiro_lore_nail','takahisa610','jazcrafts','hisashikanazawa','ghostinmpc',
			# 'monaria_mona','pheacadh623','arainiko','nonoyaworld','pieni_puu','veriteco','jikannomorigallery','chimaskistudio',
			# 'discographydesign','moierg','jun_okazawa','loyaltothegrave','one_noble_novel','atelierkeika','haruka_nara',
			# 'sakewine.com_marumoto','k_coffee2014','aneshkaaccessory','mermaid_beach_','yuko_merci.deco','mayonaka_sample',
			# 'kqurious','kims.koreandiner','afro_inst','katochisa32','module_design','zacchino_official','yun_322','shopluana',
			# 'mt__book','hatsume3','ayako32flavors','corsicacoffee','sowmen','teda_nada','liberty_shop5970','decor_unitedhomes',
			# 'chisatooyama801','dyjfh387','yamamotodadada','kawanisimeisankeikenootani','playatuner','2222take','Pishka.Jiyugaoka',
			# 'be.ni.o','caliner_pic','rinko_kudo','shamjas_official','udatakuo','noreri_shop','juzusuke','naranja_accessory','h_birthdaytoyou','takuizawa','cream_bandh','ja_int','k.lovethailand','freedom_spectacles','oqoymomo','paddle_official','343s_webshop','anutrof.blanchet','se_lection','enjoy_crop','eclat.hamamatsu','tmhy.2525','jango_oac','imamurayumi_yumiimamura','letoffe.niigata','hisashi_saito_pulselize','immypenny','crude.yamada','_aokimiwa_','otherlounge','tcs_international','urushi610','solfeggiotones','3grrr','sea.ibiza','hakudou','amalia_studio','stella.__8','yuzen_jewelry.suiu','ksmin2','chiffonglass','blueverystudio','mayasworks','yagitee_info','gentletreesapporo','isao.1226','kotoribeach','rbfm_plus','yoshiblessed','day_traction','R.Mstyle','bambi_garden','reads_nao','lapunieni','cento_f','shop_hyacca','doodle45','n_a_o314','nekokick8787','crackbeerpunk','nonfiction_rubia','CALBERRY88','chkuwan','loners1541','atease_style','ericalien','equalia0124','plus_coffee.jp','nouveau_tresor','nkhc','toolconsulting','bebe_couture','LAU.MADE.IN.JAPAN','energyfrog','pre_hanaco','blanc_kee','naotooga','madoka_amazingme','_STORY.M_','junichiito_official','otome_youbi_','tundraeskimo','FNPtyo','souei.jewel','pariss1717','LanikaiJewelryCo','fairysouls','shiica_','okinawa_0120_akinawan','nonoko0629','mao.uoxou','belo_ism','y_ryuta_k_','areren2013','rune214','rayamic','yellow_gipsy420','baby_shower_and_sons','artique0','eclectic_sato','rocos','kiini_tokyo','k_by_c','_soasoah_','machico729','amayadori2005','lukacca','bella_legame','murakushu','monopro7881','sevenchakrajewelry','milimilijapan','ekmahalo_golf_jewelry','toffymori','chloemnh','mimiperuru','ayushke_toltec','merbytokyo','cometcometcomet','HIRO_PRUEBA','mana_ohana','tinylily','jewelearth.ishigaki','panchiiyamauchi','zunko0215','xscherzox','daisy.silver.accessory','setogiants','mayu.mycraft','jojoyarn_bymyjojo','flys_unidentified','aoimoment','mumu5357','vadaaantiques','kaito_boat','kohiro_n14','76nanaroku','cailin.agus.grandma','tegami.tokei','fujiocurry','papa_soze','lonesomegoodluck','matrice.aya','aki.s623','atelier_minuit','yood1122','tomomi_masuda5525','uponhandmade','riko_0719','hanataku_1102','lander','musubiyakyoto','cye_biquette','diopiccolo89','beadsyakuroneko','fasso_on','amigirl_knits','nishiyamamiya','kiyoe175','thecirculationoflove','the_rendezvous_mami','kihadasalon','maysea0606','crewtag.abc','hayacocco','akagumichan','kasyoan','riz_a.m','maison_masumi','earial.ambellir.y','calpia.accessory','leather.base','gebccraft','zaptastick','petit__lys','ultra_mint_company','kusabananokawori','myriad.official','threelittlebirds.acce','nooncall.mono','salonyururi','luana.nail.relaxation','redprofile_info','__bosque.__','akinaruji','hum_leather','ohsumitaro','623duck','microm81','_mamalovesyou_','seamakana','chidapan.hakone','shoartshop','ekka_2015','mature_ndesign','misha_antiques','reing.d.heero','aotamanyaaaan','moeko_dr','y__o__n__a','POMAYOSHIDA','candle3leafmituba','mocha.monday','mi2_mini','humsedesign','stamp.klover','macaronisurf','chezlion1','dongree_kyoto','unbouquet1388','cocoro.kurumu','chappy.magokoro','makaane214','septoile','DEADSPACE.online','cafe_danslaforet','ramuneid','lanka.knit','cocon_iro_soushingu','COSMICFAMILY7','lapplause.shop','14kgf','yaji_cafe','hikaru_coral_tida_stone','milch.inc','iriecandle','grpz_ikkyu_marvelous','liquid_acce','wasakijunya0912','mugoisiuchi','hiroyuki_nishiyama','kanegon','ateliertamari','mazto_mami','munizo023','hugme_frill','Luki_aloha','ikyuji','marer0','obakeclothing','balancer21g','the___garden','hmt666theshop','tomocotton100','airi0818','astro_theater','aya4721','gricoapart.cafe_shop','mine15shop','ecrairgoods2017','atelier_dodo','yuko.cm1013','satokasei','jpfloweressences','winstoncraftworks','SCREEN_MASTER_WORKS','jplan_tabi','lesfavoris_wedding','i_cle','nanahisaoka','entro_campos','gluckjapan','equipplas','lazoomeek3939','claseek.co','___ciclo','fleurien1227','keepsurfkeepsmiling','pescafiore_','kr._.store','her_handcrafted','lazy.holic','by164paris.jp','mizuhikigirl','beticorouge','lumiere_jubilee','lovebearaccessory','klimaanlage_','tsuboikenzai','cottind','masami1988','little_village_and_co','madoka25oct','toshiohosono','akiramuracco','yumiha_tote','maaroorganic','kosokobo.naito','kikumamu_','saerasshop','fragmentfactory','daborabo','sekiyuden','_colinalina_','balloonconchelu1021','pongtearkon','hsap2014','llsilverspoonll','kimurin0424','vitamincandle','maypartjohn','valmy.jp','itomomi39','nowaymag_kg','yykupukupu','nishimura7825','yukari.boo','jum8','terihaeru','chaaaa3sx','seafeary','selectshop_fur','yuki_Louza','reeeeeach0222','luminaishiai','atelier_fiction','qtcraftsea','mashum.and.dwarf','closer.okinawa','closet_bar','myrulestheark','rocca2405','masanobu_ueda','ihallande','hairytree_sachiko','artshoka.aiko','esolathelab','re_miy216','alocasia_vintage','mana_tomiyama','hikaririri88','id_usedclothes','percou_acce','pacelolpop','dag_theshop','redmoontradingpost',

			#'yurtao','miekoyashirocafe','mondozine','andmoze38','studioshon','konote.handcrafted','d_hata','skiwada','m_amako','msfleamarket','lou.peace.design','tokyosquash','beni_417','akiko_tajima','xxlazwardxx','june.handmade','kyoumi_oosu','komamonoya_hiroha','nakedsun_official','_m.o.m.i_','cem_broche','reikosan_925','sopo.candle','lumiere_de_tache','cyassylabo','nestofmanure','crafsort','rover.factory','buhibokko','boomdigi2017','pleiadesdots','ogawayasaketen','s_ken1ro','setouchisacacoche','kisekaeya','emigraphics','marukiya_official','rondineofficial','kakuremi_official','kettlesan','the_smoke_works','dousa.dibi','erico_collections','kawakami.shiho','hello_and_roll','style4t','leilani.dog','TSUMUGILABO_TANI','beer2life','yumaahi','margaretcourt_shop','irihiakane','nytsworks','bonobagel','sbmg666','cut_looks','moily.bk','gulara_eri','latelier_de_yu','hiromi_merci','deliciousweets','bando_inc','yome5289','pee_ka_boo_sendai','minormode','snipe_sendai','hoshikisara','naomiangel777','lifestyle_1r','nuts323','ak2015_3','5ft46','mushoml84','puako_shop','smartphonekoolgang','vivivionline','yayanon024','theporkshop','ken0jyu0','ayaeivissa','tamura_works','empoposhop','kurutariusu','cage_yamamoto','y1216naru','breathhamamatsu_official','feel_up','littleribbon.123','norma_tokyo','rojiurasan','steelol_vene','maisondehilo','hamppu.ja.mina','lionchan911','cosmicstones','titti1024','punicourt','shimizuchef','emuhamadaraka','MAYU120934','shop.justlikehere','ateliersango','gutouan.go_yamazaki','katadama','encyab','teddy4jp','laf_gluedeco','garage_ill','aryjewelry','tarui.showten','between_kn_takako','balloonshop_esmile','kayonoko','siscy_siscy','shitajimaen','coenoe','chimera_shop_info','shogoron','aromavert','jukebox1121','ceskariko','mayutama_mayu','anchori','nicori_candle','aykstamp','SEMBAN460','ayuayu.handmade','NICKNEEDLES','carriere_vintage_clothing','_yuki_yasuda_','omg_by_doctor_l_lab','alto2525','mituon','bunnybissoux','okawaglass','flowers_import','boriesy','mayu_arc','milinfeng','NAMIHEI1210','nakanotenkids','kimonogasuki01','hoashiyusuke','locoloco443443','12_JUUNI','takayakamma','kazuakihayakawa','keiko_omama_evolution','dog.headcover','rotari_store','carimera123','nichiho_210','morita4055','mgstore_official','asuka.shimada','livenermist','handmade.ocean','shakainomad_punk_girl','gogo.yukachan','ochobi_taeco','enanapockets','bonsaiyatoki','styleandthings_abp','codomopaper','tamatefarm','charlotte_nagoya','rightfitclub','cosyhana','ai.no.mannaka.products','miwele_official','cocomaam','happyis505','shapely_salon','ocantie_art_room','peehana','morijirushi','denimman50','misakitan22','taimahak003','fiorebianca_','aaamemiii','mar1.jasm1n','eat.eat.food','esoracoffee','rmusic358','ayafude','modeofdetail.wardrobes','otomoni','one.1a','tomymuesli','sync_classta','honour.ovation','aoyagimai','yusukesugisawa','sakurainouen','elli00z','fukudaeiichiro','taichi_kurahashi','cross_the_border.shop','erika_4mama','tsuujiimot','tiesocietyjapan','toyshead','_valerie52_','studiocoudre','r3.aoii','copelplanet','_tessea_','tomo.tycka','nail_ribborn','naho_nakanishi','prewo_since2015','dokidokiclub_insta2','tatemai_piaceresolo','pri_mirror','azy_azy_azy','ryokuen.tokyo','jeanskokubo','filica_oyatsu','Calin_la_main','mayuhanafusa','suzukakeshin','candly_info','fedeca_global','las42018','kobaco.store','erikun_made','tdkz_z','storemeimeimei','masaru_kamada','rank_nagasaki','waracbe','bean_product','deco_te_kyoto','verograzia','chario_lifestyle','nattuny','koichimakigami','_nitako_','nowaki.jp','naonaonuts','yshandmadeaccessories','inumagazine','masash1k1mura','brownsheep_me','ninold_45','linoplus_accessory','yves_nil','maturevery.yuko','peeace0315','gift_hokuriku','kunimacoffee','okinawantaste','shiodaruma','kurumiarimoto','gypsy.works','ayahime777','inspirationmaster','noncommittal.osaka','kaiaina_','hitomaruichi','mukonokome','fuku_l','tolnedo1018','netshop_mimiiro','revel_web','worth_wear_works','twistortokyo','kinue_handmade','greedy_usedshop','mauna_tresor','__glittershop__','familia_nail_eyelash','nidom216','fromkobechuchu','oeuftarte','towa_accessory','kanameeeeeee','props_nakameguro','raoingcoinring','numazuno.odashi','gaya038','mkuku52','belladonna.noir','87toiro','taikodou','shop.priscilla','thecoffeex3','kuopus2016','atelier.mof','ritia_select','trailhut_jp','nerikome','analogic_yutenji','kulamastore','ramon_bikes','tepee77','homna_handmade','HIPSTER_OSU','GESCHENK_MANA','kocuu13','botanical_sendai','croque.en.bouche','synthesizakkar','wideheapsdesign','becik19','honeylash','nano.nano.nanoko','____y225','leaaccessory_tmm','kunsaido','ketchap_official','sweetdish_non323','nemuke0728','baobab_store','kagaribi0727','motheranddaughter.pink','shop.gizumo','kurkku.farm','elder_flowers','koikatsugirl','spicca_jewelry','sakuraco898','majolly_official','littleearth807','thewest4thny','fran_the15','myfavand','manico_tanaka','gotsukooo','rakugakigood','rikolekt','nanairo_stagram','muffin_sn','natsumikoike','3270948919','pucapucaofficial','kakaco.accessory','haruharu__jp','printemps_kumamoto','blackmental.ttr','lily_0226_','clothing_bowwow','yukibikinistyle','yuki.ceo','ililanihawaii','plain0811','matoi___','laboum_tokyo','burn_design_store','lewdlybug','rickiey_leather','aroma_shop_triton','b.eave.r','andr0919','baramon_goto','crispypopcorn_snats','littleearth807','yachimun8641','wallworks_cvteye','waonnono','kloop_land.m','maya_____taka','by_kou','anela_onlineshop','yokoracco','blueline4423.jp','mumumimi6633','maitoparta_asahikawa','yunomi03','022performance','chi_mustard','aine916','lexsportskids','ku_ja_ku','hayama244','eater2012','youtaro16','velicloset','Najm0701','indi_life_post','hyo105okame','seeco7373','shiny1days','8cut8','zukky_factory','_shi_n_do_','lahonghu','motherjuice.jp','sundays.23','kotitti','minami4hayato','sunny_vintageparadise','GOOFYSTYLE_wataru','tiare_koubou_akiko','mshamuso','kai_makana_aloha','yoshiakiishiyama','matsunbocraft','fott.jp','yuren.renmosir','one_homey','shiawase_deli','conforto.facil','abesakebrewery','by164paris.jp','pordoutdoor','sexvirginkiller','hokushinac','the_fanon','pine_create_web','kayo_movement','shizukustone_12','sau_hidarimigi','centurion.japan','amam.accesorry','cacoaccessories','matofkyoto','serafine444','allgreen2525','arayacocolo','psyche.par.sonre','thiapily','mamau.jp','lovable.handmade','candlevarious','miracle.com_','lucy_lue_hiroshima','endo.ayako','yaukuwau','Qmyjm','luckysmile.shop','salondeleaf','oliver_garbo','umi.doodle','sharinkan','naturally0707','iy.iy_','maruu_design','selectshop202','around_the_world_shop_2016','milkyflower_wedding','standards_cosme','aya.made','CHAUTESEI','plus__mini','freehairgeneralstore','hrmorg','JYA_ME','june25junjun','whitesportiif','bulldog_skateshop','oisocoffee_an','labochu','katotomotaka','arionkurenka','unomori9','gobananasbrand','momomi_sato','yagi_project','lopitalheart','surfvillage_official','1016LF','lily_accessory','appartement_paris','island.lovers_official','alisa_select','marico.safarii_vintage','emily_kylie_77','ManamiMatsuyama','nahezu_gleich_official','pepepepapers','monange___official','1988.design','orangesun1212','rii__star','low00_official','mielruban','atelier_ci_pu','MORE_Beauty_mb','shop_dearchildren','andma.style','yunism2','astar.candle','workshopbeey','onzyu_','shizendo_mutenka','onando_plat','farm_sunpo','guilty_sawa','mihokakuta','gallery_fotori','marieroppongi7','moi_sopo','takushi_tanaka_gladio','woodbird2013','house_of_beatz1973','yosshi007','henes.jp','nodokaphoto07','kinaco_sak','Htminami','kthfarming','gekko_kobo','mei_w24','epaulement_h','ema.nishinomiya','toiro_knit','atomamakids','wooh_rabbit','salon_odette','house_of_steel_093','tie_accessory','12.angeliaison.34','memoshop168','kukkaricaco','kinasaki09','box_evidence','wafu_kimonogaragara','tantan2010_rianas_style','will_gallery','full_bros','finalbeatdowndistro','okyan_plus','smasta_garden','cocoaru101','fuuyuuka_lyrical','lowpowerworks','workbenchcoffee','h_k_shop_official','zr6shop','onebasic_','nakaokacof','koshijicoffee','peace_trunk','123.mart','xximsjnxx','sakano_garden','b.i.onc','yunyun.nigaoe','stureet','yamanoborimusician','kazutaka.satou','early2ataru','den_portera','cicaco_sk','nihoncha_okamura','yuenterprise','nakamura3217','lily_neige','gracegroan','gypsygemstones','cordialement','sunagaworks','poke.tokushima','unithe_jp','whoopie_roux','vacant_tokyo','kobe_flavor','kissmi_wakisaka','ubvctokyo','pimentrouge210','_mar1una_','tombotencho','bikowoodworks','marimisono.cookies','milleamulette','michie_hoshina','sunshineartworks','maple_fam','ink.tokyo','pinkreligion_official','yoshikawamochi','haginosioya','enanopizaya2','kaisome','199bnf','_____ichi_____','maedakobo','chi98_t','balum.m','doopsclothing','m0tif.1208','gojuon_ginza','kuku_the_one_design','latinnotes.jp','kuniken_ig','__muutos__','minaeuematsu','_silyus_','nosari_kumamon','ngok16','cereal_koenji','kyogudrddd','RFS_TENNIS','blaze_of_destroy','bestdayever.kaede','coffeeroasterie.KATANA','natsuki_sc7','accessory.muw','e_ttun_','akichicribbon','capricemaimade','jouetfood','pal_punto','tea_ishimatsuen','kabukigao_keisano','neo.style.order','kawazaikerwr','kocchi0002','scotchbonnet_japan','_favoritebear_','pinetreebench','towatomo.as','yamanekoya.theshop','iicoto.babygift.ehon','alwanmaroc','birdcamp_','ao_madoca','kentokunnnn','ayumingo_q','ak__2016','varbarossa','hachioji_trains','mmm_made_m.tsujioka','lalajasmily','fell_tokyo','dotclds','stripes_yokohama','caan.ca','kaleyde_kana','7mama.qread','ayasansweets','necorepublicikebukuro','papier.papel','flot_sss','deco_can','y_haruno919','erina_34','kizzifabric','store.wanderlusterslife','livease.jp','tsukuriyayun','brooklyn_furniture','keipleasure28','laniu_hawaii','littlevelvet_d','aloalomiki','nanala_design','hwii0525','tas_sense_official','yumel.h.acs','babna827','kaorin7266','thebluecounty','8__admirable','atsuhideyukumi','office_seasow2','gosuikan','668banchi','maedasenko','haglobe','upset_hiroshima','cafefua','kitchen.of.pet','al.mondo0127','yuchin_y.c.n','yusshiiii','nakazonoyoru','___coto.oto','jams2009handmadestore','lino_stylex','sawitri_spirit','morris.miho','sonneco','ifk.farm','lovablegoblin_room','mulgatheartistjapan','anthemum_vintage','_____petitpas','sunny_and_ringo','baubau','natur.yukari','kiito_yun','4u_fy','isostagram___','gardener.f.f','flowertarot','hotoku_no_mori','guruguruglass','necca.handwork','lilyofthevalley_333','oof_design','moccopooko','xxaazxx','marumekko_','trois_portdor','jphata','maidoarii','handyfallcollection','carriedaway_coco','jorchidjewels','melody.oxo.vintage','_nana_mi_','_satsanga','funyani','escape_vintage','chinatsusunada','puapua_skk','emunana.jp','chocolatmill','Andaganer','heren_r','manimanium','home.decorean','i.s.e_yuki','hakugendo','bunkichiya','eriuhiroko','zi_da_ne_10_5','petit_cerfeuil','swantailor0','reshoe01','kecilbali_osaka','hedgehog_harimaru','mokumerecords','stardust_kana','togarideyukichari','onomichi.ramen.daruma','MARIAATNOA','alohabyzoom','gelato_ladolcevita','shop_okinio','sally_91_i','martha_sirene','rosy_tokyo','cocoiro_room','Paddle_2012','septlumiere','mitsuhiro8486','bustacrew06','stuff_room','amour_jp','kingsmile77','sakurasaku23','menschouchou','dothepogo','neutral044','splende.it','__harch__','kujukogenkabo','lastdance_2015','lebijpujapan','akaitocoffee','hitsujinokaze_no_pan','adamgina_gallery','woolykun','mirufu2017','reward_interior','miyachann.k','yuma0500','felice__album','castella_note','full_figueroa','lop_80','k_awayoshi','jamie__shop','bebeaimable','cbd.natural.clinic','ronramstone','honnoh_genta','lisa_morrienouk','bavoletful','eight_league_fukuoka','_and_ask','sabrina_walnut_st','tipi_angel','tambayasai','flipperyuka','haapsack','kids.gloovy','wedding_at_audrey','anela_liona','mamahada_jp','sekakuri','hiveswimwearjapan','5senses_collection','amagi_kohzanyoh','dolce_garage','asaimari','hachiiro.southosaka','proshop_hamada','marmalade__home','lucy3177','chouchou.km','__iymu.acc','omitanomizu_official','alpacanokyoudai','selectshop.ishigaki','biro_woodworking','tuffrock','izumikawamacfly','anachronic_shop','naoya_0127','fuse.japan','nananano.nano','kondo5869','willow_shop','chocolateholic.r','lindo.yumi_i','cest_mignon_zakka','patissrie.oeuf','mayon___accessorys','melancholicsister','hanauta0728','tigermacrover','es_bake_works','DIEZE.com','plantstrade_official','sakurablossom.2017','billk_mowa','littlethingsforlittleonestokyo','dummpuppe','cuirdeson','g_yuncosandy','5gatsudo','pinoepalude','rangolibindijp','coffeebox2017','present_to_you','_monsroe_','pon__cho','coffee_roughnecks','lelienci','megumiiii615','mato_ya','Hobby_Wonder_land','ashley_reekome','artcocktail_osaka','kaede_lapin','awesome9.shop','momo___rosette','ailly.mai','kanjinoterakoya','miki_milkymart','__potiron__','_benir_','takahitosato','sol__original','twelveone.121','zakka_moko','maffy.y','Reine__official','neko_pantu','yoshihi_futana','onlineacacia','akanesas_football','icoasagiwa','hassyadai','first_room_','piggies.t','woodfactory.aseru','pine__ma','cocovanillaicecream','masaki0409','poupon__','_seaand_','lohasstyle7','phinier_acce','yukikoji.gram','mycloset_0303','riverwellsbeauty','under_myspell','ayurworld.jpn','emvant','lapis_lazli_wedding','taishocoffeeroaster','circusfactory','rikayokomoriblog','lastellacanta','react_official4','anncrea','dolce_bita','simpttywear_','libreange','bigamiclinic','eskapua.jewel','happyringforcolors','dropper_japan','mixto5021','senkamasu','kayocompose_art','tribejapan.2017','mole_loungewear','cuesegg','select_sss','rays.kyoto','mmnyan222','cadeaudelanature','yattoco.handmade','nuit_bijou','u.alt_0204','noirnoiraccessories','LibeNoir','jeema_world','i_am_unisan','mi_wa.hs','blueblue84','peacock_9983','ensoleille._','plus_wan_','kaorimaliesmile','monokana.official','milli_vintage','selectshop_uriel_','sakura_syoukai','monyochita','aoyagikaoru','akihiro_sumiyoshi','tadayori.sakai','radiant_handmade_','navie_tokyo','graffiti2011','calme_dog_wear_','atz77kaz','selectshop_lilyofthevalley','iuarrows','cocoro276','kikiko115','suisounokujira','mocolier','lovers_wedding','asoogunisugilab','nanasora_kids','mr.littleplanet','sola_i_solen','power_tokyo','monfavori214','maruru3y','jun.sweet','pinkstudio1994','eternite.vintage','handmadebag_pagot','asselect710','handwanko_chie','astrojemimas','hachibayayurharbsri','drops.box','yukarikomatsuzaki','photogenique__','flora.r.shop1','513moment_for_kids','ehamakana','hiroki_inoue_northern','hajimetesangokushi','novum.watch','first.fruits','mksts.accessory','carte.official','cocoa_3715','mcflyrecords_jp','_____umu','seven71one_select','anos_roasters','alatsubasa','cocostone_jewelry','leather_aqulia','rayca_funnybunny','watanabemokkougei','QUICKOOL90','mountainwalker14','just_gomyway','_chamoli','alaula_mariko','minttea1017','heymama_tokyo','lucia.888','holocoffeeroaster','lightmeup.japan','hauoli_miki_','gelyasan_mikaribbon','breedtaieikaen','fairy2011.kobe','lalaena879','oryns_','luxisselection','akanepoyon','tokyorice','hono_tojin','fcbenevo','kiss__tokyo','wakagenoitaly','top.notchi','jamboxparlour','adom_tokyo','sii_etoile','chiaboost','karin2122','go.rock.7th','hatchiarmbands',
			't4beachclub','xmoaleax','takeokina','hokubeiyarou','Ms_yarn','voyage.for.lala','jun.horoscope','crazyabout4649','uan_osaka','goldcrown3342','ami_yogastyle','makibue4run','konawinds.life','irodorialbum','silverfrog_dad','meocco','sugisakimasanori','ri_ki_year','prefere_aco','syu_official','cotona_333','sora201704','cuddlydominion','bebec_select','eight8cosme','esma_1210','izumiyamasaki_official','cochococho_kyoto','mademoisell.yoko','cafe_do_toyo','mimia217','despair_shion','yamaji_mami','beetzlibrary','mth.select','groundstarplus','peche_shimokitazawa','beautycatalyst.naomi','iluz47','__merrily_s__','nyctophilia_jp','hamadaippei','lilascherie_fashion','handmade_lilys','asukakoubou','hellobiscuit.shop','artdaifuku','choco_mint30','forreststorejp','aduppe79','maco.decadeau','misa.handmade','chouchou_zakka','nicoflower_shop','venom_lure','am_desu','sachiopiacoffee','mi.acc_','hanko.sanbido','248turbo','haruhimagram','_____awihi','pc.1banbo4','atelier_lab','lumina_sao','1mt_mt2','mocaplus','shiro_dashi','zoo.handmade','m_and_accessories','worldmark.2500','snack_yoko','konikoni917','gumer1706','samurai.pic','syubisya','allmeru.allmeru','cafe.ins','ilachica_pan28panda3','fryuifryui','dh92_official','__u_nil','hdc.outdoor','sumire_atelier','ah_n__','patisserie_yuinohana','hanamusubi88','tsukurico_official','tesoro1204','popcorner.japan','norikids5','anela.chappy','ekodanogarakuta','femico_ei','cherrystaaar','unpeu_rebond','xx_xy_tokyo','plaisir_staff','accessory_vega','kanyamiki','soa0301','makana5525','shopFLAZ','happysmile1107','sun_dove_diner','onceuponatime_aoyama','nailoom.shop','bonsairecord','arikalab','hirochikamachida','lurimo_harimo','karakaze_to_hana','morals.morals.2017','kawasho_matsumoto','amore_mare7','ohiokidsminato','w_flat','koko57428','mural_lily','letteringavenue','yuuki_candle','cocoboo_select','nouson.marche','dreamdrive45','home_roast_hiwahiwa','wc_johnny','yume__end','mochizuki_miki','bible5090','karappo_ya','bmsally729','obon_nagoya','swing_street_cafe','vitcool.official','hilokit','angeroom1','Jewelry_brand_or_','granoladays','klafterselect','autumnflower_i','__selectshop__selfless_love','thingdubthings','calm_sea_closet','fil_baby','brillante_accessory','stimpack.jp','scorilly','kohakoha222','dcp_inc_accessories','_new_deer','opera17vintageselect','jammoca0601','musume.kusumike','aceusedclothing','zozorabbit2017','flow_wing_style','amblinmini','del_hits','andbouquet.shop','yamaiki_ichi','kawadokobo','37camp','SisterJuliet','masashipass','litalico_shop','stark.official2018','rhinestone8008','etoie1127','mashiro.official','uggaust1974','sidewalk.ono','triumph_yokohama','ribonsomurie_osaka','aki.820','funky_pop1125','antique_zakka_cherir_919','selectshop_queenssecret','tapiocaz_taiwan_anime_shop','ayanonhawaii','nishi_akiland','lovecocoa_japan','nagatomonouka','miu_itoh','character_ag','kataoka_farm','merrys2015','c_o_l_o_r_c_o_l_o_r_','boutique_neon','miss_locket','masataka813','rakthai_lincii','ricca2514','meubebe_1014','ek_0101','blairaccessories','bananafishclothing','chambrette.kmp','praysjewels','pas_a_pas2016','books_and_modern','MW_emleu','en1002___','nolicoembroidery','ones_truth','ukietpon','sakura_pluto','uranaiharuka_fukusimanohaha','takaitocoffee','tarui_yusuke','bless_hand','omusubiflowers','wakuwakujam','jewelrynuts','24fragrance_inc','risakato0215','ku_umi0802','miki_aoya','runpoke','penshopimai','goennosuke','blair.select','squeeze2017','poseriwaki','mimi_kazari','fast.baby_kids','marsa0906','akmovement.official','unpont.com_','lihua.lumos','fods_sc','kentarosakauchi','pencake15','0550fifty_fifty','anys_ramp','monaca_coffee','konaco3','sittingbull_kobe','savonfutur','epicbazaar','bonita.shop2999','regalo_baby','atelier_s111','i__do__wedding','emmadechoeur_official','KeRoll_official','lily_accerssorie','mizuho_yoshida','lufmonet','maroa_coco_net','mensmelrose_h','moani.special_life','satohirotaka1129','poeasy_vintage','ahmilly_shop','candymakesyoustrong','mimo.selectshop','cruxpark','office_plan28spice','circle_hat','takayoshi_3721','shirokumaizm','radiann.official','__viodure__','tres_jolie_077','takita_shoes','spread_buyshop','nichibunkyo','freakpiece','byhighland','revived2426','mimimaru55','select_lune','act_64','anniversary.select','takacha_official','woot_snowboard_park_school','mg.rize_4153','loabel.life','mmymselect','masashiigari','elly5coco','aroma_nagi','editta.japan','kurashi_no_mori','nonno_flex','thegrandpillow','shikiko_onlinestore','mc0124mc','bustaskill','kaon1_','macrame_serendipity','pulic_shop','le_lien_11','kamehama_takashi','_hoshikui_','makana.a24','aicocoscrap','zoo.specimen','pluschocolat.jp','zundareofficial','cuore_556','asahi_to_yuhi','goodnightogata','dressshop_roses','ma_natula','spread_snow','herbalshopadhara','hypermilk','saraba.seijaku','commeparis','cfcjapan','mimi.and.merrybon','hirooshunsenbin','_erkmb_','adoka0208','_booonds_','kumagree','iro__iro__','hexis_onlinediet','second_living','mggm.3415','kakavaka_nagoya_','gemmafolia','ren.11.05','gummygummy1107','mosaic_jp','miyu_8080','harika_krd','mumumu_sp','naty.zakka','onokoujiten','keitoyaoon','sweet_godot','purelamo_official','rizu12m','erbenmu0629','movement.jp','swim_swag2016','sekine_nouen','jino.toy','___kokeco___','miyaramakico','misato.t_y','magari_books_2','sri__anna','tita_rico','unerobeme','honeypop1985','t_s_u_g_e_2ge','millvalley_tokyo','tsuchinokonokozjapan','maindish','hibikino_denshi','albero_sacro','yan3_kondoshinya','sayunobake','bontique__','_cotesunday_','katayama_aco','harunayamaguch','marmo___','akiaki_h','curry_nagomiya','materiatools','sappuyer_tokyo','colorful_dress','naotadachi','reflection_nanasaki','francesca_handmadeshop','rayaccessories.wsk','mare__jp','anzieroom','sherry.byme','ranran_fashion','megumi_dama','aleesha_no_hikari_no_niwa','contenavintage','lavillecollection','mieishii_official','Cream_jp_official','emable','maltie_company','_chouchou._','mays_mart','vintage_clothing_cher','yumefuyoudai','viewn_news','63_jun3th_','veicar_official','hakubasouvenirmountain','zakka_tambourine','dekiru.dekiru','vanillaya_official','hoshina_haru0106','mokera_band','maluko_handmade','rents_unstyling','munpa.6080','angle_store','katacoto_sha','une_graine','miwa0japan','ambroom17','otokonouta_magazine','butterflyyogi.jp','happysmile.gram','pyromania_espresso','am.ina.pm','magnolia_handmade.m','kids_petite','hau___oli','airan.05','kintoto_rec','mogura','makomo800','azuma.78tp','soy_town','akimotocoffee','le__magnoliafleuriste','malt_vintage','miel_closet','scandinavia.red','Moonshotgears_info','new_oil_deals','tsushinyan','sfy2017mb','ToantreRi','alice.rosegaden','lagraine201607','sejelu_official','nippondanjijp','kumako365','odeyu86','throttle_wafful','tokyo.producers.house','kn_rosette','0408babyleaf','haruka.sakurai41','beautysalonmy','yuuri__123','vlook_store','handmade_kiyu','photocouture_official','florilege82','wajiya_kanazawa','magicon.kobe','monstown','asa.210','ayaminn_','holycamelp','aruikimono','babyme.babyme','rompgarden.ma','kanazawapacks','chacOrange','zizania_worldbeauty','biobeauty.cosme','satoshl_official','star_lets','mitchyuki001','iz17.jp','meguzou','petit_kicco','ishikabakun','zuiu.driedflower','hanasouvi','saori.komatsubara','cibi_tokyo','reptilegarden2017','sun2closet','chiaki7049','sueyoshiseichakobo','karimizu_dejima','depend_official','julius.babykids','aixknn','ahummarche','sayakamasuoka','iraminaaaaaa','kiminoria.shop','h.matsugashita','ashinaka','laube_accessory','ame.handmade','yuzo_ishida','mimima.shop','scandinavian_shelf','hashibamivintage','riria_leilani','maro.0718','kagurazakaplus','creambaseshop','jooo_thumb','to_to_10_17','beishizu','wasanbon_wansanbon','caplicexx3','meg_merry0523','koihamamono','ofgolddusk','assc__official_hiroshi','ueuhm','scarynoon','hideyamoto','austere.co','ayane_333','boubutu_haru','may_bookcover','tiyokoillust','ki13ki13','yoshikomyideallife','oyasumi.nono','tomoyakiba','basement_bloom','_kagetora.628','mountain_etsuko','nihonneko7','erin.s_selectshop_','plus_mignon','romerotrade','littlerexofficial','majiacarina','regalo.kaori','temporary_boutique','shokotaso','chi.co0609','modaladian_shoesshop','nunc_official','riekim','chiharu_482','rami_hoshinomiya','masumi.washo','raro_accessory','429aki','tokyogirly_official','OtaruIchifuji','goddess358','bempet_japan','emiishida.makemi','youngsavagecoco','pulehina','miu_rairai','minamiyonokidsangel','earthworm_japan','blueroom115','wahu_nagiya','ishibashi.electronics','wazuka.kunka','iimio','mino_ice_mino','simp.life','kunatoryu0204','one_off_buyer','miikafraise_acc','sara_terunuma','kartelltokyo','anastasio0808','zanpangram','the_3_design','yoshinon_base','aquagarden12','ublukcy','mau_akaaka_kids','mimi_3.3_','throwback__2000','makichang55','blooming.babyandkids','achell.swimwear','cray_me.acc','jasminekids2018','tickledpink_jp','remmy_buu','genie_tokyo','romclothingrom','honeoyaji','_marucoro','natsu0217j','kanahiiii','lefty_hiroi','xxcapybarafunxx','medamayakidoll','dab_hair','docan.kohta','theera2018','shtil_il','perfumer_nobuya','totten_totten','urbancacaojapan','selefeel.art','kotorichan_dayo','nikusubrow_2016','scgr_japan','Dorothy.Clothes','badass.co.jp','miico2391','noiva5015','swag.market.jp','yasutakefa','matsuko0621','jun_006','syrinx_chigasaki','ohana_sora','_hipo__','bearfactoryfuk','_b_l_a_c_k_m_i_n_d_','raykajp','7fashion_foryou','mer_citron','usabamon','maruyama_tty','usagiui','birdcage_hoei','felixy','_ug','akyuu.handcrafted','__nanapgram__','mishuku1surf','kyoko_nanba','kamigaki_official','empire.clothing1988','hajimaru_art','shirobenradio','yellow_rompers','iiberal','yakuzenshi','uchukurage2','la_eln2018','mashiro_shirakami','chillhousejp','beadspush_art.yuki','pechimoto','riliartoriginal','alpha_plus_select','harajuku_minmin','crayonkids721','truckyosakoi','oldrookieofficial','misakixxa','honoka_illustration','ks_papa_lure','nagisane_store','taka8taka','uruwashihanaten','mainichi_kichijitsu','flower.salon.karen528','penguin_tsubasa','shun.kikuta','kraby_zna','valite_official','maiacatam','ruedeboy','n.mimiu__','samuraiapartment','hermana_de_moda','taku.k25','ryoko3065','goodfeeling313','keetgakki','uri.gero','jun_t_0110','celli_botti','aruto.accessory','mosaic404','heytaxi_magazine','nachara_doodle','limkurumikeikaku','shop_hachimitsu','memechan_zz','sachikkosuge','saori6be','iandyou_from','zaguzaguro','haruhibatake','yamanami_hm','sunny_anela','gry.ac','milista.jp','rustica_ab','tonalnostalgia','unidots_official','illustratorsalon','noelrose.nail','mikuchibiko','seacret20170423','stevenchoy_asia','__11tommy22__','agendera.jp','inari_channel','lapislazulilove','solid_japan','yamareco']

		return arrShops
	end

end
