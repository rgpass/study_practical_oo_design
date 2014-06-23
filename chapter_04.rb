# CREATING FLEXIBLE INTERFACES
# Interfaces in this sense is how a class operates with your class.
# So public interface would be public methods and private interface
# would be private methods.

# Public Interfaces:
# a. reveal its primary responsibility
# b. are expected to be invoked by others
# c. will not change on a whim
# d. are safe for others to depend on
# e. are thorougly documented in the tests

# Private Interfaces:
# a. handle implementation details
# b. are not expected to be sent by other objects
# c. can change for any reason whatsoever
# d. are unsafe for others to depend on
# e. may not even be referenced in the tests

# When starting a project, think of each noun as a new class.
# Customer, User, Bicycle, Trip, Route
# Anything that has both data and behavior is a class. These are
# called Domain Objects.
# Do not focus on Domain Objects though. It's more important to
# focus on the messages that pass between them.

# Create Sequence Diagrams to figure out how they will communicate.
# These allow you to see what classes you'll really need (some of
# the Domain Objects plus some new ones). Typically have done
# Data Models after the Wireframe, but it may be better to do a
# Sequence Model between the two.

# Public Methods should:
# a. be explicitly identified as such
# b. be more about what than how
# c. have names that, insofar as you can anticipate, will not change
# d. take a hash as an options parameter

# Listen to the Law of Demeter. Only use one dot for method calls.
# Bad: customer.trips.bicycles.clean
# If you ever experience this, immediately write out a Sequence
# Diagram. This will help you go from an object-focused design to
# a message-focused design.

