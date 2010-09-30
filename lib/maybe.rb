def Maybe(value)
  Maybe.new(value)
end

class Maybe

  instance_methods.reject { |method_name| method_name =~ /^__/ || method_name =~ /object_id/ }.each { |method_name| undef_method method_name }

  def initialize(value)
    @value = value
    self.join
  end

  def method_missing(method_name, *args)
    self.fmap do |value|
      value.send(method_name,*args) do |*block_args|
        yield(*block_args) if block_given?
      end
    end
  end
  
  def value(value_if_nil=nil)
    if(value_if_nil!=nil && @value==nil)
      value_if_nil
    else
      @value
    end
  end
  
  # Given that the value is of type A
  # takes a function from A->M[B] and returns
  # M[B] (a monad with a value of type B)
  def pass
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
  
  def nil?
    @value==nil
  end

  def join
    if(@value.is_a?(Maybe))
      @value = @value.value
    end
    self
  end

  # for testing purposes
  def value=(value)
    @value = value
  end

end
