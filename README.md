maybe
=====

A library for treating nil and non-nil objects in a similar manner. Technically speaking, Maybe is an implemenation of the maybe monad.

Synopsis
--------

The Maybe class wraps any value (nil or non-nil) and lets you treat it as non-nil.

    require "maybe"
    "hello".upcase                         #=> "HELLO"
    nil.upcase                             #=> NoMethodError: undefined method `upcase' for nil:NilClass
    Maybe.new("hello").upcase.__value__    #=> "HELLO"
    Maybe.new(nil).upcase.__value__        #=> nil

You can also use the method `Maybe` for convenience. The following are equivalent:

    Maybe.new("hello").__value__           #=> "hello"
    Maybe("hello").__value__               #=> "hello"
     
You can also optionally patch `Object` to include a `#maybe` method:

    require "maybe/core_ext"
    "hello".maybe.upcase                   #=> "HELLO"
   
When you call `Maybe.new` with a value, that value is wrapped in a Maybe object. Whenever you call methods on that object, it does a simple check: if the wrapped value is nil, then it returns another Maybe object that wraps nil. If the wrapped object is not nil, it calls the method on that object, then wraps it back up in a Maybe object. 

This is especially handy for long chains of method calls, any of which could return nil.

    # foo, bar, and/or baz could return nil, but this will still work
    Maybe.new(foo).bar(1).baz(:x)

Here's a real world example. Instead of writing this:

    if(customer && customer.order && customer.order.id==newest_customer_id)
      # ... do something with customer
    end

just write this:

    if(Maybe.new(customer).order.id.__value__==newest_customer_id)
      # ... do something with customer
    end

If your wrapped object does not have a `#value` method, you can call

    Maybe.new(obj).value

instead of

    Maybe.new(obj).__value__

Examples
--------

    require "maybe"

    Maybe.new("10")                    #=> A Maybe object, wrapping "10"
  
    Maybe.new("10").to_i               #=> A Maybe object, wrapping 10
  
    Maybe.new("10").to_i.__value__     #=> 10
  
    Maybe.new(nil)                     #=> A Maybe object, wrapping nil 
  
    Maybe.new(nil).to_i                #=> A Maybe object, still wrapping nil
  
    Maybe.new(nil).to_i.__value__      #=> nil

Related Reading
---------------

* [MenTaLguY has a great tutorial on Monads in Ruby over at Moonbase](http://moonbase.rydia.net/mental/writings/programming/monads-in-ruby/00introduction.html)
* [Oliver Steele explores the problem in depth and looks at a number of different solutions](http://osteele.com/archives/2007/12/cheap-monads)
* [Reg Braithwaite explores this same problem and comes up with a different, but very cool solution in Ruby](http://weblog.raganwald.com/2008/01/objectandand-objectme-in-ruby.html)
* [Weave Jester has another solution, inspired by the Maybe monad](http://weavejester.com/node/10)

Note on Patches/Pull Requests
------
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but
  bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
----

Copyright (c) 2009, 2010 Ben Brinckerhoff. See LICENSE for details.
