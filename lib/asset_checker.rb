# frozen_string_literal: true

class AssetChecker
  attr_accessor :client

  def initialize
    puts "setting pu client"
    @client = Mongo::Client.new([ 'mongo-3.6:27017' ], :database => 'asset-manager')
    puts @client
  end

  def close
    @client.close
  end

  def remote_assets_exist(whitehall_asset)
    versions = whitehall_asset.file.versions.keys
    expected_assets = 0
    remote_assets = 0
    
    # get base asset
    expected_assets +=1
    root_path = whitehall_asset.file.path
    results = @client[:assets].find({ legacy_url_path: root_path})
    if results.count == 1
      remote_assets += 1
    end
    
    versions.map do |version|
      next unless whitehall_asset.file.versions[version].file
      expected_assets +=1 
      path = whitehall_asset.file.versions[version].file.path
      results = @client[:assets].find({ legacy_url_path: path})
      if results.count == 1
        remote_assets += 1
      end
    end
    expected_assets == remote_assets
  end

  def check_all()
    # AttachmentData.where(created_at: 1.year.ago..).take(5).each do |att|
    #   remote_assets_exist(att)
    # end
    good_count = 0
    bad_count = 0
    AttachmentData.take(100000).each do |attachment|
      if remote_assets_exist(attachment)
        good_count += 1
      else
        bad_count += 1
      end
    end
    puts "Good attachments: #{good_count} bad attachments #{bad_count}"
  end

end
