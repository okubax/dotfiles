#!/bin/bash

# Initialize an array to store the numbers
declare -a nums

# Generate six unique random numbers
for i in {1..6}
do
    # Generate a random number
    num=$((1 + RANDOM % 59))
    
    # Check if the number is already in the array
    while [[ "${nums[@]}" =~ "${num}" ]]
    do
        num=$((1 + RANDOM % 59))
    done
    
    # Add the unique number to the array
    nums+=("$num")
done

# Print the numbers
echo "Your UK National Lottery numbers are:"
echo "${nums[*]}"
