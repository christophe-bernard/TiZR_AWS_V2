# Quality constants
quality_pixel_factor=331776
quality_bandwidth_factor=600 # Raise to increase quality

declare -A encoding_profile
num_rows=5 # 5 encoding profile
num_columns=4 # Width / Height / Video datarate / Audio datarate

# Profile 1
encoding_profile[1,1]=256
encoding_profile[1,2]=144
encoding_profile[1,3]=135
encoding_profile[1,4]=32

# Profile 2
encoding_profile[2,1]=512
encoding_profile[2,2]=288
encoding_profile[2,3]=381
encoding_profile[2,4]=96

# Profile 3
encoding_profile[3,1]=768
encoding_profile[3,2]=432
encoding_profile[3,3]=700
encoding_profile[3,4]=128

# Profile 4
encoding_profile[4,1]=1024
encoding_profile[4,2]=576
encoding_profile[4,3]=1078
encoding_profile[4,4]=128

# Profile 5
encoding_profile[5,1]=1280
encoding_profile[5,2]=720
encoding_profile[5,3]=1506
encoding_profile[5,4]=128
