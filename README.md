# WebApollo

![WebApollo Logo](http://gmod.org/mediawiki/images/thumb/4/4a/WebApolloLogo.png/400px-WebApolloLogo.png)

From the [GMOD Wiki](http://gmod.org/wiki/WebApollo)

> WebApollo is a browser-based tool for visualisation and editing of sequence
> annotations. It is designed for distributed community annotation efforts,
> where numerous people may be working on the same sequences in geographically
> different locations; real-time updating keeps all users in sync during the
> editing process.

This container is a work in progress, so please be aware of that.

## Running the Container

The container is publicly available as `erasche/webapollo`. Running it requires a postgres database container which you can bring up with:

```console
$ docker run -d --name db postgres:9.4
```

Once that container is online (give it a second or two), you can bring up the webapollo container:

```console
$ docker run -i -t --link db:db erasche/webapollo
```

and you'll see the output of tomcat/webapollo as they boot. By default, the
container includes Pythium Utlimum data. WebApollo will boot, and be available
on [http://localhost:8080](http://localhost:8080).

Please note that per [issue #1](https://github.com/erasche/docker-webapollo/issues/1), the port you use to access WebApollo MUST be 8080.

## Building the Container Locally

A `fig.yml` file is available for building the container. Simply run:

```console
$ fig build
$ fig up
```

to build and bring up the two linked containers.

## TODO:

- Blat
- OAuth?
- ability to add users via ENV
- Turning WebApollo into a Galaxy [Interactive Environment](https://wiki.galaxyproject.org/Admin/IEs?highlight=%28interactive%29%7C%28environment%29)

