require "test_helper"

class CacheControlHelperTest < ActionView::TestCase
  class DummyController
    include CacheControlHelper
    def expires_in(*args); end
  end

  setup do
    @controller = DummyController.new
  end

  test "sends an expiry header using the max_age for the earliest scheduled item" do
    scheduled_editions = [
      stub("edition 1", scheduled_publication: 33.seconds.from_now),
      stub("edition 2", scheduled_publication: 5.seconds.from_now),
      stub("edition 3", scheduled_publication: 23.seconds.from_now),
    ]

    @controller.expects(:expires_in).with(5, public: true)
    @controller.expire_on_next_scheduled_publication(scheduled_editions)
  end

  test "gracefully controls expiry time for pages where scheduled items are overdue" do
    (-30..1).step(3).each do |secs_ago|
      assert_equal 1, @controller.max_age_for(secs_ago.seconds.from_now), secs_ago
    end

    assert_equal 60, @controller.max_age_for(31.seconds.ago)
  end

  test "never sends an expiry time longer than the default max cache time" do
    assert_equal Whitehall.default_cache_max_age, @controller.max_age_for(Whitehall.default_cache_max_age.from_now + 1.second)
  end
end
