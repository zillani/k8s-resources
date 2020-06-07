# Exam tips

First tip is to bookmark all the important section from kubernetes official documentation,

## Setup VIM

```bash
vim ~/.vimrc
set nu
set expandtab
set shiftwidth=2
set tabstop=2
```

## Generators

Copy pasting yamls from official docs can be time consuming, so use generators,

- __Deployment__ -> Don't specify anthing here
- __Pod__ -> restart=Never
- __Job__ -> restart=onFailure
- __CronJob__ -> restart=onFailure --schedule=<cron-expression>

```bash
kubectl run busybox --image=busybox:latest --rm -it --restart=Never --dry-run -o yaml > busybox.yaml
```


