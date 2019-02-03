# Azure-auto-tagging

The PowerShell function to add the tag which informs who create a resource.

<img src="https://user-images.githubusercontent.com/3410186/51788139-04d3c100-21be-11e9-9fda-04dd3d341b86.PNG" width="800">

This function searches the action which creates a new resource by using Activity Log in Log Analytics once every hour. If a new resource was created, this function adds `createdBy` tag to a new resource.

# Architecture

![](https://user-images.githubusercontent.com/3410186/52177145-235e3b80-2800-11e9-852e-6a8da59ee51f.png)

# Installation

1. Open the bash of Cloud Shell
1. `git clone https://github.com/kongou-ae/azure-auto-tagging.git`
1. `cd azure-auto-tagging`
1. `terraform init`, `terraform plan` and `terraform apply`

# Contributing
If you confirm the resource which this function could not add a tag, please open an issue or create a pull request.

# License
[MIT](https://choosealicense.com/licenses/mit/)
