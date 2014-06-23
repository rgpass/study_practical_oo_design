# DESIGNING CLASSES WITH A SINGLE RESPONSIBILITY

# Deciding What Belongs in a Class
# "Despite the importance of correctly grouping methods into classes, 
# at this early stage of your project you cannot possibly get it right. 
# You will never know less than you know right now. If your application 
# succeeds many of the decisions you make today will need to be changed 
# later. When that day comes, your ability to successfully make those 
# changes will be determined by your application’s design.
# Design is more the art of preserving changeability than it is the act 
# of achieving perfection."

# Code you write should be TRUE:
# Transparent - The consequences of change should be obvious in the code 
# 	that is changing and in distant code relies upon it
# Reasonable - The cost of any change should be proportional to the 
# 	benefits the change achieves
# Usable - Existing code should be usable in new and unexpected contexts
# Exemplary - The code itself should encourage those who change it to 
# 	perpetuate these qualities

# Each class should have a single, well-defined responsibility. In other
# words, it should do the smallest possible useful thing.

# Initial example:
chainring = 52
cog 			= 11
ratio			= chainring / cog.to_f # => 4.7272727272727275

chainring = 30
cog				= 27
ratio 		= chainring / cog.to_f # => 1.1111111111111112
# Intuition says Bicycle should be a class, but there are currently
# no behaviors (methods) for Bicycle, so it does not qualify. It is
# only data, not behavior. Gears, however, have both data and behavior,
# thus Gears qualify as a separate class.
class Gear
	attr_reader :chainring, :cog

	def initialize(chainring, cog)
		@chainring = chainring
		@cog 			 = cog
	end

	def ratio
		chainring / cog.to_f
	end
end
puts Gear.new(52, 11).ratio # => 4.7272727272727275
puts Gear.new(30, 27).ratio # => 1.1111111111111112

# Lets say your friend wants you to compute gear inches, which is a
# bike metric for comparing different gears and wheel sizes. You change
# the code above to:
class Gear
	attr_reader :chainring, :cog, :rim, :tire

	def initialize(chainring, cog, rim, tire)
		@chainring = chainring
		@cog 			 = cog
		@rim			 = rim
		@tire			 = tire
	end

	def ratio
		chainring / cog.to_f
	end

	def gear_inches
		ratio * (rim + (tire * 2))
	end
end
puts Gear.new(52, 11, 26, 1.5).gear_inches  # => 137.090909090909
puts Gear.new(52, 11, 24, 1.25).gear_inches # => 125.272727272727
# But now when you try your previous code...
puts Gear.new(52, 11).ratio # you get wrong number of arguments 2 of 4

# To determine if a class needs to be broken up, ask it interrogation
# style questions about its methods.
# Mr. Gear, what is your ratio?    Sounds good.
# Mr. Gear, what is your gear inches?   OK, a little weird.
# Mr. Gear, what is your tire size?   Doesn't belong.
# Another thing to do is to describe the class in one sentence. If you
# use the word 'and' or 'or', then it needs to be split up.

# Classes should have responsibilities that fulfill its purpose. It
# shouldn't be too small or too large.

# Sometimes it's better to leave the class like it is now and wait
# for future requirements to come through. Ask yourself, "What is the
# future cost of doing nothing now?"

# Always use accessor methods over using instance variables in methods.
# Good: See the code above.
# Bad:
class Gear
	def initialize(chainring, cog)
		@chainring = chainring
		@cog 			 = cog
	end

	def ratio
		@chainring / @cog.to_f
	end
end

# When you complex data, it's better to have a method that cleans it up.
# Here's a bad example. This example requires a 2d array.
class ObscuringReferences 
	attr_reader :data
	def initialize(data)
		@data = data
	end
	def diameters
		# 0 is rim, 1 is tire 
		data.collect {|cell| cell[0] + (cell[1] * 2)} 
	end
  # ... many other methods that index into the array
end
# In this case, diameters has to take a 2d array. Would be better to take
# any enumerable where each enumerated thing responds to rim and tire.
class RevealingReferences
	attr_reader :data
	def initialize(data)
		@data = wheelify(data)
	end
	def diameters
		wheels.collect { |wheel| wheel.rim + (wheel.tire * 2) }
	end
	Wheel = Struct.new(:rim, :tire)
	def wheelify(data)
		data.collect { |cell| Wheel.new(cell[0], cell[1]) }
	end
end
# Doing this converts data from an array of Arrays to an array of Structs.
# This allows diameter to use wheel.rim and wheel.tire
# Similar to how you can use a method to wrap an instance variable, you can
# use Struct to wrap a structure.
# What was cell[0] is now wheel.rim
# Ruby docs define Struct as: "an easy way to bundle a number of attributes
# together, using accessor methods, without having to write an explicit class."

# Applying the Single Responsibility Principle goes beyond classes. Ask each
# method "What is your responsibility?" If the word 'and' is used, fix it.
# diameters, what is your responsibility?
# Iterate over the wheels and calculate the diameter.
# The fix:
def diameters
	wheels.collect { |wheel| diameter(wheel) }
end
def diameter(wheel)
	wheel.rim + (wheel.tire * 2)
end
# An easy to recognize case of invalidating SRP is iteration + action, as
# seen above.

# Another case that you can recognize is when any calculation is done
# inside parantheses (excluding cases where making another method would
# cause only clutter, such as the () inside the diameter function above).
# Our previous gear_inches method:
def gear_inches
	ratio * (rim + (tire * 2))
end
# Can be changed to:
def gear_inches
	ratio * diameter
end
def diameter
	rim + tire * 2
end

# Although Wheel doesn't necessarily align with the Gear class, sometimes
# you don't know if you'll need it separated out or not. Doing so prematurely
# can cause significant headaches down the line. A good stopping point for
# our Gear class is:
class Gear
	attr_reader :chainring, :cog, :wheel
	def initialize(chainring, cog, rim, tire)
		@chainring = chainring
		@cog 			 = cog
		@wheel     = Wheel.new(:rim, :tire)		
	end
	def ratio
		chainring / cog.to_f
	end
	def gear_inches
		ratio * wheel.diameter
	end
	Wheel = Struct.new(:rim, :tire) do
		def diameter
			rim + (tire * 2)
		end
	end
end
# This is not a long-term solution, but cleans up Gear while we wait on
# more info to create a Wheel class or not.

# In our scenario (and in the real world), Wheels exist without gears, thus
# the Wheel class should be separate. Lets say our friend needs to know the
# circumference of the wheel as their speedometer requires it. Now we know
# that we should move Wheel to a separate class. Making our code:
class Gear
	attr_reader :chainring, :cog, :wheel
	def initialize(chainring, cog, wheel=nil)
		@chainring = chainring
		@cog 			 = cog
		@wheel     = wheel	
	end
	def ratio
		chainring / cog.to_f
	end
	def gear_inches
		ratio * wheel.diameter
	end
end
class Wheel
	attr_reader :rim, :tire
	def initialize(rim, tire)
		@rim  = rim
		@tire = tire
	end
	def diameter
		rim + (tire * 2)
	end
	def circumference
		diameter * Math::PI
	end
end
@wheel = Wheel.new(26, 1.5) 
puts @wheel.circumference # => 91.106186954104
puts Gear.new(52, 11, @wheel).gear_inches # => 137.090909090909
puts Gear.new(52, 11).ratio # => 4.72727272727273

