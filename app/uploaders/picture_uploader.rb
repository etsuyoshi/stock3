# encoding: utf-8

class PictureUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick
  process resize_to_limit: [400, 400]


  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # 本番環境(heroku)などで画像を使用する場合はfileではなく、fogを活用する
  # →s3画必要になるので一旦後回し
  # if Rails.env.production?
  #   # 本番の場合はストレージサービス(aws:s3)に保存
  #   # →http://railstutorial.jp/chapters/user_microposts?version=4.2#sec-image_upload_in_production
  #   # おそらくawsに保存する形では詰まるので随時さくらやgoogle cloud platformを活用する
  #   # http://qiita.com/miyukki/items/95c72f067736712fb209
  #   storage :fog
  # else
  #   # 開発版の場合は開発環境のファイルシステムに保存(herokuでこれをやろうとするとファイルが消去されてしまう)
  #   storage :file
  # end



  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  # アップロードファイルの保存先ディレクトリは上書き可能
  # 下記はデフォルトの保存先
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end

end
