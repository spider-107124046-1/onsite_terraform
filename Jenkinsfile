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
            if (env.BRANCH_NAME.startsWith('feature/')) {
              def tfvars = """
                project_id        = "spider-107124046-onsite"
                region            = "asia-south1"
                cluster_name      = "spider-web-${env.BRANCH_NAME.replaceAll('/', '-')}"
                node_count        = 1
                node_machine_type = "e2-micro"
                network_name      = "spider-web-${env.BRANCH_NAME.replaceAll('/', '-')}-vpc"

                subnets = [
                  {
                    name          = "subnet-${env.BRANCH_NAME.replaceAll('/', '-')}"
                    ip_cidr_range = "10.40.0.0/16"
                  }
                ]

                db_instance_name = "spider-db-${env.BRANCH_NAME.replaceAll('/', '-')}"
                db_name          = "classroom_${env.BRANCH_NAME.replaceAll('/', '_')}"

                ssh_allowed_ip_cidr = "0.0.0.0/0"

                buckets = {
                  "spider-${env.BRANCH_NAME.replaceAll('/', '-')}-uploads" = {
                    public_access     = true
                    enable_versioning = false
                  }
                }
              """
              writeFile file: "infra/envs/${env.BRANCH_NAME}.tfvars", text: tfvars
              env.TF_VAR_FILE = "infra/envs/${env.BRANCH_NAME}.tfvars"
            } else {
              withCredentials([file(credentialsId: 'terraform-staging-tfvars', variable: 'TFVARS_FILE')]) {
                sh 'cp "$TFVARS_FILE" infra/envs/staging.tfvars'
                env.TF_VAR_FILE = 'infra/envs/staging.tfvars'
              }
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
            def workName = env.BRANCH_NAME ? env.BRANCH_NAME.replaceAll('/', '-') : 'default'
            sh """
              terraform workspace new "${workName}" || terraform workspace select "${workName}"
              terraform workspace show
            """
          }
        }
      }
    }

    stage('Terraform Plan') {
      steps {
        dir('infra') {
          sh "terraform plan -var-file=${env.TF_VAR_FILE} -out=tfplan.out"
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
              sh "terraform destroy -auto-approve -var-file=${env.TF_VAR_FILE}"
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
          def ws = env.BRANCH_NAME ? env.BRANCH_NAME.replaceAll('/', '-') : 'default'
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