class TagChangesExporter
  def initialize(csv_location, topic_id_to_add, topic_id_to_remove)
    @csv_location = csv_location
    @topic_id_to_add = topic_id_to_add
    @topic_id_to_remove = topic_id_to_remove
  end

  def export
    generate_csv_with_tag_changes
  end

private

  attr_reader :csv_location, :topic_id_to_add, :topic_id_to_remove

  def generate_csv_with_tag_changes
    CSV.open(csv_location, "wb") do |csv|
      csv << headers
      taggings.each { |tagging| csv << tagging }
    end
  end

  def tagged_to_topic
    Edition.published
    .joins(:specialist_sectors)
    .where(specialist_sectors: { tag: topic_id_to_remove })
  end

  def headers
    %w(id type slug add_topic remove_topic)
  end

  def taggings
    tagged_to_topic.each_with_object([]) do |edition, result|
      result << [edition.id, edition.type, edition.slug, topic_id_to_add, edition.primary_specialist_sector_tag]
    end
  end
end
