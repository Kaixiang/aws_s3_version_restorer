module AwsS3VersionRestorer
  class AwsS3Helper
    class << self
      attr_accessor :key_id, :sec_id, :bucket_name

      def config(key_id, sec_id, bucket_name)
        @key_id = key_id
        @sec_id = sec_id
        @bucket_name = bucket_name

        aws_init

        raise 'not exist bucket' unless @s3.buckets[bucket_name].exists?
        raise 'not a versinized bucket' unless @s3.buckets[bucket_name].versioning_enabled?
      end

      # Split the restore process into 2 process to give user the chance to track
      def restored_objects(datetime)
        aws_init
        restored_objs = {}
        @bucket.versions.each do |version|
          if restored_objs[version.object.key].nil?
            restored_objs[version.object.key] = {}
            restored_objs[version.object.key][:obj] = version.object
            restored_objs[version.object.key][:retain_versions] = []
            restored_objs[version.object.key][:discard_versions] = []
          end

          if version.last_modified > datetime
            restored_objs[version.object.key][:discard_versions] << version
          else
            restored_objs[version.object.key][:retain_versions] << version
          end
        end

        # no action if no discard_versions found
        restored_objs.each do |key, value|
          if value[:discard_versions].empty?
            restored_objs.delete(key)
          end
        end

        restored_objs
      end

      # This is the actual restore
      def do_restore(restore_obj)
        aws_init
        restore_obj.each do |key, value|
          if value[:retain_versions].empty?
           # discard all version
            value[:obj].delete
          else
            value[:retain_versions].sort_by! { |x| x.last_modified }
            restore_to = value[:retain_versions].last
            if restore_to.delete_marker?
              value[:obj].delete
            else
              # Don't remove any version, overwrite it with the content so we can roll back
              # TODO: streaming content, + log the process + restore from fail point
              @bucket.objects.create(key, restore_to.read)
            end
          end
        end
      end

      private

      def aws_init
        raise 'no key_id found' if @key_id.nil?
        raise 'no key_id found' if @sec_id.nil?
        raise 'no bucket configured' if @bucket_name.nil?

        AWS.config({
          :access_key_id => @key_id, 
          :secret_access_key => @sec_id,
        })

        @s3 = AWS::S3.new
        @bucket = @s3.buckets[@bucket_name]
      end

    end
  end
end
