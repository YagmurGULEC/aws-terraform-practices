#!/bin/bash

sudo yum update -y
sudo yum install -y httpd
echo "<h1>Welcome to My Website</h1>" | sudo tee /var/www/html/index.html
sudo systemctl start httpd
sudo systemctl enable httpd
