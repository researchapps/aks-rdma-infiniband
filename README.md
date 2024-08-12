# AKS RDMA/Infiniband Support
To support running HPC workloads using RDMA/Infiniband on AKS, this repo provides a daemonset to install the necessary RDMA drivers and device plugins on HPC-series VMs. 

## Prerequisites
This installation assumes you have the following setup:
- AKS cluster with Infiniband feature flag enabled:
    - enable flag: `az feature register --name AKSInfinibandSupport --namespace Microsoft.ContainerService`
    - check status: `az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKSInfinibandSupport')].{Name:name,State:properties.state}"`
    - register when ready: `az provider register --namespace Microsoft.ContainerService`
- AKS nodepool with RDMA-capable skus:
    - Refer to the HPC docs: https://docs.microsoft.com/en-us/azure/virtual-machines/sizes-hpc
    - Sample command to create AKS nodepool with HPC-sku (assuming aks resource group and cluster already created): 
        - `az aks nodepool add --resource-group <resource group name> --cluster-name <cluster name> --name rdmanp --node-count 2 --node-vm-size Standard_HB120rs_v2`
        - Note: VM size names are case-sensitive
    
## Configuration
Depending on intended usage there are alterations that can be made to the `shared-hca-images/configMap.yaml`:
- if you only intended to assign a single pod to each node, keep the `rdmaHcaMax` parameter as 1
- if you want to run parallel workloads with multiple pods per node, modify `rdmaHcaMax` to be how many pods you want on a single node
    - Note: this will affect the latency, since the pods will be sharing the bandwidth

## Quickstart
1. Clone repository
2. Download the new nvidia `MLNX_OFED_LINUX-24.04-0.7.0.0-ubuntu22.04-x86_64.iso` that is copied into the image for the Dockerfile. I chose this version based on the Azure Ubuntu HPC/AI image I chose with the same. I had to [agree to the license stuffs](https://developer.nvidia.com/networking/mlnx-ofed-eula?mtag=linux_sw_drivers&mrequest=downloads&mtype=ofed&mver=MLNX_OFED-24.04-0.7.0.0&mname=MLNX_OFED_LINUX-24.04-0.7.0.0-ubuntu22.04-x86_64.iso) and download to my host, thus the COPY. Mellanox used to allow you to just curl download, but Nvidia is being annoying.
3. Build & push image (this image to a registry you can pull from):
    - build image locally: `docker build -t <image-name> .`
    - push image to ACR or other registry: https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli
        - https://docs.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes#create-an-image-pull-secret
    - replace image name in `shared-hca-images/driver-installation.yml` with your image name
4. Deploy manifests:
    - `kubectl apply -k shared-hca-images/.`
5. Check installation logs to confirm driver installation 
    -  `kubectl get pods`
    -  `kubectl logs <name of installation pod>`
    -  Wait until you see message indicating installation completed successfully
6. Deploy MPI workload (refer to example test pods, `test-rdma-pods.yaml`, specifically the resources section to see how to pull resources)
    -  `kubectl apply -f <rdma workload>`


** This solution is modelled after: https://github.com/alexeldeib/aks-fpga **


## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
