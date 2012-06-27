require File.expand_path("test_helper", File.dirname(__FILE__))

class CoreExtTest < Test::Unit::TestCase

  context "Object#maybe" do

    should "not include patching by default" do
      assert_raises NoMethodError do
        "foo".maybe
      end
    end

    should "allow calling foo#maybe rather than Maybe.new(foo)" do
      require 'maybe/core_ext'
      assert_kind_of Maybe, "foo".maybe
    end

    teardown do
      Object.send(:undef_method, :maybe) if Object.new.respond_to?(:maybe)
    end

  end

end
