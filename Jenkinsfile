pipeline {
  agent { node { label 'terraform' } }

  environment {
    TF_IN_AUTOMATION = 'true'
    GOOGLE_APPLICATION_CREDENTIALS = credentials('gcp-spider-service-account')
  }

  options {
    timestamps()
    skipStagesAfterUnstable()
  }

  triggers {
    githubPush()
    // pollSCM('H/5 * * * *')
  }

  parameters {
    booleanParam(name: 'AUTO_APPROVE', defaultValue: false, description: 'Auto-apply without manual approval')
  }

  stages {
    stage('Setup tfvars for Respective Branches') {
      steps {
        dir('infra') {
          script {
            env.SAFE_BRANCH_NAME = env.BRANCH_NAME?.replaceAll('/', '-') ?: 'default'
            echo "Using SAFE_BRANCH_NAME=${env.SAFE_BRANCH_NAME}"
            if (env.BRANCH_NAME.startsWith('feature/')) {
              def tfvars = """
                project_id        = "spider-107124046-onsite"
                region            = "asia-south1"
                cluster_name      = "spider-web-${env.SAFE_BRANCH_NAME}"
                node_count        = 1
                node_machine_type = "e2-micro"
                network_name      = "spider-web-${env.SAFE_BRANCH_NAME}-vpc"

                subnets = [
                  {
                    name          = "subnet-${env.SAFE_BRANCH_NAME}"
                    ip_cidr_range = "10.40.0.0/16"
                  }
                ]

                db_instance_name = "spider-db-${env.SAFE_BRANCH_NAME}"
                db_name          = "classroom_${env.SAFE_BRANCH_NAME}"

                ssh_allowed_ip_cidr = "0.0.0.0/0"

                buckets = {
                  "spider-${env.SAFE_BRANCH_NAME}-uploads" = {
                    public_access     = true
                    enable_versioning = false
                  }
                }
              """
              env.SAFE_BRANCH_NAME = env.BRANCH_NAME.replaceAll('/', '-')
              writeFile file: "envs/${env.SAFE_BRANCH_NAME}.tfvars", text: tfvars
              env.TFVARS_FILE = "envs/${env.SAFE_BRANCH_NAME}.tfvars"
            }
          }
        }
      }
    }

    stage('Terraform Init') {
      steps {
        dir('infra') {
          sh 'terraform init'
        }
      }
    }

    stage('Set Terraform Workspace') {
      steps {
        dir('infra') {
          script {
            def workName = env.SAFE_BRANCH_NAME
            sh "terraform workspace new '${workName}' || terraform workspace select '${workName}'"
            sh "terraform workspace show"
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('infra') {
          script {
            if (env.BRANCH_NAME.startsWith('feature/')) {
              env.TFVARS_FILE = "envs/${env.SAFE_BRANCH_NAME}.tfvars"
              sh "terraform plan -var-file=$TFVARS_FILE -out=tfplan.out"
            } else if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'prod') {
              withCredentials([file(credentialsId: 'terraform-prod-tfvars', variable: 'TFVARS_FILE')]) {
                sh "terraform plan -var-file=$TFVARS_FILE -out=tfplan.out"
              }
            } else if (env.BRANCH_NAME == 'develop') {
              withCredentials([file(credentialsId: 'terraform-develop-tfvars', variable: 'TFVARS_FILE')]) {
                sh "terraform plan -var-file=$TFVARS_FILE -out=tfplan.out"
              }
            } else if (env.BRANCH_NAME == 'staging') {
              withCredentials([file(credentialsId: 'terraform-staging-tfvars', variable: 'TFVARS_FILE')]) {
                sh "terraform plan -var-file=$TFVARS_FILE -out=tfplan.out"
              }
            } else {
              currentBuild.result = 'ABORTED'
              error "Unsupported branch: ${env.BRANCH_NAME}. Aborting pipeline"
              return
            }
          }
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
          expression { return params.AUTO_APPROVE }
        }
      }
      steps {
        dir('infra') {
          sh 'terraform apply -auto-approve tfplan.out'
        }
      }
    }

    stage('Terraform Destroy (Ephemeral)') {
      when {
        not {
          branch 'main'
        }
      }
      steps {
        dir('infra') {
          script {
            if (env.BRANCH_NAME.startsWith('feature/') || env.CHANGE_BRANCH) {
              sh "terraform destroy -auto-approve -var-file=${env.TFVARS_FILE}"
            }
          }
        }
      }
    }
  }

  post {
    always {
      echo "Cleaning up Terraform workspace"
      dir('infra') {
        script {
          def ws = env.SAFE_BRANCH_NAME
          sh 'terraform workspace select default || true'
          sh "terraform workspace delete ${ws} || true"
        }
      }
    }
    failure {
      echo 'Pipeline failed.'
    }
  }
}