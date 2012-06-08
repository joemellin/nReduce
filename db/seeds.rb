# Create default user

u = User.new(:name => 'Josh', :email => 'josh@nreduce.com', :password => 'bHAxMBr8', :password_confirmation => 'bHAxMBr8')
u.admin = true
u.save