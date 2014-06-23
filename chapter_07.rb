# SHARING ROLE BEHAVIOR WITH MODULES
# Perpendicular in thought, a role is different than a class.

# The total set of messages to which an object can respond:
# * Those it implements
# * Those implemented in all objects above it in the hierarchy
# * Those implemented in any module that has been added to it
# * Those implemented in all modules added to any object above it in the hierarchy

# Scenario: Want to add a Schedule class that also knows how long
# each Preparer needs inbetween trips (resting, maintenance, etc).

# The best way to write Role code (aka Modules) is to put the code into
# one of the concrete classes, then analyze what is shared. For example,
# write it inside Bicycle, then pull it out to Schedulable.
class Schedule
	def scheduled?(schedulable, start_date, end_date)
		puts 	"This #{schedulable.class} " +
					"is not scheduled\n" + 
					" between #{start_date} and #{end_date}"
		false
	end
end
class Bicycle
	attr_reader :schedule, :size, :chain, :tire_size

	def initialize(args={})
		@schedule = args[:schedule] || Schedule.new
		# ...
	end

	# Return true if this bicycle is available
	# during this (now Bicycle specific) interval.
	def schedulable?(start_date, end_date)
		!scheduled(start_date - lead_days, end_date)
	end

	# Return the schedule's answer
	def scheduled?(start_date, end_date)
		schedule.scheduled?(self, start_date, end_date)
	end

	# Return the number of lead_days before a bicycle # can be scheduled.
	def lead_days
		1
	end

	# ...
end

require 'date'
starting = Date.parse("2015/09/04")
ending   = Date.parse("2015/09/10")

b = Bicycle.new
b.schedulable?(starting, ending)
# This Bicycle is not scheduled
# between 2015-09-03 and 2015-09-10 
# => true


# Since Mechanic and Vehicle also need some of this behavior, we put it
# into a module
module Schedulable
	attr_writer :schedule

	def schedule
		@schedule ||= ::Schedule.new
	end

	def schedulable?(start_date, end_date)
		!scheduled(start_date - lead_days, end_date)
	end

	def scheduled?(start_date, end_date)
		schedule.scheduled?(self, start_date, end_date)
	end

	# includers may override
	def lead_days
		0
	end
end
# Notice how the module implemented its default value of lead_days. Need to
# do this because if it's forgotten/omitted, an error will occur. Can even change
# it to raise an error of your choosing.
class Bicycle
	include Schedulable

	def lead_days
		1
	end

	# ...
end
require 'date'
starting = Date.parse("2015/09/04")
ending   = Date.parse("2015/09/10")

b = Bicycle.new
b.schedulable?(starting, ending)
# This Bicycle is not scheduled
# between 2015-09-03 and 2015-09-10 
# => true


# All subclasses of abstract superclasses should share the functionality that's
# in the super. When only a portion of functionality is shared, there is an
# underlying problem.

# Subclasses should be substitutable for their superclass. As in, they respond
# to all of super's methods as super would. They can go beyond that, but should
# always at least respond to all super's methods.

# This concept is the idea behind the L in SOLID: Liskov Substitution Principle.
# This states that any subclass can be substituted for its super and where modules
# can be trusted to play the module's role.

# When working with inheritance, it's best to focus on shallow, wide models. Instead
# of having a long inheritance chain (deep), it's better to have lots of objects
# inherit from one abstract (wide).
