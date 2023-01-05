### AWS S3 bucket access policy based on IP Address

#### Allow access from subnet 154.155.156.0/24 (with one exception 154.155.156.157) and 54.55.56.57

```json
{
    "Version": "2012-10-17",
    "Id": "S3PolicyId1",
    "Statement": [
        {
            "Sid": "IPAllow",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::MY-BUCKET/*"
            ],
            "Condition": {
                "IpAddress": {"aws:SourceIp": [ "154.155.156.0/24", "54.55.56.57/32" ]},
                "NotIpAddress": {"aws:SourceIp": "154.155.156.157/32"}
            }
        }
    ]
```
