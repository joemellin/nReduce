require 'spec_helper'

describe Relationship do
  before :each do
    @startup1 = FactoryGirl.create(:startup)
    @startup2 = FactoryGirl.create(:startup, :name => 'Facebook for Ferrets')
    @relationship = Relationship.start_between(@startup1, @startup2, :startup_startup)
  end

  it "should add a startup in a relationship" do
    @relationship.pending?.should be_true
  end

  it "should approve a startup in a relationship" do
    @relationship.approve!
    Relationship.where(:entity_id => @startup1.id, :entity_type => 'Startup', :connected_with_id => @startup2.id, :connected_with_type => 'Startup', :status => Relationship::APPROVED).count.should == 1
    @startup1.connected_to?(@startup2).should be_true
  end

  it "should reject a startup in a relationship" do
    @relationship.reject!
    @startup1.connected_to?(@startup2).should be_false
  end

  it "should add a mentor to a startup" do
    mentor = FactoryGirl.create(:mentor)
    relationship = Relationship.start_between(@startup1, mentor, :startup_mentor)
    relationship.approve!.should be_true
    Relationship.between(@startup1, mentor).approved?.should be_true
    @startup1.connected_to?(mentor).should be_true
  end

  # it "should do a performance test" do
  #   require 'benchmark'
  #   # Test one-sided relationship
  #   1.upto(1000000) do |i|
  #     id1 = Random.rand(1..5000000)
  #     id2 = Random.rand(1..5000000)
  #     Relationship.transaction do
  #       Relationship.create(:startup_id => id1, :connected_with_id => id2, :status => Relationship::APPROVED)
  #     end
  #   end

  #   puts "For single relationship just using integer ids"
  #   Benchmark.benchmark(10) do |x|
  #     1.upto(10) do |i|
  #       id = Random.rand(1..5000000)
  #       x.report("ALL for #{id}"){ Relationship.where(:startup_id => id).all }
  #     end
  #     1.upto(10) do |i|
  #       id1 = Random.rand(1..5000000)
  #       id2 = Random.rand(1..5000000)
  #       x.report("ONE btw #{id1} - #{id2}"){ Relationship.where(:startup_id => id).where(:connected_with_id => id2).all }
  #     end
  #   end

  #   puts "For relationships with inverse just using integer ids"

  #   # Create inverse relationships
  #   Relationship.transaction do
  #     Relationship.all.each{|r| Relationship.create(:startup_id => r.connected_with_id, :connected_with_id => r.entity_id, :status => Relationship::APPROVED)}
  #   end

  #   # Test using inverse relationship
  #   Benchmark.benchmark(10) do |x|
  #     1.upto(10) do |i|
  #       id = Random.rand(1..5000000)
  #       x.report("ALL for #{id}"){ Relationship.where(:startup_id => id).all }
  #     end
  #     1.upto(10) do |i|
  #       id1 = Random.rand(1..5000000)
  #       id2 = Random.rand(1..5000000)
  #       x.report("ONE btw #{id1} - #{id2}"){ Relationship.where(:startup_id => id, :connected_with_id => id2).all }
  #     end
  #   end

  #   # Test using object classes with string
  #   Relationship.delete_all

  #   # One sided
  #   puts "Creating relationships with object types"
  #   1.upto(1000000) do |i|
  #     id1 = Random.rand(1..5000000)
  #     id2 = Random.rand(1..5000000)
  #     class1 = ['Startup', 'User'][id1 % 2]
  #     class2 = ['Startup', 'User'][id2 % 2]
  #     Relationship.transaction do
  #       Relationship.create(:entity_id => id1, :entity_type => class1, :connected_with_id => id2, :connected_with_type => class2, :status => Relationship::APPROVED)
  #     end
  #   end

  #   puts "Testing with object types"
  #   Benchmark.benchmark(10) do |x|
  #     1.upto(10) do |i|
  #       id = Random.rand(1..5000000)
  #       klass = ['Startup', 'User'][id % 2]
  #       x.report("ALL for #{id}"){ Relationship.where(:entity_id => id, :entity_type => klass).all }
  #     end
  #     1.upto(10) do |i|
  #       id1 = Random.rand(1..5000000)
  #       id2 = Random.rand(1..5000000)
  #       class1 = ['Startup', 'User'][id1 % 2]
  #       class2 = ['Startup', 'User'][id2 % 2]
  #       x.report("ONE btw #{id1} - #{id2}"){ Relationship.where(:entity_id => id, :entity_type => class1, :connected_with_id => id2, :connected_with_type => class2).all }
  #     end
  #   end
  # end
end
