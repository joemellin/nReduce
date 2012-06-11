# Create default user

unless User.where(:email => 'josh@nreduce.com').count > 0
  u = User.new(:name => 'Josh', :email => 'josh@nreduce.com', :password => 'bHAxMBr8', :password_confirmation => 'bHAxMBr8')
  u.admin = true
  u.save
end

# Seed from exported yaml files on old site

authentications = YAML.load_file("#{RAILS_ROOT}/lib/data/authentications.yml")

unless authentications.blank?
  authentications.each do |a|
    

  end

  @user = User.new

  # Attributes for the user
  @attrib = {
    :name       => "Test1 name",
    :surname    => "Test1 surname",
    :email      => "test1@test1.test1"
  }

  # Use 'send' to call the attributes= method on the object and ignore attr_accesible limitations
  @user.send :attributes=, @attrib, false

  # Save the object
  @user.save
end