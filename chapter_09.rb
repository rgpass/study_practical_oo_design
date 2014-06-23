# DESIGNING COST-EFFECTIVE TESTS
# Writing changeable code requires three things:
# 1. Understanding OO design -- keeping in mind that changeable code is the only
# design metric that matters, need to know concepts of OOD.
# 2. Must know how to refactor -- "Refactoring is the process of changing a 
# software system in such a way that it does not alter the external behavior of 
# the code yet improves the internal structure."
# 3. Learn the art of writing high-value tests -- only through high-value tests
# can you constantly refactor and improve the design. Should be able to alter the
# code without having to write new tests.

# Tests not only reduce bugs and provide documentation, they reduce costs. Without
# tests, more time is spend reducing bugs and writing documentation.

# Writing tests at first will seem like the costs outweigh the benefits. The solution
# is not to stop writing tests but to get better at writing them. Learn what, when
# and how to test.

# Tests:
# 1. Help find bugs early on, significantly lowering costs
# 2. Supply documentation. Assume you will have amnesia -- tests are the best docs!
# 3. Can defer design decisions until more information arrives
# 4. When more information does arrive, if you are writing good tests you'll be able
# to see the whole picture easier. This enables you to see abstractions easier.
# 5. Exposes dependencies. If they're hard to write, there's probably a reason.

# Tests should only focus on the incoming and outgoing messages of the object
# being tested. Are the correct inputs being used? What happens when an incorrect
# input is used? Are the output messages correct?

# Tests should only be on the public interface.

# There are two kinds of outgoing messages.
# 1. Queries -- DO NOT need to be tested -- when a sender sends a message and expects
# back a response, but nothing else in the app cares.
# 2. Commands -- DO need to be tested -- when there are side effects, such as a
# new entry in a database, a file is written, action is taken.

# Incoming messages should be tested for the state they return.

# Always aim to write tests first, no matter how hard it is or how much you disagree
# with the costs.

# BDD and TDD are different approaches to the same problem.
# BDD: Behavior Driven Development looks to go outside-in
# TDD: Test Driven Development looks to go inside-out

# Try to make your tests know nothing about the rest of the application.

# Starting from code found in chapter 3. Running tests with MiniTest.
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
class Gear
	attr_reader :chainring, :cog, :rim, :tire
	def initialize(args)
    @chainring = args[:chainring]
    @cog       = args[:cog]
    @rim       = args[:rim]
    @tire      = args[:tire]
	end
	def gear_inches
		ratio * Wheel.new(rim, tire).diameter
	end
	def ratio
		chainring / cog.to_f
	end
	# ...
end
# If this code had any methods that no object depended on, it would be deleted.
# Erasing code and retrieving it is much less costly than keeping unused code.

# The first requirement of any incoming message is to confirm that it returns the
# correct value in every possible situation.
class WheelTest < MiniTest::Unit::TestCase
	def test_calculates_diameter
		wheel = Wheel.new(26, 1.5)
		assert_in_delta(29, wheel.diameter, 0.01)
	end 
end
# diameter has no external dependencies, so this test is simple.
class GearTest < MiniTest::Unit::TestCase
	def test_calculates_gear_inches 
		gear = Gear.new(chainring: 52, cog: 11, rim: 26, tire: 1.5)
		assert_in_delta(137.1, gear.gear_inches, 0.01)
	end
end
# This doesn't look any more complicated, but it is since Gear has a dependency
# on Wheel. The fact that a Wheel instance has to be created can have serious
# performance impacts on the code. If Wheel is a huge class, this will take time.
# Also, if Wheel is broken but Gear is fine, this test will fail. Making you investigate
# Gear instead of the real issue. In this example, this is not a big deal, but
# in enterprise-level code, this can be significant.

class Gear
	attr_reader :chainring, :cog, :wheel
	def initialize(args)
    @chainring = args[:chainring]
    @cog       = args[:cog]
    @wheel     = args[:wheel]
	end
	def gear_inches
		# The object in the'wheel' variable # plays the 'Diameterizable' role.
    ratio * wheel.diameter
	end
	def ratio
	chainring / cog.to_f
	end
	# ...
end
# This version of the code does not create a new object. Also, it does not care
# about the new object, just the fact that it responds to diameter.
# The test becomes:
class GearTest < MiniTest::Unit::TestCase
	def test_calculates_gear_inches
		gear = Gear.new(chainring: 52,
										cog: 11,
										wheel: Wheel.new(26, 1.5))
		assert_in_delta(137.1, gear.gear_inches, 0.01)
	end
end
# Now looking at this test and code, it isn't Wheel the matters, it's just anything
# that responds to diameter. Thus, we could call it Diameterizable.new
# It's not obvious that Wheel is playing a Diameterizable role and it's coupled
# to the Gear class.
# This coupling is OK for specific cases, but when going abstract it is not good enough.


