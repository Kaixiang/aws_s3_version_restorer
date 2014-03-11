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

  def interval_wait
    sleep 5
  end

  def timestamp
    interval_wait
    stamp = DateTime.now
    interval_wait
    stamp
  end

  TEST_BUCKET_NAME = 'this_is_a_test_bucket_name_from_aws_s3_version_restorer'
  TEST_BLOB = 'test_blob'

  before :all do
    @s3_helper = AwsS3VersionRestorer::Spec::S3_Spec_Helper.new
    @s3_helper.init(aws_key_id, aws_sec_key)
  end

  context 'iterate S3 bucket for restored objects' do
    before :all do
      @s3_helper.setup_test_bucket(TEST_BUCKET_NAME)
      @time_s0 = timestamp
      @s3_helper.upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version1')
      @time_s1 = timestamp
      @s3_helper.upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version2')
      described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME)
    end

    after :all do
      @s3_helper.clear_test_bucket(TEST_BUCKET_NAME)
    end

    it 'should list objects need to be restored according to time modified' do
      objs = described_class.restored_objects(DateTime.now)
      expect(objs).to eq({})
      objs = described_class.restored_objects(@time_s1)
      objs.should have_key(TEST_BLOB)
      objs[TEST_BLOB][:discard_versions].should have(1).items
      objs[TEST_BLOB][:retain_versions].should have(1).items
      objs = described_class.restored_objects(@time_s0)
      objs.should have_key(TEST_BLOB)
      objs[TEST_BLOB][:discard_versions].should have(2).items
      objs[TEST_BLOB][:retain_versions].should have(0).items
    end

  end

  context 'doing actual S3 obj restore' do
    before :all do
      @s3_helper.setup_test_bucket(TEST_BUCKET_NAME)
      @time_s2 = timestamp
      @s3_helper.upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version1')
      @time_s3 = timestamp
      @s3_helper.delete_blob(TEST_BUCKET_NAME, TEST_BLOB)
      @time_s4 = timestamp
      @s3_helper.upload_blob(TEST_BUCKET_NAME, TEST_BLOB, 'version2')
      described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME)
      expect(@s3_helper.object_exists?(TEST_BUCKET_NAME, TEST_BLOB)).to be(true)
      expect(@s3_helper.object_content(TEST_BUCKET_NAME, TEST_BLOB)).to eq('version2')
      @time_s5 = timestamp
    end

    after :all do
      @s3_helper.clear_test_bucket(TEST_BUCKET_NAME)
    end

    it 'should delete objects if previous version is a delete mark' do
      objs = described_class.restored_objects(@time_s4)
      described_class.do_restore(objs)
      expect(@s3_helper.object_exists?(TEST_BUCKET_NAME, TEST_BLOB)).to be(false)
    end

    it 'should be able to roll back' do
      objs = described_class.restored_objects(@time_s3)
      described_class.do_restore(objs)
      interval_wait
      expect(@s3_helper.object_exists?(TEST_BUCKET_NAME, TEST_BLOB)).to be(true)
      expect(@s3_helper.object_content(TEST_BUCKET_NAME, TEST_BLOB)).to eq('version1')
    end

    it 'should delete objects if the restored date is before the first version creation time' do
      objs = described_class.restored_objects(@time_s2)
      described_class.do_restore(objs)
      expect(@s3_helper.object_exists?(TEST_BUCKET_NAME, TEST_BLOB)).to be(false)
    end

    it 'should be able to restore to latest version' do
      objs = described_class.restored_objects(@time_s5)
      described_class.do_restore(objs)
      interval_wait
      expect(@s3_helper.object_exists?(TEST_BUCKET_NAME, TEST_BLOB)).to be(true)
      expect(@s3_helper.object_content(TEST_BUCKET_NAME, TEST_BLOB)).to eq('version2')
    end
  end

  context 'error handlings' do
    before :all do
      expect(@s3_helper.bucket_exists?(TEST_BUCKET_NAME)).to be false
      @s3_helper.setup_test_bucket(TEST_BUCKET_NAME, false)
    end

    after :all do
      @s3_helper.clear_test_bucket(TEST_BUCKET_NAME)
    end

    it 'should raise error when not a versioning bucket' do
      expect { described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME) }.to raise_error("not a versionized bucket")
    end

  end

  context 'error handlings without bucket init' do
    it 'should raise error when bucket_name not exist' do
      expect { described_class.config(aws_key_id, aws_sec_key, TEST_BUCKET_NAME) }.to raise_error("not exist bucket")
    end
  end

end
