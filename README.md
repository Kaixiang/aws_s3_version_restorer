# AwsS3VersionRestorer

Managing A big S3 bucket with versioning enabled could be painful, This is a tool intent to help relieve the pain.

## Feature:

1. input the time in the past you want to restore your bucket. as far as your bucket versioning is enabled. This tool will automatically restore the version for you. 

1. this tool will not delete any version, it just append a new version with the same content you want to restore. so you can run it again to revise to another date.


## Usage

1. bundle install

```
bundle install
```

1. export your AWS key

```
export AWSAccessKeyId=[Some key]
export AWSSecretKey=[Some secret]
```
Note: You can avoid this step and input the credential later in Cli

1. run restor cmd and input bucket name, as well as the time you want to revise your bucket to.

```
./bin/svr restore
the bucket name need to restored
[mybucket]

Now input the date/time you want to restore the bucket object versions to

Input Year:
2014
Input Month:
3
Input Day:
1
Input Hour:
12
Input Minute:
0
Input Seconds:
0
Input TimeZone(+n/-n):
+8
the time you want to restore is 16days 2hour 55minute 36sec  before now
Are you sure? (type 'yes' to continue): 
yes
below objects versions are discarded:
====================
object name: 1
discarded versions:
  version_id:   UGALaJVV2dChxaIdTaSbgSgPVaULZiaI
  modified_at:  2014-03-17T06:15:49+00:00
  version_id:   4igtgeNg_Av1z8lHNodAHWVXnAMX4UOe
  modified_at:  2014-03-06T08:28:24+00:00
  version_id:   MBVWLS4_0xZCQYOZNv5FpFTlVr2qi0Qp
  modified_at:  2014-03-04T06:01:13+00:00
Are you sure? (type 'yes' to continue): 
yes
```

## Contributing

1. Fork it
1. Create your feature branch (`git checkout -b my-new-feature`)
1. Write/Run test 
1. Commit your changes (`git commit -am 'Add some feature'`)
1. Push to the branch (`git push origin my-new-feature`)
1. Create new Pull Request
