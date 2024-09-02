Before we start any CI/CD setup there's a need to "Dockerize the app provided"
--
1. Python app dockerization 
This is Hello World Python app used for assesment.  
To build and run the app please use the next commands: (change tag name if needed )
docker build -t hello_world:latest . 

this app needs requirement.txt file with flask package
also I added dockerignore file 

To start the app
docker run -d -p 8080:8080 hello_world 
CRTL+C to exit

Check app availability please use browser or curl command, you should see "Hello World" message
curl -X GET http://localhost:8080 

To publish Docker app in docker hub please use the next 
docker login
docker push vknysh79/hello_world:latest

Once you need to use this docker image
docker run -it -p 8080:8080 vknysh79/hello_world:latest

2. Continious Integration 
Let's try to implement IaC approach since Jenkins file and Argo defined as a code. Helm app will help with K8S internal app/services deployment 

Jenkins file includes several steps: 
SCM checkout ( webhook in jenkins: make sure that GitHub hook trigger for GITScm polling is checked)
BUILD - jenkins worker nodes must have docker cli installed
LOGIN (creds to docker hub stored in jenkins configuration)
PUSH 
CLEAN WorkSpace 

--
3. K8s and Argo CD, all required fiels stored in gitHub repo in K8S folder
I'm used to work with minikube 
Also, it's rather to separate Teams, Applications, etc in different NameSpaces thus we create and then use a new one NS for argoCD

Use helm chart to get Traefik  ready 
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install traefik traefik/traefik --namespace kube-system

Switch to  K8S folder 
ArgoCD setup and network access from 
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd-application.yaml 
middleware-ip-whitelist.yaml
ingressroute-hello-world-app.yaml

As far as I know password can be found like this (make sure you're in a proper NS)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

SSL setup described in
values.yaml
acme-pvc.yaml
ingressroute-tls.yaml

I've notified that if you dont have DNS name to be used thus there's a chance to use external IP thus ingress route should be amened before you apply 
kubectl get services // and check External IP and paste to a myapp-ingressroute-ip.yaml
================================================================================================
!!!  -- From Bonus Task - access to diffrent teams I would use the next approach --
--
 A. Staging approach is implemented in Jenkins_staging file + service and deployment yaml files. ( k8s/staging)
 B. Different NS and different Binding and Roles for Teams I would use the next approach 

DevOps Group  - cluster-admin since it has a whole access 
QA Group - Staging & Dev Environment - Full Access but No Delete (we need to get rid of mistaken delition)

K8S/access_roles 
DevOps admin access described in
devops-admin-role.yaml
devops-admin-binding.yaml

QA access in staging and dev namespaces described in
qa-role-staging.yaml
qa-role-binding-staging.yaml
qa-role-dev.yaml
qa-role-binding-dev.yaml

Apply Developer read-only access in dev namespace described in
developer-view-role.yaml
developer-view-role-binding.yaml

----
What principles I tried to use 
1. gitops: with Argocd to sync K8s with one point of truth - github
2. IaC: Jenkinsfile, K8s manifests - to allow repeatble deployments
3. Automation: reduce human eerror, reliability
4. CI/CD: jenkins to build app and push images, argo cd it to deploy app to k8s

----
Potential improvements in the future

1. Jenkins nodes should have labels like small, medium and large to in order to use resources properly
2. k8s should connect to jenkins as dynamic slave approach 
3. If we use k8s for CI there's a need of multi-master k8s cluster
4. the best solution is to have one-click solution with the next stack implemented ( AWS, Terrafrom, Ansible, K8S, Vault, ELK, LBs, Grafana+Prometheus, GitLAB as CI)
5. GitHub has some limitations for API connections, hence I'd recommend to use client's bitbucket or gitlab instances.
6. Code PRs/MRs should be integrated with JIRA.
7. For disaster recovery there should be one-click solution as well. ( migration to another cloud or DC)
8. 





















