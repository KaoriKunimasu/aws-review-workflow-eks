# EKS Operations Runbook — review-api

Operational procedures for the review-api service running on Amazon EKS
(cluster: `review-workflow-dev`, region: `ap-southeast-2`).

Assumes kubectl is pointed at the cluster:

```bash
aws eks update-kubeconfig --region ap-southeast-2 --name review-workflow-dev
kubectl config current-context   # confirm it is the EKS cluster, not kind
```

## 1. Deploy / update

Build for the cluster architecture and push to ECR:

```bash
docker build --platform linux/amd64 -t <ecr-repo-url>:<tag> .
docker push <ecr-repo-url>:<tag>
```

Set the new tag in the EKS overlay (`k8s/overlays/eks/kustomization.yaml`, `images[].newTag`), then apply and wait for the rollout:

```bash
kubectl apply -k k8s/overlays/eks
kubectl rollout status deployment/review-api
```

Confirm both replicas are running and healthy:

```bash
kubectl get pods -o wide
```

> **Notes:**
> - Always build with `--platform linux/amd64`. An image built for a different architecture will start but the Pods will crash-loop on the nodes.
> - Prefer an explicit tag (`v1`, `v2`, …) over `latest` so rollbacks are deterministic.

## 2. Rollback

Check the rollout history:

```bash
kubectl rollout history deployment/review-api
```

Roll back to the previous revision:

```bash
kubectl rollout undo deployment/review-api
kubectl rollout status deployment/review-api
```

To roll back to a specific revision:

```bash
kubectl rollout undo deployment/review-api --to-revision=<n>
```

## 3. Image pull failures (ImagePullBackOff / ErrImagePull)

**Symptom:** Pods stuck in `ImagePullBackOff` or `ErrImagePull`.

```bash
kubectl get pods
kubectl describe pod <pod-name>   # read the Events section at the bottom
```

Common causes and checks:

- The image tag in the overlay does not exist in ECR. Verify:

```bash
aws ecr list-images --repository-name review-workflow-dev-review-api \
  --region ap-southeast-2
```

- The node role lacks ECR pull permission. The EKS managed node role normally includes `AmazonEC2ContainerRegistryReadOnly`; confirm it is attached:

```bash
aws iam list-attached-role-policies --role-name <node-group-role-name>
```

- Wrong image URI in the overlay (account id / region / repo name typo).

## 4. Health check / readiness failures

**Symptom:** Pods are `Running` but `0/1` ready, or the rollout never completes.

```bash
kubectl get pods
kubectl describe pod <pod-name>   # look for failed readiness/liveness probes
kubectl logs <pod-name>
```

The container listens on the expected port (`8080`) and `/health` returns `200`. Test from inside the cluster:

```bash
kubectl exec deploy/review-api -- \
  python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/health').read())"
```

ConfigMap values are present (missing `WORKFLOW_TABLE_NAME` makes the API return `500` on data routes):

```bash
kubectl get configmap review-api-config -o yaml
kubectl exec deploy/review-api -- env | grep -E "WORKFLOW_TABLE_NAME|AWS_REGION"
```

## 5. IRSA not taking effect

**Symptom:** the Pod authenticates to AWS as the node role (`assumed-role/<node-group-role>/i-...`) instead of the dedicated IRSA role.

Confirm which identity the Pod uses:

```bash
kubectl exec deploy/review-api -- \
  python -c "import boto3; print(boto3.client('sts').get_caller_identity()['Arn'])"
```

A correct result looks like: `assumed-role/review-workflow-dev-review-api-irsa/...`

If it still shows the node role, work through these in order:

**The ServiceAccount must carry the role-arn annotation:**

```bash
kubectl get serviceaccount review-api -o yaml
```

It must contain `eks.amazonaws.com/role-arn: arn:aws:iam::<account-id>:role/review-workflow-dev-review-api-irsa`. If missing, the kustomize patch did not apply — verify the rendered output:

```bash
kubectl kustomize k8s/overlays/eks | grep role-arn
```

> Use a strategic-merge patch (full ServiceAccount YAML) rather than an inline JSON patch; the JSON-patch form silently failed to add the annotation.

**The Deployment must reference the ServiceAccount:**

```bash
kubectl get pod -l app=review-api \
  -o jsonpath="{.items[0].spec.serviceAccountName}"
```

This must print `review-api`, not `default`.

**IRSA env vars are injected only at Pod creation.** After fixing the annotation, recreate the Pods:

```bash
kubectl rollout restart deployment/review-api
kubectl rollout status deployment/review-api
kubectl exec deploy/review-api -- env | grep AWS
```

You should see `AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE`.

## 6. Logs and inspection

```bash
kubectl logs deploy/review-api --tail=50
kubectl logs deploy/review-api -f            # follow
kubectl get events --sort-by=.lastTimestamp  # recent cluster events
```

Local smoke test through port-forward:

```bash
kubectl port-forward svc/review-api 8080:80
# in another shell:
curl localhost:8080/health
curl localhost:8080/reviews
```

## 7. Teardown

Destroy all infrastructure when validation is complete:

```bash
cd infra/environments/dev
terraform destroy
```

If destroy fails with `RepositoryNotEmptyException` on ECR, the repository still contains images. The repo is configured with `force_delete = true`; if an older state is in effect, either delete the images first:

```bash
aws ecr batch-delete-image --repository-name review-workflow-dev-review-api \
  --region ap-southeast-2 --image-ids imageDigest=<digest>
```

or apply the `force_delete` change before destroying:

```bash
terraform apply -target="aws_ecr_repository.review_api"
terraform destroy
```

After teardown, confirm nothing billable remains:

```bash
aws ec2 describe-nat-gateways --region ap-southeast-2 \
  --query "NatGateways[?State!='deleted'].NatGatewayId"
aws ec2 describe-addresses --region ap-southeast-2 \
  --query "Addresses[].AllocationId"
aws eks list-clusters --region ap-southeast-2
```
All three should be empty.