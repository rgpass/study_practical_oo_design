# ACQUIRING BEHAVIOR THROUGH INHERITANCE
# Inheritance can be complicated, but at the end of the day it's about
# automatic message delegation. If the original receiving object does
# not know how to respond to that message, it is automatically sent to
# the superclass.

# Starting with what is necessary for a road bike
class Bicycle
	attr_reader :size, :tape_color

	def initialize(args)
		@size       = args[:size]
		@tape_color = args[:tape_color]
	end

	# every bike has the same default for tire and chain size
	def spares
		{ chain: 			"10-speed",
			tire_size: 	"23",
			tape_color: tape_color }
	end

	# Many other methods...
end
bike = Bicycle.new(size: 'M', tape_color: 'red')
bike.size     # => 'M'
bike.spares
# -> {:tire_size   => "23",
#     :chain       => "10-speed",
#     :tape_color  => "red"}


# The example below is an example with BAD code. The scenario is now
# the company from above wants to have mountain bikes and road bikes.
# The code below is called an Antipattern -- a common pattern that
# appears to be beneficial but is actually detrimental and for which,
# there is a well-known alternative.
class Bicycle
	attr_reader :style, :size, :tape_color, :front_shock, :rear_shock

	def initialize(args)
		@style				= args[:style]
		@size 				= args[:size]
		@tape_color 	= args[:tape_color]
		@front_shock	= args[:front_shock]
		@rear_shock		= args[:rear_shock]
	end

	# checking "style" starts down a slippery slope
	def spares
		if style == :road
			{ chain: 			"10-speed",
				tire_size: 	"23", 		# millimeters
				tape_color: tape_color }
		else
			{ chain: 			"10-speed",
				tire_size: 	"2.1",		# inches
				rear_shock: rear_shock }
		end
	end
end
bike = Bicycle.new( style: 				:mountain,
			              size: 				'S',
			              front_shock:  'Manitou',
			              rear_shock:   'Fox')
bike.spares
# -> {:tire_size   => "2.1",
#     :chain       => "10-speed",
#     :rear_shock  => 'Fox'}


# Similar to how duck-typing should be used when there were if statements
# on classes and that was an indicator to use duck typing, the above
# example has an if statement on an attribute of self. This is an
# indicator to use inheritance.

# A subclass should be everything its super is plus more. Thus, a class
# of MountainBike should build on top of Bicycle. However, Bicycle should
# not reference anything for RoadBike.

# For inheritance to work, two things must be true.
# 1. There must be a generalization-specialization relationship.
# 2. You must use correct coding techniques.

# Now, Bicycle is an abstract class (abstract: being disassociated from
# any instance). Here's an outline of change process:
class Bicycle
	# This class is now empty.
	# All code has been moved to RoadBike.
end
class RoadBike < Bicycle
	# Subclass of Bicycle.
	# Has all the code previously in Bicycle.
end
class MountainBike < Bicycle
	# Subclass of Bicycle.
	# Has no code in it.
end
# When creating an abstract in this process, it's easier to promote
# behavior up to a super than move it down to a sub. This is why all code
# that was in Bicycle was put into RoadBike, then brought back up. Failure
# to separate the concrete from the abstract is what causes most confusion
# when implementing inheritance.

# Next step in the process is to bring behavior up to Bicycle and utilize
# the abstract class. Starting with size since it's the simplest.
class Bicycle
	attr_reader :size

	def initialize(args={})
		@size = args[:size]
	end
end
class RoadBike < Bicycle
	attr_reader :tape_color

	def initialize(args)
		@tape_color = args[:tape_color]
		super(args)		# RoadBike must now send 'super'
	end
end
# Because the super is explicitly called, the initialize message is now
# shared.
road_bike = RoadBike.new( size: 'M', tape_color: 'red' )
road_bike.size  # -> ""M""

mountain_bike = MountainBike.new( size: 'S', front_shock:  'Manitou',
                        					rear_shock:   'Fox')
mountain_bike.size # -> 'S'

# Spares on the other hand is a convoluted mix of what is shared, what
# is default, and what is specific to subs. We now need to make rules
# that consider:
# 1. Bicycles have a chain and a tire size.
# 2. All bicycles share the same default for chain.
# 3. Subclasses provide their own default for tire size.
# 4. Concrete instances of subclasses are permitted to ignore defaults and supply instance-specific values.
# The below example of using defaults is called the Template Mathod pattern.
class Bicycle
	attr_reader :size, :chain, :tire_size

	def initialize(args={})
		@size 			= args[:size]
		@chain			= args[:chain]			|| default_chain
		@tire_size	= args[:tire_size]	|| default_tire_size
	end

	def default_chain				# <-- Common default
		'10-speed'
	end
end
class RoadBike < Bicycle
	# ...
	def default_tire_size		# <-- Subclass default
		'23'
	end
end
class MountainBike < Bicycle
	# ...
	def default_tire_size		# <-- Subclass default
		'2.1'
	end
end

road_bike = RoadBike.new(size: 'M', tape_color: 'red')
road_bike.tire_size 	# => '23'
road_bike.chain 			# => '10-speed'
mountain_bike = MountainBike.new(size: 'S', front_shock: 'Manitou', rear_shock: 'Fox')
mountain_bike.tire_size # => '2.1'
mountain_bike.chain 		# => '10-speed'

