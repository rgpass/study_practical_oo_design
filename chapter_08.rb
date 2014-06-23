# COMBINING OBJECTS WITH COMPOSITION
# Similar to have music is a composition of notes -- i.e. notes align are small
# and nothing significant, the composition of them makes something bigger than
# the sum of their parts. OO composition is the same.

# Starting from the final code from chapter 6.
# A bicycle is really many parts. If it wants spares, it should send that
# message to a Parts object. This makes the code:
class Bicycle
	attr_reader :size, :parts
	def initialize(args={})
		@size  = args[:size]
		@parts = args[:parts]
	end
	def spares
		parts.spares
	end
end
# Moving the parts code from before into the Parts object.
class Parts
	attr_reader :chain, :tire_size
	def initialize(args={})
		@chain     = args[:chain]     || default_chain
		@tire_size = args[:tire_size] || default_tire_size
		post_initialize(args)
	end
	def spares
		{ tire_size: tire_size, chain: chain }.merge(local_spares)
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
class RoadBikeParts < Parts
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
class MountainBikeParts < Parts 
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
# Now there is an abstract Parts class that RoadBikeParts and MountainBikeParts
# is sub too.
road_bike = Bicycle.new(
	size: 'L',
	parts: RoadBikeParts.new(tape_color: 'red'))
road_bike.size # => 'L'
road_bike.spares
# -> {:tire_size=>"23",
#     :chain=>"10-speed",
#     :tape_color=>"red"}
mountain_bike = Bicycle.new(
	size: 'L',
	parts: MountainBikeParts.new(rear_shock: 'Fox'))
mountain_bike.size # => 'L'
mountain_bike.spares
# -> {:tire_size=>"2.1",
#     :chain=>"10-speed",
#     :rear_shock=>"Fox"}
# Although this refactoring didn't do much to improve our previous situation, it
# did tell us that Bicycle doesn't do that much.

# Considering the code above deals mostly with individual parts, it makes sense to
# create a Part objects.

class Bicycle
	attr_reader :size, :parts
	def initialize(args={})
		@size = args[:size]
		@parts = args[:parts]
	end
	def spares
		parts.spares
	end
end
class Parts
	attr_reader :parts
	def initialize(parts)
		@parts = parts
	end
	def spares
		parts.select { |part| part.needs_spare }
	end
end
class Part
	attr_reader :name, :description, :needs_spare
	def initialize(args)
		@name 			 = args[:name]
		@description = args[:description]
		@needs_spare = args.fetch(:needs_spare, true)
	end
end
# Now we can create parts
chain 				= Part.new(name: 'chain', description: '10-speed')
road_tire 		= Part.new(name: 'tire_size', description: '23')
tape 					= Part.new(name: 'tape_color', description: 'red')
mountain_tire = Part.new(name: 'tire_size', description: '2.1')
rear_shock 		= Part.new(name: 'rear_shock', description: 'Fox')
front_shock 	= Part.new(
          name: 'front_shock',
          description: 'Manitou',
          needs_spare: false)
# Can group individual Part objects together to make Parts
road_bike_parts = Parts.new([chain, road_tire, tape])
# Or you can make the Parts object on the fly when making Bicycle
road_bike = Bicycle.new(size: 'L', parts: Parts.new([chain, road_tire, tape]))
road_bike.size    # -> 'L'
road_bike.spares
# -> [#<Part:0x00000101036770
#         @name="chain",
#         @description="10-speed",
#         @needs_spare=true>,
#     #<Part:0x0000010102dc60
#         @name="tire_size",
# etc ...
mountain_bike = Bicycle.new(size: 'L', parts: Parts.new([chain, mountain_tire, front_shock, rear_shock]))
mountain_bike.size    # -> 'L'
mountain_bike.spares
# -> [#<Part:0x00000101036770
#         @name="chain",
#         @description="10-speed",
#         @needs_spare=true>,
#     #<Part:0x0000010101b678
#         @name="tire_size",
# etc ...

# The main challenge now is making Parts behave more like an array. Currently:
mountain_bike.spares.size # -> 3
mountain_bike.parts.size
# -> NoMethodError:
#      undefined method 'size' for #<Parts:...>
# Instead of adding a size method or making it inherit from Array, it's best to do:
require 'forwardable'
class Parts
	include Forwardable
	def_delegators :@parts, :size, :each
	extend Enumerable
	def initialize(parts)
		@parts = parts
	end
	def spares
		select { |part| part.needs_spare }
	end
end
# Now...
mountain_bike = Bicycle.new(size: 'L', 
														parts: Parts.new([chain,
                            									mountain_tire,
									                            front_shock,
									                            rear_shock]))
mountain_bike.spares.size   # -> 3
mountain_bike.parts.size    # -> 4

# The downside of the above is that you have to memorize what parts go with which
# bike type. This can be fixed my making a config array.
road_config = [['chain', '10-speed'],
							 ['tire_size', '23'],
							 ['tape_color', 'red']]
