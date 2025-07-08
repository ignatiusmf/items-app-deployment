# DevOps-Exercise
Create a script that will deploy a premade application and make is publically accessible on a clean ubuntu server.


## Things
clone in home directory
chmod +x setup.sh
run setup.sh with "./setup.sh"

You can set the following parameters:
PORT
DBLOCATION


## Assumptions
Changes to app.py won't immediately take effect. It will chanage the app.py used to serve the appplication, but a "system restart items-app" will be required. Also, depending on the change, you would need to update you venv
If the DB path changes, you won't delete the old sqlite db, could cause clutter