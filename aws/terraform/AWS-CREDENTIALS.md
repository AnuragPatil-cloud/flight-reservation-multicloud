# AWS credentials

Do not store AWS access keys in Terraform files or Git.

For a workstation or temporary administration VM:

```bash
aws configure
aws sts get-caller-identity
```

For EC2, prefer an IAM instance role. The Terraform creates instance roles for Jenkins and monitoring administration.
