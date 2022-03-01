pipeline {

    agent { label 'geljsl01'}

    stages {
        stage('Prepping Environment') {
            steps {
                echo "Running ${env.JOB_NAME} in ${env.WORKSPACE} on ${env.JENKINS_URL}"
                cleanWs(patterns: [[pattern: '*', type: 'INCLUDE']])
                sh 'printenv'
            }
        }

       stage('Copy artifacts and git clone the project') {
            steps {
                copyArtifacts filter: '*', projectName: 'Viya 4 Deployment Workshop/001 - GenerateAnsibleArtifacts'

                git branch: "${ALT_BRANCH}", url: 'https://gitlab.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes.git'

                sh label: 'make key read-only', script: '''
                    chmod 0400 ./cloud-user-key.pem
                    #ansible-playbook ./wait_for_servers.yaml
                    #ansible colls -m ping
                    ls -al
                '''

                sh label: 'display content', script: '''
                    ls -al
                '''
            }
        }

       stage('Book Collection') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'cf76689d-66d2-4fe5-abc5-70125199b46a', passwordVariable: 'USER_PASS', usernameVariable: 'USER_ID')]) {

                sh label: 'reserve collection', script: '''

                   curl --user ${USER_ID}:${USER_PASS} \\
                        -H "Content-Type: application/json" \\
                        http://race.exnet.sas.com/api/reservations?AppId=tst | jq

                    bash -x ./scripts/automation/race.01.book.collection.sh \\
                    	--user ${USER_ID} \\
                        --pass ${USER_PASS} \\
                        --coll-id ${COLL_ID} \\
                        --coll-comment "_BREAK_ ${COLL_COMMENT}" \\
                        --coll-hours ${COLL_HOURS} \\
                        --additional-emails ${ADDITIONAL_EMAILS}
                    '''
                }
            }
       }

       stage('Wait for RACE Collection') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'cf76689d-66d2-4fe5-abc5-70125199b46a', passwordVariable: 'USER_PASS', usernameVariable: 'USER_ID')]) {

                sh label: 'wait for collection', script: '''

                    rm inventory.ini
                    whoami
                    pwd
                    ls -altr

                    RESERVATION_ID="$(cat ./res.id.txt)"

                    echo ${RESERVATION_ID}

                    bash -x ./scripts/automation/race.02.wait.for.collection.sh \\
                        --user ${USER_ID} \\
                        --pass ${USER_PASS} \\
                        --reservation-id ${RESERVATION_ID} \\
                        --sleep 30 \\
                        --retries 150

                    '''
                }
            }
       }

       stage('Wait for Linux machines') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'cf76689d-66d2-4fe5-abc5-70125199b46a', passwordVariable: 'USER_PASS', usernameVariable: 'USER_ID')]) {

                sh label: 'wait for linux', script: '''
                    bash -x ./scripts/automation/race.03.wait.for.linux.servers.sh
                    '''
                }
            }
       }

       stage('Do the Enable on the collection ') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'cf76689d-66d2-4fe5-abc5-70125199b46a', passwordVariable: 'USER_PASS', usernameVariable: 'USER_ID')]) {
                sh label: 'identify node1', script: '''
                    node1ip=$(ansible all -m shell -a " cat /etc/hosts | grep sasnode01 | awk '{print \\$1}' " | grep -v CHANGED | sort -u)
                    echo "The IP of Node1 is: $node1ip"
                    '''

                sh label: 'quick test', script: '''

                    ansible all -m shell -b -a "hostname -f ; rm -rf /tmp/testclone"


                    #ansible all -m shell -b -a " mv /opt/raceutils/raceapiscripts/getdescription.py \\
                    #     /opt/raceutils/raceapiscripts/getdescription.moved"

                    # run on all the nodes to enable
                    ansible all ${ASYNC} -m shell -b -a " curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh | sed 's|_BREAK_|_NOBREAK_|g' | bash -s enable https://gelgitlab.race.sas.com/GEL/workshops/PSGEL255-deploying-viya-4.0.1-on-kubernetes.git \${ALT_BRANCH}"

                    # to have a good exit code here:
                    ls -al
                    '''
                }
            }
        }

       stage('Do the Start on the collection ') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'cf76689d-66d2-4fe5-abc5-70125199b46a', passwordVariable: 'USER_PASS', usernameVariable: 'USER_ID')]) {

                sh label: 'start', script: '''
                    # do the start now

                    ansible all ${ASYNC} -m shell -a " curl -fsSL https://gelgitlab.race.sas.com/GEL/utilities/raceutils/raw/master/bootstrap/bootstrap.collection.sh | sed 's|_BREAK_|_NOBREAK_|g' | sudo bash -s start "

                    ansible all  -m shell -a " cat /etc/hosts | grep sasnode01 | awk '{print \\$1}' " | grep -v CHANGED | sort -u

                    node1ip=$(ansible all -m shell -a " cat /etc/hosts | grep sasnode01 | awk '{print \\$1}' " | grep -v CHANGED | sort -u)
                    echo $node1ip
                    printf "${node1ip}" >> node1.ini
                    '''
                }
            }
        }

       stage('Deploy and wait for dailymirror') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'cf76689d-66d2-4fe5-abc5-70125199b46a', passwordVariable: 'USER_PASS', usernameVariable: 'USER_ID')]) {

                sh label: 'deploy_dailymirror', script: '''
                    # do the start now
                    #ansible all ${ASYNC} -i ./node1.ini -m shell -a " bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/05_Deployment_tools/96_deploy_dailymirror.sh "
                    '''

                sh label: 'wait for dailymirror', script: '''
                    # do the start now
                    #ansible all ${ASYNC} -i ./node1.ini -m shell -a " time gel_OKViya4 -n dailymirror -ps --wait --min-success-rate 90 --max-retries 60 --retry-gap 60  "
                    '''

                }
            }
       }

       stage('Deploy and wait for lab') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'cf76689d-66d2-4fe5-abc5-70125199b46a', passwordVariable: 'USER_PASS', usernameVariable: 'USER_ID')]) {

                sh label: 'deploy_lab', script: '''
                    # do the start now
                    #ansible all  ${ASYNC} -i ./node1.ini -m shell -a " bash -x ~/PSGEL255-deploying-viya-4.0.1-on-kubernetes/_autodeploy-lab_.sh "
                    '''


                sh label: 'wait for lab', script: '''
                    # do the start now
                    #ansible all  ${ASYNC} -i ./node1.ini -m shell -a " time gel_OKViya4 -n lab -ps --wait --min-success-rate 90 --max-retries 60 --retry-gap 60  "
                    '''

                }
            }
       }



    }

     post {
         always {
             echo 'This will always run'
         }
         success {
             echo 'This will run only if successful'
         }
         failure {
             mail bcc: '', body: "<b>Example</b><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL of build: ${env.BUILD_URL}", cc: '', charset: 'UTF-8', from: '', mimeType: 'text/html', replyTo: '', subject: "ERROR CI: Project name -> ${env.JOB_NAME}", to: "${ADDITIONAL_EMAILS}";
         }
         unstable {
             echo 'This will run only if the run was marked as unstable'
         }
         changed {
             echo 'This will run only if the state of the Pipeline has changed'
             echo 'For example, if the Pipeline was previously failing but is now successful'
         }
     }


}



