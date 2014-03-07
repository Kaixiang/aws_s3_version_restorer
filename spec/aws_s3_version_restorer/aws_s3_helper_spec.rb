require "spec_helper"

describe AwsS3VersionRestorer::AwsS3Helper, aws_credentials: true do

  def aws_key_id
    key = ENV['AWSAccessKeyId']
    raise 'need to setup AWSAccessKeyId environment variable' unless key
    key
  end

  def aws_sec_key
    key = ENV['AWSSecretKey']
    raise 'need to setup AWSSecretKey environment variable' unless key
    key
  end

  def setup_test_bucket(bucket_name, version = true)
    AWS.config({
      :access_key_id => aws_key_id,
      :secret_access_key => aws_sec_key,
    })
    s3 = AWS::S3.new
    raise 'the bucket already exist' if s3.buckets[bucket_name].exists?
    bucket = s3.buckets.create(bucket_name)
    bucket.enable_versioning if version
  end
  
  def upload_blob(bucket_name, blob_name, content)
     AWS.config({
      :access_key_id => aws_key_id,
      :secret_access_key => aws_sec_key,
    })
    s3 = AWS::S3.new
    raise 'the bucket not exist' unless s3.buckets[bucket_name].exists?
    bucket = s3.buckets[bucket_name]
    bucket.objects.create(blob_name, content)
  end

  def clear_test_bucket(bucket_name)
    AWS.config({
      :access_key_id => aws_key_id,
      :secret_access_key => aws_sec_key,
    })
    s3 = AWS::S3.new
    raise 'the bucket not exist' unless s3.buckets[bucket_name].exists?
    bucket = s3.buckets[bucket_name]
    bucket.clear!
    bucket.delete!
  end

  def detect_object(object, key)
    object.detect { |k| 
      k[:obj].key == key
    }
  end

  TEST_BUCKET_NAME = 'this_is_a_test_bucket_name_from_aws_s3_version_restorer'
  TEST_BLOB = 'test_blob'

  context 'iterate S3 bucket' do

    before :all do
      setup_test_bucket(TEST_BUCKET_NAME)
      described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME)
    end

    after :all do
      clear_test_bucket(TEST_BUCKET_NAME)
    end

    it 'should list objects need to be restored according to time modified' do
      upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version1')
      datetime = DateTime.now
      sleep 5
      upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version2')
      objs = described_class.restored_objects(datetime)
      detect_object(objs, TEST_BLOB).should_not be_nil
      objs = described_class.restored_objects(DateTime.now)
      detect_object(objs, TEST_BLOB).should be_nil
    end
  end

  context 'error handlings' do

    it 'should raise error when bucket_name not exist' do
      expect { described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME) }.to raise_error("not exist bucket")
    end

    it 'should raise error when not a versioning bucket' do
      setup_test_bucket(TEST_BUCKET_NAME, false)
      expect { described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME) }.to raise_error("not a versinized bucket")
      clear_test_bucket(TEST_BUCKET_NAME)
    end

  end


end
