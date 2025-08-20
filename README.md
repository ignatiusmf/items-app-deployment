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


## Ideas
- Seperate the script from the code? Then clone the code repo and then continue script. Instead of cloning the repo and running it's script?
- Healing. Sodat as jy die script run dan restart of check hy enige system wat nie werk nie.
- Cleaner deployment strategy (Hoe jy die assets op die machine kry. Meer succint steps van blank VM --> Running server)
- Extract packages wat in die app gebruik word na n pipfile, dan word venv dynamically created