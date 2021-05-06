apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: alb-ingress-controller
  namespace: argocd
spec:
  destination:
    namespace: kube-system
    server: https://kubernetes.default.svc
  project: default
  source:
    path: ${path}
    repoURL: ${repo}
    targetRevision: ${revision}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
