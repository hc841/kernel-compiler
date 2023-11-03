#!/bin/bash

# Set the destination directory as the user's home folder
destination_dir="$HOME"

# Check if the source directory already exists in the home folder and delete it
if [ -d "$destination_dir/source" ]; then
  echo "Deleting the old source folder at $destination_dir/source..."
  rm -rf "$destination_dir/source"
fi

# Ask the user for the Linux kernel download link
read -p "Enter the download link for the Linux kernel: " kernel_link

# Check if the link was provided
if [ -z "$kernel_link" ]; then
  echo "No link provided. Exiting the script."
  exit 1
fi

# Get the kernel file name from the link
kernel_filename=$(basename "$kernel_link")

# Download the kernel to the user's home folder
echo "Downloading the kernel to $destination_dir/$kernel_filename..."
wget -P "$destination_dir" "$kernel_link"

# Check the download status
if [ $? -ne 0 ]; then
  echo "Error during download. Please check the link and try again."
  exit 1
fi

# Extract the kernel in the home folder
echo "Extracting the kernel in $destination_dir..."
tar -xvf "$destination_dir/$kernel_filename" -C "$destination_dir"

# Check the extraction status
if [ $? -ne 0 ]; then
  echo "Error during extraction. Please check the downloaded file and try again."
  exit 1
fi

# Get the kernel directory name after extraction
kernel_directory=$(tar -tf "$destination_dir/$kernel_filename" | head -1 | sed -e 's@/.*@@')

# Ask the user if they want to enter the kernel menuconfig
read -p "Do you want to enter the kernel menuconfig for adjustments? (Y/n): " menuconfig_choice
if [ "$menuconfig_choice" = "n" ] || [ "$menuconfig_choice" = "N" ]; then
  echo "Generating .config automatically..."
  kernel_source_dir="$destination_dir/$kernel_directory"
  cd "$kernel_source_dir"
  make defconfig
else
  # Enter the menuconfig
  kernel_source_dir="$destination_dir/$kernel_directory"
  cd "$kernel_source_dir"
  make menuconfig
fi

# Ask the user about the number of CPU cores for compilation
read -p "Do you want to specify the number of CPU cores for compilation? (Y/n): " cores_choice
if [ "$cores_choice" = "n" ] || [ "$cores_choice" = "N" ]; then
  # Use all available CPU cores
  cores="$(nproc)"
else
  while true; do
    read -p "Enter the desired number of CPU cores (from 1 to $(nproc)): " cores
    if [[ $cores =~ ^[0-9]+$ ]] && [ "$cores" -ge 1 ] && [ "$cores" -le $(nproc) ]; then
      break
    else
      echo "Invalid number of CPU cores. Please enter a number from 1 to $(nproc)."
    fi
  done
fi

# Compilation of the kernel using the specified number of CPU cores
echo "Starting the kernel compilation with $cores cores..."
make -j"$cores"

# Check the compilation status
if [ $? -eq 0 ]; then
  echo "Kernel compilation completed successfully."

  # Ask the user if they want to install the newly compiled kernel
  read -p "Do you want to install the newly compiled kernel? (Y/n): " install_choice
  if [ "$install_choice" = "y" ] || [ "$install_choice" = "Y" ]; then
    echo "Installing the kernel..."
    sudo make modules_install install
  fi
else
  echo "Error during kernel compilation."
  exit 1
fi

