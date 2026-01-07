# Create NodeJs app artifact :
______
node pack

## untar the artifact 
tar -xzvf nodejs-app-for-testing-ansible-1.0.0.tgz

## Run the app after untar
1- npm i

2- node app.js


# Run as Docker Container 
_____

1- docker build -t my-node-app .

2- docker run -dp 3000:3000 --name nodeapp my-node-app
