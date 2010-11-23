def Maybe(value)
  Maybe.new(value)
end

class Maybe

  LEGACY_METHODS = %w{value pass fmap join}

  instance_methods.reject { |method_name| method_name.to_s =~ /^__/ || ['object_id','respond_to?', 'methods'].include?(method_name.to_s) }.each { |method_name| undef_method method_name }

  def initialize(value)
    @value = value
    __join__
  end
  
  def respond_to?(method_name)
    return true if LEGACY_METHODS.include?(method_name.to_s)
    super || @value.respond_to?(method_name)
  end

  def methods
    super + @value.methods + LEGACY_METHODS
  end

  # For Ruby 1.9 support
  def respond_to_missing?(method_name, *args, &block)
    super
  end

  def method_missing(method_name, *args, &block)
    if LEGACY_METHODS.include?(method_name.to_s)
      if @value.respond_to?(method_name)
        @value.send(method_name, *args, &block)
      else
        __send__("__#{method_name}__", *args, &block)
      end
    else
      __fmap__ do |value|
        value.send(method_name,*args) do |*block_args|
          yield(*block_args) if block_given?
        end
      end
    end
  end

  def __value__(value_if_nil=nil)
    if(@value==nil)
      value_if_nil
    else
      @value
    end
  end

  def nil?
    @value==nil
  end

  # Given that the value is of type A
  # takes a function from A->M[B] and returns
  # M[B] (a monad with a value of type B)
  def __pass__
    __fmap__ {|*block_args| yield(*block_args)}.__join__
  end

  # Given that the value is of type A
  # takes a function from A->B and returns
  # M[B] (a monad with a value of type B)
  def __fmap__
    if(@value==nil)
      self
    else
      Maybe.new(yield(@value))
    end
  end

  def __join__
    if(@value.is_a?(Maybe))
      @value = @value.__value__
    end
    self
  end

end
