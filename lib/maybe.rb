def Maybe(value)
  Maybe.new(value)
end

class Maybe

  instance_methods.reject { |method_name| method_name =~ /^__/ || method_name == 'object_id' }.each { |method_name| undef_method method_name }

  def initialize(value)
    @value = value
    join
  end

  def method_missing(method_name, *args, &block)
    fmap do |value|
      #value.send(method_name, *args, &block)
      value.send(method_name,*args) do |*block_args|
        yield(*block_args) if block_given?
      end
    end
  end

  def __value__(value_if_nil=nil)
    if(value_if_nil!=nil && @value==nil)
      value_if_nil
    else
      @value
    end
  end
  
  def value(*args, &block)
    if @value.respond_to?(:value)
      @value.send(:value, *args, &block)
    else
      __value__(args.first)
    end
  end

  def nil?
    @value==nil
  end

  def pass(*args, &block)
    if @value.respond_to?(:pass)
      @value.send(:pass, *args, &block)
    else
      __pass__(&block)
    end
  end

  # Given that the value is of type A
  # takes a function from A->M[B] and returns
  # M[B] (a monad with a value of type B)
  def __pass__
    fmap {|*block_args| yield(*block_args)}.join
  end

  # Given that the value is of type A
  # takes a function from A->B and returns
  # M[B] (a monad with a value of type B)
  def fmap
    if(@value==nil)
      self
    else
      Maybe.new(yield(@value))
    end
  end
  
  def join
    if(@value.is_a?(Maybe))
      @value = @value.__value__
    end
    self
  end

end
