# Placeholder Page

## Build and Push to Docker Hub

```bash
docker build -t hazelgallery/place-holder-page .
docker push hazelgallery/place-holder-page
```

## Pull and Run from Docker Hub

```bash
docker run -p 8510:80 -e PORT=8510 hazelgallery/place-holder-page
```