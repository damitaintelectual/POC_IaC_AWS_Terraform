#!/bin/bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get -y install nginx
sudo service nginx start
sudo echo '<h1>Hola Nubox!</h1>' | sudo tee /var/www/html/index.nginx-debian.html