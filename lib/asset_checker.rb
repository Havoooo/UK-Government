# frozen_string_literal: true

require "ruby-progressbar"

class AssetChecker
  attr_accessor :mongodb_client

  def initialize
    puts "setting pu client"
    @mongodb_client = Mongo::Client.new(["mongo-3.6:27017"], database: "asset-manager")
    puts @mongodb_client
  end

  def close
    @mongodb_client.close
  end

  # This is too slow - and very FileAttachment specific.  Removing for now
  # def whitehall_asset_state(whitehall_asset)
  #   attachment = whitehall_asset.significant_attachment(include_deleted_attachables: true)
  #   unless attachment
  #     return "missing_attachment"
  #   end
  #   if attachment.is_a? Attachment::Null
  #     return "null_attachment"
  #   end
  #
  #   edition = Edition.unscoped.find_by_id(attachment.attachable_id)
  #   edition ? edition.state : "missing_edition"
  # end

  def add_matching_asset(whitehall_asset, version, am_asset, statistics)
    # key = { version:, whitehall_exists: true, am_exists: true, am_state: am_asset["state"], am_draft: am_asset["draft"], am_deleted: !am_asset["deleted_at"].nil? }
    key = { version:, whitehall_exists: true, am_exists: true, am_state: am_asset["state"], am_draft: am_asset["draft"], am_deleted: !am_asset["deleted_at"].nil? }
    statistics[key] += 1
  end

  def add_missing_asset(whitehall_asset, version, statistics)
    key = { version:, whitehall_exists: true, am_exists: false, am_state: nil, am_draft: nil, am_deleted: nil }
    statistics[key] += 1
  end

  def aggregate_statistics(whitehall_asset, statistics)
    versions = whitehall_asset.file.versions.keys

    # get base asset
    root_path = whitehall_asset.file.path
    results = @mongodb_client[:assets].find({ legacy_url_path: root_path })
    if results.count == 1
      add_matching_asset(whitehall_asset, :base, results.first, statistics)
    else
      add_missing_asset(whitehall_asset, :base, statistics)
    end

    versions.map do |version|
      next unless whitehall_asset.file.versions[version].file

      path = whitehall_asset.file.versions[version].file.path
      results = @mongodb_client[:assets].find({ legacy_url_path: path })
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

  def check_all
    statistics = Hash.new(0)

    total_attachments = AttachmentData.unscoped.count
    max_attachments = 10000 # or total for full run
    puts "Total attachments: #{total_attachments} limiting to #{max_attachments}"
    progressbar = ProgressBar.create(total: max_attachments, throttle_rate: 0.1, format: " %E	%t: |%B|")
    AttachmentData.unscoped.take(max_attachments).each_with_index do |attachment, _row_index|
      progressbar.increment
      aggregate_statistics(attachment, statistics)
    end
    # pp statistics
    CSV.open("asset_stats.csv","w") do |csv|
      csv << %w(count version whitehall_exists am_exists am_state am_draft am_deleted)
      statistics.each { |(stats, count)|
        csv << [count, stats[:version], stats[:whitehall_exists], stats[:am_exists], stats[:am_state], stats[:am_draft], stats[:am_deleted]]
      }
    end
  end
end
