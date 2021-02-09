## Manual steps in order to deploy the ELK stack

### IAM user with right rules

1- we will need to have an IAM user with EC2Fullaccess and VPCFullaccess we can create this user from this guide. https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console , Save the access key ID and secret access key

2- we need the credintials of this IAM user we saved in the right format with having file called credintials in this path ~/.aws/credentials or we can use aws CLI to configure the IAM user like here https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html

### Vault password

we need a file with vault password called secret in the root directory of the project that has the vault password inside it. you will need the secret in order to run the playbook or you can encrypt your own passwords and certificates


### Variables

you need to set up your own terraform vars like region, profile, and credintials if it's not the same as mine

In order to set your own terrform vars 

```bash
export TF_VAR_region=<region name>
export TF_VAR_profile=<profile name>
export TF_VAR_credintials=<credintials path>
```

## Run the install.sh script

This script will install ansible and its dependencies, terraform, setup ssh keypair and will run the terraform commands which will deploy the infrastructure
