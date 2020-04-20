# Operator

Dealing with stateful application in k8s in not easy, that is why we have operators.

## Table of Contents
1. [Operator](#Operator)
2. [Go vs Helm/Ansible](#Go vs Helm/Ansible)
3. [Steps](#Steps)
4. [Initialize Operator](#Initialize Operator)
5. [Operator Scope](#Operator Scope)
6. [CRD](#CRD)
7. [Operator Permissions](#Operator Permissions)
8. [Controller](#Controller)
9. [Child Resource](#Child Resource)
    1. [Child Resource Creation](#Child Resource Creation)
    2. [Child Resource Deletion](#Child Resource Deletion)
    3. [Child Resource Naming](#Child Resource Naming)
10. [Idempotency](#Idempotency)
11. [Operator Impact](#Operator Impact)
12. [Running Locally](#Running Locally)
13. [Visitor Operator](#Visitor Operator)
14. [References](#References)

### Operator

### Go vs Helm/Ansible
While the Helm and Ansible Operators can be created quickly and easily, their functionality is ultimately limited 
by those underlying technologies. Advanced use cases, such as those that involve dynamically reacting to specific 
changes in the application or the cluster as a whole, require a more flexible solution. The Operator SDK provides 
that flexibility by making it easy for developers to use the Go programming language, including its ecosystem of 
external libraries, in their Operators

Below are high level steps involved in creating operators,
### Steps
1. Create the necessary code that will tie in to Kubernetes and allow it to run the Operator as a controller. 
2. Create one or more CRDs to model the application’s underlying business logic and provide the API for users to interact with. 
3. Create a controller for each CRD to handle the lifecycle of its resources. 
4. Build the Operator image and create the accompanying Kubernetes manifests to deploy the Operator and its RBAC components (service accounts, roles, etc.).

### Initialize Operator

```bash
OPERATOR_NAME=visitors-operator 
operator-sdk new $OPERATOR_NAME
```

### Operator Scope

### CRD
Add a new CRD to an operator,
```bash
 operator-sdk add api --api-version=example.com/v1 --kind=VisitorsApp 
```

### Operator Permissions
### Controller
### Child Resource
#### Child Resource Creation
#### Child Resource Deletion
#### Child Resource Naming
### Idempotency
### Operator Impact
### Running Locally

### Visitor Operator
We will create operator for this app called visitor, (a stateful application with front-end & backend)

### References
- [operators_by brendanburns](https://www.youtube.com/watch?v=DhvYfNMOh6A)
- [operators_by ibm cloud](https://www.youtube.com/watch?v=i9V4oCa5f9I&t=255s)
- [operators_by lili cosic](https://www.youtube.com/watch?v=Lv4TTsGiK5E)
- [k8s-controller vs operators](https://github.com/octetz/k8s-controllers-vs-operators)
- [kubecontroller vs operator-framework](https://github.com/operator-framework/operator-sdk/issues/1758)
- [helm-operator vs golang-operator](https://vmblog.com/archive/2019/11/04/operators-a-journey-from-helm-to-golang-to-deliver-on-cloud-native-applications-day-2-operations.aspx#.Xp0q6MgzZPY)
