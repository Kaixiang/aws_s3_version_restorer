require "spec_helper"

describe AwsS3VersionRestorer::RestorerCommand do
  let(:cli) { AwsS3VersionRestorer::RestorerCommand.new }

  subject do
    capture_output do
      cli.stub(:input) { inputs }
      cli.execute(command, [])
    end
  end

  context 'when invoke help' do
    let (:inputs) { {} }
    let (:command) { Mothership.commands[:help] }

    it 'should print help msg' do
      subject
      expect(stdout.string).to match(/Show Help/)
    end
  end

  context 'when invoke restore' do
    let (:command) { Mothership.commands[:restore] }

    it 'should ask for aws keyi/sec if no env given' do
      HighLine.any_instance.stub(:ask).with('the aws key id') {'id'}
      HighLine.any_instance.stub(:ask).with('the aws sec id') {'sec'}
      HighLine.any_instance.stub(:ask).with('the bucket name need to restored') {'bu'}
      AwsS3VersionRestorer::RestorerCommand.any_instance.stub(:input_date_time)
      AwsS3VersionRestorer::AwsS3Helper.should_receive(:config).with('id', 'sec', 'bu')
      subject
    end

    it 'should avoid input aws keys if env already given' do
      ENV.stub(:[]).with("AWSAccessKeyId").and_return("key")
      ENV.stub(:[]).with("AWSSecretKey").and_return("secret")
      HighLine.any_instance.stub(:ask).with('the bucket name need to restored') {'bu'}
      AwsS3VersionRestorer::RestorerCommand.any_instance.stub(:input_date_time)
      AwsS3VersionRestorer::AwsS3Helper.should_receive(:config).with('key', 'secret', 'bu')
      subject
    end

    it 'should ask/confirm for Datetime and invoke S3 iteration and doing restore' do
      HighLine.any_instance.stub(:ask).with('the aws key id') {'id'}
      HighLine.any_instance.stub(:ask).with('the aws sec id') {'sec'}
      HighLine.any_instance.stub(:ask).with('the bucket name need to restored') {'bu'}

      HighLine.any_instance.stub(:ask).with('Input Year:') {'2014'}
      HighLine.any_instance.stub(:ask).with('Input Month:') {'3'}
      HighLine.any_instance.stub(:ask).with('Input Day:') {'1'}
      HighLine.any_instance.stub(:ask).with('Input Hour:') {'12'}
      HighLine.any_instance.stub(:ask).with('Input Minute:') {'0'}
      HighLine.any_instance.stub(:ask).with('Input Seconds:') {'0'}
      HighLine.any_instance.stub(:ask).with('Input TimeZone(+n/-n):') {'+8'}
      HighLine.any_instance.stub(:ask).with('Are you sure? (type \'yes\' to continue): ') {'yes'}

      AwsS3VersionRestorer::AwsS3Helper.should_receive(:config).with('id', 'sec', 'bu')
      AwsS3VersionRestorer::AwsS3Helper.should_receive(:restored_objects).with(DateTime.parse('2014-3-1T12:00:00+8')) {{}}
      AwsS3VersionRestorer::AwsS3Helper.should_receive(:do_restore).with({})

      subject

    end

  end

end
