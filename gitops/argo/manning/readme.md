# Argo CD Guide

## Table of Contents

1. [What is ArgoCD](#What-is-ArgoCD)
   1. [Main use cases](#Main-use-cases)
   2. [Core Concepts](#Core-Concepts)
   3. [Architecture](#Architecture)
2. [Deploy your first application](#Deploy-your-first-application)
   1. [Deploy your first application](#Deploy-your-first-application)
   2. [Inspect application using user interface](#Inspect-application-using-user-interface)
3. [Deep dive into Argo CD features](#Deep-dive-into-Argo-CD-features)
   1. [GitOps driven deployment](#GitOps-driven-deployment)
   2. [Resource Hooks](#Resource-Hooks)
   3. [Post-deployment verification](#Post-deployment-verification)
4. [Enterprise features](#Enterprise-features)
   1. [Single sign-on](#Single-sign-on)
   2. [Access control](#Access-control)
5. [Summary](#Summary)
6. [Reference](#Reference)


## What is ArgoCD

Argo CD is an open-source GitOps operator for Kubernetes[1]. The project is a part of the Argo family - a set of cloud-native tools for running and managing jobs and applications on Kubernetes. Along with Argo Workflows, Rollouts, and Events, Argo CD focuses on application delivery use cases and makes it easier to combine three modes of computing: services, workflows, and event-based processing.
The company behind Argo CD is Intuit - the creator of TurboTax and QuickBooks. In early 2018 Intuit decided to adopt Kubernetes to speed up cloud migration. At the time, the market already had several successful continuous deployment tools for Kubernetes, but none of them fully satisfied Intuit’s needs. So instead of adopting an existing solution, the company decided to invest in a new project and started working on Argo CD. So what is so special about Intuit's requirements? The answer to that question explains how Argo CD is different from other Kubernetes CD tools and explains the main project use cases.

#### Main use cases

The importance of a GitOps methodology and benefits of representing infrastructure as code is not questionable. However, the enterprise-scale applies additional requirements. The Intuit is a cloud-based software-as-a-service company. With around five thousand developers, the company successfully runs hundreds of micro-services on-premise and in the cloud. Given that scale, it was unreasonable to expect that every team would run its own Kubernetes cluster. Instead, it was decided that a centralized platform team would run and maintain a set of multi-tenant clusters for the whole company. At the same time, the end-users should have the freedom and necessary tools to manage workloads in those clusters. These considerations have defined the following additional requirements on top of the decision to use GitOps:
Available as a service
The simple onboarding process is extremely important if you are trying to move hundreds of micro-services to Kubernetes. Instead of asking every team to install, configure, and maintain the deployment operator, it should be provided by the centralized team. With several thousands of new users, SSO integration is crucial. The service must integrate with various SSO providers instead of introducing its own user management.
Enable multi-tenancy and multi-cluster management
In multi-tenant environments, users need an effective and flexible access control system. The Kubernetes has a great built-in role-based access control system, but that is not enough when you have to deal with hundreds of clusters. The continuous deployment tool should provide access control on top of multiple clusters and seamlessly integrate with existing SSO providers.
Enable observability

Last but not least, the continuous deployment tool should provide developers insights about the state of managed applications. That assumes the user-friendly interface that quickly answers the following questions:
•	Is the application configuration in sync with the configuration defined in Git?
•	What exactly is not matching?
•	Is the application up and running?
•	What exactly is broken?

The company needed the GitOps operator ready for enterprise scale. The team evaluated several GitOps operators, but none of them satisfied all requirements, so it was decided to implement Argo CD.

Exercise 9.1
Reflect on your organization's needs and compare it to use cases that Argo CD is focused on. Try to answer if Argo CD solves the pain points your team has.

#### Core Concepts

In order to effectively use the Argo CD, we should understand two basic concepts: the Application and the Project. Let’s have a closer look at the application first.
Application
The Application - provides a logical grouping of Kubernetes resources and defines the resources manifests source and destination.
The Application source - includes the repository URL and the directory inside of the repository. Typically repositories include multiple directories, one per application environments such as QA and Production. The sample directory structure of such a repository is represented below:

```bash
├── prod
│ └── deployment.yaml
└── qa
  └── deployment.yaml
```

Each directory does not necessarily contain plain YAML files. Argo CD does not enforce any configuration management tool and instead provides first-class support for various config management tools. So the directory might as well contain a Helm chart definition or YAML
along with Kustomize overlays.
The Application destination defines where resources must be deployed and includes the API server URL of the target Kubernetes cluster, along with the cluster namespace name. The API server URL identifies the cluster where all application manifests must be deployed. It is impossible to deploy application manifests across several clusters, but different applications might be deployed into different clusters. The namespace name is used to identify the target namespace of all namespace level application resources.
So the Argo CD application represents an environment deployed in the Kubernetes cluster and connects it to the desired state stored in the Git repository.

Exercise 9.2

Consider the real service deployed in your organization and come up with a list of Argo CD applications. Define the source repository URL, directory, and target cluster with the namespace for one of the applications from your list.
In addition to the source and destination, the Argo CD application has another two important properties: Sync and Health statuses.
Sync Status answers whether the observed application resources state deviates from the resources state stored in the Git repository. The logic behind deviation calculation is equivalent to the logic of the kubectl diff command. The possible values of a sync status are In-Sync and Out-Of-Sync. The In-Sync status means that each application resource is found and fully matching to the expected resource state. The Out-Of-Sync status means that at least one resource status is not matching to the expected state or not found in the target cluster.
The health status aggregates information about the observed health status of each resource that comprises the application. The health assessment logic is different for each Kubernetes resource type and resulted in one of the following values:
•	Healthy - for example, the Kubernetes deployment is considered Healthy if the required number of Pods is running and each Pod successfully passing both readiness and liveness probes
•	Progressing - represents a resource that is not healthy yet but still expected to reach a healthy state. The Deployment is considered progressing if it is not healthy yet but still without time limit specified by the progressingDeadlineSeconds [2]field.
•	Degraded - the antipode of Healthy status. The example is a Deployment that could not reach a healthy status within an expected timeout.
•	Missing - represents the resource that is stored in Git but not deployed to the target cluster.
The aggregated application status is the worst status of every application resource. The Healthy status is the best, then goes Progressing, Degraded, and the Missing is the worst. So if all application resources are Health and only one is Degraded, then aggregated status is also Degraded.

Exercise 9.3

Consider an application consisting of two Deployments. The following information is known about the resources:
•	Deployment one has an image that does not match the image stored in the Git repository. All Deployment Pods have failed to start for several hours while Deployment progressingDeadlineSeconds is set to 10 minutes.
•	The Deployment two is not fully matching the expected state and has all Pods running.

Please answer what are the application Sync and Health statuses?
The Health and Sync statuses answers the two most important questions about an application:
•	Is my application working?
•	Am I running what is expected?

Project
Argo CD applications provide a very flexible way to manage different applications independently from each other. This functionality provides very useful insights to the team about each piece of infrastructure and greatly improves productivity. However, this is not enough to support multiple teams with different access levels:
•	The mixed list of applications creates confusion that creates a human error possibility.
•	Different teams have different access levels. As has been described in Chapter 6, the individual might use the GitOps operator to escalate his own permissions to get full cluster access.
The workaround for these issues is a separate Argo CD instance for each team. This is not a perfect solution since a separate instance means management overhead. In order to avoid management overhead, Argo CD introduces the Project abstraction. Figure 9.1 illustrates the relationship between applications and projects.

![application project relation](https://raw.githubusercontent.com/zillani/img/master/argo-img/app-projects.png)
 
The Project - provides a logical grouping of applications, isolates teams from each other, and allows for fine-tuning access control in each Project.
In addition to the separating sets of applications, the Project provides the following set of features:
•	Restricts which Kubernetes clusters and Git repositories might be used by project applications.
•	Restricts which Kubernetes resources can be deployed by each application within the project.

Exercise 9.4

Try to come up with a list of projects in your organization. Using projects, you can restrict what kind of resource users can deploy, source repositories, and destination clusters available within the project. Which restrictions would you configure for your projects?

### Architecture

Try to come up with a list of projects in your organization. Using projects, you can restrict what kind of resource users can deploy, source repositories, and destination clusters available within the project. Which restrictions would you configure for your projects?

At first glance, the implementation of the GitOps operator does not look too complex. In theory, all you need is to clone the Git repository with manifests and use kubectl diff and kubectl apply to detect and handle config drifts. This is true until you are trying to automate this process for multiple teams and managing the configuration of dozens of clusters simultaneously. Logically this process is split into three phases, and each phase has its own challenges:
•	Retrieve resource manifests.
•	Detect and fix the deviations.
•	Present the results to end-users.
Each phase consumes different resources, and the implementation of each phase has to scale differently. A separate Argo CD component is responsible for each phase.


![components](https://raw.githubusercontent.com/zillani/img/master/argo-img/components.png)
 
Let's go through each phase and the corresponding Argo CD component implementation details.
Retrieve resource manifests
The manifest generation in Argo CD is implemented by the “argocd-repo-server” component. This phase presents a whole set of challenges.

![architecture](https://raw.githubusercontent.com/zillani/img/master/argo-img/repo-architecture.png)
 
The controller maintains a lightweight cache of each managed cluster and updates it in the background using Kubernetes watch API. This allows the controller to perform reconciliation on an application within a fraction of a second and empowers it to scale and manage dozens of clusters simultaneously. After each reconciliation, the controller has the exhausting information about each application resource, including the sync and health status. The controller saves that information into the Redis cluster so it could be presented to the end-user later.
Present the results to end-users
Finally, the reconciliation results must be presented to end-users. This task is performed by the "argocd-server" component. While the heavy lifting is already done by the "argocd-repo-server" and "argocd-application-controller", this last phase has the highest resiliency requirements. The "argocd-server" is a stateless web application that loads the information about reconciliation results and powers the web user interface.
The architecture design allows Argo CD to serve GitOps operations a whole company and minimize the maintenance overhead.

Exercise 9.5

Which components serve user requests and require multiple replicas for resiliency?
Which components might require a lot of memory to scale?

## Deploy your first application

While Argo CD is an enterprise-ready, complex distributed system, it is still lightweight and can easily run on minikube. The installation is trivial and includes a few simple steps. Please refer to Appendix B for more information on how to install Argo CD or follow the official Argo CD instructions[3].

#### Deploying the first application

As soon as Argo CD is running, we are ready to deploy our first application. As it's been mentioned before, to deploy an Argo CD application, we need to specify the Git repository that contains deployment manifests and target Kubernetes cluster and namespace. To create the Git repository for this exercise, open the https://github.com/gitopsbook/sample-app-deployment and create a repository fork[4]. Argo CD can deploy into the external cluster as well as into the same cluster where it is installed. Let's use the second option and deploy our application into the default namespace of our Minikube cluster.
The application might be created using the Web user interface, using the CLI, or even programmatically using the REST or gRPC APIs. Since we already have Argo CD CLI installed and configured, let's use it to deploy an application. Please go ahead and execute the following command to create an application:

```bash
argocd app create sample-app \
  --repo https://github.com/<username>/sample-app-deployment \
  --path . \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

As soon as the application is created, we can use the Argo CD CLI to get the information about the application state. Use the following command to get the information about the “sample-app” application state:

```bash
argocd app get sample-app

Name:               sample-app
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://<host>:<port>/applications/sample-app
Repo:               https://github.com/<username>/sample-app-deployment
Target:
Path:               .
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        OutOfSync from  (09d6663)
Health Status:      Missing
 
GROUP  KIND        NAMESPACE  NAME        STATUS     HEALTH   HOOK  MESSAGE
       Service     default    sample-app  OutOfSync  Missing
apps   Deployment  default    sample-app  OutOfSync  Missing
```
As we can see from the command output, the application is out-of-sync and not healthy. By default, Argo CD does not push resources defined in the Git repository into the cluster even if it detects the deviation. In addition to the high-level summary, we can see the details of every application resource. Argo CD detected that the application is supposed to have a Deployment and a Service, but both resources are missing. To deploy the resources, we need to either configure automated application syncing using the sync policy[5] or trigger syncing manually. To trigger the sync and deploy the resources use the following command:

```bash
argocd app sync sample-app
TIMESTAMP                  GROUP        KIND   NAMESPACE                NAME    STATUS    HEALTH        HOOK  MESSAGE
2020-03-17T23:16:50-07:00            Service     default            sample-app  OutOfSync  Missing
2020-03-17T23:16:50-07:00   apps  Deployment     default            sample-app  OutOfSync  Missing
 
Name:               sample-app
Project:            default
Server:             https://kubernetes.default.svc
Namespace:          default
URL:                https://<host>:<port>/applications/sample-app
Repo:               https://github.com/<username>/sample-app-deployment
Target:
Path:               .
SyncWindow:         Sync Allowed
Sync Policy:        <none>
Sync Status:        OutOfSync from  (09d6663)
Health Status:      Missing
 
Operation:          Sync
Sync Revision:      09d6663dcfa0f39b1a47c66a88f0225a1c3380bc
Phase:              Succeeded
Start:              2020-03-17 23:17:12 -0700 PDT
Finished:           2020-03-17 23:17:21 -0700 PDT
Duration:           9s
Message:            successfully synced (all tasks run)
 
GROUP  KIND        NAMESPACE  NAME        STATUS     HEALTH       HOOK  MESSAGE
       Service     default    sample-app  Synced     Healthy            service/sample-app created
apps   Deployment  default    sample-app  Synced     Progressing        deployment.apps/sample-app created
```

As soon as the sync is triggered, Argo CD will push the manifests stored in Git into the Kubernetes cluster and then re-evaluates the application state. The final application state is printed to the console when the synchronization completes. The “sample-app” application was successfully synced, and each result matches the expected state.

#### Inspect application using user interface

In addition to the CLI and API, Argo CD provides a user-friendly Web interface. Using the web interface, you might get the high-level view of all your applications deployed across multiple clusters as well as get very detailed information about every application resource. Open the https://<host>:<port> URL to see the applications list in the Argo CD user interface.

![application list](https://raw.githubusercontent.com/zillani/img/master/argo-img/app-list.png)
 
The applications list page provides high-level information about all deployed applications, including health and synchronization status. Using this page, you can quickly find if any of your applications have degraded or have configuration drift. The user interface is designed for large enterprises and able to handle hundreds of applications. You can use search and various filters to quickly find the desired applications.

Exercise 9.6
Experiment with the filters and page view settings to learn which other features available in the applications list page.
The additional information about the application is available on the application details page. Navigate to the application details page by clicking on the “sample app” application tile.

![application Detail](https://raw.githubusercontent.com/zillani/img/master/argo-img/app-details.png)
 
The application details page visualizes the application resources hierarchy and provides additional details about synchronization and health status. Let’s take a look closer at the application resources tree and learn which features it provides.
The root element of the resource tree is the application itself. The next level consists of managed resources. The managed resources are resources that manifest defined in Git and controlled by Argo CD explicitly. As we’ve learned in chapter 2, the Kubernetes controllers often leverage delegation and create child resources to delegate the work. The third and deeper levels represent such resources. That provides complete information about every application element and makes the application details page an extremely powerful Kubernetes dashboard.
In addition to the information, the user interface allows executing various actions against each resource. It is possible to delete any resource, recreate it by running sync action, update the resource definition using a built-in YAML editor, and even run resource specific actions such as Deployment restart.

Exercise 9.7

Go ahead, use the Application details page to inspect your application. Try to find how to view the resource manifests; locate Pods, and find a way to see the live logs.

## Deep dive into Argo CD features

So far, we’ve learned how to deploy new applications using Argo CD and get detailed application information using CLI and the user interface. Next, let’s learn how to deploy a new application version using GitOps and Argo CD.

#### GitOps driven deployment

In order to perform GitOps deployment, we need to update resource manifests and let the GitOps operator push changes into the Kubernetes cluster. As a first step clone the deployment repository using the following command:

```bash
git clone git@github.com:<username>/sample-app-deployment.git
cd sample-app-deployment
```

Next, use the following command to change the image version of the Deployment resource.

```bash
sed -i '' 's/sample-app:v.*/sample-app:v0.2/' deployment.yaml

Use the git diff command to make sure that your Git repository has expected changes:
git diff
diff --git a/deployment.yaml b/deployment.yaml
index 5fc3833..397d058 100644
--- a/deployment.yaml
+++ b/deployment.yaml
@@ -16,7 +16,7 @@ spec:
       containers:
       - command:
         - /app/sample-app
-        image: gitopsbook/sample-app:v0.1
+        image: gitopsbook/sample-app:v0.2
         name: sample-app
         ports:
         - containerPort: 8080
```

Finally use git commit and git push to push changes to the remote Git repository:

```bash
git commit -am "update deployment image"
git push
```

Let’s use the Argo CD CLI to make sure that Argo CD correctly detected manifest changes in Git and then trigger a synchronization process to push the changes into the Kubernetes cluster.

```bash
argocd app diff sample-app --refresh
===== apps/Deployment default/sample-app ======
21c21
<         image: gitopsbook/sample-app:v0.1
---
>         image: gitopsbook/sample-app:v0.2
```

Exercise 9.8

Open Argo CD UI and use the application details page to check application sync status and inspect managed resources status.
Use the argocd sync command to trigger the synchronization process:

argocd app sync sample-app

Great, you just performed GitOps deployment using Argo CD!

### Resource Hooks

The resource manifests syncing is just the basic use-case. In real life, we often need to execute additional steps before and after actual deployment. For example, set the maintenance page, execute database migration before the new version deployment and finally remove the maintenance page.
Traditionally these deployment steps are scripted in the CI pipeline. However, this again requires production access from the CI server that possesses a security threat. To solve that problem, Argo CD provides a feature called Resource Hooks. These hooks allow running custom scripts, typically packaged into a Pod or a Job, inside of the Kubernetes cluster during the synchronization process.
The hook is a Kubernetes resource manifest stored in the Git repository and annotated with the argocd.argoproj.io/hook annotation. The annotation value contains a comma-separated list of phases when the hook is supposed to be executed. Following phases are supported:
•	PreSync - Executes prior to the applying of the manifests.
•	Sync - Executes after all PreSync hooks completed and were successful, at the same time as the apply of the manifests.
•	Skip - Indicates to Argo CD to skip the apply of the manifest.
•	PostSync - Executes after all Sync hooks completed and were successful, a successful apply, and all resources in a Healthy state.
•	SyncFail - Executes when the sync operation fails.
The hooks are executed inside of the cluster, so there is no need to access the cluster from the CI pipeline. The ability to specify the sync phase provides the necessary flexibility and allows a mechanism to solve the majority of real-life deployment use cases.

![synchronize](https://raw.githubusercontent.com/zillani/img/master/argo-img/synchornize.png)
 
It is time to see the hooks feature in action! Add the hook definition into the sample app deployment repository and push changes to the remote repository:

```bash
git add pre-sync.yaml
git commit -am 'Add pre-sync hook'
git push
```

Listing 9.1 pre-sync.yaml

```bash
apiVersion: batch/v1
kind: Job
metadata:
  name: before
  annotations:
    argocd.argoproj.io/hook: PreSync
spec:
  template:
    spec:
      containers:
      - name: sleep
        image: alpine:latest
        command: ["echo", "pre-sync"]
      restartPolicy: Never
  backoffLimit: 0
```

Argo CD user interface provides much better visualization of a dynamic process than CLI. Let's use it to better understand how hooks work. Open the Argo CD UI using the following command:

```bash
minikube service argocd-server -n argocd --url
```

Navigate to the “sample-app” details page and trigger the synchronization process using the “Sync” button. The syncing process is represented in the figure below:

![application sync](https://raw.githubusercontent.com/zillani/img/master/argo-img/app-sync.png)
 
As soon as the sync is started, the application details page shows live process status in the top right corner. The status includes information about operation start time and duration. You can view the syncing status panel with detailed information, including sync hook results, by clicking the sync status icon.
The hooks are stored as the regular resource manifests in the Git repository and also visualized as regular resources in the Application resource tree. You can see the real-time status of the “before” job and use the Argo CD user interface to inspect child Pods.
In addition to phase, you might customize hook deletion policy. The deletion policy allows automating hook resources deletion that will save you a lot of manual work.
Exercise 9.9
Read more details in the Argo CD documentation[6] and change the “before” Job deletion policy. Use the Argo CD user interface to observe how various deletion policies affect hook behavior. Synchronize application and observe how hook resources got created and deleted by Argo CD.

### Post-deployment verification

The resource hooks allow encapsulating the application synchronization logic, so we don’t have to use scripts and continuous integration tools. However, some of such use-cases naturally belong to continuous integration processes, and it is still preferable to use tools like Jenkins or CircleCI.
One of such use-cases is the post-deployment verification. The challenge here is that GitOps deployment is asynchronous by nature. After the commit is pushed to the Git repository, we still need to make sure that changes are propagated to the Kubernetes cluster. Even after changes are propagated, it is not safe to start running tests. In most cases, the update of a Kubernetes resource is not instant either. For example, the Deployment resource update triggers the rolling update process. The rolling update might take several minutes or even fail due if the new application version has an issue. So if you start tests too early, you might end up testing the previously deployed application version.
The Argo CD makes this issue trivial by providing tools that help to monitor application status. The argocd app wait command monitors the application and exits after the application reaches a synched and healthy state. As soon as the command exits, you can assume that all changes are successfully rolled out, and it is safe to start post-deployment verification. The argocd app wait command is often used in conjunction with argocd app sync. Use the following command to synchronize your application and wait until the change is fully rolled out, and the application is ready for testing:

argocd app sync sample-app && argocd app wait sample-app

## Enterprise features

The Argo CD is pretty lightweight, and it is really easy to start using it. At the same time, it scales well for a large enterprise and able to accommodate the needs of multiple teams. The enterprise features can be configured as you go. If you are rolling out an Argo CD for your organization, then the first question is how to configure the end-user and effectively manage access control.

### Single sign-on

Instead of introducing its own user management system, Argo CD provides integration with multiple single sign-on services (SSO). The list includes Okta, Google OAuth, Azure AD, and many more.

NOTE
SSO SSO is a session and user authentication service that allows a user to use one set of login credentials to access multiple applications.
The SSO integration is great because it saves you a lot of management overhead, as well as for end-users, who don’t have to remember another set of login credentials. There are several open standards for exchanging authentication and authorization data. The most popular ones are SAML, OAuth, and OpenID Connect (OIDC). Among those three, SAML and OIDC satisfy the best requirements of a typical enterprise and can be used to implement SSO. Argo CD decided to go ahead with OIDC because of its power and simplicity.
The number of steps required to configure an OIDC integration depends on your OIDC provider. The Argo CD community already contributed a number of instructions for popular OIDC providers such as Okta and Azure AD. After performing the configuration on the OIDC provider side, you need to add the corresponding configuration to the argocd-cm ConfigMap. The snippet below represents the sample Okta configuration:

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  url: https://<myargocdhost>
  oidc.config: |
    name: Okta
    issuer: https://yourorganization.oktapreview.com
    clientID: <your client id>
    clientSecret: <your client secret>
    requestedScopes: ["openid", "profile", "email", "groups"]
    requestedIDTokenClaims: {"groups": {"essential": true}}
```

What if your organization does not have an OIDC compatible SSO service? In this case, you can use a federated OIDC provider Dex[7] which is bundled into the Argo CD by default. Dex acts as a proxy to other identity providers and allows establishing integration with SAML, LDAP providers, or even services like GitHub and Active Directory.
GitHub often is a very attractive option, especially if it is already used by developers in your
organization. Additionally, organizations and teams configured in Github naturally fit the access control model required to organize cluster access. As you are going to learn soon, it is very easy to model Argo CD access using the Github team membership. Let's use Github to enhance our Argo CD installation and enable SSO integration.
First of all, we need to create a Github OAuth application. Navigate to the https://github.com/settings/applications/new URL and configure the application settings as represented in the figure below:
 
![github oauth](https://raw.githubusercontent.com/zillani/img/master/argo-img/register-oauth.png)

Specify the application name of your choice and the home page URL that matches the Argo CD web user interface URL. The most important application setting is the callback URL. The callback URL value is the Argo CD web user interface URL plus the /api/dex/callback path. The sample URL with minikube might be http://192.168.64.2:32638/api/dex/callback.
After creating the application, you will be redirected to the OAuth application settings page. Copy the application Client ID and Client Secret. These values will be used to configure the Argo CD settings.

Figure 9.11 Github OAuth application settings
 
```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  url: https://<minikube-host>:<minikube-port>
 
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: <client-id>
          clientSecret: <client-secret>
          loadAllGroups: true
```

Update the Argo CD ConfigMap using the kubectl apply command:

```bash
kubectl apply -f ./argocd-cm.yaml -n argocd
```

You are ready to go! Open the Argo CD user interface in the browser and use the “LOGIN VIA GITHUB” button.

### Access control

You might notice that after a successful login using Github SSO integration, the application list page is empty. If you try creating a new application, you will see a “permission denied” error. This behavior is expected because we have not given any permission to the new SSO user yet. In order to provide the user with appropriate access, we need to update Argo CD access control settings.
Argo CD provides a flexible role-based access control (RBAC) system which implementation is based on Casbin[8] - powerful open-source access control library. Casbin provides a very solid foundation and allows configuring various access control rules.
The RBAC Argo CD settings are configured using argocd-rbac-cm ConfigMap. To quickly dive into the configuration details, let’s update the ConfigMap fields and then go together through each change.
Substitute the <username> placeholder with your Github account username in the argocd-rbac-cm.yaml file:
Listing 9.3 argocd-rbac-cm.yaml

```bash
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  labels:
    app.kubernetes.io/name: argocd-rbac-cm
    app.kubernetes.io/part-of: argocd
data:
  policy.csv: |
    p, role:developer, applications, *, */*, allow                   
    g, role:developer, role:readonly                                 
 
    g, <username>, role:developer                                    
 
  scopes: '[groups, preferred_username]'
```

Apply the RBAC changes using the kubectl apply command:

```bash
kubectl apply -f ./argocd-rbac-cm.yaml -n argocd
```

The policy.csv field in the configuration above defines a role named role:developer with full permissions on Argo CD applications and read-only permissions over Argo CD system settings. The role is granted to any user that belongs to a group whose name matches your Github account username. As soon as changes are applied, please refresh the Applications list page and try syncing the “sample-app” application.
We've introduced quite a few new terms. Let’s step back and discuss what roles, groups, claims are and how they work together.
Role
The role allows or denies a set of actions on an Argo CD object to a particular subject. The role is defined in the following form:

p, subject, resource, action, object, effect

where:
•	p - indicates the RBAC policy line
•	subject - is a group
•	resource - one of Argo CD resource types. Argo CD supports the following resources: "clusters", "projects", "applications", "repositories", "certificates", "accounts".
•	action - an action name that might be executed against a resource. All Argo CD resources support the following actions: "get", "create", "update", "delete". The “*” value matches any action.
•	object - a pattern that identifies a particular resource instance. The “*” value matches any instance.
•	effect - defines whether the role grants or denies the action
The role:developer role from the example above allows any action against any Argo CD application:

p, role:developer, applications, *, */*, allow

Group
Group provides the ability to identify a set of users and works in conjunction with OIDC integration. After performing the successful OIDC authentication, the end-user receives a JWT token that verifies the user identity as well as provides additional metadata stored in the token claims.
NOTE
JWT Token A JWT Token is an internet standard for creating JSON-based access tokens that assert some number of claims.[9]
The token is supplied with every Argo CD request. The Argo CD extract the list of groups that user belongs to from a configured list of token claims and use it to verify user permissions.
Take a look at the real like token claims example generated by Dex:

```bash
{
  "iss": "https://192.168.64.2:32638/api/dex",
  "sub": "CgY0MjY0MzcSBmdpdGh1Yg",
  "aud": "argo-cd",
  "exp": 1585646367,
  "iat": 1585559967,
  "at_hash": "rAz6dDHslBWvU6PiWj_o9g",
  "email": "AMatyushentsev@gmail.com",
  "email_verified": true,
  "groups": [
    "gitopsbook"
  ],
  "name": "Alexander Matyushentsev",
  "preferred_username": "alexmt"
}
```

The token contains two useful claims which might be useful for authorization:
•	groups - includes a list of Github orgs and teams the user belongs to
•	preferred_username - the Github account username

Exercise 9.10

## Summary

This chapter covers important foundations of Argo CD and gets you ready for further learning. Explore Argo CD documentation to learn about diffing logic customization, config management tools fine-tuning, advanced security features, such as auth tokens, and many more.
The project keeps evolving and getting new features in every release. Checkout the Argo CD blog[10] to stay up to date with the changes, and don't hesitate to ask questions in Argoproj slack[11] channel.
In this chapter, you learned:
•	Argo CD main use cases and core concepts.
•	Architecture design that makes Argo CD enterprise-ready
•	How to install Argo CD and deploy your first application
•	Use the Argo CD command line and user interfaces to inspect application details.
•	Advanced Argo CD features to solve real live use-cases such as complex deployments and deployment verification.
•	Configuring Argo CD for multi-tenant use in a large organization

## Reference

- https://argoproj.github.io/projects/argo-cd
- https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#progress-deadline-seconds
- https://argoproj.github.io/argo-cd/getting_started/
- https://help.github.com/en/github/getting-started-with-github/fork-a-repo
- https://argoproj.github.io/argo-cd/user-guide/auto_sync/
- https://argoproj.github.io/argo-cd/user-guide/resource_hooks/#hook-deletion-policies
- https://github.com/dexidp/dex
- https://github.com/casbin/casbin
- https://en.wikipedia.org/wiki/JSON_Web_Token
- https://blog.argoproj.io/
- https://argoproj.github.io/community/join-slack


