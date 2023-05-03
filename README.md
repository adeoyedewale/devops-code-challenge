# Overview
This repository contains a React frontend, and an Express backend that the frontend connects to.

# Objective
Deploy the frontend and backend to somewhere publicly accessible over the internet. The AWS Free Tier should be more than sufficient to run this project, but you may use any platform and tooling you'd like for your solution.

Fork this repo as a base. You may change any code in this repository to suit the infrastructure you build in this code challenge.

# Submission
1. A github repo that has been forked from this repo with all your code.
2. Modify this README file with instructions for:
* Any tools needed to deploy your infrastructure
* All the steps needed to repeat your deployment process
* URLs to the your deployed frontend.

# Evaluation
You will be evaluated on the ease to replicate your infrastructure. This is a combination of quality of the instructions, as well as any scripts to automate the overall setup process.

# Setup your environment
Install nodejs. Binaries and installers can be found on nodejs.org.
https://nodejs.org/en/download/

For macOS or Linux, Nodejs can usually be found in your preferred package manager.
https://nodejs.org/en/download/package-manager/

Depending on the Linux distribution, the Node Package Manager `npm` may need to be installed separately.

# Running the project
The backend and the frontend will need to run on separate processes. The backend should be started first.
```
cd backend
npm ci
npm start
```
The backend should response to a GET request on `localhost:8080`.

With the backend started, the frontend can be started.
```
cd frontend
npm ci
npm start
```
The frontend can be accessed at `localhost:3000`. If the frontend successfully connects to the backend, a message saying "SUCCESS" followed by a guid should be displayed on the screen.  If the connection failed, an error message will be displayed on the screen.

# Configuration
The frontend has a configuration file at `frontend/src/config.js` that defines the URL to call the backend. This URL is used on `frontend/src/App.js#12`, where the front end will make the GET call during the initial load of the page.

The backend has a configuration file at `backend/config.js` that defines the host that the frontend will be calling from. This URL is used in the `Access-Control-Allow-Origin` CORS header, read in `backend/index.js#14`

# Optional Extras
The core requirement for this challenge is to get the provided application up and running for consumption over the public internet. That being said, there are some opportunities in this code challenge to demonstrate your skill sets that are above and beyond the core requirement.

A few examples of extras for this coding challenge:
1. Dockerizing the application
2. Scripts to set up the infrastructure
3. Providing a pipeline for the application deployment
4. Running the application in a serverless environment

This is not an exhaustive list of extra features that could be added to this code challenge. At the end of the day, this section is for you to demonstrate any skills you want to show that’s not captured in the core requirement.

# Steps Needed to Deploy my Application Using Jenkins
The following are the steps needed to deploy my application:
1. Access Jenkins Automation Server console already provisioned and running on AWS account using this url http://204.236.244.121:8080/
2. username for Jenkins: bravo
3. password for Jenkins: bravo
4. On Jenkins dashboard, click on "New item" to create a new pipeline job
5. Give a name to your new pipeline job, select "Pipeline" option and click "OK"
6. On the "Configuration" page that follows, scroll down to "Pipeline" section.
7. In "Pipeline" section and under "Definition", select "Pipeline script from SCM" option out of the dropdown options.
8. Under SCM, select "Git" from its dropdown options.
9. Copy my gitHub repository url "https://github.com/adeoyedewale/devops-code-challenge.git" into "Repository URL" text field
10. Under "Credentials", select "adeoyewale/******" 
11. Scroll all the way to the bottom to to click "Apply" and "Save" buttons
12. On the Pipeline page, click on "Build Now" to run the pipeline project

# General Description of Infrastructure Components Supporting Jenkins Server
1. Manually created a custom Virtual Private Cloud (VPC) with following features:
      * IPv4 CIDR block 10.0.0.0/16
      * The VPC has one (1) public subnet and zero (0) private subnet
      * Default Tenancy
      * One (1) Availability Zone (AZ)
      * None NAT gateways
      * None VPC endpoints
2. Launched EC2 instance with following features:
      * Number of instance = 1
      * Amazon machine Image = Ubuntu Server 20.04 LTS
      * Instance type = t2 medium
      * Edit network setting to select the custom VPC and public subnet created above
      * Security Group inbound rules were edited by adding ssh with port 22, custom TCP for HTTP with port 8080, and custom TCP for HTTPS with port 443
      * Configured storage with Root volume of 20 GiB gp2
 3. Created IAM user with AdministratorAccess policy attached to the user
   
# Setting up my Environment on the EC2
To install necessary packages and softwares on the EC2 virtual machine, I connected to Visual Studio Code IDE through SSH Connection on Powershell terminal using private key from AWS. The following installations were done after successful SSH connection between EC2 on AWS and VS Code on local system:
     * Installed Jenkins
     * Installed Docker
     * Installed AWS CLIv2
     * Installed Terraform
     * Install npm
     * Install Node.js v16

# Application Infrastructure Provisioning Using Terraform
* Inorder to run the Terraform script located in the private GitHub repository "https://github.com/adeoyedewale/devops-code-challenge.git", the repository was cloned into the root directory of the EC2 machine running the Jenkins server.
* Then cd into the cloned directory to access the terraform file
* Then used the following commands: aws configure, terraform init, terraform validate, terraform plan, terraform apply -auto-approve
* After successful run, the script outputs Application Load Balancer DNS name which is used together with frontend app port 3000 to access the deployed frontend application.
     
     

# Accessing Deployed Frontend Web Application
The url of the deployed frontend web application is "http://lightfeather-lb-1106546257.us-east-1.elb.amazonaws.com:3000"
Both frontend and backend applications are deployed behind an Application Load Balancer with the load balancer dns name "lightfeather-lb-1106546257.us-east-1.elb.amazonaws.com"
