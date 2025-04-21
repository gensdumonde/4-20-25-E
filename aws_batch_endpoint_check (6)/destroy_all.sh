#!/bin/bash
# destroy_all.sh - cleanup all Terraform-managed resources

echo "Destroying all Terraform-managed infrastructure..."
terraform destroy -var-file=terraform.tfvars -auto-approve
