Backup::Model.new(:db_backup, 'A sample backup configuration') do

  split_into_chunks_of 4000

  database MySQL do |database|
    database.name               = 'nreduce_production'
    database.username           = 'DATABASE_USERNAME'
    database.password           = 'DATABASE_PASSWORD'
    database.skip_tables        = ['logs']
    database.additional_options = ['--single-transaction', '--quick']
  end

  compress_with Gzip do |compression|
    compression.best = true
  end

  encrypt_with OpenSSL do |encryption|
    encryption.password = 'ENCRYPTION_PASSWORD'
  end

  store_with S3 do |s3|
    s3.access_key_id      = Settings.aws.s3.access_key_id
    s3.secret_access_key  = Settings.aws.s3.secret_access_key
    s3.region             = 'us-east-1'
    s3.bucket             = 'nreduce_backup'
    s3.keep               = 20
  end

  notify_by Mail do |mail|
    mail.on_success = false
    mail.on_warning = true
    mail.on_failure = true
  end
end