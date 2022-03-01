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

       stage('Copy artifacts and wait for servers') {
            steps {
                copyArtifacts filter: '*', projectName: 'Viya 4 Deployment Workshop/001 - GenerateAnsibleArtifacts'

                sh label: 'make key read-only', script: '''ls -al
                chmod 0400 ./cloud-user-key.pem
                #ansible-playbook ./wait_for_servers.yaml
                ansible colls -m ping
                ls -al '''
            }
        }

        stage('rebuild cheatcodes') {
            steps {
                sh label: '', script: '''
                #ansible colls -m shell -a "hostname"

                ansible colls -m shell -a " cd /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes ;\
                                             rm -rf /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/* ;\
                                             git fetch --all ; \
                                             git reset --hard origin/${BRANCH} ; \
                                             bash /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/scripts/loop/GEL.02.CreateCheatcodes.sh start "
                '''
            }
        }

        stage('Cleanup the environment') {
            steps {
                sh label: 'Clean Slate', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "kubectl delete ns gelenv-stable big lab dev po testready dailymirror mirror harbor ; kubectl get ns "
                     ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' "
                     ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' "
                     ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'df -a' "
                '''
            }
        }


        stage('Testing gelenv-stable_order') {
            steps {
                sh label: 'Clean Slate', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "kubectl delete ns gelenv-stable lab dev po testready dailymirror mirror ; kubectl get ns "
                     ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' "
                '''
                sh label: 'do the gelenv-stable order deployment', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/01_000*.sh "
                '''
                sh label: 'wait for gelenv-stable', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "time gel_OKViya4 -n gelenv-stable --wait -ps --min-success-rate 10 --max-retries 60 --retry-gap 60"
                '''
                sh label: 'clean', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "kubectl delete ns gelenv-stable ; echo 'done' "
                     ansible colls  -B 3600 -P 60  -m shell -a  " kubectl get ns"
                     #ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' ; echo 'done'"
                '''
            }
        }

        stage('Testing HO 06_') {
            steps {
                sh label: 'Clean Slate', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "kubectl delete ns gelenv-stable lab dev po testready dailymirror mirror ; kubectl get ns "
                     #ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' "
                '''
                sh label: '06_031', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/06_031*.sh "
                '''
                sh label: '06_051', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/06_051*.sh "
                     #ansible colls  -B 3600 -P 60  -m shell -a  "time gel_OKViya4 -n lab --wait -ps --min-success-rate 10 --max-retries 60 --retry-gap 60"

                '''
                sh label: '06_061', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/06_061*.sh "
                '''
                // sleep time: 30, unit: 'MINUTES'
                sh label: 'check_lab_and_dev', script: '''
                     #ansible colls  -B 3600 -P 60  -m shell -a  "time gel_OKViya4 -n dev --wait -ps --min-success-rate 10 --max-retries 60 --retry-gap 60"
                '''

                sh label: '06_071', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/06_071*.sh "
                '''
                sh label: 'clean', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  " kubectl delete ns lab ; kubectl get ns"
                     ansible colls  -B 3600 -P 60  -m shell -a  " kubectl delete ns dev ; kubectl get ns"
                     ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' ; kubectl get ns"
                '''
                sh label: '06_015', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/06_015*.sh "
                '''
                sh label: '06_215', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/06_215*.sh "
                '''
                sh label: 'clean', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  " kubectl delete ns lab ; kubectl get ns"
                     ansible colls  -B 3600 -P 60  -m shell -a  " kubectl delete ns dev ; kubectl get ns"
                     ansible colls  -B 3600 -P 60  -m shell -a  " kubectl delete ns po ; kubectl get ns"
                     #ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' ; kubectl get ns"
                '''

            }
        }

        stage('Testing HO mirroring') {
            steps {
                sh label: 'Clean Slate', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "kubectl delete ns gelenv-stable lab dev po testready dailymirror mirror ; kubectl get ns "
                     ansible colls  -B 3600 -P 60  -m shell -a  "rm -rf ~/sas_repo/  ; echo 'done' "
                     ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' "
                '''
                sh label: '05_051', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/07_051*.sh "
                '''
                sh label: '05_052', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  " ansible all -m shell -a 'df -h' "
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/07_052*.sh "
                '''
                sh label: '05_053', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "bash -x /home/cloud-user/PSGEL255-deploying-viya-4.0.1-on-kubernetes/*/07_053*.sh "
                '''
                sh label: 'wait', script: '''
                     #ansible colls  -B 3600 -P 60  -m shell -a  "gel_OKViya4 -n mirrored  --wait -ps --min-success-rate 50 --max-retries 60 --retry-gap 60"
                '''
                sh label: 'stop', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "kubectl delete ns mirrored ; kubectl get ns"
                '''
                sh label: 'clean', script: '''
                     ansible colls  -B 3600 -P 60  -m shell -a  "rm -rf ~/sas_repo/  ; echo 'done' "
                     #ansible colls  -B 3600 -P 60  -m shell -a  "ansible sasnode* -m shell -a 'docker image prune -a --force' ; kubectl get ns"
                '''
            }
        }
    }

    post {
        success {
            echo 'We are done here'
        }
    }

}