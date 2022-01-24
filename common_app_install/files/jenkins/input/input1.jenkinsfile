pipeline {
  agent any
  stages {
    stage ("Prompt for input") {
      steps {
        script {
          env.USERNAME = input message: 'Please enter the username',
                             parameters: [string(defaultValue: '',
                                          description: '',
                                          name: 'Username')]
          env.PASSWORD = input message: 'Please enter the password',
                             parameters: [password(defaultValue: '',
                                          description: '',
                                          name: 'Password')]
        }
        echo "Username: ${env.USERNAME}"
        echo "Password: ${env.PASSWORD}"
      }
    }
  }
}
