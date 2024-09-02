Assesment steps and what principles were choseen:

1. Dockerize the app 
2. Jenkins file with
3. K8s setup and access desciption
4. External access 

======
Before we start any CI/CD setup there's a need to "Dockerize the app provioded"
--
1. Python app dockerization 
 This is Hello World Python app used for assesment.  
 To build and run the app please use the next commands: (change tag name if needed )
docker build -t hello_world:latest .  

To start the app please use the next statement 
docker run -d -p 8080:8080 hello_world 
CRTL+C to exit

Check app availability please use browser or curl command, you should see "Hello World" message
curl -X GET http://localhost:8080 

To publish Docker app in docker hub please use the next 
docker login
docker push vknysh79/hello_world:latest

Once you need to use this docker image
docker run -it -p 8080:8080 vknysh79/hello_world:latest

Full docker hub url
--
2. CI - Jenkins file includes several steps: 
SCM checkout ( webhook in jenkins: make sure that GitHub hook trigger for GITScm polling is checked)
BUILD - jenkins worker nodes must have docker cli installed
LOGIN (creds to docker hub stored in jenkins configuration)
PUSH 
CLEAN WorkSpace 

--
3. K8s and Argo CD , all required fiels stored in gitHub repo in K8S folder
I'm used to work with minikube therfore
minikube start 

It's rather to separate Teams, Applications, etc in different NameSpaces thus we create a new one NS  
kubectl create namespace argocd

cd K8S

Use helm chart to get argoCD ready 
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
helm install traefik traefik/traefik --namespace kube-system

Argo CD setup and network access from LH
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl port-forward svc/argocd-server -n argocd 8080:443
kubectl apply -f argocd-application.yaml 
kubectl apply -f middleware-ip-whitelist.yaml
kubectl apply -f ingressroute-hello-world-app.yaml

 in order to login to argoCD UI 
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

 all these fiels required for SSL 
kubectl aaply -f values.yaml
kubectl aaply -f acme-pvc.yaml
kubectl aaply -f ingressroute-tls.yaml

I've notified that if you  dont have DNS name to be used thus there's a chance to use external IP thus ingress route should be amened before you apply 
kubectl get services // and check External IP and paste to a myapp-ingressroute-ip.yaml
================================================================================================
!!!  ------- From Bonus Task - access to diffrent teams I would use the next approach ---------
--
 A. Staging approach is implemented in Jenkins_staging file + service and deployment yaml files. ( k8s/staging)
 B. Different NS and different Binding and Roles for Teams I would use the next approach 

 DevOps Group  - cluster-admin since it has a whole access 
 QA Group - Staging & Dev Environment - Full Access but No Delete
 All files located in K8S/access_roles 
 Apply DevOps admin access

kubectl apply -f devops-admin-role.yaml
kubectl apply -f devops-admin-binding.yaml

 Apply QA access in staging and dev namespaces
kubectl apply -f qa-role-staging.yaml
kubectl apply -f qa-role-binding-staging.yaml

kubectl apply -f qa-role-dev.yaml
kubectl apply -f qa-role-binding-dev.yaml

 Apply Developer read-only access in dev namespace
kubectl apply -f developer-view-role.yaml
kubectl apply -f developer-view-role-binding.yaml

------ what i would improve.

1. Jenkins nodes should have labels like small and large which allow implement paralelizm 
2. k8s should connect to jenkins as dynamic slave approach
3. If we use k8s for CI there's a need of multi-master k8s cluster
4. 





















