# Flight Reservation - AWS Terraform

This Terraform configuration follows the Azure project's module structure, converted to AWS with simple resource-based modules.

Architecture:
- VM1: C7i-flex.large - Jenkins, Docker, SonarQube
- VM2: C7i-flex.large - kubectl, Helm, Argo CD CLI, monitoring administration
- EKS: 2 x C7i-flex.large nodes
- RDS MariaDB: replaces Kubernetes MariaDB/PVC
- S3: important application file storage
- ECR: frontend, reservation and check-in images
- SNS: email notifications
- CloudWatch: EC2/RDS alarms
- Prometheus/Grafana: installed in EKS from VM2 with Helm

The Terraform code does not create Kubernetes application manifests. After EKS is created, configure kubectl on VM2 and install Argo CD / kube-prometheus-stack.

RDS creates the initial `flightdb` database. Create `checkin_db` afterward using the supplied SQL helper script from a host that can reach the private RDS endpoint (VM2 is in the same VPC).

Use `aws configure` or an EC2 instance role for AWS authentication. Do not commit `terraform.tfvars`.


## How this maps to the Azure project

The Azure project modules were `network`, `vm`, `aks`, `database`, `storage`, and `sns`. This AWS version keeps the same simple module idea and maps them to:

- `network` -> `vpc`
- `vm` -> `ec2-jenkins` and `ec2-monitoring`
- `aks` -> `eks`
- `database` -> `rds`
- `storage` -> `s3`
- `sns` -> `sns`
- AWS container registry -> `ecr`
- AWS alarms -> `cloudwatch`

The Kubernetes MariaDB/PVC resources from the Azure GitOps directory are intentionally not part of the AWS Terraform stack because RDS is the production database.
