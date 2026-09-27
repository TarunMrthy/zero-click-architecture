# Zero-Click 3-Tier AWS Architecture

## Overview
This project demonstrates a secure, automated 3-tier cloud network deployed in AWS (Mumbai region) using Infrastructure as Code (Terraform). 

## Architecture Design
* **Tier 1 (Presentation):** An internet-facing Apache web server (`t3.micro`) inside a public subnet.
* **Tier 2 (Application):** An internal server isolated in a private subnet. Uses Security Group chaining to strictly accept traffic ONLY from Tier 1.
* **Tier 3 (Database):** A private MySQL database server locked down to only accept Port 3306 connections directly from Tier 2.

## Technologies Used
* AWS (VPC, EC2, Security Groups, Subnets, Internet Gateway)
* Terraform (IaC)
* Git / GitHub
