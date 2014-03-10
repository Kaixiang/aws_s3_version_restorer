module AwsS3VersionRestorer::Spec
  class S3_Spec_Helper
    attr_accessor :s3

    def init(aws_key_id, aws_sec_key)
      AWS.config({
        :access_key_id => aws_key_id,
        :secret_access_key => aws_sec_key,
      })
      @s3 = AWS::S3.new
    end

    def setup_test_bucket(bucket_name, version = true)
      raise 'the bucket already exist' if s3.buckets[bucket_name].exists?
      bucket = @s3.buckets.create(bucket_name)
      bucket.enable_versioning if version
    end

    def clear_test_bucket(bucket_name)
      raise 'the bucket not exist' unless s3.buckets[bucket_name].exists?
      bucket = s3.buckets[bucket_name]
      bucket.clear!
      bucket.delete!
    end

    def upload_blob(bucket_name, blob_name, content)
      raise 'the bucket not exist' unless s3.buckets[bucket_name].exists?
      bucket = @s3.buckets[bucket_name]
      bucket.objects.create(blob_name, content)
    end

    def delete_blob(bucket_name, object)
      raise 'the bucket not exist' unless s3.buckets[bucket_name].exists?
      bucket = @s3.buckets[bucket_name]
      raise 'obj not exist' unless bucket.objects[object].exists?
      bucket.objects[object].delete
    end

    def object_content(bucket_name, object)
      raise 'the bucket not exist' unless s3.buckets[bucket_name].exists?
      bucket = s3.buckets[bucket_name]
      raise 'obj not exist' unless bucket.objects[object].exists?
      bucket.objects[object].read
    end

  end
end
