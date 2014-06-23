# MANAGING DEPENDENCIES
# Modified version of our previous code that has many dependencies.
class Gear
	attr_reader :chainring, :cog, :rim, :tire 
	def initialize(chainring, cog, rim, tire)
		@chainring = chainring
		@cog       = cog
		@rim       = rim
		@tire      = tire
	end
	def gear_inches
		ratio * Wheel.new(rim, tire).diameter
	end
	def ratio
		chainring / cog.to_f
	end
	# ...
end
class Wheel
	attr_reader :rim, :tire 
	def initialize(rim, tire)
		@rim = rim
		@tire = tire
	end
	def diameter
		rim + (tire * 2)
	end
	# ...
end
Gear.new(52, 11, 26, 1.5).gear_inches

# An object has dependencies when it knows:
# The name of another class. Gear expects a class named Wheel to exist.
# The name of a message that it intends to send to someone other than
# 	self. Gear expects a Wheel instance to respond to diameter.
# The arguments that a message requires. Gear knows that Wheel.new
# 	requires a rim and tire.
# The order of those arguments. Gear knows the first argument to
# Wheel.new should be rim, the second, tire.

# Elaborating on the first point, what if you want to compute the
# gear_inches for a disk? Or a cylinder? Both have diameters. But in
# this case it's not possible. It's more important that the object
# respond to diameter than it is that the object is a wheel. This is
# an example of a class that needs duck typing.
# Changing the original code to the below helps significantly:
class Gear
	attr_reader :chainring, :cog, :wheel
	def initialize(chainring, cog, wheel)
		@chainring = chainring
		@cog       = cog
		@wheel     = wheel		
	end
	def gear_inches
		ratio * wheel.diameter
	end
	def ratio
		chainring / cog.to_f
	end
end
# Expects a 'Duck' that knows 'diameter'
Gear.new(52, 11, Wheel.new(26, 1.5)).gear_inches
# This technique is known as Dependency Injection
# Just because Gear needs to send diameter somewhere, doesn't mean it
# needs to know about Wheel.

# If the situation exists where you can't decouple it, or you're not
# sure if you will need to (see chapter 2), it's best to isolate it as
# much as possible. Two examples.
# 1. Defining it in the initialize statement so it's obvious.
def initialize(chainring, cog, rim, tire)
	@chainring = chainring
	@cog       = cog
	@wheel     = Wheel.new(rim, tire)
end
# 2. Lazily create @wheel only if it's called
def initialize(chainring, cog, rim, tire)
	@chainring = chainring
	@cog       = cog
	@rim       = rim
	@tire      = tire	
end
def wheel
	@wheel ||= Wheel.new(rim, tire)
end
# Although these examples have dependencies, they are revealed and
# are not concealed at all. The more obvious the better.

# Isolate Vulnerable External Messages
def gear_inches
	ratio * wheel.diameter
end
# In this case, the example is simple. But if this were a more complex
# method, then having this external message of diameter called on
# something outself of self is a risk that should be isolated.
def gear_inches
	ratio * diameter
end
def diameter
	wheel.diameter
end
# Before: Gear's gear_inches was coupled to another class' method.
# After: It is not. If Wheel changes, the errors are isolated to this
# 	single method and can easily be changed.


# Remove Argument-Order Dependencies
# Notice that Gear.new requires 3 arguments in a specific order.
class Gear
	attr_reader :chainring, :cog, :wheel
	def initialize(chainring, cog, wheel)
		@chainring = chainring
		@cog       = cog
		@wheel     = wheel
	end
	# ...
end
Gear.new(
	52,
	11,
	Wheel.new(26,1.5)).gear_inches
# This can be fixed a couple of ways. One is to have hash initialization.
def initialize(args)
	@chainring = args[:chainring]
	@cog       = args[:cog]
	@wheel     = args[:wheel]
end
Gear.new(chainring: 52, cog: 11, wheel: Wheel.new(26,1.5)).gear_inches
# Pros: Less dependency on order, Future changes may be easier,
# 	Future users will clearly understand its implementation
# Cons: Much more verbose
# This change loses the dependency on order, but it does create a
# dependency on the hash key names. It is still a big improvement.

# Another method is to set defaults. This can be done two ways:
def initialize(args)
	@chainring = args.fetch(:chainring, 40)
	@cog       = args.fetch(:cog, 18)
	@wheel     = args[:wheel]
end
# Or...
def initialize(args)
	args = defaults.merge(args)
	@chainring = args[:chainring]
	@cog       = args[:cog]
	@wheel     = args[:wheel]
end
def defaults
	{ chainring: 40, cog: 18 }
end

# If you do not have control over the Gear class, for ex if it's in
# an external module, you can change this via a wrapper.
# When Gear is part of an external interface
module SomeFramework
  class Gear
		attr_reader :chainring, :cog, :wheel 
		def initialize(chainring, cog, wheel)
      @chainring = chainring
      @cog       = cog
      @wheel     = wheel
		end
		# ...
	end 
end
# wrap the interface to protect yourself from changes
module GearWrapper
	def self.gear(args)
		SomeFramework::Gear.new(args[:chainring], args[:cog],
														args[:wheel])
	end
end
GearWrapper.gear(chainring: 52, cog: 11, wheel: Wheel.new(26, 1.5)).gear_inches
# In this case, GearWrapper is used to create an instance of some other class.
# Another term for this is Factory: an object whose purpose is to create other
# objects.
# Always wrap external dependencies that require fixed arguments in your own
# wrapper method. This way, if that dependency changes, you can quickly and
# easily fix your own code.


# Managing Dependency Direction
# Reversing Dependencies
# In our previous code, Gear depended on Wheel. It's possible to switch these.
class Gear
	attr_reader :chainring, :cog
	def initialize(chainring, cog)
    @chainring = chainring
    @cog       = cog		
	end
	def gear_inches(diameter)
		ratio * diameter
	end
	def ratio
		chainring / cog.to_f
	end
end
class	Wheel
	attr_reader :rim, :tire, :gear
	def initialize(rim, tire, chainring, cog)
		@rim       = rim
		@tire      = tire
		@gear 		 = Gear.new(chainring, cog)
	end
	def diameter
		rim + (tire * 2)
	end
	def gear_inches
		gear.gear_inches(diameter)
	end
end
Wheel.new(26, 1.5, 52, 11).gear_inches
# Which one depends on the other is a critical decision to make.
# IMPORTANT: Always try to depend on the class that's least likely to change.

# 3 truths about code:
# 1. Some classes are more likely than others to have changes in requirements.
# 2. Concrete classes are more likely to change than abstract classes.
# 3. Changing a class that has many dependents will result in widespread
# 	 consequences.

# Abstract: disassociated from any specific instance
