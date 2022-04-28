# add AWS   # in pkg mode
# add AWSS3, Serialization

using AWS, AWSS3, Serialization
struct MyData
  a::Int
  b::String
end

d = MyData(1,"xyz")
aws = global_aws_config(; region="us-west-2")

s3_create_bucket(aws, "my.bucket")

b = IOBuffer()

serialize(b, d)
s3_put(aws, "your-s3-bucket-name","myfile.bin", b.data)

ddat = s3_get(aws, "your-s3-bucket-name","myfile.bin")
d2 = deserialize(IOBuffer(ddat))

@assert d == d2

p = S3Path("s3://my.bucket/test1.txt")  # provides an filesystem-like interface
write(p, "some data")
read(p, byte_range=1:4)  # returns b"some"

s3_delete_bucket("my.bucket")
