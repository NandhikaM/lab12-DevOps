pipeline {
  agent any

  environment {
    DOCKERHUB_USER = 'nandhika1905'          // <-- change this
    IMAGE_NAME     = "${DOCKERHUB_USER}/bluegreen-node-app"
    IMAGE_TAG      = "${BUILD_NUMBER}"
    NETWORK        = 'bluegreen-net'
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Install & Test') {
      steps {
        sh 'node -v && npm -v'
        sh 'npm install'
        sh 'npm test'
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $IMAGE_NAME:$IMAGE_TAG -t $IMAGE_NAME:latest .'
      }
    }

    stage('Push to Docker Hub') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                                          usernameVariable: 'DH_USER',
                                          passwordVariable: 'DH_PASS')]) {
          sh 'echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin'
          sh 'docker push $IMAGE_NAME:$IMAGE_TAG'
          sh 'docker push $IMAGE_NAME:latest'
        }
      }
    }

    stage('Detect Live / Idle Environment') {
      steps {
        script {
          def live = sh(returnStdout: true,
                        script: 'docker exec nginx-proxy cat /etc/nginx/active.inc').trim()
          env.LIVE = live.contains('app-blue') ? 'blue' : 'green'
          env.IDLE = (env.LIVE == 'blue') ? 'green' : 'blue'
          env.IDLE_PORT = (env.IDLE == 'blue') ? '3001' : '3002'
          echo "LIVE = ${env.LIVE}, deploying new version to IDLE = ${env.IDLE}"
        }
      }
    }

    stage('Deploy to Idle Environment') {
      steps {
        sh '''
          docker rm -f app-$IDLE || true
          docker run -d --name app-$IDLE --network $NETWORK -p $IDLE_PORT:3000 \
            -e APP_COLOR=$IDLE -e APP_VERSION=$IMAGE_TAG \
            $IMAGE_NAME:$IMAGE_TAG
        '''
      }
    }

    stage('Health Check Idle') {
      steps {
        sh '''
          for i in $(seq 1 15); do
            if docker exec app-$IDLE wget -qO- http://localhost:3000/health | grep -q UP; then
              echo "app-$IDLE is healthy"; exit 0
            fi
            echo "waiting for app-$IDLE ($i/15)..."; sleep 2
          done
          echo "app-$IDLE failed health check"; exit 1
        '''
      }
    }

    stage('Approve Switch') {
      steps {
        input message: "Idle (${env.IDLE}) v${env.BUILD_NUMBER} is up at http://localhost:${env.IDLE_PORT}. Switch live traffic?"
      }
    }

    stage('Switch Traffic') {
      steps {
        sh '''
          OLD=$(docker exec nginx-proxy cat /etc/nginx/active.inc)
          docker exec nginx-proxy sh -c "echo 'server app-$IDLE:3000;' > /etc/nginx/active.inc"
          if docker exec nginx-proxy nginx -t; then
            docker exec nginx-proxy nginx -s reload
          else
            docker exec nginx-proxy sh -c "echo '$OLD' > /etc/nginx/active.inc"
            exit 1
          fi
        '''
      }
    }
  }

  post {
    success {
      echo "SUCCESS: ${env.IDLE} (v${env.BUILD_NUMBER}) is LIVE. ${env.LIVE} kept running for instant rollback."
    }
    failure {
      echo "FAILED: live traffic was NOT switched. ${env.LIVE} is still serving users."
    }
  }
}
