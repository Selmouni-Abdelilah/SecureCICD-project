pipeline {
    agent any
    tools {
        maven "maven"
        }
    environment {
        IMAGE_NAME="myproject"
        TAG="latest"
        dockerImage=""
        RESOURCE_GROUP='ressourcegrp'
        registryCredential = 'ACRcredentials'
        registryUrl = 'securecicdpipeline.azurecr.io'
        registryName = 'securecicdpipeline'
        AKS_CLUSTER_NAME = 'cicdcluster'
        APP_URL = 'http://20.127.252.195:8080/myproject/'
    }
    stages {
        stage('Fetch the code') {
            steps {
                checkout scmGit(branches: [[name: '*/master']], extensions: [], userRemoteConfigs: [[credentialsId: 'GitHubcredentials', url: 'https://github.com/Selmouni-Abdelilah/SecureCICD-project.git']])
            }
        }
        
        stage('Build Artifacts') {
            steps {
                sh 'mvn clean package'
            }
            post {
                success {
                    echo 'Archiving Artifacts'
                    archiveArtifacts artifacts: 'target/*.war'
                }
            }
            }
        stage('Code Quality Analysis + SAST'){
            steps {
                script {
                    def scannerHome = tool 'Sonar-Scanner';
                    withSonarQubeEnv(credentialsId: 'token_sonar',installationName:'Sonarqube'){
                        sh "${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=library \
                        -Dsonar.projectName=CICD \
                        -Dsonar.host.url=http://localhost:9090 \
                        -Dsonar.token=token_sonar \
                        -Dsonar.sources=src \
                        -Dsonar.java.binaries=target\
                        -Dsonar.java.libraries=target/library-0.0.1-SNAPSHOT/WEB-INF/lib/*.jar "
    
                    }
                }       
            }

        }
        stage("Quality Gate") {
            steps {
              timeout(time: 1, unit: 'HOURS') {
                waitForQualityGate abortPipeline: true
              }
            }
        }
        stage('SCA') {    
            steps {
                    snykSecurity(
                    snykInstallation: 'Snyk',
                    snykTokenId: 'snykapitoken',
                    failOnIssues: false,
                    failOnError: false,
                    additionalArguments: '--all-projects --detection-depth=3'
                    )
            }
        }
        stage ('Build Docker image') {
            steps {
                
                script {
                    dockerImage = docker.build IMAGE_NAME
                }
            }
        }
        stage("Docker image scanning"){
            steps {
                script{
                // Install trivy
                sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s  v0.44.1'
                sh 'chmod +x ./bin/trivy'
                sh 'curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/html.tpl > html.tpl'
                def dockerImageName = "${registryUrl}/${IMAGE_NAME}:${TAG}"
                // Scan all vuln levels
                sh "./bin/trivy image --ignore-unfixed --scanners vuln --vuln-type os,library --format template --template @html.tpl -o trivy-scan.html ${dockerImageName}"      
                    publishHTML target : [
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: '.',
                        reportFiles: 'trivy-scan.html',
                        reportName: 'Trivy Scan',
                        reportTitles: 'Trivy Scan'
                    ]
        
                }
            }
        }
        stage('Upload Image to ACR') {
        steps{   
            script {
                docker.withRegistry( "http://${registryUrl}",registryCredential ) {
                dockerImage.push()
                }
            }
        }
        }
        stage('Deploy to AKS') {
            steps {
                        sh 'az aks get-credentials --name $AKS_CLUSTER_NAME --resource-group $RESOURCE_GROUP'
                        sh 'az aks update -n $AKS_CLUSTER_NAME -g $RESOURCE_GROUP --attach-acr $registryName '
                        sh "helm upgrade my-project --set image.repository=${registryUrl}/${IMAGE_NAME}:${TAG} ./project-chart"
            }
        }
        stage('DAST'){
            steps{
                script{  
                    sh "chmod +x ${ZAPPROXY_HOME}/zap.sh"  
                    sh "${ZAPPROXY_HOME}/zap.sh -cmd -quickurl ${APP_URL} -quickout ${WORKSPACE}/zapReports.html"
                    publishHTML target : [
                                allowMissing: true,
                                alwaysLinkToLastBuild: true,
                                keepAll: true,
                                reportDir: '.',
                                reportFiles: 'zapReports.html',
                                reportName: 'ZAP Scan',
                                reportTitles: 'ZAP Scan'
                            ]
                 }
            }
        }
    } 
}
