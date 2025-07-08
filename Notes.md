# IMPORTANT
- Web Server: Install and configure Nginx to act as a reverse proxy, directing traffic from Port 80 to the running Flask application on port 3000.  
- There is no requirement to run the Python application as a system service, it can simply be run from the terminal. However, if you wish to implement this, you are free to do so.  
- Networking: Configure the instance's firewall to allow inbound traffic on Port 22 (SSH) and Port 80 (HTTP). Any Linux firewalling utility is acceptable.

# NOTES
1. If you change the parameters in the script, for example changing the Python app's port number, then a restart of the Python app and Nginx is entirely reasonable and would not be considered "breaking" as it is intended behaviour.
    - Make the python app's port number configurable
2. Ensure that if you add some fields to the database and rerun the setup script that those fields are still accessible?
3. Use linux conventions for where you store the app.py + sqlite dababase --> Find out what those conventions are

# STEPS
### FROM WINDOWS
ssh -i .\tech-assessment.pem ubuntu@13.246.152.191  
scp -i .\tech-assessment.pem .\app.py ubuntu@13.246.152.191:/home/ubuntu/  

### FROM SSH
sudo apt-get update -y  
sudo apt install python3-pip  
sudo apt install python3.12-venv  
python3 -m venv ~/flask_test_env  
source ~/flask_test_env/bin/activate  
pip install flask  
python app.py  

### FROM ANOTHER SSH
./get_item.sh "13.246.152.191:3000" 1  

### FROM WINDOWS
./get_item.sh "13.246.152.191:3000" 1  

### FROM SSH
pip install gunicorn  
gunicorn -w 2 -b 0.0.0.0:3000 app:app  

### FROM WINDOWS
./get_item.sh "13.246.152.191:3000" 1  

### FROM SSH
sudo vim /etc/systemd/system/items.service  

```
[Unit]
Description=Items API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu
Environment=DB_PATH=/home/ubuntu/items_db.sqlite
ExecStart=/home/ubuntu/flask_test_env/bin/gunicorn -w 2 -b 0.0.0.0:3000 app:app
Restart=always

[Install]
WantedBy=multi-user.target
```
sudo systemctl daemon-reload  
sudo systemctl enable --now test.service  
sudo systemctl status test.service  

### FROM WINDOWS 
./get_item.sh "13.246.152.191:3000"  
./add_item.sh "13.246.152.191:3000" "Test Item" "This is a test item, added through the helper script"  

### FROM SSH
#### (Cleaning after service testing)  
sudo systemctl stop test.service
sudo systemctl disable test.service
sudo rm /etc/systemd/system/test.service
sudo systemctl daemon-reload
sudo systemctl status test.service
#### Further testing of subcomponents
sudo apt install nginx  
sudo rm /etc/nginx/sites-enabled/default  
sudo nginx -t && sudo systemctl reload nginx  

sudo vim /etc/nginx/sites-available/test  
sudo ln -s /etc/nginx/sites-available/test /etc/nginx/sites-enabled/test  
sudo nginx -t  
sudo systemctl reload nginx  

#### FROM WINDOWS
./get_item.sh "13.246.152.191:3000" 2


### FROM SSH
#### (Cleaning after nginx testing)  
sudo rm /etc/nginx/sites-enabled/test  
sudo rm /etc/nginx/sites-available/test  
sudo nginx -t && sudo systemctl reload nginx  


### Further testing of subcomponents
sudo ufw status  
sudo ufw enable  
sudo ufw allow 22  
sudo ufw allow 80  




# USEFUL COMMANDS
sudo systemctl restart items-app
sudo systemctl status items-app
journalctl -u items-app.service -n 50 --no-pager
ls /srv/items-app/