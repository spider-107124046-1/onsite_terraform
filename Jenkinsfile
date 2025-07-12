pipeline {
  agent {
    docker {
      image 'hashicorp/terraform:latest'
      args '-u root:root' // Run as root to avoid permission issues
    }
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-spider-service-account') // from Jenkins credentials
  }

  options {
    timestamps()
    skipStagesAfterUnstable()
  }

  triggers {
    // Trigger build via GitHub Webhook (preferred)
    githubPush()

    // OR uncomment below for polling Git repo every 5 minutes
    /*
    pollSCM('H/5 * * * *')
    */
  }

  parameters {
    booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Auto-apply without manual approval')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    // TODO: Hashed names for buckets in feature branches. DO NOT CREATE feature/ BRANCHES UNTIL THEN
    stage('Setup tfvars for Respective Branches') {
      when {
        expression { return env.BRANCH_NAME.startsWith('feature/') }
      }
      steps {
        script {
          if (env.BRANCH_NAME.startsWith('feature/')) {
            def tfvars = """
              project_id        = "spider-107124046-onsite"
              region            = "asia-south1"
              cluster_name      = "spider-web-${BRANCH_NAME.replaceAll('/', '-')}"
              node_count        = 1
              node_machine_type = "e2-micro"
              network_name      = "spider-web-${BRANCH_NAME.replaceAll('/', '-')}-vpc"

              subnets = [
                {
                  name          = "subnet-${BRANCH_NAME.replaceAll('/', '-')}"
                  ip_cidr_range = "10.40.0.0/16"
                }
              ]

              db_instance_name = "spider-db-${BRANCH_NAME.replaceAll('/', '-')}"
              db_name          = "classroom_${BRANCH_NAME.replaceAll('/', '_')}"

              ssh_allowed_ip_cidr = "0.0.0.0/0"

              buckets = {
                "spider-${BRANCH_NAME.replaceAll('/', '-')}-uploads" = {
                  public_access     = true
                  enable_versioning = false
                }
              }
            """
            writeFile file: "envs/${BRANCH_NAME}.tfvars", text: tfvars
          }
          // Use the appropriate tfvars file based on branch from Jenkins Credentials
          if (env.BRANCH_NAME.startsWith('feature/')) {
            env.TF_VAR_FILE = "envs/${BRANCH_NAME}.tfvars"
          } else {
            // Pull tfvars from Jenkins credentials for prod, staging and dev. USING ONLY STAGING FOR NOW
            withCredentials([file(credentialsId: 'terraform-staging-tfvars', variable: 'TFVARS_FILE')]) {
              sh '''
                cp "$TFVARS_FILE" envs/staging.tfvars
              '''
              env.TF_VAR_FILE = 'envs/staging.tfvars'
            }
          }
        }
      }
    }

    stage('Terraform Init') {
      steps {
        dir('infra') {
          // Initialize Terraform with backend configuration
          sh 'terraform init'
        }
      }
    }

    stage('Set Terraform Workspace') {
      steps {
        dir('infra') {
          // Create or select Terraform workspace based on branch name
          script {
            env.WORK_NAME = env.BRANCH_NAME ?: 'default'
            env.WORK_NAME = env.BRANCH_NAME.replaceAll('/', '-')
            sh '''
              terraform workspace new "${WORK_NAME}" || terraform workspace select "${WORK_NAME}"
              terraform workspace show
            '''
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('infra') {
          def tfvarsFile = env.TF_VAR_FILE
          sh "terraform plan -var-file=${tfvarsFile} -out=tfplan.out"
        }
      }
    }

    stage('Approval Gate') {
      when {
        branch 'main'
        expression { return !params.AUTO_APPROVE }
      }
      steps {
        input message: "Approve Terraform Apply to MAIN?", ok: 'Apply'
      }
    }

    stage('Terraform Apply') {
      when {
        anyOf {
          branch 'develop'
          branch 'main'
          expression { params.AUTO_APPROVE }
        }
      }
      steps {
        sh 'terraform apply -auto-approve tfplan.out'
      }
    }

    stage('Terraform Destroy (Ephemeral)') {
      when {
        not {
          branch 'main'
        }
      }
      steps {
        script {
          if (env.BRANCH_NAME.startsWith('feature/') || env.CHANGE_BRANCH) {
            sh 'terraform destroy -auto-approve -var-file=staging.tfvars'
          }
        }
      }
    }
  }

  post {
    always {
      echo "Cleaning up Terraform workspace"
      sh 'terraform workspace select default'
      sh 'terraform workspace delete "${BRANCH_NAME}" || true'
    }
    failure {
      echo 'Pipeline failed.'
    }
  }