Serverless and Kubernetes trade-offs
=======================================

This isn't a general "Lambda vs. Kubernetes" comparison. It's what this specific migration actually traded, based on what changed between the two versions in this repository.

Operational surface
----------------------

Lambda's operational model is close to zero maintenance for a workload this size: no nodes to patch, no cluster version to plan an upgrade around, no capacity to size ahead of time. EKS trades that away for control. You decide the node instance type, the replica count, the resource limits per Pod, at the cost of now owning all of it. ``docs/adr/0003-eks-cluster-topology.md`` picked a single managed node group over Fargate specifically to keep that operational surface visible rather than abstracted further. That was the right call for demonstrating Kubernetes operations; it isn't necessarily the right call for a team that wants to operate as little infrastructure as possible.

Cost shape
------------

Lambda bills per invocation and per millisecond; an idle API costs nothing. EKS has a control plane charge, a running node group, and, in this configuration, a NAT gateway, all billed continuously regardless of traffic. For a workload that gets occasional requests, that baseline cost is pure overhead compared to Lambda. It only pays for itself at a request volume, or with a workload shape (long-running connections, background processing, predictable steady load), where the constant cost is offset by not paying Lambda's per-invocation premium at scale.

Portability and local development
-------------------------------------

This is where EKS won cleanly for this project. The exact container image that runs on EKS also runs locally under Docker Compose, against DynamoDB Local, with no separate emulation layer. Lambda's local development story (SAM, LocalStack, or similar) approximates the runtime rather than running the same artifact. The tutorial in :doc:`../tutorials/run-the-service-locally` works because "run it locally" and "run it in the cluster" are the same container.

Where this project landed
-----------------------------

Given the actual traffic level and endpoint count here, Lambda's cost and operational profile would have been the better fit on those two axes alone. The migration to EKS makes sense as a deliberate choice to demonstrate container orchestration, Kubernetes-native access control (IRSA), and Infrastructure-as-Code patterns around a real cluster, not because the workload outgrew Lambda. That's a legitimate reason to choose EKS. It's a different reason than "Lambda couldn't handle this," and the README doesn't claim the latter.