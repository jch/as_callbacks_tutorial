require 'bundler/setup'
require 'active_support'

# Group is the base class where we define our custom callbacks. After
# mixing in `ActiveSupport::Callbacks`, we define a custom `:user_added`
# callback with `#define_callbacks`. This lets us use before, around, and
# after callbacks.
class Group
  include ActiveSupport::Callbacks
  define_callbacks :user_added

  def initialize(opts = {})
    @users = []
  end

  # Whenever we add a new user to our array, we wrap the code
  # with `run_callbacks`. This will run any defined callbacks
  # in order.
  def add_user(u)
    run_callbacks :user_added do
      puts "    adding user"
      @users << u
    end
  end
end

class SubGroup < Group
  # To register a callback, use `set_callback`. By default,
  # it assumes you are defining a `before` callback.
  set_callback :user_added, :before_sub_user

  def add_user(u)
    super("sub_#{u}")
  end

  def before_sub_user
    puts "before_sub_user: #{@users.inspect}\n"
  end
end

class CustomGroup < SubGroup
  # Multiple callbacks can be registered. Callbacks are run
  # in FIFO order, with callbacks later in the inheritance
  # tree having lower precendence. So the parent class's
  # `#before_sub_user` will be called before this class's
  # `#before_user`.
  set_callback :user_added, :before, :before_user
  set_callback :user_added, :around, :around_user
  set_callback :user_added, :after,  :after_user

  def before_user
    puts "before_user: #{@users.inspect}\n"
  end

  def around_user
    puts "  around_user: #{@users.inspect}"
    puts "  around_user yield:"
    yield
    puts "  around_user: #{@users.inspect}"
  end

  def after_user
    puts "after_user: #{@users.inspect}"
  end
end

# Here we create a new CustomGroup and kick of the callbacks.
# The results will look like:
# 
# <pre>
# before_sub_user: []
# before_user: []
#   around_user: []
#   around_user yield:
#     adding user
# after_user: ["sub_bob"]
#   around_user: ["sub_bob"]
# </pre>
cg = CustomGroup.new
cg.add_user("bob")
