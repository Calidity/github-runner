# Github self-hosted runner Dockerfile and Kubernetes configuration

Implements a GitHub Actions organization level self hosted runner in Docker.

Has a few additional features:

- Supports GitHub Apps credentials instead of personal access tokens
- Supports organization-level runners instead of only repo-level runners

## Setting up with personal access token

1. Go to your personal settings: GitHub > your name > Settings > Developer
2. Open the personal access tokens section
3. Create a new personal access token with org admin access

## Setting up the GitHub App

In order to use this project:

1. Go to your Organization's settings: GitHub > (your org) > Settings
2. Open the GitHub Apps section
3. Click on the New GitHub App button
4. Set a name, description, and add the following permissions:
  - Organization Permissions > Administration: Read & write
  - Organization Permissions > Self-hosted runners: Read & write
5. Disable webhook
6. Empty user callback URL
7. Leave other settings as-is
8. Click on "Create GitHub App"
9. Click on "Generate a private key"
10. Save the private key file. This project needs that file.
11. Click on "Install App" in the left sidebar
12. Install the app for your own org
13. Click on "General" - copy the "App ID: 12345" number. This project needs the App ID


## Running the project (GitHub App)

1. Get your key file and app ID ready, to use the GitHub App method (recommended)
2. Build the project: `docker build -t runner .`
3. Run the project: `docker run -it -e GITHUB_OWNER=orgnamehere -e GITHUB_APP_ID=appidhere -v $(pwd)/private-key.cer:/private-key.cer:ro runner`
4. Stop the project with Ctrl+C. It should automatically clean up.

## Running the project (Personal access token)

1. Get your Personal Access Token ready, and the Organization name to add under.
2. Build the project: `docker build -t runner .`
3. Run the project: `docker run -it -e GITHUB_OWNER=orgnamehere -e GITHUB_PAT=personalaccesstokenhere runner`

Original readme is below.

---

This repository contains a Dockerfile that builds a Docker image suitable for
running a [self-hosted GitHub runner](https://help.github.com/en/actions/hosting-your-own-runners/about-self-hosted-runners). A Kubernetes Deployment file is also included that you can use to deploy this container to your Kubernetes cluster.

You can build this image yourself, or use the Docker image from the
[Docker Hub](https://hub.docker.com/repository/docker/sanderknape/github-runner/general).

More information can be found in my blog post: [Running self-hosted GitHub Actions runners in your Kubernetes cluster
](https://sanderknape.com/2020/03/self-hosted-github-actions-runner-kubernetes/)