# Sometimes it makes sense to use a test double to make sense of dependencies.
# Create a player of the ‘Diameterizable’ role
class DiameterDouble
  def diameter
  	10
  end
end
class GearTest < MiniTest::Unit::TestCase
	def test_calculates_gear_inches
		gear = Gear.new(chainring: 52,
										cog: 11,
										wheel: DiameterDouble.new)
		assert_in_delta(47.27, gear.gear_inches, 0.01)
	end
end
# Test Doubles are used solely to help with testing. It is essentially a stub.
# The issue with test doules is that if you change the Gear code to require
# wheel.width insted of wheel.diameter, the program fails but the test passes.
# This should be addressed in WheelTest.
class WheelTest < MiniTest::Unit::TestCase
	def setup
		@wheel = Wheel.new(26, 1.5)
	end
	def test_implements_the_diameterizable_interface
		assert_respond_to(@wheel, :diameter)	# Right here
	end
	def test_calculates_diameter
		wheel = Wheel.new(26, 1.5)
		assert_in_delta(29, wheel.diameter, 0.01)
	end
end
# This actually does not give a good enough solution. Refer to Testing
# Duck Types below.

# When it comes to private methods, don't test them. They're unstable and 
# unnecessary to know from outside. It's actually a code smell to have lots
# of private methods since that probably means the class is doing too much.
# When it comes to private methods:
# The rules-of-thumb for testing private methods are thus: Never write them, 
# and if you do, never ever test them, unless of course it makes sense to do so.

# Do not test outgoing query messages. An example would be wheel.diameter --
# the tests proving that diameter works correctly belongs in WheelTest. The
# tests that prove gear_inches works correctly belongs in GearTest.

# However, do test outgoing command messages.
# The new example is that this app is used for a virtual racing game. The
# application must now know when the gear changes.
class Gear
	attr_reader :chainring, :cog, :wheel, :observer
	def initialize(args)
		# ...
		observer = args[:observer]
	end
	# ...
	def set_cog(new_cog)
		@cog = new_cog
		changed
	end
	def set_chainring(new_chainring)
		@chainring = new_chainring
		changed
	end
	def changed
		observer.changed(chainring, cog)
	end
end
# We want to test that changed is sent to observer and we don't need to
# care about what is returned from this method call. To do this, we use a mock
# which simulates behavior rather than simulating state.
class GearTest < MiniTest::Unit::TestCase
	def setup
		@observer = MiniTest::Mock.new
		@gear = Gear.new( chainring: 52, cog: 11, observer: @observer)
	end
	def test_notifies_observers_when_cogs_change
		@observer.expect(:changed, true, [52, 27])
		@gear.set_cog(27)
		@observer.verify
	end
	def test_notifies_observers_when_chainrings_change
		@observer.expect(:changed, true, [42, 11])
		@gear.set_chainring(42)
		@observer.verify
	end
end
# This is the classical way to use a mock. Mocks are used to prove that messages
# get sent. In this case, we're expecting observer.changed to receive a message
# when given those params, we then send the params via set_cog or set_chainring,
# then we verify that the message was sent.
# Although we define what the mock should return (true), we don't really care.


# For testing Duck Types, we start at:
class Trip
	attr_reader :bicycles, :customers, :vehicle
	def prepare(preparers)
		preparers.each {|preparer| preparer.prepare_trip(self)} 
	end
end
# Think of Trip as a Preparable and the Mechanic, TripCoordinator, and Driver
# as Preparers. Tests should document the existence of each Preparer role, that
# each of them behave correctly, and that they interact with Trip correctly.
# Because several classes act as Preparers, their tests should be shared.
module PreparerInterfaceTest
	def test_implements_the_preparer_interface
		assert_respond_to(@object, :prepare_trip)
	end
end
class MechanicTest < MiniTest::Unit::TestCase
	include PreparerInterfaceTest
	def setup
		@mechanic = @object = Mechanic.new
	end
	# other tests which rely on @mechanic
end
# This way you write the test once, use it in each role it is applicable, and
# provide substaintial documentation on its purpose.
# Now to test that Trip properly sends the prepare_trip method.
class TripTest < MiniTest::Unit::TestCase
	def test_requests_trip_preparation
		@preparer = MiniTest::Mock.new
		@trip = Trip.new
		@preparer.expect(:prepare_trip, nil, [@trip])

		@trip.prepare([@preparer])
		@preparer.verify
	end
end


# We're now prepared to handle the false positive that happened with the
# stub from before. We can pull the code into a module of itself.
module DiameterizableInterfaceTest
	def test_implements_the_diameterizable_interface
		assert_respond_to(@object, :width)
	end
end
class WheelTest < MiniTest::Unit::TestCase 
	include DiameterizableInterfaceTest
	def setup
		@wheel = @object = Wheel.new(26, 1.5)
	end
	def test_calculates_diameter 
		# ...
	end
