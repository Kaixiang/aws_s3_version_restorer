require "spec_helper"

describe AwsS3VersionRestorer::AwsS3Helper, aws_credentials: true do

  def detect_object(object, key)
    object.detect { |k|
      k[:obj].key == key
    }
  end

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

  TEST_BUCKET_NAME = 'this_is_a_test_bucket_name_from_aws_s3_version_restorer'
  TEST_BLOB = 'test_blob'

  before :all do
    @s3_helper = AwsS3VersionRestorer::Spec::S3_Spec_Helper.new
    @s3_helper.init(aws_key_id, aws_sec_key)
  end

  context 'iterate S3 bucket' do

    before :all do
      @s3_helper.setup_test_bucket(TEST_BUCKET_NAME)
      @s3_helper.upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version1')
      @time_s1 = DateTime.now
      sleep 5
      @s3_helper.upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version2')
      described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME)
    end

    after :all do
      @s3_helper.clear_test_bucket(TEST_BUCKET_NAME)
    end

    it 'should list objects need to be restored according to time modified' do
      objs = described_class.restored_objects(@time_s1)
      detect_object(objs, TEST_BLOB).should_not be_nil
      objs = described_class.restored_objects(DateTime.now)
      detect_object(objs, TEST_BLOB).should be_nil
    end

    it 'should restore objects to previous version' do
      expect(@s3_helper.object_content(TEST_BUCKET_NAME, TEST_BLOB)).to eq('version2')
      objs = described_class.restored_objects(@time_s1)
      described_class.do_restore(objs)
      expect(@s3_helper.object_content(TEST_BUCKET_NAME, TEST_BLOB)).to eq('version1')
    end
  end

  context 'iterate S3 bucket with deletion version' do

    it 'should delete objects if previous version is a delete mark' do
    end

    it 'should delete objects if the restored date is before the first version creation time' do
    end

  end

  context 'error handlings' do
    it 'should raise error when bucket_name not exist' do
      expect { described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME) }.to raise_error("not exist bucket")
    end

    it 'should raise error when not a versioning bucket' do
      @s3_helper.setup_test_bucket(TEST_BUCKET_NAME, false)
      expect { described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME) }.to raise_error("not a versinized bucket")
      @s3_helper.clear_test_bucket(TEST_BUCKET_NAME)
    end

  end

end
