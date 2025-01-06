#!/bin/bash

# Set the VM, image, and networking configuration
VM_NAME="langflow-dev"
IMAGE_FAMILY="debian-11"
IMAGE_PROJECT="debian-cloud"
BOOT_DISK_SIZE="100GB"
ZONE="us-central1-a"
REGION="us-central1"
VPC_NAME="default"
SUBNET_NAME="default"
SUBNET_RANGE="10.128.0.0/20"

# Set the GCP project's compute region
gcloud config set compute/region $REGION

# Check if the VPC exists, and create it if not
vpc_exists=$(gcloud compute networks list --filter="name=$VPC_NAME" --format="value(name)")
if [[ -z "$vpc_exists" ]]; then
  gcloud compute networks create $VPC_NAME --subnet-mode=custom
fi

# Check if the subnet exists, and create it if not
subnet_exists=$(gcloud compute networks subnets list --filter="name=$SUBNET_NAME AND region=$REGION" --format="value(name)")
if [[ -z "$subnet_exists" ]]; then
  gcloud compute networks subnets create $SUBNET_NAME --network=$VPC_NAME --region=$REGION --range=$SUBNET_RANGE
fi

# Create a firewall rule to allow TCP port 7860 for all instances in the VPC
firewall_7860_exists=$(gcloud compute firewall-rules list --filter="name=allow-tcp-7860" --format="value(name)")
if [[ -z "$firewall_7860_exists" ]]; then
  gcloud compute firewall-rules create allow-tcp-7860 --network $VPC_NAME --allow tcp:7860 --source-ranges 0.0.0.0/0 --direction INGRESS
fi

# Define the startup script as a multiline Bash here-doc
STARTUP_SCRIPT=$(cat <<'EOF'
#!/bin/bash

# Update and upgrade the system
apt update && apt upgrade -y

# Install necessary dependencies
apt install -y python3-pip git nginx

# Upgrade pip to the latest version
pip3 install --upgrade pip

# Clone the LangFlow repository to get the latest version
cd /opt
git clone https://github.com/langflow-ai/langflow.git
cd langflow

# Install LangFlow and its dependencies
pip3 install .

# Set up a systemd service to run LangFlow
cat <<EOT > /etc/systemd/system/langflow.service
[Unit]
Description=LangFlow Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/langflow
ExecStart=/usr/bin/python3 -m langflow run --host 0.0.0.0 --port 7860
Restart=always

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd, enable, and start the LangFlow service
systemctl daemon-reload
systemctl enable langflow
systemctl start langflow

# Open port 7860 for incoming connections
ufw allow 7860
EOF
)

# Create a temporary file to store the startup script
tempfile=$(mktemp)
echo "$STARTUP_SCRIPT" > $tempfile

# Create the VM instance with the specified configuration and startup script
gcloud compute instances create $VM_NAME \
  --image-family $IMAGE_FAMILY \
  --image-project $IMAGE_PROJECT \
  --boot-disk-size $BOOT_DISK_SIZE \
  --machine-type=n1-standard-4 \
  --metadata-from-file startup-script=$tempfile \
  --zone $ZONE \
  --network $VPC_NAME \
  --subnet $SUBNET_NAME

# Remove the temporary file after the VM is created
rm $tempfile
