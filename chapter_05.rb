# REDUCING COSTS WITH DUCK TYPING
# Original code
class Trip
	attr_reader :bicycles, :customers, :vehicle
	# This 'mechanic' could be of any class
	def prepare(mechanic)
		mechanic.prepare_bicycles(bicycles)
	end
end
# If you happen to pass an instance of *this* class it works.
class Mechanic
	def prepare_bicycles(bicycles)
		bicycles.each { |bicycle| prepare_bicycle(bicycle) }
	end
	def prepare_bicycle(bicycle)
		# ...
	end
end
# Note: Mechanic class is not referenced in Trip. Any
# object could be passed through it.

# If you needed a trip coordinator and a driver, the previous
# idea that prepare knew of some object's methods gets much
# more convoluted.
class Trip
	attr_reader :bicycles, :customers, :vehicle
	def prepare(preparers)
		preparers.each { |preparer|
			case preparer
			when Mechanic
				preparer.prepare_bicycles(bicycles)
			when TripCoordinator
				preparer.buy_food(customers)
			when Driver
				preparer.gas_up(vehicle)
				preparer.fill_water_tank(vehicle)
			end
		}
	end
end
class TripCoordinator
	def buy_food(customers)
		# ...
	end
end
class Driver
	def gas_up(vehicle)
		# ...
	end
	def fill_water_tank(vehicle)
		# ...
	end
end
# Worst of all, this class is now dependent on multiple classes.
# To fix this, do not think about what methods are already in 
# each class you're invoking, but what the initial method (in this
# case, prepare) really needs. What does it need?
# It needs the trip to be prepared. By adding in a Preparer class,
# Preparer can easily call prepare_trip to each class. 

# Preparer in this sense is abstract and can be concrete by changing 
# method names.
class Trip
	attr_reader :bicycles, :customers, :vehicle
	def prepare(preparers)
		preparers.each { |preparer| preparer.prepare_trip(self) }
	end
end
# when every preparer is a Duck that responds to prepare_trip
class Mechanic
	def prepare_trip(trip)
		trip.bicycles.each { |bicycle| prepare_bicycle(bicycle) }
	end
	# ...
end
class TripCoordinator
	def prepare_trip(trip)
		buy_food(trip.customers)
	end
end
class Driver
	def prepare_trip(trip)
		vehicle = trip.vehicle
		gas_up(vehicle)
		fill_water_tank(vehicle)
	end
	# ...
end

# Polymorphism in OOP: the ability of many different objects to
# respond to the same message. Senders do not care about the class
# of the receiver; receivers supply their own specific version of
# the behavior.

# You can replace any of the following with Ducks:
# a. Case statements that switch on class
# b. kind_of? and is_a?
# c. responds_to?

# (a.) Was seen in the example above. Ask what message you're trying
# to send to each of argument.

# (b.) Rewriting the original code from above
if preparer.kind_of?(Mechanic)
	preparer.prepare_bicycles(bicycles)
elsif preparer.kind_of?(TripCoordinator)
	preparer.buy_food(customers)
elsif preparer.kind_of?(Mechanic)
	preparer.gas_up(vehicle)
	preparer.fill_water_tank(vehicle)
end
# Same concept is still there. Trust the class to do its part.

# (c.) Rewriting the original code from above
if preparer.responds_to?(:prepare_bicycles)
	preparer.prepare_bicycles(bicycle)
elsif preparer.responds_to?(:buy_food)
	preparer.buy_food(customers)
elsif preparer.responds_to?(:gas_up)
	preparer.gas_up(vehicle)
	preparer.fill_water_tank(vehicle)
end
# Same as above.
