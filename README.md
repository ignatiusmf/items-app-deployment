# DevOps-Exercise
Create a script that will deploy a premade application and make is publically accessible on a clean ubuntu server.  

## INSTRUCTIONS
clone https://github.com/ignatiusmf/items-app-deployment.git  
cd items-app-deployment/files  
chmod +x setup.sh  
./setup.sh  

### Tunable parameters:
Database Location (as DB_PATH, through environment variable to setup script)   

## Assumptions
Assumes app.py won't change  
If the DB path changes, old sqlite db won't be deleted, could cause clutter  

## Please note
A modification was made to the app.py file 