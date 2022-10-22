# Allianceauth Docker PyPy

This is the repo for building the Docker image using PyPy Python interpreter for AllianceAuth. Go to the package `authpypy` linked to this repo to see all the supported tags.

## Why using this image

The PyPy interpreter is a JIT for Python, in short it optimizes running teh same code multiple times. For a complete and technical description, go to [PyPy website](https://www.pypy.org/).

The main benefits of using this image over the CPython one provided by AllianceAuth are
1. Better task throughput, especially with the thread configuration of Celery suggested by the most task intesive apps like [MemberAudit](https://apps.allianceauth.org/apps/detail/aa-memberaudit)
2. Faster page loading for big installations with low cpu resources

while the main disadvantages are
1. Slower startup and slower execution of once in a while code like django shell
2. Possible incompatibility with some dependencies

## Moving to this image

WARNING: Before using this image in a live environment, you should test all of the following in a test environment because of the possible incompatibilities between PyPy and some Python dependencies that some community apps could have.

1. Update AllianceAuth to the latest version using the AllianceAuth image and make sure to follow release notes and test if everything works.
2. Change the image to this package one. If you follow the guide in AllianceAuth docs, you should have a line like this in the .env file  
```AA_DOCKER_TAG=registry.gitlab.com/allianceauth/allianceauth/auth:<VERSION_TAG>```.  
Replace the part before the version tag with
```ghcr.io/maestro-zacht/authpypy```, you should have something like this:  
```AA_DOCKER_TAG=ghcr.io/maestro-zacht/authpypy:<VERSION_TAG>```

The version tag is the same as AllianceAuth, so v3.3.0 of this image has v3.3.0 of AllianceAuth.

For better performance in Celery, you should increase the value of the `--max-tasks-per-child` to the maximum possible. This options is necessary in order to avoid memory leaks but it kills the process, vanishing all the benefits of using PyPy. I suggest doing a few tests with your environment and increase this number paying attention at memory usage.

## Updating this image

When an AllianceAuth update comes out, I'll build and publish the updated image. In order to update this image, you just have to follow the release notes of the update and change the version tag like you would do in the default image.

## Known incompatibilities
Here is a list of known incompatibilities as of `PyPy 3.9` and image version `v3.3.0`:  
- .