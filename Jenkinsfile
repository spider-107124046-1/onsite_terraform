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

    stage('Terraform Init') {
      steps {
        sh 'terraform init -backend-config=envs/staging.backend.tf'
      }
    }

    stage('Set Terraform Workspace') {
      steps {
        sh '''
          terraform workspace new "${BRANCH_NAME}" || terraform workspace select "${BRANCH_NAME}"
        '''
      }
    }

    stage('Terraform Plan') {
      steps {
        sh 'terraform plan -var-file=envs/staging.tfvars -out=tfplan.out'
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
}
