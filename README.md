# Rivendell Deploy
## Dockerized Webhook Listener for Automated Deployments

This project is a Dockerized webhook listener designed to automate deployments in response to GitHub push events. It leverages a Flask-based Python server to listen for webhook events, verifies their authenticity via HMAC SHA-256 signatures, and triggers a deployment process through a sample script (`deploy.sh`).

## Features

- **Automated Deployments:** Automatically trigger deployments when a push event occurs on your GitHub repository.
- **Secure Webhook Endpoint:** Uses HMAC SHA-256 signature verification to ensure that requests are coming from GitHub.
- **Dockerized Environment:** Entirely containerized using Docker and Docker Compose for easy deployment and scaling.
- **Custom Deployment Script:** Includes a sample `deploy.sh` script that demonstrates cloning/pulling a repository, building a Flutter web application, and organizing versioned deployments.
- **RSA Key Integration:** Securely mounts RSA keys via Docker volumes to facilitate SSH authentication for Git operations (essential for accessing private repositories).

## Project Structure

```plaintext
.
├── Dockerfile                # Defines the Docker image (based on Flutter & Python)
├── docker-compose.yml        # Docker Compose configuration to run the webhook service
├── app.py                    # Flask-based webhook listener with signature verification
├── deploy.sh                 # Sample deployment script
├── requirements.txt          # Python dependencies for the webhook listener
├── .env                      # Environment variables configuration file
├── rsa/                     # Directory for RSA keys (mounted as a Docker volume)
└── deploy/                  # Directory for versioned deployment outputs
```

## Prerequisites

- **Docker & Docker Compose:** Ensure you have Docker and Docker Compose installed on your system.
- **RSA Keys:** You need a valid RSA key pair for SSH authentication. Place your RSA keys in the `rsa/` directory. This is crucial for secure Git operations (e.g., cloning or pulling updates from your GitHub repository).

## Setup and Installation

1. **Clone the Repository:**

   ```bash
   git clone git@github.com:ruvido/webhook-deploy.git
   cd webhook-deploy
   ```

2. **Prepare Your RSA Keys:**
   - Place your RSA private and public keys in the `rsa/` folder.
   - Ensure the keys have the appropriate permissions to be used for SSH authentication.

3. **Configure Environment Variables:**
   - Create a `.env` file in the root directory with the following content (adjust values as needed):

     ```env
     PORT=5000
     SECRET=your_webhook_secret
     SCRIPT_PATH=/app/deploy.sh
     ```


**Heads Up!** The `SCRIPT_PATH` variable is intended to reference the location of scripts within the Docker environment. When specifying the path to your deployment script, use `app/deploy.sh` if the script is located in the root of your repository. Avoid using `./deploy.sh`, as this will not correctly point to the script within the Docker container's file system.

4. **Build and Run the Docker Container:**

Use Docker Compose to build the image and start the service:

   ```bash
   docker-compose up --build
   ```

This command builds the Docker image and launches the webhook listener on the defined port.

## Configuring the GitHub Repository for Webhook Deployment

To integrate your GitHub repository with this deployment system, follow these steps:

1. **Navigate to Your Repository Settings:**
   - Go to your repository on GitHub.
   - Click on the **Settings** tab.

2. **Access the Webhooks Section:**
   - In the sidebar, select **Webhooks**.
   - Click on **Add webhook**.

3. **Configure the Webhook:**
   - **Payload URL:** Enter the URL where your Docker container is running, followed by `/deploy`.  
     For example:  
     `http://<your-server-ip>:5000/deploy`
     
5000 is an example, use whatever port you put in `.env` file. On the other hand the `deploy` endpoint is hardcoded in the `app.py`.

   - **Content type:** Choose `application/json`.
   - **Secret:** Enter the same secret you specified in your `.env` file (i.e., the value of `SECRET`). This ensures that the webhook payload is verified correctly by your Flask app.
   - **Events:** By default, GitHub sends a **push** event. You can choose to trigger the webhook on:
     - Just the push event (default), or
     - Send everything, if you want to catch more events.
     
4. **Save the Webhook:**
   - Click **Add webhook** to save your configuration.

Once configured, GitHub will send a POST request to your specified URL whenever a push occurs. The webhook listener will then verify the signature and trigger the deployment process using the `deploy.sh` script.

## How It Works

### Webhook Listener

- **Endpoint:** The Flask app listens for POST requests at `/deploy`.
- **Signature Verification:** Every incoming request must include the `X-Hub-Signature-256` header. The server computes the HMAC SHA-256 hash of the request payload using the secret provided in `.env` and compares it with the header value.
- **Triggering Deployment:** Once the signature is verified, the server executes the `deploy.sh` script, streaming the output live.

### Deployment Script (`deploy.sh`)

The `deploy.sh` script demonstrates a complete deployment workflow:

1. **RSA Key Setup:**
   - Copies RSA keys from the mounted `rsa/` directory into `/root/.ssh` within the container.
   - Updates SSH known hosts by scanning GitHub’s host key.

2. **Repository Operations:**
   - Checks if the repository directory exists. If it does, the script pulls the latest changes; if not, it clones the repository.
   
3. **Building the Application:**
   - Installs Flutter dependencies.
   - Executes Flutter commands to create or update web support.
   - Builds the Flutter web application.
   
4. **Versioned Deployment:**
   - Creates a deployment directory with a timestamp as its version to facilitate easy rollback.
   - Copies the build output to this versioned directory.
   - Updates a symbolic link (`current`) to point to the latest version for easy access.

### RSA Keys and Docker Volumes

The RSA keys are essential for secure SSH-based Git operations, especially when dealing with private repositories. In the `docker-compose.yml` configuration, the `rsa/` folder is mounted as a volume. This setup ensures that the `deploy.sh` script can access and correctly configure the RSA keys (by copying them into `/root/.ssh`), enabling seamless authentication with GitHub.

## Testing the Webhook locally

Once docker image is started locally, you can test the enviroment locally by

```bash
curl -X POST http://localhost:5000/deploy \
-H "Content-Type: application/json" \
-H "X-Hub-Signature-256: sha256=$(echo -n '{"action": "push", "repository": {"name": "test-repo"}}' | openssl dgst -sha256 -hmac 'your_webhook_secret' | sed 's/^.* //')" \
-d '{"action": "push", "repository": {"name": "test-repo"}}'
```

This script sends a POST request to the specified URL, including the necessary headers and payload to simulate a GitHub push event. Make sure to replace `your_webhook_secret` with the actual secret you configured for your GitHub webhook.

