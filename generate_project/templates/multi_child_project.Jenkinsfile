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
         choice choices: ['child_project1', 'child_project2', '.'], description: '', name: 'CHILD_PROJECT'
    }
    //tools {
       // Install the Maven version configured as "M3" and add it to the path.
    //   maven "qd_maven-3.5_private_nexus"
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
            // Run Maven on a Unix agent.
            sh "${MAVEN_HOME}/bin/mvn -T 10 {{project_maven_options}} -f ${CHILD_PROJECT}/pom.xml"
            sh 'env'
         }
      }
   }
   post { 
        success { 
            sh '''
                cd ${AN_PLAY_HOME}/{{project_local_workdir}}
                if [ "$CHILD_PROJECT" == "." ];then
                    child_progs="{{ projects | json_query('[*].project_prog_name') | join(' ')}}"
                    for prog_var_file in ${child_progs};do
                    	ansible-playbook deploy_postloan.yml -e @vars/${prog_var_file}.yml
                    done
                else
                    ansible-playbook deploy_postloan.yml -e @vars/${CHILD_PROJECT}.yml
                fi
               '''
        }
    }
}

