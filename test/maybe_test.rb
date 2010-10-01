require File.expand_path("test_helper", File.dirname(__FILE__))
require 'cgi'
require 'shoulda'

class MaybeTest < Test::Unit::TestCase

  context "#initialize" do

    should "perform join" do
      assert_equal 1, Maybe.new(Maybe.new(1)).value
    end

    should "never call pass on nested maybe" do
      Maybe.any_instance.expects(:pass).never
      Maybe.new(Maybe.new(1)).value
    end
    
  end

  context "when calling methods" do

    should "return correct value for match operator" do
      assert_equal nil, (Maybe.new(nil)=~/b/).value
      assert_equal 1, (Maybe.new('abc')=~/b/).value    
    end

    should "return correct value for to_s" do
      assert_equal nil, (Maybe.new(nil).to_s).value
      assert_equal "1", (Maybe.new(1).to_s).value
    end

    should "return correct value for to_int" do
      assert_equal nil, Maybe.new(nil).to_int.value
      assert_equal 2, Maybe.new(2.3).to_int.value
    end
    
    should "work if method call takes a block" do
      assert_equal nil, Maybe.new(nil).map{|x|x*2}.value
      assert_equal [2,4,6], Maybe.new([1,2,3]).map{|x|x*2}.value
    end

    should "work if methods takes args and a block" do
      assert_equal nil, Maybe.new(nil).gsub(/x/) {|m| m.upcase}.value
      str = Maybe.new('x').gsub(/x/) do |m| 
        m.upcase
      end
      assert_equal 'X', str.value
    end

    should "not change the value" do
      x = Maybe.new(1)
      x.to_s
      assert_equal 1, x.value
    end

  end

  context "when calling object_id" do
    
    should "have different object id than wrapped object" do
      wrapped = "hello"
      maybe = Maybe.new(wrapped)
      assert_not_equal wrapped.object_id, maybe.object_id
      assert_equal wrapped.object_id, maybe.value.object_id
    end

  end

  context "#join" do
    
    should "not call #pass" do
      Maybe.any_instance.expects(:pass).never
      m = Maybe.new(nil)
      m.value = Maybe.new(1)
      m.join
    end

  end

  context "#pass" do

    should "work with CGI.unescape" do
      # using CGI::unescape because that's the first function I had problems with 
      # when implementing Maybe
      assert_equal nil, Maybe.new(nil).pass {|v|CGI.unescapeHTML(v)}.value
      assert_equal '&', Maybe.new('&amp;').pass {|v|CGI.unescapeHTML(v)}.value
    end
    
  end

  context "#nil?" do
    
    should "be true for nil value" do
      assert_equal true, Maybe.new(nil).nil?
    end

    should "be false for non-nil value" do
      assert_equal false, Maybe.new(1).nil?
    end

  end

  context "#value" do

    should "return value with no params" do
      assert_equal nil, Maybe.new(nil).value
      assert_equal 1, Maybe.new(1).value
    end

    context "when default is provided" do

      should "return default is value is nil" do
        assert_equal "", Maybe.new(nil).value("")
        assert_equal nil, Maybe.new(nil).value(nil)
        assert_equal false, Maybe.new(nil).value(false)
      end

      should "return value if value is non-nil" do
        assert_equal 1, Maybe.new(1).value("1")
        assert_equal true, Maybe.new(true).value(nil)
        assert_equal 1, Maybe.new(1).value(false)
      end

    end

  end

  context "when testing monad rules" do

    # the connection between fmap and pass (translated from)
    # http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-3.html
    # scala version: m map f ≡ m flatMap {x => unit(f(x))}
    # note that in my code map == fmap && unit==Maybe.new && flatMap==pass
    should "satisfy monad rule #0" do
      f = lambda {|x| x*2}
      m = Maybe.new(5)
      assert_equal m.fmap(&f), m.pass {|x| Maybe.new(f[x])}
    end

    # monad rules taken from http://moonbase.rydia.net/mental/writings/programming/monads-in-ruby/01identity
    # and http://james-iry.blogspot.com/2007_10_01_archive.html
  
    #1. Calling pass on a newly-wrapped value should have the same effect as giving that value directly to the block.
    # (this is actually the second law at http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-3.html)
    # scala version: unit(x) flatMap f ≡ f(x)
    should "satisfy monad rule #1" do
      f = lambda {|y| Maybe.new(y.to_s)}
      x = 1
      assert_equal f[x], Maybe.new(x).pass {|y| f[y]}.value
    end
  
    #2. pass with a block that simply calls wrap on its value should produce the exact same values, wrapped up again.
    # (this is actually the first law at http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-3.html)
    # scala version: m flatMap unit ≡ m
    should "satisfy monad rule #2" do
      x = Maybe.new(1)
      assert_equal x.value, x.pass {|y| Maybe.new(y)}.value
    end

    #3. nesting pass blocks should be equivalent to calling them sequentially
    should "satisfy monad rule #3" do
      f = lambda {|x| Maybe.new(x*2)}
      g = lambda {|x| Maybe.new(x+1)}
      m = Maybe.new(3)
      n = Maybe.new(3)
      assert_equal m.pass{|x| f[x]}.pass{|x|g[x]}.value, n.pass{|x| f[x].pass{|y|g[y]}}.value
    end

  end

end
