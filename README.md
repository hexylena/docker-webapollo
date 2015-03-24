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
container includes no data! If you would like to load the example Pythium
Ultimum data, your launch command will be a little bit different:

```console
$ wget http://icebox.lbl.gov/webapollo/data/pyu_data.tgz
$ tar xvfz pyu_data.tgz
$ docker run -i -t -v `pwd`/pyu_data:/data --link db:db erasche/webapollo
````

WebApollo will boot, and be available on
[http://localhost:8080/apollo/](http://localhost:8080/apollo/). The username is
`web_apollo_admin` and the password is `password`.

## Building the Container Locally

A `fig.yml` file is available for building the container. Simply run:

```console
$ fig build
$ fig up
```

to build and bring up the two linked containers. To load the Pythium data, execute the following before `fig up`

```console
$ wget http://icebox.lbl.gov/webapollo/data/pyu_data.tgz
$ tar xvfz pyu_data.tgz
```

## TODO:

- Blat
- Turning WebApollo into a Galaxy [Interactive Environment](https://wiki.galaxyproject.org/Admin/IEs?highlight=%28interactive%29%7C%28environment%29)

## Environment Variables

Several configurable parameters are exposed as environment variables that can be set per-container. If you need more, just create a new [GitHub issue](https://github.com/erasche/docker-webapollo/issues/new).

Variable                | Use
----------------------- | ---
`APOLLO_ORGANISM`       | Organism name for use in main display
`APOLLO_AUTHENTICATION` | Authentication class name. [Docs](http://webapollo.readthedocs.org/en/latest/Configure/#database-configuration)
`DB_IS_CHADO`           | Not currently used, but in the future will inform Apollo that the database is a Chado instance and can be used for persisting annotations
`APOLLO_USERNAME`       | Default username for logging in. This account is added automatically, and permissions on any fasta files are automatically given to that user.
`APOLLO_PASSWORD`       | Default password for logging in.


## `REMOTE_USER` Authentication

Some sites prefer `REMOTE_USER` type authentication through an upstream proxy
like Apache or Nginx.

In order to use this type of authentication, you'll need to do a couple things. It's highly recommended that you use fig (or similar) to manage the images at this point:

Here's an example fig.yml:

```yaml
db:
    image: postgres:9.4
webapollo:
    image: erasche/webapollo
    links:
        - db
    ports:
        - "8080:8080"
    volumes:
        - ./pyu_data:/data
    environment:
        APOLLO_AUTHENTICATION: org.bbop.apollo.web.user.remoteuser.RemoteUserAuthentication
```

This will enable the RemoteUser authentication. Please make sure your upstream
proxy (e.g. apache) is sending a username in the `REMOTE_USER` header. (You can
check with a command like `sudo tcpdump -A -s 0 'tcp port 8080' -i lo` and
looking for the request headers)

Once you log in, you'll get a permission denied error and not be able to see
any tracks. You can fix that by running a script to add specific users to a
track:

```console
$ fig run webapollo /bin/register-user.sh 'username@fqdn.edu'
```
