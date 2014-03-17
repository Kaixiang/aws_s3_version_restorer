module AwsS3VersionRestorer::Spec
  module CliHelper
    attr_reader :stdout, :stderr, :stdin, :status

    def capture_output
      $real_stdout = $stdout
      $real_stderr = $stderr
      $real_stdin = $stdin
      $stdout = @stdout = StringIO.new
      $stderr = @stderr = StringIO.new
      $stdin = @stdin = StringIO.new
      @status = yield
      @stdout.rewind
      @stderr.rewind
      @status
    ensure
      $stdout = $real_stdout
      $stderr = $real_stderr
      $stdin = $real_stdin
    end
  end
end
