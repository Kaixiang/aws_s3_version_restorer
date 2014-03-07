module AwsS3VersionRestorer
  class AwsS3Helper
    class << self
      attr_accessor :s3, :bucket_name, :bucket

      def config(key_id, sec_id, bucket_name)
        AWS.config({
          :access_key_id => key_id, 
          :secret_access_key => sec_id,
        })

        @s3 = AWS::S3.new
        @bucket_name = bucket_name

        raise 'not exist bucket' unless @s3.buckets[bucket_name].exists?
        raise 'not a versinized bucket' unless @s3.buckets[bucket_name].versioning_enabled?

        @bucket = @s3.buckets[bucket_name]
      end

      def restored_objects(datetime)
        raise 'no bucket configured' if @bucket.nil?
        restored_objs = []
        @bucket.objects.each do |obj|
          res_obj = {}
          res_obj[:retain_versions] = []
          res_obj[:discard_versions] = []

          obj.versions.each do |obj_version|
            if obj_version.last_modified > datetime
              res_obj[:discard_versions] << obj_version
            else
              res_obj[:retain_versions] << obj_version
            end
          end

          unless res_obj[:discard_versions].empty?
            res_obj[:obj] = obj
            restored_objs << res_obj
          end
        end
        restored_objs
      end

    end
  end
end
