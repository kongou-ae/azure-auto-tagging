# Azure-auto-tagging

The powershell function to add the tag which inform who create a resource.

<img src="https://user-images.githubusercontent.com/3410186/51788139-04d3c100-21be-11e9-9fda-04dd3d341b86.PNG" width="800">

# Installation

1. Open the bash of Cloud Shell
1. `git clone https://github.com/kongou-ae/azure-auto-tagging.git`
1. `cd azure-auto-tagging`
1. `zip -r autotagging.zip autotagging/ host.json`
1. `terraform init`, `terraform plan` and `terraform apply`
1. To install this function in Function apps, run the command which terraform will inform of you.
1. Add Azure Activity log to the data source of your Log Analytics workspaces.

# Contributing
If you confirm the resource which this function could not add a tag, please open an issue or create a pull request.

# License
[MIT](https://choosealicense.com/licenses/mit/)