# However now if there's a new sub created, such as RecumbentBike,
# the implementer will have to know that the super requires default_tire_size.
# Not having it will produce an unclear error message. To fix this, add:
class Bicycle
	# ...
	def default_tire_size
		raise NotImplementedError,
			"This #{self.class} cannont respond to: "
	end
end
# This will produce:
bent = RecumbentBike.new
# NotImplementedError:
# This RecumbentBike cannot respond to: # 'default_tire_size'
# Remember to always document Template Method requirements!


# Now we have to move spares from RoadBike up to Bicycle. There are two
# ways to do this. One is easier, but more coupled. The other more
# sophisticated but more robust.
# Current:
class RoadBike < Bicycle
	# ...
	def spares
		{ chain: '10-speed', tire_size: '23', tape_color: 'red' }
	end
end
class MountainBike < Bicycle
	# ...
	def spares
		super.merge({rear_shock: rear_shock})
	end
end
# Changing RoadBike to mimic MountainBike and changing Bicycle to:
class Bicycle
	def spares
		{ tire_size: tire_size, chain: chain }
	end
end
# Gives an overall code that is easier, but coupled. This code is:
class Bicycle
	attr_reader :size, :chain, :tire_size

	def initialize(args={})
		@size 			= args[:size]
		@chain 			= args[:chain] 			|| default_chain
		@tire_size 	= args[:tire_size] 	|| default_tire_size
	end

	def spares
		{ chain: chain, tire_size: tire_size }
	end

	def default_chain
		'10-speed'
	end

	def default_tire_size
		raise NotImplementedError
	end
end
class RoadBike < Bicycle
	attr_reader :tape_color

	def initialize(args)
		@tape_color = args[:tape_color]
		super(args)
	end

	def spares
		super.merge({ tape_color: tape_color })
	end

	def default_tire_size
		'23'
	end
end
class MountainBike < Bicycle
	attr_reader :front_shock, :rear_shock

	def initialize(args)
		@front_shock 	= args[:front_shock]
		@rear_shock 	= args[:rear_shock]
		super(args)
	end

	def spares
		super.merge({ rear_shock: rear_shock })
	end

	def default_tire_size
		'2.1'
	end
end
# The issue here is that if a new person is tasked to create a subclass
# on Bicycle and they forget to put super in either the initialize or the
# spares method, a very-hard-to-troubleshoot error will occur. To fix this
# you can implement hooks. Note: The code below removes the initialize
# method and the spares method in the subs.
class Bicycle
	def initialize(args={})
		@size 			= args[:size]
		@chain 			= args[:chain] 			|| default_chain
		@tire_size 	= args[:tire_size] 	|| default_tire_size

		post_initialize(args)		
	end

	def post_initialize(args)
		nil
	end
	
	def spares
		{ chain: chain, tire_size: tire_size }.merge(local_spares)
	end
	
	def local_spares
		{}
	end
end
class RoadBike < Bicycle
	def post_initialize(args)					# RoadBike optionally overrides
		@tape_color = args[:tape_color] # the post_initialize in the super
	end

	def local_spares
		{ tape_color: tape_color }
	end
end
class MountainBike < Bicycle
	def post_initialize(args)						# MountainBike optionally overrides
		@front_shock = args[:front_shock] # the post_initialize in the super
		@rear_shock  = args[:rear_shock]
	end

	def local_spares
		{ rear_shock: rear_shock }
	end
end
# Now the subs aren't responsible for initializing. They responsible for
# specific info that is required for initializing, but not when it occurs.


# Final code:
class Bicycle
	attr_reader :size, :chain, :tire_size
	
	def initialize(args={})
		@size = args[:size]
		@chain = args[:chain] || default_chain
		@tire_size = args[:tire_size] || default_tire_size

		post_initialize(args)
	end
	
	def spares
		{ tire_size: tire_size, chain: chain}.merge(local_spares)
	end
	
	def default_tire_size
		raise NotImplementedError
	end

  # subclasses may override
	def post_initialize(args)
		nil
	end
	
	def local_spares
		{}
	end
	
	def default_chain
		'10-speed'
	end
end
class RoadBike < Bicycle
	attr_reader :tape_color
	def post_initialize(args)
		@tape_color = args[:tape_color]
	end
	def local_spares
		{tape_color: tape_color}
	end
	def default_tire_size
		'23'
	end
end
class MountainBike < Bicycle 
	attr_reader :front_shock, :rear_shock
	def post_initialize(args)
		@front_shock = args[:front_shock]
		@rear_shock = args[:rear_shock]
	end
	def local_spares
		{rear_shock: rear_shock}
	end
	def default_tire_size
		'2.1'
	end
end

# With this, a new subclass just has to implement the template methods.
class RecumbentBike < Bicycle
	attr_reader :flag

	def post_initialize(args)
		@flag = args[:flag]
	end

	def local_spares
		{ flag: flag }
	end

	def default_chain
		'9-speed'
	end

	def default_tire_size
		'28'
	end
end
bent = RecumbentBike.new(flag: 'tall and orange')
bent.spares
# -> {:tire_size => "28",
#     :chain     => "10-speed",
#     :flag      => "tall and orange"}


# Note: It's best to wait until you have three concrete examples before
# making a super/sub relationship. This way you can clearly know what is
# concrete and what is abstract.
