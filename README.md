# CI/CD Pipeline Documentation

## Overview

This GitHub Actions pipeline implements a comprehensive CI/CD workflow for a Node.js application with Docker containerization and AWS ECR integration. The pipeline follows a multi-stage approach: preparation, building, containerization, promotion, and deployment.

## Pipeline Architecture

The pipeline consists of six sequential jobs that work together to deliver code from repository to production:

```
prepare → config_aws (parallel)
   ↓
build
   ↓
docker
   ↓
promote
   ↓
deploy
```

## Pipeline Jobs

### 1. Prepare Job

**Purpose:** Extract and store the application version for use across all subsequent jobs.

**Steps:**
1. Checks out the repository code
2. Executes `version_extract.sh` to read version from `package.json`
3. Creates a `version.yaml` file containing the extracted version
4. Uploads the version file as a GitHub Actions artifact for downstream jobs

**Runner:** `ubuntu-latest`

---

### 2. Config AWS Job

**Purpose:** Establish AWS credentials and authenticate with Amazon ECR.

**Steps:**
1. Configures AWS credentials using repository secrets
2. Authenticates with Amazon ECR to enable Docker image push/pull operations

**Runner:** `ubuntu-latest`

> **Note:** This job runs independently but its purpose appears redundant since other jobs configure AWS credentials individually.

---

### 3. Build Job

**Purpose:** Build the Node.js application and create a distributable artifact.

**Dependencies:** `prepare`

**Steps:**
1. Checks out repository code
2. Downloads the version artifact from the prepare job
3. Loads version into environment variables using `load_version.sh`
4. Sets up Node.js 20 with npm caching
5. Installs application dependencies
6. Packages the application into a versioned tarball using `package_artifact.sh`
7. Uploads the packaged artifact for the docker job

**Artifact naming convention:** `cicd-aseel-{VERSION}-{SHORT_SHA}.tgz`

**Runner:** `ubuntu-latest`

---

### 4. Docker Job

**Purpose:** Build and push the Docker image to AWS ECR with a test tag.

**Dependencies:** `build`

**Steps:**
1. Checks out repository code
2. Downloads version and build artifacts
3. Loads version into environment variables
4. Extracts the application tarball using `extract_artifact.sh`
5. Configures AWS credentials and logs into ECR
6. Builds Docker image using the Dockerfile
7. Pushes image to ECR with tag format: `{VERSION}-test`

**Image Tag Format:** `{ECR_URI}/cicd-aseel:{VERSION}-test`

**Runner:** `ubuntu-latest`

---

### 5. Promote Job

**Purpose:** Promote the tested Docker image by removing the test suffix and creating a production-ready tag.

**Dependencies:** `docker`

**Steps:**
1. Checks out repository code
2. Configures AWS credentials and logs into ECR
3. Executes `promote.sh` script which:
   - Queries ECR for the latest image with a "test" tag
   - Pulls that image locally
   - Creates a new tag by removing the "-test" suffix
   - Pushes the promoted image back to ECR
4. Outputs the `BASE_TAG` for use in deployment

**Example:** `1.0.0-test` → `1.0.0`

**Outputs:**
- `BASE_TAG`: The production version tag without "-test" suffix

**Runner:** `ubuntu-latest`

---

### 6. Deploy Job

**Purpose:** Deploy the promoted Docker image to the target server.

**Dependencies:** `promote`

**Steps:**
1. Checks out repository code
2. Downloads version artifact
3. Loads version into environment variables
4. SSH into the target server and:
   - Authenticates with AWS ECR
   - Pulls the promoted Docker image using the `BASE_TAG` from the promote job
   - Stops and removes any existing container named "nodeapp"
   - Runs a new container with the updated image on port 3000

**Container Configuration:**
- **Name:** `nodeapp`
- **Port Mapping:** `3000:3000`
- **Mode:** Detached (`-d`)

**Runner:** `ubuntu-latest`

---

## Common Scripts

### version_extract.sh

Extracts the version number from `package.json` and creates a `version.yaml` file. This ensures version consistency across all pipeline stages.

**Process:**
1. Reads version from `package.json` using `jq`
2. Sets `VERSION` environment variable
3. Creates `version.yaml` with the version string

---

### load_version.sh

Loads the version from `version.yaml` into the GitHub Actions environment.

**Process:**
1. Parses `version.yaml` to extract the version value
2. Sets `VERSION` environment variable for the current job

---

### package_artifact.sh

Creates a compressed tarball of the application code.

**Process:**
1. Generates artifact name: `cicd-aseel-{VERSION}-{SHORT_SHA}.tgz`
2. Creates temporary directory structure
3. Copies all files except temporary directories, artifacts, and git folders
4. Creates compressed tarball in `artifacts/` directory
5. Cleans up temporary files

**Excluded from packaging:**
- `artifact-temp/`
- `artifacts/`
- `.git/`
- `.github/`

---

### extract_artifact.sh

Extracts the packaged application artifact for Docker image building.

**Process:**
1. Creates an `app/` directory (mentioned in the Dockerfile)
2. Identifies the correct artifact file matching the version pattern
3. Extracts the tarball contents into the app directory

---

### promote.sh

Handles the promotion of test images to production-ready images.

**Process:**
1. Queries AWS ECR for images in the `cicd-aseel` repository
2. Filters for images with tags containing "test"
3. Identifies the most recently pushed test image using `jq`
4. Pulls the image locally
5. Creates a new tag by removing the "-test" suffix
6. Pushes the promoted image back to ECR
7. Exports `BASE_TAG` to `$GITHUB_ENV` and `$GITHUB_OUTPUT`

**Environment Variables Required:**
- `AWS_REGION`: AWS region for ECR
- `ECR_URI`: ECR repository URI

**Outputs:**
- `BASE_TAG`: Production version tag (exported for deploy job)

**Usage:**
```bash
chmod +x common/promote.sh
./common/promote.sh
```

---

## Required Secrets

The pipeline requires the following GitHub repository secrets:

| Secret Name | Description |
|-------------|-------------|
| `AWS_ACCESS_KEY` | AWS access key ID for ECR access |
| `AWS_SECRET_ACCESS_KEY` | AWS secret access key for ECR access |
| `AWS_REGION` | AWS region where ECR repository exists |
| `ECR_URI` | URI of the ECR repository |
| `HOST` | Target deployment server IP |
| `HOST_NAME` | SSH username for the deployment server |
| `KEY` | SSH private key for server authentication |

---

## Image Tagging Strategy

The pipeline implements a two-stage tagging approach:

1. **Test Stage:** Images are tagged as `{VERSION}-test` after building
2. **Production Stage:** After validation, the `-test` suffix is removed, creating production tags like `{VERSION}`

**Example Flow:**
```
Build → 1.2.3-test
Promote → 1.2.3
```

This strategy provides a clear separation between testing and production-ready images while maintaining traceability through version numbers.

---

## Prerequisites

1. **AWS ECR Repository:** Repository named `cicd-aseel` must exist
2. **Target Server:** Server must have:
   - Docker installed
   - AWS CLI installed and configured
   - SSH access enabled
3. **GitHub Secrets:** All required secrets configured in repository settings

---
