# Disaster Recovery for Azure Cloud
### Architectural components
**VMs in source region**: One of more Azure VMs in a supported source region. VMs can be running any supported operating system.
**Source VM storage**: Azure VMs can be managed, or have non-managed disks spread across storage accounts.
**Source VM networks**: VMs can be located in one or more subnets in a virtual network (VNet) in the source region.
**Cache storage account**: You need a cache storage account in the source network. During replication, VM changes are stored in the cache before being sent to target storage. Cache storage accounts must be Standard. Using a cache ensures minimal impact on production applications that are running on a VM.
**Target resources**: Target resources are used during replication, and when a failover occurs. Site Recovery can set up target resource by default, or you can create/customize them. In the target region, check that you're able to create VMs, and that your subscription has enough resources to support VM sizes that will be needed in the target region.

### Target resources
When you enable replication for a VM, Site Recovery gives you the option of creating target resources automatically.
**Target subscription**: Same as the source subscription.
**Target resource group**: The resource group to which VMs belong after failover. It can be in any Azure region except the source region. Site Recovery creates a new resource group in the target region, with an "asr" suffix. 
**Target VNet**: The virtual network (VNet) in which replicated VMs are located after failover. A network mapping is created between source and target virtual networks. Site Recovery creates a new VNet and subnet, with the "asr" suffix.
**Target storage account**: If the VM doesn't use a managed disk, this is the storage account to which data is replicated. Site Recovery creates a new storage account in the target region, to mirror the source storage account.
**Replica managed disks**: If the VM uses a managed disk, this is the managed disks to which data is replicated. Site Recovery creates replica managed disks in the storage region to mirror the source.
**Target availability sets**: Availability set in which replicating VMs are located after failover. Site Recovery creates an availability set in the target region with the suffix "asr", for VMs that are located in an availability set in the source location. If an availability set exists, it's used and a new one isn't created.
**Target availability zones**: If the target region supports availability zones, Site Recovery assigns the same zone number as that used in the source region.

### Replication process
When you enable replication for an Azure VM, the following happens:
1. The Site Recovery Mobility service extension is automatically installed on the VM.
2. The extension registers the VM with Site Recovery.
3. Continuous replication begins for the VM. Disk writes are immediately transferred to the cache storage account in the source location.
4. Site Recovery processes the data in the cache, and sends it to the target storage account, or to the replica managed disks.
5. After the data is processed, crash-consistent recovery points are generated every five minutes. App-consistent recovery points are generated according to the setting specified in the replication policy.

### Failover process
When you initiate a failover, the VMs are created in the target resource group, target virtual network, target subnet, and in the target availability set. During a failover, you can use any recovery point.
#### Enable replication for the Azure VM
The following steps enable VM replication to a secondary location.
1. On the Azure portal, from **Home > Virtual machines** menu, select a VM to replicate.
2. In Operations select **Disaster recovery**.
3. From **Basics > Target region**, select the target region.
4. To view the replication settings, select **Review + Start replication**. If you need to change any defaults, select **Advanced settings**.
5. To start the job that enables VM replication select **Start replication**.

#### Verify settings
After the replication job finishes, you can check the replication status, modify replication settings, and test the deployment.
1. On the Azure portal menu, select **Virtual machines** and select the VM that you replicated.
2. In **Operations** select **Disaster recovery**.
3. To view the replication details from the **Overview** select **Essentials**. More details are shown in the **Health and status, Failover readiness**, and the **Infrastructure view** map.

#### Clean up resources
To stop replication of the VM in the primary region, you must disable replication:
- The source replication settings are cleaned up automatically.
- The Site Recovery extension installed on the VM during replication isn't removed.
- Site Recovery billing for the VM stops.
To disable replication, do these steps:
1. On the Azure portal menu, select **Virtual machines** and select the VM that you replicated.
2. In **Operations** select **Disaster recovery**.
3. From the **Overview**, select **Disable Replication**.
4. To uninstall the Site Recovery extension, go to the VM's **Settings > Extensions**.
