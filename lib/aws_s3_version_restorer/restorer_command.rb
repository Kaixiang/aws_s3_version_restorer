require 'mothership'
require 'highline/import'
require 'date'

module AwsS3VersionRestorer
  class RestorerCommand < Mothership
    option :help, :desc => "Show command usage", :alias => "-h",
      :default => false

    desc "Show Help"
    input :command, :argument => :optional
    def help
      if name = input[:command]
        if cmd = @@commands[name.gsub("-", "_").to_sym]
          Mothership::Help.command_help(cmd)
        else
          unknown_command(name)
        end
      else
        Mothership::Help.basic_help(@@commands, @@global)
      end
    end

    desc "Restore s3 bucket versions to Previous date"
    input(:aws_key_id) { hint; ask("the aws key id") }
    input(:aws_sec_id) { hint; ask("the aws sec id") }
    input(:bucket) { ask("the bucket name need to restored") }
    def restore
      AwsS3Helper.config(aws_key_id(input), aws_sec_id(input), input[:bucket])
      datetime = input_date_time
      unless datetime.nil?
        objects_need_restored = AwsS3Helper.restored_objects(datetime)
        puts 'below objects versions are discarded:'
        objects_need_restored.each do |key, value|
          puts "===================="
          puts "object name: #{key}"
          puts "discarded versions:"
          value[:discard_versions].each do |version|
            puts "  version_id:   #{version.version_id}"
            puts "  modified_at:  #{version.last_modified}"
          end
        end
        if confirmed?
          AwsS3Helper.do_restore(objects_need_restored)
        end
      end
    end

    private

    def aws_key_id(input)
      key = ENV['AWSAccessKeyId']
      key = input[:aws_key_id] unless key
      key
    end

    def aws_sec_id(input)
      key = ENV['AWSSecretKey']
      key = input[:aws_sec_id] unless key
      key
    end

    def hint
      puts "[HINT] source the aws key file (env for AWSAccessKeyId,AWSSecretKey) to avoid input key"
    end

    def confirmed?(question = 'Are you sure?')
      ask("#{question} (type 'yes' to continue): ") == 'yes'
    end

    def caculate_sec(sec)
      if sec > 60
        minute = sec / 60
        _sec = sec % 60
        sec = _sec
        if minute > 60
          hour = minute / 60
          _minute = minute % 60
          minute = _minute
          if hour > 24
            day = hour / 24
            _hour = hour % 24
            hour = _hour
          end
        end
      end

      result = ''
      unless day.nil?
        result+= "#{day}days "
      end
      unless hour.nil?
        result+= "#{hour}hour "
      end
      unless minute.nil?
        result+= "#{minute}minute "
      end
      result+= "#{sec}sec "
      result
    end

    def input_date_time
      puts "Now input the date/time you want to restore the bucket object versions to"
      year = ask('Input Year:')
      month = ask('Input Month:')
      day = ask('Input Day:')
      hour = ask('Input Hour:')
      minute = ask('Input Minute:')
      second = ask('Input Seconds:')
      zone = ask('Input TimeZone(+n/-n):')

      input_time = DateTime.parse("#{year}-#{month}-#{day}T#{hour}:#{minute}:#{second}#{zone}")
      timenow = DateTime.now

      raise 'your input time is in the future' unless input_time < timenow

      time_diff = ((timenow - input_time) * 24 * 60 * 60).to_i

      puts "the time you want to restore is #{caculate_sec(time_diff)} before now"
      unless confirmed?
        input_time = nil
      end
      input_time
    end

  end
end
