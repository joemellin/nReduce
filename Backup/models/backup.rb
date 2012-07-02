Backup::Model.new(:db_backup, 'MySQL database backup') do

  split_into_chunks_of 4000

  database MySQL do |database|
    database.name               = 'nreduce_production'
    #database.skip_tables        = ['user_actions']
    database.additional_options = ['--single-transaction', '--quick']
  end

  compress_with Gzip do |compression|
    compression.level = 9
  end

  encrypt_with OpenSSL

  store_with S3 do |s3|
    s3.bucket             = 'nreduce_backup'
    s3.keep               = 20
  end

  notify_by Mail do |mail|
    mail.on_success = false
    mail.on_warning = true
    mail.on_failure = true
  end
end