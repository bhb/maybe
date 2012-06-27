# -*- coding: utf-8 -*-
require File.expand_path("test_helper", File.dirname(__FILE__))
require 'cgi'
require 'maybe'

class MaybeTest < Test::Unit::TestCase

  context "#initialize" do

    should "perform join" do
      assert_equal 1, Maybe.new(Maybe.new(1)).__value__
    end

    should "never call pass on nested maybe" do
      Maybe.any_instance.expects(:__pass__).never
      Maybe.new(Maybe.new(1)).__value__
    end

  end

  context "when calling methods" do

    should "return correct value for match operator" do
      assert_equal nil, (Maybe.new(nil)=~/b/).__value__
      assert_equal 1, (Maybe.new('abc')=~/b/).__value__
    end

    should "return correct value for to_s" do
      assert_equal nil, (Maybe.new(nil).to_s).__value__
      assert_equal "1", (Maybe.new(1).to_s).__value__
    end

    should "return correct value for to_int" do
      assert_equal nil, Maybe.new(nil).to_int.__value__
      assert_equal 2, Maybe.new(2.3).to_int.__value__
    end

    should "work if method call takes a block" do
      assert_equal nil, Maybe.new(nil).map{|x|x*2}.__value__
      assert_equal [2,4,6], Maybe.new([1,2,3]).map{|x|x*2}.__value__
    end

    should "work if methods takes args and a block" do
      assert_equal nil, Maybe.new(nil).gsub(/x/) {|m| m.upcase}.__value__
      str = Maybe.new('x').gsub(/x/) do |m|
        m.upcase
      end
      assert_equal 'X', str.__value__
    end

    should "not change the value" do
      x = Maybe.new(1)
      x.to_s
      assert_equal 1, x.__value__
    end

  end

  context "when calling object_id" do

    should "have different object id than wrapped object" do
      wrapped = "hello"
      maybe = Maybe.new(wrapped)
      assert_kind_of Fixnum, maybe.object_id
      assert_not_equal wrapped.object_id, maybe.object_id
      assert_equal wrapped.object_id, maybe.__value__.object_id
    end

  end

  context "#join" do

    should "not call #pass" do
      Maybe.any_instance.expects(:__pass__).never
      m = Maybe.new(nil)
      m.instance_variable_set(:@value, Maybe.new(1))
      m.join
      m.__join__
    end

    should "call the wrapped object's #join if defined" do
      wrapped = %w{a b c}
      assert_equal "a b c", Maybe.new(wrapped).join(' ')
      assert_equal "a b c", Maybe.new(Maybe.new(wrapped)).join(' ')
    end

  end

  context "respond_to?" do

    should "respond correctly" do
      klass = Class.new do
        def fmap
        end

        def foo
        end
      end

      wrapped = klass.new
      maybe = Maybe.new(wrapped)

      assert_equal false, wrapped.respond_to?(:bar)
      assert_equal true, wrapped.respond_to?(:foo)
      assert_equal true, wrapped.respond_to?(:fmap)
      assert_equal false, wrapped.respond_to?(:join)
      assert_equal false, wrapped.respond_to?(:value)
      assert_equal false, wrapped.respond_to?(:pass)
      assert_equal false, wrapped.respond_to?(:__fmap__)
      assert_equal false, wrapped.respond_to?(:__join__)
      assert_equal false, wrapped.respond_to?(:__value__)
      assert_equal false, wrapped.respond_to?(:__pass__)

      assert_equal false, maybe.respond_to?(:bar)
      assert_equal true, maybe.respond_to?(:foo)
      assert_equal true, maybe.respond_to?(:fmap)
      assert_equal true, maybe.respond_to?(:join)
      assert_equal true, maybe.respond_to?(:value)
      assert_equal true, maybe.respond_to?(:pass)
      assert_equal true, maybe.respond_to?(:__fmap__)
      assert_equal true, maybe.respond_to?(:__join__)
      assert_equal true, maybe.respond_to?(:__value__)
      assert_equal true, maybe.respond_to?(:__pass__)
    end

  end

  context "#methods" do

    should "contain methods from wrapped method and wrapper" do
      klass = Class.new do
        def fmap
        end

        def foo
        end
      end

      wrapped = klass.new
      maybe = Maybe.new(wrapped)

      methods = maybe.methods.map{|x| x.to_sym}

      assert_equal false, methods.include?(:far)
      assert_equal true, methods.include?(:foo)

      assert_equal true, methods.include?(:fmap)
      assert_equal true, methods.include?(:value)
      assert_equal true, methods.include?(:pass)
      assert_equal true, methods.include?(:join)

      assert_equal true, methods.include?(:__fmap__)
      assert_equal true, methods.include?(:__value__)
      assert_equal true, methods.include?(:__pass__)
      assert_equal true, methods.include?(:__join__)
    end

  end

  context "#pass" do

    should "not conflict with wrapped object's #pass method" do
      ball = Object.new
      def ball.pass
        "success"
      end
      assert_equal "success", Maybe.new(ball).pass
    end

    should "work with CGI.unescape" do
      # using CGI::unescape because that's the first function I had problems with
      # when implementing Maybe
      assert_equal nil, Maybe.new(nil).pass {|v|CGI.unescapeHTML(v)}.value
      assert_equal '&', Maybe.new('&amp;').pass {|v|CGI.unescapeHTML(v)}.value

      assert_equal nil, Maybe.new(nil).__pass__ {|v|CGI.unescapeHTML(v)}.__value__
      assert_equal '&', Maybe.new('&amp;').__pass__ {|v|CGI.unescapeHTML(v)}.__value__
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

    should "return value if wrapped object does not define #value" do
      assert_equal nil, Maybe.new(nil).value
      assert_equal 1, Maybe.new(1).value
    end

    should "call wrapped object's #value if defined" do
      wrapped = Object.new
      def wrapped.value
        "foo"
      end
      assert_equal "foo", Maybe.new(wrapped).value
      assert_equal "foo", Maybe.new(Maybe.new(wrapped)).value
    end

    should "call wrapped object's #value if defined (with params and block)" do
      wrapped = Object.new
      def wrapped.value(value)
        value * yield
      end
      assert_equal 4, Maybe.new(wrapped).value(2) { 2 }
      assert_equal 4, Maybe.new(Maybe.new(wrapped)).value(2) { 2 }
    end

  end

  context "#__value__" do

    should "return value with no params" do
      assert_equal nil, Maybe.new(nil).__value__
      assert_equal 1, Maybe.new(1).__value__
    end

    context "when default is provided" do

      should "return default is value is nil" do
        assert_equal "", Maybe.new(nil).__value__("")
        assert_equal nil, Maybe.new(nil).__value__(nil)
        assert_equal false, Maybe.new(nil).__value__(false)
      end

      should "return value if value is non-nil" do
        assert_equal 1, Maybe.new(1).__value__("1")
        assert_equal true, Maybe.new(true).__value__(nil)
        assert_equal 1, Maybe.new(1).__value__(false)
      end

    end

  end

  context "#fmap" do

    should "call wrapped object's #fmap if defined" do
      wrapped = Object.new
      def wrapped.fmap
        "x"
      end
      assert_equal "x", Maybe.new(wrapped).fmap
      assert_equal "x", Maybe.new(Maybe.new(wrapped)).fmap
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
      assert_equal m.__fmap__(&f), m.__pass__ {|x| Maybe.new(f[x])}
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
      assert_equal f[x], Maybe.new(x).__pass__ {|y| f[y]}.__value__
    end

    #2. pass with a block that simply calls wrap on its value should produce the exact same values, wrapped up again.
    # (this is actually the first law at http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-3.html)
    # scala version: m flatMap unit ≡ m
    should "satisfy monad rule #2" do
      x = Maybe.new(1)
      assert_equal x.value, x.pass {|y| Maybe.new(y)}.value
      assert_equal x.__value__, x.pass {|y| Maybe.new(y)}.__value__
    end

    #3. nesting pass blocks should be equivalent to calling them sequentially
    should "satisfy monad rule #3" do
      f = lambda {|x| Maybe.new(x*2)}
      g = lambda {|x| Maybe.new(x+1)}
      m = Maybe.new(3)
      n = Maybe.new(3)
      assert_equal m.pass{|x| f[x]}.pass{|x|g[x]}.value, n.pass{|x| f[x].pass{|y|g[y]}}.value
      assert_equal m.__pass__{|x| f[x]}.__pass__{|x|g[x]}.__value__, n.__pass__{|x| f[x].__pass__{|y|g[y]}}.__value__
    end

  end

end
