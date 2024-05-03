# django-test

```
docker build -t django-test .
docker run -d -p 8080:8080 django-test 
docker ps -a
docker rm -f <pid>

```

## Stop all the containers
```
docker stop $(docker ps -a -q)

```
## Remove all the containers
```
docker rm $(docker ps -a -q)
```
