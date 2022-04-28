# add GoogleCloud    # pkg mode

using GoogleCloud

creds = GoogleCredentials(expanduser("credentials.json"))
session = GoogleSession(creds, ["devstorage.full_control"])
set_session!(storage, session)    # storage is the API root, exported from GoogleCloud.jl
bkts = storage(:Bucket, :list)    # storage(:Bucket, :list; raw=true) returns addition information

for item in bkts
    display(item)
    println()
end

storage(:Bucket, :insert; data=Dict(:name => "a12345foo"))

# Verify the new bucket exists in the project
bkts = storage(:Bucket, :list)
for item in bkts
    display(item)
    println()
end

storage(:Object, :list, "a12345foo")

# String containing the contents of test_image.jpg. The semi-colon avoids an error caused by printing the returned value.
file_contents = readstring(open("test_image.jpg", "r"));

# Upload
storage(:Object, :insert, "a12345foo";     # Returns metadata about the object
    name="image.jpg",           # Object name is "image.jpg"
    data=file_contents,         # The data being stored on your project
    content_type="image/jpeg"   # The contents are specified to be in JPEG format
)

# Verify that the object is in the bucket
obs = storage(:Object, :list, "a12345foo")    # Ugly print
map(x -> x[:name], obs)                       # Pretty print

s = storage(:Object, :get, "a12345foo", "image.jpg");
s == file_contents    # Verify that the retrieved data is the same as that originally posted

storage(:Object, :delete, "a12345foo", "image.jpg")

# Verify that the bucket is now empty
storage(:Object, :list, "a12345foo")

storage(:Bucket, :delete, "a12345foo")

# Verify that the bucket has been deleted
bkts = storage(:Bucket, :list)
for item in bkts
    display(item)
    println()
end