# frozen_string_literal: true

require 'ruby-progressbar'

class AssetChecker
  attr_accessor :client

  def initialize
    puts "setting pu client"
    @client = Mongo::Client.new([ 'mongo-3.6:27017' ], database: 'asset-manager')
    puts @client
  end

  def close
    @client.close
  end

  def whitehall_asset_state(whitehall_asset)
    attachment = whitehall_asset.significant_attachment(include_deleted_attachables: true)
    if !attachment
      return "missing_attachment"
    end
    if attachment.is_a? Attachment::Null
      return "null_attachment"
    end
    edition = Edition.unscoped.find_by_id(attachment.attachable_id)
    edition ? edition.state : "missing_edition"
  end

  def add_matching_asset(whitehall_asset, version, am_asset, statistics)
    key = {version:, whitehall_state: whitehall_asset_state(whitehall_asset), am_state: am_asset["state"], am_draft: am_asset["draft"], whitehall_exists: true, am_exists: true}
    statistics[key] += 1
  end

  def add_missing_asset(whitehall_asset, version, statistics)
    key = {version:, whitehall_state:  whitehall_asset_state(whitehall_asset), am_state: nil, am_draft: nil, whitehall_exists: true, am_exists: false}
    statistics[key] += 1
  end


  def aggregate_statistics(whitehall_asset, statistics)
    versions = whitehall_asset.file.versions.keys

    # get base asset
    root_path = whitehall_asset.file.path
    results = @client[:assets].find({ legacy_url_path: root_path})
    if results.count == 1
      add_matching_asset(whitehall_asset, :base, results.first, statistics)
    else
      add_missing_asset(whitehall_asset, :base, statistics)
    end

    versions.map do |version|
      next unless whitehall_asset.file.versions[version].file
      path = whitehall_asset.file.versions[version].file.path
      results = @client[:assets].find({ legacy_url_path: path})
      if results.count == 1
        add_matching_asset(whitehall_asset, version, results.first, statistics)
      else
        add_missing_asset(whitehall_asset, version, statistics)
      end
    end
  end

  def suppress_sql_logs
    ActiveRecord::Base.logger.level = 1
  end
  def restore_sql_logs
    ActiveRecord::Base.logger.level = 0
  end

  def check_all()
    statistics = Hash.new(0)

    total_attachments = AttachmentData.unscoped.count
    max_attachments = 1000 # or total for full run
    puts "Total attachments: #{total_attachments} limiting to #{max_attachments}"
    progressbar = ProgressBar.create(total: max_attachments, throttle_rate: 0.1, format: " %E	%t: |%B|")
    AttachmentData.unscoped.take(max_attachments).each_with_index do |attachment, row_index|
      progressbar.increment
      aggregate_statistics(attachment, statistics)
    end
    pp statistics
  end

end
