pipeline {
    agent {
        label 'qd_slave'
    }
    environment { 
        ANSIBLE_HOME='/data/apps/data/wanghaifeng/ansible'
        ANSIBLE_CONFIG="${ANSIBLE_HOME}/ansible.cfg"
        AN_PLAY_HOME="${ANSIBLE_HOME}/playbooks"
        project_git_url="{{project_git_url}}"
        MAVEN_HOME="/data/apps/opt/maven"
    }
    options {
        buildDiscarder logRotator(artifactDaysToKeepStr: '60', artifactNumToKeepStr: '20', daysToKeepStr: '60', numToKeepStr: '20')
    }
    parameters {
        gitParameter branch: '', 
                     branchFilter: '.*', 
                     defaultValue: 'master', 
                     description: '', 
                     name: 'TAG', 
                     quickFilterEnabled: false, 
                     selectedValue: 'NONE', 
                     sortMode: 'NONE', 
                     tagFilter: '*', 
                     useRepository: '{{project_git_url}}',
                     type: 'PT_BRANCH_TAG'
    }
   //tools {
      // Install the Maven version configured as "M3" and add it to the path.
      //maven "qd_maven-3.5_private_nexus"
   //}

   stages {
       stage('SourceCheckout') {
           steps {
               checkout([$class: 'GitSCM', 
                         branches: [[name: "${params.TAG}"]], 
                         doGenerateSubmoduleConfigurations: false, 
                         extensions: [], 
                         gitTool: 'Default', 
                         submoduleCfg: [], 
                         userRemoteConfigs: [[url: "${project_git_url}"]]
                        ])
           }
       }
      stage('Build') {
          steps {
             // Get some code from a GitHub repository
             //git branch: "${params.TAG}", credentialsId: '15865d01-62a1-45ff-9f55-d95374652f27', url: "${project_git_url}"

             // Run Maven on a Unix agent.
             sh "mvn -T 10 {{project_maven_options}} -f pom.xml"

             sh 'env'
          }
       }
    }
    post { 
        success { 
            sh "ansible-playbook ${AN_PLAY_HOME}/{{project_local_workdir}}/deploy_message.yml"
        }
    }
}
