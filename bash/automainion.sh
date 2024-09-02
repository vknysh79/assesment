#!/bin/bash
set -e

detect_package_manager() {
    if command -v yum &>/dev/null; then
        echo "yum"
    elif command -v dnf &>/dev/null; then
        echo "dnf"
    elif command -v apt-get &>/dev/null; then
        echo "apt-get"
    else
        echo "Unsupported OS"
        exit 1
    fi
}

PACKAGE_MANAGER=$(detect_package_manager)

# Step 1: Install necessary tools based on OS
echo "Installing necessary tools..."
if [ "$PACKAGE_MANAGER" = "yum" ] || [ "$PACKAGE_MANAGER" = "dnf" ]; then
    # For RPM-based systems
    sudo $PACKAGE_MANAGER install -y epel-release
    sudo $PACKAGE_MANAGER install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Install Jenkins
    sudo $PACKAGE_MANAGER install -y java-11-openjdk
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
    sudo $PACKAGE_MANAGER install -y jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins

elif [ "$PACKAGE_MANAGER" = "apt-get" ]; then
    # For Debian-based systems
    sudo apt-get update
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    sudo apt-get install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker

    # Install Jenkins
    curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee \
      /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
      https://pkg.jenkins.io/debian binary/ | sudo tee \
      /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jdk jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
else
    echo "Unsupported OS detected. Exiting."
    exit 1
fi

# Step 2: Install Minikube and kubectl
echo "Installing Minikube and kubectl..."
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube /usr/local/bin/

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Step 3: Start Minikube with Docker driver
echo "Starting Minikube..."
minikube start --driver=docker

# Step 4: Deploy Jenkins pipeline and Dockerize the app
echo "Configuring Jenkins for Docker..."
cat <<EOF > Jenkinsfile
pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                sh 'docker build -t vknysh79/hello-world-app:latest .'
            }
        }
        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                    sh 'echo \$DOCKER_PASSWORD | docker login -u \$DOCKER_USERNAME --password-stdin'
                    sh 'docker push vknysh79/hello-world-app:latest'
                }
            }
        }
    }
}
EOF

# Step 5: Apply Kubernetes manifests
echo "Applying Kubernetes manifests..."
cat <<EOF > hello-world-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-world-app
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-world-app
  template:
    metadata:
      labels:
        app: hello-world-app
    spec:
      containers:
      - name: hello-world-app
        image: vknysh79/hello-world-app:latest
        ports:
        - containerPort: 8080
EOF

kubectl apply -f hello-world-deployment.yaml

# Step 6: Expose the application using NodePort
echo "Exposing application using NodePort..."
kubectl expose deployment hello-world-app --type=NodePort --port=8080

# Step 7: Install ArgoCD
echo "Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Step 8: Set up RBAC roles for DevOps, QA, and Developers
echo "Setting up RBAC roles..."
cat <<EOF > rbac-config.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: devops-admin
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: staging
  name: qa-role
rules:
- apiGroups: [""]
  resources: ["pods", "deployments", "statefulsets", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: developer-role
rules:
- apiGroups: [""]
  resources: ["pods", "deployments", "services"]
  verbs: ["get", "list", "watch"]
EOF

kubectl apply -f rbac-config.yaml

# Step 9: Provision Staging Environment
echo "Creating Staging Environment..."
kubectl create namespace staging
kubectl apply -f hello-world-deployment.yaml -n staging

# Step 10: Provide access via ArgoCD
echo "Configuring ArgoCD for staging..."
cat <<EOF > staging-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: staging-app
  namespace: argocd
spec:
  destination:
    namespace: staging
    server: https://kubernetes.default.svc
  source:
    path: .
    repoURL: 'https://github.com/your-repo/hello-world-app.git'
    targetRevision: HEAD
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

kubectl apply -f staging-app.yaml

echo "Setup Complete!"