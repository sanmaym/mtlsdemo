### Instructions for README

This README file provides instructions for setting up and testing a frontend service with mutual TLS (mTLS) enabled. Follow these steps to deploy the necessary infrastructure, obtain the server certificate, and run a test command.


## 1. Terraform deployment

First, navigate to the `frontend` directory and deploy the infrastructure using Terraform.

Create/modify `terraform.tfvars` as needed.

1. Open the directory:
```bash
cd frontend
```
2. Run Terraform apply:
```bash
terraform apply
```
3. Go back to the root directory:
```bash
cd ..
```
4. Run Terraform apply from the root directory:
```bash
terraform apply
```


## 2. Obtain Forwarding Rule IP

Once the infrastructure is deployed, get the IP address of the forwarding rule.

Run:
```bash
gcloud compute forwarding-rules describe FORWARDINGRULE_NAME --global --project=PROJECT_ID
```
For example:
```bash
gcloud compute forwarding-rules describe sanalt1-fr --global --project=santest-1
```


## 3. Test the Service with mTLS

Go back to the `frontend` directory and use `curl` to test the service with the client certificate, key, and the obtained server certificate.

1. Go back to the `frontend` directory:
```bash
cd frontend
```

2. Retrieve the server certificate (replace the IP and hostname as appropriate):
```bash
openssl s_client -connect 34.107.136.149:443 -servername san-gxlb.com -showcerts </dev/null 2>/dev/null \
  | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > server.crt
```

3. Run the `curl` command (substitute the IP/hostname as needed):
```bash
curl -v --cert ./fe-client.cert \
  --key ./fe-client.key \
  --cacert ./server.crt \
  https://san-gxlb.com/server.php \
  --resolve san-gxlb.com:443:34.107.136.149
```

---
### Instructions for README

This README file provides instructions for setting up and testing a frontend service with mutual TLS (mTLS) enabled. Follow these steps to deploy the necessary infrastructure, obtain the server certificate, and run a test command.

-----

### 1\. Terraform Deployment

First, navigate to the `frontend` directory and deploy the infrastructure using Terraform.

Create/ modify terraform.tfvars file accordingly

1.  **Open the directory:**
    ```bash
    cd frontend
    ```
2.  **Run Terraform apply:**
    ```bash
    terraform apply
    ```
3.  **Go back to the root directory:**
    ```bash
    cd ..
    ```
4.  **Run Terraform apply from the root directory:**
    ```bash
    terraform apply
    ```

-----

### 2\. Obtain Forwarding Rule IP

Once the infrastructure is deployed, get the IP address of the forwarding rule.

  * **Run the following command:**
    ```bash
    gcloud compute forwarding-rules describe FORWARDINGRULE_NAME --global --project=PROJECT_ID
    ```
    For example
    ```bash
    gcloud compute forwarding-rules describe sanalt1-fr --global --project=santest-1
    ```
-----

-----

### 3\. Test the Service with mTLS

Finally, go back to the `frontend` directory and use `curl` to test the service with the client certificate, key, and the obtained server certificate.

1.  **Go back to the `frontend` directory:**
    ```bash
    cd frontend
    ```
2. 
  **Run the following command to get the `server.crt` file by inputting the forwarding rule IP from previous step:**
    ```bash
    openssl s_client -connect 34.107.136.149:443 -servername san-gxlb.com -showcerts </dev/null 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > server.crt
  ```
3.  **Run the following `curl` command by substituting the IP from previous step:**

    ```bash
    curl -v --cert ./fe-client.cert \
        --key ./fe-client.key \
        --cacert ./server.crt https://san-gxlb.com/server.php \
        --resolve san-gxlb.com:443:34.107.136.149
    ```