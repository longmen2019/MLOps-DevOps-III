```markdown
# Image Processor (AWS Lambda + Terraform)

A fully serverless, event‑driven image‑processing pipeline built on AWS Lambda, S3, and Terraform.  
When an image is uploaded to the **upload bucket**, Lambda automatically generates multiple optimized variants and stores them in the **processed bucket**.

## Architecture Overview

- **AWS Lambda (Python 3.12)**  
  Processes incoming images using Pillow and generates:
  - Compressed JPEG
  - Low‑quality JPEG
  - PNG conversion
  - WEBP conversion
  - Thumbnail

- **Lambda Layer (Pillow)**  
  Custom-built on Amazon Linux 2023 with compiled C‑extensions (`_imaging`, `_webp`, `_imagingft`, etc.) for full Pillow compatibility.

- **Amazon S3**  
  - `upload_bucket`: receives original images  
  - `processed_bucket`: stores processed variants  
  - S3 → Lambda event notifications trigger processing

- **Terraform**  
  Manages all AWS resources:
  - Lambda function + IAM role
  - Lambda layer
  - S3 buckets
  - S3 → Lambda notifications
  - Outputs for easy CLI usage

## Deployment

### 1. Build the Pillow Lambda Layer

Inside `pillow-build/`:

```bash
docker build -t pillow-layer .
docker create --name extract pillow-layer
docker cp extract:/tmp/pillow_layer.zip ./pillow_layer.zip
docker rm extract
mv pillow_layer.zip ..
```

### 2. Deploy Infrastructure

```bash
terraform init
terraform apply
```

Terraform outputs:

- `upload_bucket_name`
- `processed_bucket_name`
- `lambda_function_name`
- `upload_command_example`

## Usage

Upload any image to the upload bucket:

```bash
aws s3 cp your-image.jpg s3://<upload_bucket_name>/
```

Lambda automatically generates:

- `<name>_compressed_<id>.jpg`
- `<name>_low_<id>.jpg`
- `<name>_png_<id>.png`
- `<name>_webp_<id>.webp`
- `<name>_thumbnail_<id>.jpg`

Check processed images:

```bash
aws s3 ls s3://<processed_bucket_name>/
```

## Logging

View Lambda logs:

```bash
aws logs tail /aws/lambda/<lambda_function_name> --since 5m
```

## Folder Structure

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── lambda_function.zip
├── pillow_layer.zip
└── pillow-build/
    ├── Dockerfile
    └── build scripts
```

## Requirements

- Docker Desktop (WSL2 integration enabled)
- Terraform ≥ 1.5
- AWS CLI configured with valid credentials
- Python 3.12 Lambda runtime

## Notes

- Buckets use versioning; destroying requires clearing all object versions.
- Pillow layer must be built on Amazon Linux 2023 for Python 3.12 compatibility.

## License

MIT
```