end
# Now we can use the Test Double with confidence knowing that if the
# width method changes back to diameter or something else, it will
# still work.
class DiameterDouble
	def diameter
		10
	end
end
# Prove the test double honors the interface this # test expects.
class DiameterDoubleTest < MiniTest::Unit::TestCase
	include DiameterizableInterfaceTest
	def setup
		@object = DiameterDouble.new
	end
end
class GearTest < MiniTest::Unit::TestCase 
	def test_calculates_gear_inches
		gear = Gear.new(chainring: 52, cog: 11, wheel: DiameterDouble.new)
		assert_in_delta(47.27, gear.gear_inches, 0.01)
	end
end
# The above fails because the method is diameter when it should be width.
# The below is the fixed code.
class DiameterDouble
	def width
		10
	end
end
# However now the GearTest fails -- but this is because the real code is
# wrong, not the test code. Fixing gear_inches to refer to width and not
# diameter fixes this.


# Testing Inherited Code -- starting from the code in chapter 6.
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

# The first goal is to prove the Liskov Substitution Principle.
# The easiest way to prove this is by creating a module for the super
# and including it in each sub.
module BicycleInterfaceTest
  def test_responds_to_default_tire_size
		assert_respond_to(@object, :default_tire_size)
	end
	def test_responds_to_default_chain
		assert_respond_to(@object, :default_chain)
	end
	def test_responds_to_chain
		assert_respond_to(@object, :chain)
	end
	def test_responds_to_size
		assert_respond_to(@object, :size)
	end
	def test_responds_to_tire_size
		assert_respond_to(@object, :size)
	end
	def test_responds_to_spares
		assert_respond_to(@object, :spares)
	end
end
class RoadBikeTest < MiniTest::Unit::TestCase
	include BicycleInterfaceTest
	def setup
		@bike = @object = RoadBike.new
	end
end
# Since the subclasses have requirements, those should be tested as well.
module BicycleSubclassTest
	def test_responds_to_post_initialize
		assert_respond_to(@object, :post_initialize) 
	end
	def test_responds_to_local_spares 
		assert_respond_to(@object, :local_spares)
	end
	def test_responds_to_default_tire_size 
		assert_respond_to(@object, :default_tire_size)
	end
end
class RoadBikeTest < MiniTest::Unit::TestCase 
	include BicycleInterfaceTest
	include BicycleSubclassTest
	def setup
		@bike = @object = RoadBike.new
	end 
end

# The Bicycle class should raise an error if a tire_size is not supplied.
# Although this is a requirement of the sub, it needs to be tested in Bicycle.
class BicycleTest < MiniTest::Unit::TestCase
	include BicycleInterfaceTest
	def setup
		@bike = @object = Bicycle.new({tire_size: 0})
	end
	def test_forces_subclasses_to_implement_default_tire_size 
		assert_raises(NotImplementedError) {@bike.default_tire_size}
	end
end
# Typically it is much harder to create an instance of an abstract class. This
# is discussed later.

# Testing subclass specific behavior:
class RoadBikeTest < MiniTest::Unit::TestCase include BicycleInterfaceTest
	include BicycleSubclassTest
	def setup
		@bike = @object = RoadBike.new(tape_color: ‘red’)
	end
	def test_puts_tape_color_in_local_spares 
		assert_equal ‘red’, @bike.local_spares[:tape_color]
	end
end
# No need to test the spares method -- this is already done.

# Testing abstract superclass behavior:
# Because of our template method pattern and the Liskov principle, we can 
# create a stubbed bike to return necessary behavior provided by the sub.
class StubbedBike < Bicycle 
	def default_tire_size
		0 
	end
	def local_spares 
		{saddle: 'painful'}
	end 
end
class BicycleTest < MiniTest::Unit::TestCase 
	include BicycleInterfaceTest
	def setup
		@bike = @object = Bicycle.new({tire_size: 0}) 
		@stubbed_bike = StubbedBike.new
	end
	def test_forces_subclasses_to_implement_default_tire_size 
		assert_raises(NotImplementedError) { @bike.default_tire_size} 
	end
	def test_includes_local_spares_in_spares 
		assert_equal @stubbed_bike.spares,
			{ tire_size: 0, chain: '10-speed', saddle: 'painful'}
	end 
end
# To make sure that StubbedBike does not become obsolete, you can include
# BicycleSubclassTest for it.
class StubbedBikeTest < MiniTest::Unit::TestCase
	include BicycleSubclassTest
	def setup
		@object = StubbedBike.new
	end 
end

# Writing tests for inheritable classes is easy. Write one set for overall
# interface and another for subclass responsibilities. Make sure to isolate
# responsibilities and don't let superclasses knowledge trickle down to the sub.
