require File.expand_path("test_helper", File.dirname(__FILE__))
require 'cgi'

class MaybeTest < Test::Unit::TestCase

  def test_initialize__performs_join
    assert_equal 1, Maybe.new(Maybe.new(1)).value
  end

  def test_initialize__never_calls_pass_on_nested_maybe
    Maybe.any_instance.expects(:pass).never
    Maybe.new(Maybe.new(1)).value
  end

  def test_call_match_operator
    assert_equal nil, (Maybe.new(nil)=~/b/).value
    assert_equal 1, (Maybe.new('abc')=~/b/).value
  end

  def test_call_method_defined_on_object
    assert_equal nil, (Maybe.new(nil).to_s).value
    assert_equal "1", (Maybe.new(1).to_s).value
  end

  def test_method
    assert_equal nil, Maybe.new(nil).to_int.value
    assert_equal 2, Maybe.new(2.3).to_int.value
  end
  
  def test_method_with_block
    assert_equal nil, Maybe.new(nil).map{|x|x*2}.value
    assert_equal [2,4,6], Maybe.new([1,2,3]).map{|x|x*2}.value
  end

  def test_method__calling_method_doesnt_change_value
    x = Maybe.new(1)
    x.to_s
    assert_equal 1, x.value
  end

  def test_object_id_for_wrapped_object_is_different
    wrapped = "hello"
    maybe = Maybe.new(wrapped)
    assert_not_equal wrapped.object_id, maybe.object_id
    assert_equal wrapped.object_id, maybe.value.object_id
  end

  def test_method_with_arg_and_block
    assert_equal nil, Maybe.new(nil).gsub(/x/) {|m| m.upcase}.value
    str = Maybe.new('x').gsub(/x/) do |m| 
      m.upcase
    end
    assert_equal 'X', str.value
  end

  def test_join__doesnt_call_pass
    Maybe.any_instance.expects(:pass).never
    m = Maybe.new(nil)
    m.value = Maybe.new(1)
    m.join
  end

  def test_pass__with_cgi_unescape
    # using CGI::unescape because that's the first function I had problems with 
    # when implementing Maybe
    assert_equal nil, Maybe.new(nil).pass {|v|CGI.unescapeHTML(v)}.value
    assert_equal '&', Maybe.new('&amp;').pass {|v|CGI.unescapeHTML(v)}.value
  end

  def test_nil
    assert_equal true, Maybe.new(nil).nil?
    assert_equal false, Maybe.new(1).nil?
  end

  def test_value__returns_value_with_no_params
    assert_equal nil, Maybe.new(nil).value
    assert_equal 1, Maybe.new(1).value
  end

  def test_value__with_default
    assert_equal "", Maybe.new(nil).value("")
    assert_equal 1, Maybe.new(1).value("1")
    assert_equal nil, Maybe.new(nil).value(nil)
    assert_equal true, Maybe.new(true).value(nil)
    assert_equal false, Maybe.new(nil).value(false)
    assert_equal 1, Maybe.new(1).value(false)
  end

  # the connection between fmap and pass (translated from)
  # http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-3.html
  # scala version: m map f ≡ m flatMap {x => unit(f(x))}
  # note that in my code map == fmap && unit==Maybe.new && flatMap==pass
  def test_monad_rule_0
    f = lambda {|x| x*2}
    m = Maybe.new(5)
    assert_equal m.fmap(&f), m.pass {|x| Maybe.new(f[x])}
  end

  # monad rules taken from http://moonbase.rydia.net/mental/writings/programming/monads-in-ruby/01identity
  # and http://james-iry.blogspot.com/2007_10_01_archive.html
  
  #1. Calling pass on a newly-wrapped value should have the same effect as giving that value directly to the block.
  # (this is actually the second law at http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-3.html)
  # scala version: unit(x) flatMap f ≡ f(x)
  def test_monad_rule_1
    f = lambda {|y| Maybe.new(y.to_s)}
    x = 1
    assert_equal f[x], Maybe.new(x).pass {|y| f[y]}.value
  end
  
  #2. pass with a block that simply calls wrap on its value should produce the exact same values, wrapped up again.
  # (this is actually the first law at http://james-iry.blogspot.com/2007/10/monads-are-elephants-part-3.html)
  # scala version: m flatMap unit ≡ m
  def test_monad_rule_2
    x = Maybe.new(1)
    assert_equal x.value, x.pass {|y| Maybe.new(y)}.value
  end

  #3. nesting pass blocks should be equivalent to calling them sequentially
  def test_monad_rule_3
    f = lambda {|x| Maybe.new(x*2)}
    g = lambda {|x| Maybe.new(x+1)}
    m = Maybe.new(3)
    n = Maybe.new(3)
    assert_equal m.pass{|x| f[x]}.pass{|x|g[x]}.value, n.pass{|x| f[x].pass{|y|g[y]}}.value
  end

end
