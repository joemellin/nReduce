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

Backup::Configuration::Database::MySQL.defaults do |database|
  database.username           = 'DATABASE_USERNAME'
  database.password           = 'DATABASE_PASSWORD'
end

Backup::Configuration::Storage::S3.defaults do |s3|
  s3.access_key_id      = Settings.aws.s3.access_key_id
  s3.secret_access_key  = Settings.aws.s3.secret_access_key
  s3.region             = 'us-east-1'
end

Backup::Configuration::Encryptor::OpenSSL.defaults do |encryption|
  encryption.password = 'ENCRYPTION_PASSWORD'
  encryption.base64   = true
  encryption.salt     = true
end

##
# Load all models from the models directory (after the above global configuration blocks)
Dir[File.join(File.dirname(Config.config_file), "models", "*.rb")].each do |model|
  instance_eval(File.read(model))
end
