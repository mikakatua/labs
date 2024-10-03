# Working with an insecure registry
This example demonstrates how to configure Docker, Helm and Kubernetes to use a registry with an invalid TLS certificate.

These tools usually work with HTTPS requests and validate that the certificate has been issued by a valid CA. If the certificate is not trusted, the request will fail with the error
```
tls: failed to verify certificate: x509: certificate signed by unknown authority
```

## Start the registry server
Run the provied script in your local computer or a VM.
```
bash start.sh
```
This will start a registry server listening on the default HTTPS port 443.
The TLS certificate has the server name **myregistry.domain.com** and the self-signed CA certificate will be in the folder `certs/rootCA.crt`.

The registry requires authentication. The username is **testuser** and the password **testpassword**

## Configure Docker
Copy the custom CA certificate under the `/etc/docker/certs.d/` directory, in a sub-directory with the name `hostname:port`. If the Docker registry is accessed without a port number, do not add the port to the directory name.
```
sudo mkdir -p /etc/docker/certs.d/myregistry.domain.com
sudo cp certs/rootCA.crt /etc/docker/certs.d/myregistry.domain.com/ca.crt
```

Prepare an image
```
docker pull hell-world
docker tag hello-world myregistry.domain.com/project1/hello-world
```

Login and push the image
```
docker login myregistry.domain.com --username testuser --password testpassword
docker push myregistry.domain.com/project1/hello-world
```

Run a container
```
docker run --rm myregistry.domain.com/project1/hello-world
```

## Configure Helm
Create a helm chart
```
helm create test
helm package test
```

Login and push the chart
```
helm registry login myregistry.domain.com --username testuser --password testpassword --ca-file certs/rootCA.crt
helm push test-0.1.0.tgz oci://myregistry.domain.com/project2 --ca-file certs/rootCA.crt
```

Render the chart
```
helm template oci://myregistry.domain.com/project2/test --ca-file certs/rootCA.crt
```

Unfortunately, Helm does not provide a mechanism to configure the CA certificate and the `--ca-file` must included in each request. Alternatively, the CA certificate can be added to the Linux system-wide CA certificate directory. See instructions below

## Configure Kubernetes (kubelet)
The kubelet relies on the Linux CA certificates. That means that the nodes must have the CA certificate installed to avoid the validation error. See instructions below

Once the registry CA certificate has been installed. The authentication credentials must be stored in a secret
```
kubectl create secret docker-registry myregistry --docker-server=myregistry.domain.com --docker-username=testuser --docker-password=testpassword
```
The image can be pulled by any pod using the secret
```
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: myjob
spec:
  template:
    spec:
      imagePullSecrets:
      - name: myregistry
      containers:
      - name: test
        image: myregistry.domain.com/project1/hello-world
      restartPolicy: Never
EOF
```

## Configure Linux
Adding a CA certificate to a Linux server is pretty simple. It requires root permissions
```
sudo cp certs/rootCA.crt /usr/local/share/ca-certificates
sudo update-ca-certificates
```
The certificate is stored in the `/etc/ssl/certs` directory