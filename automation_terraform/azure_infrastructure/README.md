# Terraform configuration for Azure Cloud
### I. Install the Azure CLI on Linux
1. Import the Microsoft repository key.
```
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
```

2. Create local azure-cli repository information.
```
echo -e "[azure-cli]
name=Azure CLI
baseurl=https://packages.microsoft.com/yumrepos/azure-cli
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
```

3. Install with the yum install command.
```
sudo yum install azure-cli
```

4. Run the Azure CLI with the az command. To sign in, use az login command.
```
az login
```

Open a browser page at https://aka.ms/devicelogin and enter the authorization code displayed in your terminal.
If no web browser is available or the web browser fails to open, use device code flow with az login --use-device-code. 
Sign in with your account credentials in the browser. Once logged in - it's possible to list the Subscriptions associated with the account via:
```
az account list
```

The output (similar to below) will display one or more Subscriptions - with the id field being the subscription_id field referenced above.
```
[
  {
    "cloudName": "AzureCloud",
    "id": "00000000-0000-0000-0000-000000000000",
    "isDefault": true,
    "name": "PAYG Subscription",
    "state": "Enabled",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "user": {
      "name": "user@example.com",
      "type": "user"
    }
  }
]
```

Should you have more than one Subscription, you can specify the Subscription to use via the following command:
```
az account set --subscription="SUBSCRIPTION_ID"
```

We can now create the Service Principal which will have permissions to manage resources in the specified.
Subscription using the following command:
```
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID"
```

This command will output 5 values:
{
"appId": "00000000-0000-0000-0000-000000000000",
"displayName": "azure-cli-2017-06-05-10-41-15",
"name": "http://azure-cli-2017-06-05-10-41-15",
"password": "0000-0000-0000-0000-000000000000",
"tenant": "00000000-0000-0000-0000-000000000000"
}

These values map to the Terraform variables like so:
**appId** is the **client_id** defined above.
**password** is the **client_secret** defined above.
**tenant** is the **tenant_id** defined above.
Finally, it's possible to test these values work as expected by first logging in:
```
az login --service-principal -u CLIENT_ID -p CLIENT_SECRET --tenant TENANT_ID
```

Once logged in as the Service Principal - we should be able to list the VM sizes by specifying an Azure region, for example here we use the West US region:
```
az vm list-sizes --location westus
```

If you're using the China, German or Government Azure Clouds - you will need to switch westus out for another region. You can find which regions are available by running.
Finally, since we're logged into the Azure CLI as a Service Principal we recommend logging out of the Azure CLI (but you can instead log in using your user account):
```
az logout
```

Information on how to configure the Provider block using the newly created Service Principal credentials can be found below.

### II. Terraform configuration
Configuring the Service Principal in Terraform. It's possible to configure credentials in a few different ways.
1. Storing the credentials as Environment Variables:
```
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

The following Provider block can be specified - where 2.5.0 is the version of the Azure Provider that you'd like to use:
```
provider "azurerm" {
    # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
    version = "=2.5.0"
    features {}
}
```
At this point running either terraform plan or terraform apply should allow Terraform to run using the Service Principal to authenticate.
2. Configure these variables either in-line or from using variables in Terraform (as the client_secret is in this example), like so:
```
variable "client_secret" {
}

provider "azurerm" {
    # Whilst version is optional, we /strongly recommend/ using it to pin the version of the Provider being used
    version = "=2.4.0"
    subscription_id = "00000000-0000-0000-0000-000000000000"
    client_id = "00000000-0000-0000-0000-000000000000"
    client_secret = var.client_secret
    tenant_id = "00000000-0000-0000-0000-000000000000"
    features {}
}
```

At this point running either terraform plan or terraform apply should allow Terraform to run using the Service Principal to authenticate.

### III. Create and apply a Terraform execution plan
To initialize the Terraform deployment, run terraform init. This command downloads the Azure modules required to create an Azure resource group.
```
terraform init
```

After initialization, you create an execution plan by running terraform plan.
```
terraform plan -out <terraform_plan>.tfplan
```

Once you're ready to apply the execution plan to your cloud infrastructure, you run terraform apply.
```
terraform apply <terraform_plan>.tfplan
```

To reverse, or undo, the execution plan, you run terraform plan and specify the destroy flag as follows:
```
terraform plan -destroy -out <terraform_plan>.destroy.tfplan
```

### IV. How To
#### Find Linux VM images in the Azure Marketplace with the Azure CLI
A Marketplace image in Azure has the following attributes:

**Publisher**: The organization that created the image. Examples: Canonical, MicrosoftWindowsServer
**Offer**: The name of a group of related images created by a publisher. Examples: UbuntuServer, WindowsServer
**SKU**: An instance of an offer, such as a major release of a distribution. Examples: 18.04-LTS, 2019-Datacenter
**Version**: The version number of an image SKU.

To identify a Marketplace image when you deploy a VM programmatically, supply these values individually as parameters. Some tools accept an image URN, which combines these values, separated by the colon (:) character: Publisher:Offer:Sku:Version. In a URN, you can replace the version number with "latest", which selects the latest version of the image.

#### List popular images
Run the az vm image list command, without the --all option, to see a list of popular VM images in the Azure Marketplace. For example, run the
following command to display a cached list of popular images in table format:
```
az vm image list --output table
az vm image list --offer Centos--all --output table
az vm image list --location westeurope --offer Centos--publisher
credativ --sku 8 --all --output table
```

#### Terraform Azure VM SSH Key
The problem is due to the configuration of the VM. It seems like you use the resource azurerm_linux_virtual_machine and set the SSH key as:
```
admin_username = "azureroot"
admin_ssh_key {
    username = "azureroot"
    public_key = file("~/.ssh/id_rsa.pub")
}
```
For the public key, you use the function file() to load the public key from your current machine with the path ~/.ssh/id_rsa.pub. So when you are in a different machine, maybe your teammate's, then the public key should be different from yours. And it makes the problem.

Here I have two suggestions for you. One is that use the static public key like this:
```
admin_username = "azureroot"
admin_ssh_key {
    username = "azureroot"
    public_key = "xxxxxxxxx"
}
```

Then no matter where you execute the Terraform code, the public key will not cause the problem. And you can change the things as you want, for example, the NSG rules.

#### AZURE CLI commands list:
[Azure Cloud CLI commands](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest)
```
az account list-locations -o table
```
