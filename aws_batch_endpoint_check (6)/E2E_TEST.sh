#!/bin/bash
# E2E_TEST.sh - Submits an AWS Batch job using the latest definition

echo "Submitting AWS Batch Job..."

JOB_NAME="test-endpoint-job"
JOB_DEF=$(aws batch describe-job-definitions --status ACTIVE --query "jobDefinitions[-1].jobDefinitionName" --output text)
QUEUE=$(aws batch describe-job-queues --query "jobQueues[0].jobQueueName" --output text)

aws batch submit-job --job-name "$JOB_NAME" --job-queue "$QUEUE" --job-definition "$JOB_DEF"
