# encoding: utf-8

##
# Backup
# Generated Main Config Template
#
# For more information:
#
# View the Git repository at https://github.com/meskyanichi/backup
# View the Wiki/Documentation at https://github.com/meskyanichi/backup/wiki
# View the issue log at https://github.com/meskyanichi/backup/issues

##
# Global Configuration
# Add more (or remove) global configuration below

Backup::Database::MySQL.defaults do |database|
  database.username           = 'DATABASE_USERNAME'
  database.password           = 'DATABASE_PASSWORD'
end

Backup::Storage::S3.defaults do |s3|
  s3.access_key_id      = Settings.aws.s3.access_key_id
  s3.secret_access_key  = Settings.aws.s3.secret_access_key
  s3.region             = 'us-east-1'
end

Backup::Encryptor::OpenSSL.defaults do |encryption|
  encryption.password_file = '/path/to/password_file'
  encryption.base64   = true
  encryption.salt     = true
end

Backup::Notifier::Mail.defaults do |mail|
  mail.from                 = 'notifiations@nreduce.com'
  mail.to                   = 'josh@nreduce.com'
  mail.address              = 'smtp.gmail.com'
  mail.port                 = 587
  mail.domain               = 'mydomain.com'
  mail.user_name            = 'donotreply@mydomain.com'
  mail.password             = 'password'
  mail.authentication       = 'plain'
  mail.enable_starttls_auto = true
end

##
# Load all models from the models directory (after the above global configuration blocks)
Dir[File.join(File.dirname(Config.config_file), "models", "*.rb")].each do |model|
  instance_eval(File.read(model))
end
