# create SSH key-pair
ssh-keygen -t rsa -b 2048 -f ~/.ssh/Keypair -q -P '';

# Create vms and deploy application
terraform init;
terraform apply -auto-approve;