mountain_config = [['chain', '10-speed'],
									 ['tire_size', '2.1'],
									 ['front_shock', 'Manitou', false],
									 ['rear_shock', 'Fox']]

# Now we can make a PartsFactory module whose sole purpose is to create parts.
module PartsFactory
	def self.build(config, part_class = Part, parts_class = Parts)
		parts_class.new(config.collect {|part_config|
			part_class.new(
				name: part_config[0],
				description: part_config[1],
				needs_spare: part_config.fetch(2,true))})
	end
end
# This comes with two consequences. First is that the above code is terse. The
# second is that once we build it using an array, it should be the only way we
# build it, or else we have to redo the code in lines 196-198.
# Now that PartsFactory is defined, we can easily create new parts via:
road_parts 			= PartsFactory.build(road_config)
mountain_parts 	= PartsFactory.build(mountain_config)

# With PartsFactory, we can look at Part class again (repeated below).
class Part
	attr_reader :name, :description, :needs_spare
	def initialize(args)
		@name 			 = args[:name]
		@description = args[:description]
		@needs_spare = args.fetch(:needs_spare, true)
	end
end
# We can now replace this with an OpenStruct. OpenStruct is like Struct, but
# has hash initialization instead of position order initialization. With that,
# we can delete the Part class and change the PartsFactory to have the Part's role.
require 'ostruct'
module PartsFactory
	def self.build(config, parts_class = Parts)
		parts_class.new(config.collect {|part_config| create_part(part_config)})
	end

	def self.create_part(part_config)
		OpenStruct.new(
			name: 				part_config[0],
			description: 	part_config[1],
			needs_spare: 	part_config.fetch(2,true))
	end
end

# Now Bicycle can use composition. The following code replaces the inheritance
# code from chapter 6.
class Bicycle
	attr_reader :size, :parts
	def initialize(args={})
		@size 	= args[:size]
		@parts 	= args[:parts]
	end
	def spares
		parts.spares
	end
end

require 'forwardable'
class Parts
	extend Forwardable
	def_delegators :@parts, :size, :each
	include Enumerable

	def initialize(parts)
		@parts = parts
	end
	def spares
		select { |part| part.needs_spare }
	end
end

require 'ostruct'
module PartsFactory
	def self.build(config, parts_class = Parts)
		parts_class.new(config.collect {|part_config| create_part(part_config)})
	end

	def self.create_part(part_config)
		OpenStruct.new(
			name: 				part_config[0],
			description: 	part_config[1],
			needs_spare: 	part_config.fetch(2,true))
	end
end

road_config = [['chain', '10-speed'],
							 ['tire_size', '23'],
							 ['tape_color', 'red']]
mountain_config = [['chain', '10-speed'],
									 ['tire_size', '2.1'],
									 ['front_shock', 'Manitou', false],
									 ['rear_shock', 'Fox']]
# Main difference: spares now returns array of Part-like objects instead of a hash
road_bike = Bicycle.new(size: 'L', parts: PartsFactory.build(road_config))
road_bike.spares
# -> [#<OpenStruct PartsFactory::Part name="chain", etc ...
mountain_bike = Bicycle.new(size: 'L', parts: PartsFactory.build(mountain_config))
mountain_bike.spares
# -> [#<OpenStruct PartsFactory::Part name="chain", etc ...

# With this setup, it's now easier to create a new kind of bike. Instead of the
# 19 lines of code required in chapter 6, it's now:
recumbent_config = [['chain', '9-speed'],
										['tire_size', '28'],
										['flag', 'tall and orange']]
# 19 down to 3.
recumbent_bike = Bicycle.new(size: 'L', parts: PartsFactory.build(recumbent_config))
recumbent_bike.spares
# [#<OpenStruct PartsFactory::Part
#   name="chain",
#   description="9-speed",
#   needs_spare=true>,
# #<OpenStruct PartsFactory::Part
#   name="tire_size",
#   description="28",
#   needs_spare=true>,
# #<OpenStruct PartsFactory::Part
#   name="flag",
#   description="tall and orange",
#   needs_spare=true>]
# We can now create a bike simply be defining its parts.

# One term that needs to be defined is Aggregation. When a Bike is destroyed, all
# of the Parts are gone. However, when a university's department is destroyed, the
# Professors of that department still go one. The first example is Composition, the
# latter is Aggregation.

# It's good to know the pros and cons of Inheritance design, Module design,
# and Composition design. Some good quotes:
# “Inheritance is specialization.”
# “Inheritance is best suited to adding functionally to existing classes when
# you will use most of the old code and add relatively small amounts of new code.”
# “Use composition when the behavior is more than the sum of it’s parts.”

# In general, use Inheritance and/or Module when it's a is-a relationship. Use
# Composition when it's a has-a relationship.
# Example: If there were lots of different kind of shocks, would use Inheritance
# since the basic shock functionality is only changed a little by each shock type.
# Example: Bikes have shocks, tires, gears, etc. This would be a has-a relationship,
# thus use Composition.

# Don't worry if you make the wrong design decision. It comes with experience. Just
# keep practicing and keep refactoring.
