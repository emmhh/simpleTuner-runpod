# Build docker image and push to docker hub
Open docker desktop, click settings icon on the top right corner. Then click DockerEngine from the side panel, and paste following settings to allow longer time out to push docker iamge to docker hub
```json
{
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "default-ulimits": {
    "nofile": {
      "Hard": 64000,
      "Name": "nofile",
      "Soft": 64000
    }
  },
  "experimental": false,
  "max-concurrent-uploads": 1
}
```
# How to use docker image
Docker Image:
yang1234321/simple-tuner-runpod:v03-fix-env-var-missing
allows you to automat hugging face login

to use it, add this docker image on runpod platform. Name the environment variables as:
- 

# moving all documentation to google doc. 