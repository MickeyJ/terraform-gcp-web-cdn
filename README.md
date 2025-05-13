# Terraform GCP Web CDN

> **Live Demo:** [app.mickeymalotte.com](https://app.mickeymalotte.com)

This project provides Terraform configurations to deploy a web application on Google Cloud Platform (GCP) with Cloud CDN enabled. It automates the provisioning of necessary resources such as storage buckets, backend services, load balancers, and CDN configuration.

## Features

- Deploys a static or dynamic web application on GCP
- Configures Google Cloud CDN for improved performance and caching
- Infrastructure as Code using Terraform

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed
- A GCP project and credentials with appropriate permissions

## Usage

1. Clone this repository.
2. Initialize Terraform:
   ```
   terraform init
   ```
3. Review and customize variables as needed.
4. Apply the configuration:
   ```
   terraform apply
   ```

## Cleanup

To destroy all resources created by this project:

```
terraform destroy
```

## License

MIT License
